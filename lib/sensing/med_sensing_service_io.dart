// ─────────────────────────────────────────────────────────────
// med_sensing_service_io.dart  — 네이티브(Android/iOS) 실제 구현
//
// tflite_flutter가 dart:ffi를 써서 웹 컴파일이 불가하므로, 이 파일은
// 조건부 import(med_sensing_service.dart)로 네이티브에서만 선택된다.
// 웹에서는 med_sensing_service_stub.dart(no-op)가 대신 쓰인다.
//
// YAMNet 감지 엔진의 "배선판". 스케줄 기반 컨트롤러가 마이크/단계를 운전한다.
//   MedPhaseController ─ onChanged ─▶ scorer.setPhase() + 마이크 start/stop
//   AudioStreamer ─ onChunk ─▶ Yamnet · Drink · Swallow ─▶ MedicationScorer
//   가속도계 ─▶ scorer.updateAccelerometer
//   scorer.onTrigger(80점↑) ─▶ p2: onMedConfirmed / gap: onUnknownMed
//   식사 상태머신(eaten) ─▶ onMealEaten + controller.notifyMealCompleted
//
// Firestore는 모른다(콜백으로만 결과 전달). 마이크 정책=(1) 예정시간 근처만:
// controller.micActive를 그대로 따라 켜고 끈다(p1→gap→p2는 연속 유지).
// ─────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/schedule_item.dart';
import 'audio_streamer.dart';
import 'drink_detector.dart';
import 'meal_state_machine.dart';
import 'med_phase_controller.dart';
import 'med_sensing_state.dart';
import 'medication_scorer.dart';
import 'swallow_inference.dart';
import 'yamnet_classifier.dart';

class MedSensingService {
  // ── YAMNet main.dart 튜닝 상수 (그대로 이식) ──
  static const double chewingThreshold = 0.45;
  static const double kCnnSwallowThreshold = 0.30;

  /// p2 트리거 → 그 약을 복용으로 확정. (scheduleId, 확정 시각)
  /// Provider가 patientId를 모른 채 서비스를 만들고, 환자 확정 후 바인더가
  /// 채우므로 final이 아니다.
  void Function(String scheduleId, DateTime at)? onMedConfirmed;

  /// gap 트리거 → 어느 약인지 미정. (점수, 시각) → 상위에서 pendingMeds 처리.
  void Function(int score, DateTime at)? onUnknownMed;

  /// 식사 완료 감지. (mealId, 완료 시각) → 상위에서 meal taken/mealStatus 기록.
  void Function(String mealId, DateTime at)? onMealEaten;

  /// 상태 변화 알림 (UI용).
  void Function(MedSensingState state)? onState;

  MedSensingService({
    this.onMedConfirmed,
    this.onUnknownMed,
    this.onMealEaten,
    this.onState,
  });

  // ── 엔진 ──
  final YamnetClassifier _classifier = YamnetClassifier();
  final AudioStreamer _streamer = AudioStreamer();
  final DrinkDetector _drink = DrinkDetector();
  final SwallowDetector _swallow = SwallowDetector();
  final MealStateMachine _meal = MealStateMachine();
  late final MedicationScorer _scorer;
  late final MedPhaseController _controller;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;

  bool _ready = false;
  bool _micPermissionDenied = false;
  bool _micBusy = false; // start/stop 중복 방지
  MedPhaseDecision _decision = MedPhaseDecision.idle;

  bool get isReady => _ready;
  MedPhase get phase => _decision.phase;

  // ── 초기화: 모델 로드 + 오디오 파이프라인 연결 ──
  Future<void> init() async {
    _scorer = MedicationScorer(onTrigger: _onScorerTrigger);
    _controller = MedPhaseController(onChanged: _onPhaseChanged);
    await _classifier.loadModel();
    await _swallow.init('assets/ml/swallow_classifier.tflite');
    await _streamer.init();
    _streamer.onChunk = _onChunk;
    _ready = true;
  }

  /// ScheduleService 스트림에서 받은 오늘 일정으로 컨트롤러를 갱신.
  void setSchedule(List<ScheduleItem> items) => _controller.setSchedule(items);

  /// (추후) 식사종료 감지기가 호출. 식후약 P2를 이벤트로 연다.
  void notifyMealCompleted(String mealId, DateTime at) =>
      _controller.notifyMealCompleted(mealId, at);

  // ── 구동 시작/정지 ──
  void start() {
    _controller.start(); // 즉시 1회 평가 → 창 안이면 onChanged가 마이크를 켠다
    _startAccelerometer();
  }

  Future<void> stop() async {
    _controller.stop();
    await _accelSub?.cancel();
    _accelSub = null;
    await _stopMic();
  }

  Future<void> dispose() async {
    await stop();
    await _streamer.dispose();
    _swallow.dispose();
    _classifier.dispose();
  }

  // ── 컨트롤러 결정 처리: setPhase + 마이크 + 식사 상태머신 수명 ──
  void _onPhaseChanged(MedPhaseDecision d) {
    final prev = _decision;
    _decision = d;
    _scorer.setPhase(d.phase);

    // 식사 상태머신 수명 관리
    if (d.phase == MedPhase.p1 && prev.phase != MedPhase.p1) {
      _meal.reset(); // 식사 창 진입 → 새 식사 세션 시작
    } else if (prev.phase == MedPhase.p1 && d.phase != MedPhase.p1) {
      // 식사 창 이탈 → 식사 중이었으면 eaten으로 마무리(3분 무음 못 채운 경우)
      if (_meal.finalizeOnExit() && prev.targetId != null) {
        _onMealEaten(prev.targetId!, DateTime.now());
      }
    }

    if (d.micActive) {
      _startMic();
    } else {
      _stopMic();
    }
    _emit();
  }

  Future<void> _startMic() async {
    if (_micBusy || _streamer.isRunning) return;
    _micBusy = true;
    try {
      if (!await _ensureMicPermission()) return;
      await _streamer.start();
    } finally {
      _micBusy = false;
    }
    _emit();
  }

  Future<void> _stopMic() async {
    if (_micBusy || !_streamer.isRunning) return;
    _micBusy = true;
    try {
      await _streamer.stop();
      _drink.reset();
      _swallow.resetBuffer();
      _scorer.reset(); // 창을 벗어나면 누적 점수 초기화(다음 창은 새로 시작)
    } finally {
      _micBusy = false;
    }
    _emit();
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    _micPermissionDenied = !status.isGranted;
    return status.isGranted;
  }

  void _startAccelerometer() {
    _accelSub ??= userAccelerometerEventStream().listen((e) {
      _scorer.updateAccelerometer(e.x, e.y, e.z);
    });
  }

  // ── 오디오 청크 처리 (YAMNet main.dart _onChunk 이식) ──
  void _onChunk(Float32List chunk) {
    final indexed = _classifier.classifyIndexed(chunk);
    final all = indexed.map((r) => r.toEntry()).toList();
    final cScore = _classifier.chewingScore(all);
    final event = _drink.process(chunk);

    _swallow.feedFloat32(chunk);
    final cnnScore = _swallow.lastScore;

    // 0) M_chew (음식 오탐 negative signal) 먼저 반영
    final chewing = cScore >= chewingThreshold;
    if (chewing) {
      _scorer.addChewDetection(confidence: cScore);
    }
    // 0-1) P1(식사) 단계면 식사 상태머신에도 씹기를 흘려보낸다.
    if (_decision.phase == MedPhase.p1) {
      final now = DateTime.now();
      if (chewing) _meal.onChew(now);
      if (_meal.tick(now) && _decision.targetId != null) {
        _onMealEaten(_decision.targetId!, now); // 식사 완료 → 식후약 P2 + 기록
      }
    }
    // 1) YAMNet 결과 전달
    for (final r in indexed) {
      _scorer.addYamnetResult(r.index, r.score);
    }
    // 2) 꿀꺽: CNN과 IIR이 같은 chunk에서 모두 감지될 때만 swallow 반영
    final swallowDetected = cnnScore >= kCnnSwallowThreshold && event.detected;
    if (swallowDetected) {
      _scorer.addSwallowDetection(confidence: cnnScore);
    }

    _emit();
  }

  // ── 식사 완료 → 식후약 P2 트리거 + 상위 기록 콜백 ──
  void _onMealEaten(String mealId, DateTime at) {
    _controller.notifyMealCompleted(mealId, at); // 식후약(after) P2 창을 연다
    onMealEaten?.call(mealId, at); // Firestore: meal taken/mealStatus
  }

  // ── 스코어러 80점 트리거 → phase로 분기 ──
  void _onScorerTrigger(MedTriggerResult r) {
    final at = DateTime.now();
    switch (r.phase) {
      case MedPhase.p2:
        final id = _decision.targetId;
        if (id != null) onMedConfirmed?.call(id, at);
        break;
      case MedPhase.gap:
        onUnknownMed?.call(r.score, at);
        break;
      case MedPhase.p1:
      case MedPhase.idle:
        break; // 트리거가 발생하지 않는 단계
    }
  }

  void _emit() {
    onState?.call(MedSensingState(
      phase: _decision.phase,
      targetId: _decision.targetId,
      listening: _streamer.isRunning,
      score: _scorer.currentScore,
      reason: _micPermissionDenied ? '마이크 권한 거부됨' : _decision.reason,
    ));
  }
}
