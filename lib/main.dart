import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'data/auth_service.dart';
import 'data/notification_service.dart';
import 'data/patient_link_service.dart';
import 'data/schedule_service.dart';
import 'data/tts_service.dart';
import 'firebase_options.dart';
import 'models/patient.dart';
import 'screens/claim_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/schedule_screen.dart';
import 'sensing/med_sensing_binder.dart';
import 'sensing/sensing_foreground_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 메인 isolate ↔ 감지 서비스 isolate 통신 포트(앱 시작 시 1회).
  // flutter_foreground_task는 android/ios 전용이고 내부적으로 dart:isolate
  // (ReceivePort/IsolateNameServer)를 쓰는데 웹에선 미지원이라 여기서 던진다.
  // 웹은 감지 자체가 no-op이므로 통신 포트도 건너뛴다.
  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notifications = NotificationService();
  await notifications.init();
  final tts = TtsService();

  // Cold start: if a full-screen reminder launched the app, read it aloud.
  final launchItem = await notifications.launchReminder();
  if (launchItem != null) {
    // Let the fixed notification clip play first, then speak the specifics.
    Future.delayed(const Duration(milliseconds: 1200),
        () => tts.speakItem(launchItem));
  }

  runApp(PatientApp(notifications: notifications, tts: tts));
}

class PatientApp extends StatelessWidget {
  const PatientApp({super.key, required this.notifications, required this.tts});

  final NotificationService notifications;
  final TtsService tts;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<PatientLinkService>(create: (_) => PatientLinkService()),
        Provider<ScheduleService>(create: (_) => ScheduleService()),
        Provider<NotificationService>.value(value: notifications),
        Provider<TtsService>.value(value: tts),
        // YAMNet sensing engine runs in a foreground-service isolate so it keeps
        // listening while the screen is off. This controller (main isolate side)
        // drives its lifecycle/communication; MedSensingBinder starts it once a
        // patient is known.
        Provider<SensingForegroundController>(
          create: (ctx) =>
              SensingForegroundController(ctx.read<ScheduleService>()),
        ),
      ],
      child: MaterialApp(
        title: '안심 케어 — 환자',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // WithForegroundTask keeps the service↔UI communication wired up.
        // 웹에는 foreground service가 없으므로 그대로 둔다.
        home: kIsWeb
            ? const _ReminderSpeaker(child: AuthGate())
            : WithForegroundTask(
                child: const _ReminderSpeaker(child: AuthGate()),
              ),
      ),
    );
  }
}

/// Watches the app lifecycle: when a full-screen reminder brings an
/// already-running app to the foreground, read the due item aloud. (Cold-start
/// launches are handled in main() via NotificationService.launchReminder.)
class _ReminderSpeaker extends StatefulWidget {
  const _ReminderSpeaker({required this.child});
  final Widget child;

  @override
  State<_ReminderSpeaker> createState() => _ReminderSpeakerState();
}

class _ReminderSpeakerState extends State<_ReminderSpeaker>
    with WidgetsBindingObserver {
  // Guard so one reminder isn't spoken twice (e.g. resume fires repeatedly).
  String? _lastSpokenKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    final due = context.read<NotificationService>().dueItemAround(now);
    if (due == null) return;
    final key = '${due.id}@${now.hour}:${now.minute}';
    if (key == _lastSpokenKey) return;
    _lastSpokenKey = key;
    context.read<TtsService>().speakItem(due);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Routes by auth + claim state: signed-out → Login; signed-in but no claimed
/// patient → Claim; claimed → Schedule.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _PatientHome(uid: user.uid);
      },
    );
  }
}

class _PatientHome extends StatelessWidget {
  const _PatientHome({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final links = context.read<PatientLinkService>();
    return StreamBuilder<Patient?>(
      stream: links.myPatient(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final patient = snap.data;
        if (patient == null) return const ClaimScreen();
        // Wrap the schedule UI so the sensing engine starts/stops with it and
        // its results are written back to this patient's schedules.
        return MedSensingBinder(
          patientId: patient.id,
          child: ScheduleScreen(patient: patient),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
