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
//   scorer.onTrigger(80점↑) ─▶ p2: onMedConfirmed
//   식사 상태머신(eaten) ─▶ onMealEaten + controller.notifyMealCompleted
//
// Firestore는 모른다(콜백으로만 결과 전달). 마이크 정책=(1) 예정시간 근처만:
// controller.micActive를 그대로 따라 켜고 끈다(p1→p2는 연속 유지).
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
  // [2026-06-09] 식사(씹기) 인식이 잘 안 돼 0.45 → 0.3으로 완화.
  static const double chewingThreshold = 0.3;
  static const double kCnnSwallowThreshold = 0.30;

  /// p2 트리거 → 그 약을 복용으로 확정. (scheduleId, 확정 시각)
  /// Provider가 patientId를 모른 채 서비스를 만들고, 환자 확정 후 바인더가
  /// 채우므로 final이 아니다.
  void Function(String scheduleId, DateTime at)? onMedConfirmed;

  /// 어느 약인지 미정인 복약 트리거. (점수, 시각) → 상위에서 pendingMeds 처리.
  /// [2026-06-09] gap(공백기) 단계를 제거하면서 현재 이 콜백을 발생시키는 경로가
  ///   없다(휴면). pendingMeds 배선은 유지하되, 호출자가 다시 생기기 전까지 미사용.
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
    // [2026-06-09] 식후약은 "식사완료" 이벤트로 P2 창을 연다(afterMedUsesMealEvent).
    // 연결된 식사가 +90분(kMealMaxDuration) 안에 감지되면 그 시점부터 창을 열고,
    // 끝내 감지 못 하면 창을 열지 않는다(폴백 없음). 식전/식사무관은 약 time 시계.
    _controller = MedPhaseController(
      onChanged: _onPhaseChanged,
      afterMedUsesMealEvent: true,
    );
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
    // 이 서비스는 Activity 없는 서비스 isolate에서 돈다. Permission.request()는
    // 권한 다이얼로그를 띄우려 Activity를 찾다가 플랫폼 채널에서 throw한다
    // (docs/log2.md). 실제 요청은 메인(UI) isolate의 requestPermissions()가
    // 이미 끝냈으므로, 여기선 Activity가 필요 없는 status 조회만 한다.
    final status = await Permission.microphone.status;
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

    // CNN 버퍼는 매 청크 누적해 연속성 유지(추론은 아래 IIR 게이트 통과 시에만).
    _swallow.pushAudio(chunk);

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
    // 2) 꿀꺽 (직렬 cascade, 2026-06-09):
    //    IIR(밴드패스+기침/말소리/충격음 차단)을 1차 게이트로 두고, 후보를 잡은
    //    청크에서만 CNN 추론을 돌린다. IIR이 못 잡으면 CNN 추론 자체를 생략.
    if (event.detected) {
      final cnnScore = _swallow.inferLatest();
      if (cnnScore >= kCnnSwallowThreshold) {
        _scorer.addSwallowDetection(confidence: cnnScore);
      }
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
        if (id != null) {
          _controller.notifyMedTaken(id); // 복용 확정 → 그 약 감시 창 즉시 종료
          onMedConfirmed?.call(id, at);
        }
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
