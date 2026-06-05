// ─────────────────────────────────────────────────────────────
// med_sensing_binder.dart  (2026-06-05 신규)
//
// MedSensingService를 앱에 "꽂는" 글루 위젯. patientId가 확정된 화면(스케줄
// 화면) 위에 얹혀, 다음을 수행한다:
//   - service.init()   : tflite 모델 로드 + 오디오 파이프라인 준비 (1회)
//   - 콜백 연결          : onMedConfirmed/onUnknownMed/onMealEaten →
//                         ScheduleService 쓰기(patientId 바인딩)
//   - service.start()  : 스케줄 기반 감시 루프 + 가속도계 시작
//   - dispose → stop() : 화면이 사라지면 감시 정지
//
// 스케줄 입력(setSchedule)은 ScheduleScreen의 StreamBuilder에서 직접 넘긴다
// (이미 흐르는 스트림을 한 갈래 더 보내는 것이므로 중복 구독을 만들지 않음).
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/schedule_service.dart';
import 'med_sensing_service.dart';

class MedSensingBinder extends StatefulWidget {
  const MedSensingBinder({
    super.key,
    required this.patientId,
    required this.child,
  });

  final String patientId;
  final Widget child;

  @override
  State<MedSensingBinder> createState() => _MedSensingBinderState();
}

class _MedSensingBinderState extends State<MedSensingBinder> {
  late final MedSensingService _service;

  @override
  void initState() {
    super.initState();
    _service = context.read<MedSensingService>();
    final schedules = context.read<ScheduleService>();
    final pid = widget.patientId;

    // 콜백 → Firestore 쓰기 (patientId 바인딩)
    _service.onMedConfirmed = (scheduleId, at) =>
        schedules.setTaken(pid, scheduleId, takenAt: _hhmm(at));
    _service.onMealEaten = (scheduleId, at) =>
        schedules.setMeal(pid, scheduleId, eatenAt: _hhmm(at));
    _service.onUnknownMed = (score, at) =>
        schedules.addPendingMed(pid, takenAt: _hhmm(at), score: score);

    // 모델 로드(비동기) 완료 후 감시 시작. (start 전에 streamer.init 필요)
    _service.init().then((_) {
      if (mounted) _service.start();
    });
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }

  /// "HH:mm" (UI takenAt 포맷과 동일).
  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => widget.child;
}
