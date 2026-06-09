// ─────────────────────────────────────────────────────────────
// sensing_foreground_controller.dart  (2026-06-05 신규)
//
// 메인(UI) isolate 측에서 YAMNet 감지 foreground service의 수명과 통신을
// 담당한다. 감지 엔진 자체는 서비스 isolate(sensing_task_handler.dart)에서
// 돌고, 이 컨트롤러는:
//   - init/start/stop  : foreground service 생성·시작·종료
//   - pushSchedule     : Firestore 스케줄을 서비스 isolate로 전달
//   - onData           : 서비스 isolate가 보낸 감지 결과를 ScheduleService
//                        쓰기로 연결(기존 med_sensing_binder의 배선을 이전)
//
// "앱이 켜진 동안 상시 유지(접근 A)" — start는 환자 확정 시 1회, stop은
// 로그아웃 시에만. 화면 전환/백그라운드에서는 서비스를 내리지 않는다.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/schedule_service.dart';
import '../models/schedule_item.dart';
import 'sensing_task_handler.dart';

class SensingForegroundController {
  SensingForegroundController(this._schedules);

  final ScheduleService _schedules;
  String? _patientId;

  /// 현재 감시(P1/P2) 중인 스케줄 항목 id. idle이면 null. UI가 이 값을 구독해
  /// 해당 타일에 "진행중..."을 표시한다. (값이 바뀔 때만 리스너에 통지)
  final ValueNotifier<String?> activeTargetId = ValueNotifier<String?>(null);

  /// 감지 결과를 어느 환자 문서에 쓸지 바인딩.
  void bind(String patientId) => _patientId = patientId;

  /// 마이크 권한 + 상주 알림 권한 + 배터리 최적화 예외(Doze에서 덜 공격적으로 죽도록).
  ///
  /// 마이크(RECORD_AUDIO)는 반드시 **메인(UI) isolate에서 먼저** 요청한다. 안드로이드
  /// 런타임 권한 다이얼로그는 포그라운드 Activity에서만 정상적으로 뜨므로, 서비스
  /// isolate(_ensureMicPermission)에 맡기면 다이얼로그가 안 떠 조용히 거부될 수 있다.
  /// 여기서 미리 받아두면 서비스 isolate의 요청은 이미 granted라 즉시 통과한다.
  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    // 1) 마이크 — 감지의 핵심. 메인 isolate에서 다이얼로그를 띄워 받는다.
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
    }
    // 2) 상주 알림
    final perm = await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    // 3) 배터리 최적화 예외
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  /// 서비스/알림 채널 구성. 알람용 채널(med_reminders/meal_reminders, MAX +
  /// alarm sound)과 분리된 전용 LOW 채널이라 소리/heads-up 충돌이 없다.
  void init() {
    if (kIsWeb) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sensing_fgs',
        channelName: '복약·식사 감지',
        channelDescription: '약·식사 시간을 백그라운드에서 자동으로 감지합니다.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // 엔진이 자체 Timer(MedPhaseController)로 돌므로 주기 이벤트 불필요.
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// 서비스 시작(중복 가드 포함). 환자 확정 후 1회 호출.
  Future<void> start() async {
    if (kIsWeb) return;
    if (await FlutterForegroundTask.isRunningService) return;
    // 마이크 타입 FGS(Android 14+/SDK36)는 시작 시점에 RECORD_AUDIO가 granted여야 한다.
    // 없으면 startForeground가 SecurityException을 던져 서비스가 5초마다 재시작
    // 루프에 빠진다(실기기 로그에서 확인). 권한을 보장하고, 끝내 없으면 시작하지 않는다.
    if (!await Permission.microphone.isGranted) {
      await Permission.microphone.request();
    }
    if (!await Permission.microphone.isGranted) {
      return; // 마이크 거부 → 마이크 FGS 시작 안 함(크래시 루프 방지)
    }
    await FlutterForegroundTask.startService(
      serviceId: 2456,
      serviceTypes: const [ForegroundServiceTypes.microphone],
      notificationTitle: '복약·식사 감지 실행 중',
      notificationText: '약·식사 시간을 자동으로 감지합니다.',
      callback: startSensingCallback,
    );
  }

  /// 서비스 종료. 로그아웃/환자 해제 시에만.
  Future<void> stop() async {
    if (kIsWeb) return;
    await FlutterForegroundTask.stopService();
  }

  /// Firestore 스케줄을 서비스 isolate로 전달(컨트롤러 setSchedule).
  void pushSchedule(List<ScheduleItem> items) {
    if (kIsWeb) return;
    FlutterForegroundTask.sendDataToTask({
      'type': 'schedule',
      'items': items.map((i) => i.toMap()).toList(),
    });
  }

  /// 서비스 isolate → 메인 메시지 핸들러. 기존 binder의 Firestore 쓰기 로직.
  void onData(Object data) {
    if (data is! Map) return;
    // 감시 상태(UI "진행중..." 표시용) — 환자 바인딩과 무관하게 처리.
    if (data['type'] == 'state') {
      final phase = data['phase'] as String?;
      activeTargetId.value =
          (phase == null || phase == 'idle') ? null : data['targetId'] as String?;
      return;
    }
    final pid = _patientId;
    if (pid == null) return;
    switch (data['type']) {
      case 'medConfirmed':
        _schedules.setTaken(pid, data['id'] as String,
            takenAt: _hhmm(data['at'] as String));
      case 'mealEaten':
        _schedules.setMeal(pid, data['id'] as String,
            eatenAt: _hhmm(data['at'] as String));
      case 'unknownMed':
        _schedules.addPendingMed(pid,
            takenAt: _hhmm(data['at'] as String), score: data['score'] as int?);
      // 'state'는 UI 표시용 — 현재는 알림 본문 갱신(서비스 isolate)으로 충분.
    }
  }

  /// ISO8601 → "HH:mm" (UI takenAt 포맷과 동일).
  static String _hhmm(String iso) {
    final t = DateTime.parse(iso);
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
