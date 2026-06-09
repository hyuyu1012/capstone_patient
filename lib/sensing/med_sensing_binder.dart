// ─────────────────────────────────────────────────────────────
// med_sensing_binder.dart  (2026-06-05 개편)
//
// YAMNet 감지 foreground service를 앱에 "꽂는" 글루 위젯. patientId가 확정된
// 화면(스케줄 화면) 위에 얹혀, 다음을 수행한다:
//   - controller.bind(patientId)          : 결과를 쓸 환자 문서 지정
//   - addTaskDataCallback(controller.onData): 서비스 isolate → 메인 메시지를
//                                            ScheduleService 쓰기로 연결
//   - 권한 요청 → init → start             : 상주 알림 + 감지 서비스 시작
//
// [접근 A — 상시 유지] 감지는 서비스 isolate에서 돌므로, 이 위젯이 사라져도
// (화면 전환/백그라운드) 서비스를 stop하지 않는다. 서비스 종료는 로그아웃 시
// schedule_screen의 핸들러에서 controller.stop()으로만 수행한다.
// (과거: dispose에서 service.stop() → 화면 벗어나면 감지가 죽던 동작을 제거)
//
// 스케줄 입력(pushSchedule)은 ScheduleScreen의 StreamBuilder에서 직접 넘긴다.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'sensing_foreground_controller.dart';

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
  late final SensingForegroundController _controller;
  late final void Function(Object) _onData;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SensingForegroundController>()
      ..bind(widget.patientId);

    // 웹에는 foreground service(flutter_foreground_task, android/ios 전용)가
    // 없으므로 감지 배선을 통째로 건너뛴다. UI/Firebase/스케줄은 정상 동작.
    if (kIsWeb) return;

    // 서비스 isolate가 보내는 감지 결과 → Firestore 쓰기.
    _onData = _controller.onData;
    FlutterForegroundTask.addTaskDataCallback(_onData);

    // 권한(알림+배터리 예외) 요청 후 서비스 시작. context를 쓰는 권한 다이얼로그가
    // 첫 프레임 이후에 뜨도록 postFrame에서 실행.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.requestPermissions();
      _controller.init();
      await _controller.start();
    });
  }

  @override
  void dispose() {
    // 콜백만 해제. 서비스는 상시 유지(로그아웃 시 schedule_screen에서 stop).
    if (!kIsWeb) {
      FlutterForegroundTask.removeTaskDataCallback(_onData);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
