// ─────────────────────────────────────────────────────────────
// sensing_task_handler.dart  (2026-06-05 신규)
//
// flutter_foreground_task의 **서비스 isolate** 진입점. YAMNet 감지 엔진
// (MedSensingService)을 이 isolate에서 통째로 돌린다. foreground service가
// 살아있는 동안 OS가 이 isolate의 펌프를 유지하므로, 화면이 꺼진 sleep
// 상태에서도 MedPhaseController의 Timer와 AudioStreamer 마이크 스트림이
// 계속 동작한다(메인 UI isolate는 백그라운드에서 paused될 수 있어 불가능).
//
// 결과(복약 확정/식사 완료/미정 복약)는 Firestore를 직접 쓰지 않고
// sendDataToMain으로 메인 isolate에 위임한다(med_sensing_binder가 받아서
// ScheduleService로 기록). 서비스 isolate에서 Firebase를 재초기화하는 가장
// 까다로운 부분을 피하기 위함 — 트리거는 하루 몇 번뿐이라 위임으로 충분하다.
//
// 스케줄은 메인 isolate가 sendDataToTask({'type':'schedule', ...})로 밀어주고
// onReceiveData에서 받아 컨트롤러에 주입한다.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/schedule_item.dart';
import 'med_sensing_service.dart';

/// 서비스 isolate가 시작될 때 호출되는 top-level 콜백.
/// 반드시 top-level/static + @pragma('vm:entry-point')여야 한다.
@pragma('vm:entry-point')
void startSensingCallback() {
  FlutterForegroundTask.setTaskHandler(SensingTaskHandler());
}

class SensingTaskHandler extends TaskHandler {
  MedSensingService? _service;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 이 isolate에서 platform channel(자산 로딩, flutter_sound, sensors_plus)을
    // 쓸 수 있게 한다. flutter_foreground_task가 대개 자동 처리하지만,
    // root 토큰을 얻을 수 있으면 명시적으로 보장해 둔다(없으면 이미 세팅된 것).
    final token = RootIsolateToken.instance;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    final service = MedSensingService(
      onMedConfirmed: (scheduleId, at) => FlutterForegroundTask.sendDataToMain({
        'type': 'medConfirmed',
        'id': scheduleId,
        'at': at.toIso8601String(),
      }),
      onUnknownMed: (score, at) => FlutterForegroundTask.sendDataToMain({
        'type': 'unknownMed',
        'score': score,
        'at': at.toIso8601String(),
      }),
      onMealEaten: (mealId, at) => FlutterForegroundTask.sendDataToMain({
        'type': 'mealEaten',
        'id': mealId,
        'at': at.toIso8601String(),
      }),
      onState: (s) {
        FlutterForegroundTask.sendDataToMain({
          'type': 'state',
          'phase': s.phase.name,
          'targetId': s.targetId, // "진행중..." 표시 대상 항목
          'listening': s.listening,
          'score': s.score,
          'reason': s.reason,
        });
        // 상주 알림 본문을 현재 감시 단계로 갱신해 동작을 가시화.
        FlutterForegroundTask.updateService(
          notificationTitle: '복약·식사 감지 실행 중',
          notificationText: s.reason,
        );
      },
    );
    _service = service;

    // init()/start()가 이 isolate에서 호출되므로 tflite Interpreter와
    // flutter_sound recorder가 서비스 isolate에 바인딩된다.
    await service.init();
    service.start();
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    if (data['type'] == 'schedule') {
      final rawItems = (data['items'] as List?) ?? const [];
      final items = rawItems
          .map((e) => ScheduleItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _service?.setSchedule(items);
    }
  }

  // 엔진이 자체 Timer로 돌므로 주기 이벤트는 사용하지 않는다.
  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _service?.dispose();
    _service = null;
  }
}
