import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_item.dart';

/// Schedules one daily-repeating local notification per [ScheduleItem]. Each
/// notification fires at the item's "HH:mm" and plays a pre-recorded voice clip
/// as its channel sound, so the patient hears a spoken reminder even when the
/// app is closed.
///
/// Voice clips live as raw resources (Android) / bundle sounds (iOS):
///   android/app/src/main/res/raw/med_voice.mp3   ("약 드실 시간이에요")
///   android/app/src/main/res/raw/meal_voice.mp3  ("식사 시간이에요")
///   ios/Runner/med_voice.aiff / meal_voice.aiff
/// If a clip is missing the OS falls back to the default notification sound —
/// the reminder still fires, just without the custom voice.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  // Channel ids — Android binds the sound to the channel, so med/meal each get
  // their own channel to carry a different voice clip.
  static const _medChannelId = 'med_reminders';
  static const _mealChannelId = 'meal_reminders';

  // The signature of the last schedule set we registered, so an unchanged
  // Firestore snapshot doesn't trigger a needless cancel/reschedule storm.
  String? _lastSignature;

  // The items currently backing scheduled reminders. Used to figure out which
  // item is "due now" when a full-screen reminder wakes the app.
  List<ScheduleItem> _items = const [];
  List<ScheduleItem> get items => _items;

  Future<void> init() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Sounds are attached per-notification; ask for the permissions up front.
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _createAndroidChannels();
    await _requestPermissions();

    _ready = true;
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _medChannelId,
      '약 복용 알림',
      description: '약 복용 시간을 음성으로 알려줍니다.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('med_voice'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _mealChannelId,
      '식사 알림',
      description: '식사 시간을 음성으로 알려줍니다.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('meal_voice'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // Android 13+ runtime notification permission.
    await android?.requestNotificationsPermission();
    // Exact alarms (Android 12+) — needed for time-precise reminders.
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Re-registers notifications to match [items]. Cheap to call on every
  /// Firestore snapshot: it no-ops when the schedule set is unchanged.
  Future<void> syncSchedules(List<ScheduleItem> items) async {
    if (!_ready) await init();

    _items = List.unmodifiable(items);

    final signature = _signatureOf(items);
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    await _plugin.cancelAll();
    for (final item in items) {
      await _scheduleDaily(item);
    }
  }

  Future<void> _scheduleDaily(ScheduleItem item) async {
    final isMed = item.kind == ScheduleKind.med;
    final body = isMed
        ? [
            '약 드실 시간이에요',
            if (item.dose != null) item.dose!,
          ].join(' · ')
        : '식사 시간이에요';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isMed ? _medChannelId : _mealChannelId,
        isMed ? '약 복용 알림' : '식사 알림',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        sound: RawResourceAndroidNotificationSound(
            isMed ? 'med_voice' : 'meal_voice'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        // Wake the screen and launch the app over the lock screen, like an
        // alarm clock. On launch the app reads the item aloud via TTS.
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        sound: isMed ? 'med_voice.aiff' : 'meal_voice.aiff',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await _plugin.zonedSchedule(
      _idFor(item),
      item.name,
      body,
      _nextInstanceOf(item.time),
      details,
      payload: encodePayload(item),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeat every day at the same wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// The next occurrence of "HH:mm" in local time, rolling to tomorrow if the
  /// time already passed today.
  tz.TZDateTime _nextInstanceOf(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// A stable 31-bit notification id derived from the Firestore doc id.
  int _idFor(ScheduleItem item) => item.id.hashCode & 0x7fffffff;

  String _signatureOf(List<ScheduleItem> items) {
    final parts = items.map((i) => '${i.id}@${i.time}#${i.kind.name}').toList()
      ..sort();
    return parts.join('|');
  }

  /// Clears every scheduled reminder (e.g. on sign-out).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _lastSignature = null;
    _items = const [];
  }

  /// If the app was launched by tapping/by a full-screen reminder, returns the
  /// item to read aloud; otherwise null.
  Future<ScheduleItem?> launchReminder() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return decodePayload(details!.notificationResponse?.payload);
  }

  /// The item whose scheduled time is within [window] of [now] — used to pick
  /// what to speak when a full-screen reminder resumes an already-running app.
  ScheduleItem? dueItemAround(DateTime now,
      {Duration window = const Duration(minutes: 1)}) {
    final nowMin = now.hour * 60 + now.minute;
    ScheduleItem? best;
    int bestDelta = window.inMinutes + 1;
    for (final item in _items) {
      final delta = (item.scheduledMinutes - nowMin).abs();
      if (delta <= window.inMinutes && delta < bestDelta) {
        best = item;
        bestDelta = delta;
      }
    }
    return best;
  }

  // --- payload codec: enough to reconstruct what TTS needs to read ---

  static String encodePayload(ScheduleItem item) => jsonEncode({
        'id': item.id,
        'kind': item.kind.name,
        'name': item.name,
        'dose': item.dose,
        'time': item.time,
      });

  static ScheduleItem? decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return ScheduleItem.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}
