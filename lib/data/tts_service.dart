import 'package:flutter_tts/flutter_tts.dart';

import '../models/schedule_item.dart';

/// Speaks a reminder out loud in Korean. Used when a full-screen-intent
/// notification wakes the app at a scheduled time — the fixed notification clip
/// plays first ("약 드실 시간이에요"), then this reads the specific item
/// ("오메가3 한 정 드실 시간이에요").
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.45); // a touch slower — easier for older users
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Route over the alarm/media stream and wait for completion.
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Reads a single schedule item. Safe to call repeatedly; stops any
  /// in-progress utterance first.
  Future<void> speakItem(ScheduleItem item) => speak(sentenceFor(item));

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureReady();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  /// The spoken sentence for an item, e.g.
  ///   med  + dose → "오메가3, 한 정 드실 시간이에요"
  ///   med  (no dose) → "오메가3 드실 시간이에요"
  ///   meal → "식사 시간이에요. 김치찌개 드세요" (name optional)
  static String sentenceFor(ScheduleItem item) {
    if (item.kind == ScheduleKind.med) {
      final dose = item.dose;
      return dose != null && dose.trim().isNotEmpty
          ? '${item.name}, $dose 드실 시간이에요'
          : '${item.name} 드실 시간이에요';
    }
    // meal
    return '식사 시간이에요. ${item.name} 드세요';
  }
}
