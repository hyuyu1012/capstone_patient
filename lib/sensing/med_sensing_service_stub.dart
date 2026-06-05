// ─────────────────────────────────────────────────────────────
// med_sensing_service_stub.dart  — 웹(및 dart:io 없는 플랫폼)용 no-op 구현
//
// tflite_flutter(dart:ffi)·flutter_sound·sensors_plus 같은 네이티브 의존성이
// 웹에서 컴파일/동작하지 않으므로, 웹 빌드에서는 이 빈 껍데기가 쓰인다.
// (웹은 어차피 마이크 PCM 녹음/TFLite 추론을 할 수 없으므로 감지는 비활성.)
//
// 네이티브 구현(med_sensing_service_io.dart)과 public API가 동일해야 한다
// — main.dart/MedSensingBinder/ScheduleScreen이 플랫폼과 무관하게 컴파일된다.
// ─────────────────────────────────────────────────────────────

import '../models/schedule_item.dart';
import 'med_sensing_state.dart';
import 'medication_scorer.dart' show MedPhase;

class MedSensingService {
  static const double chewingThreshold = 0.45;
  static const double kCnnSwallowThreshold = 0.30;

  void Function(String scheduleId, DateTime at)? onMedConfirmed;
  void Function(int score, DateTime at)? onUnknownMed;
  void Function(String mealId, DateTime at)? onMealEaten;
  void Function(MedSensingState state)? onState;

  MedSensingService({
    this.onMedConfirmed,
    this.onUnknownMed,
    this.onMealEaten,
    this.onState,
  });

  bool get isReady => false; // 웹에선 감지 엔진 비활성
  MedPhase get phase => MedPhase.idle;

  Future<void> init() async {/* no-op (웹) */}

  void setSchedule(List<ScheduleItem> items) {/* no-op (웹) */}

  void notifyMealCompleted(String mealId, DateTime at) {/* no-op (웹) */}

  void start() {/* no-op (웹) */}

  Future<void> stop() async {/* no-op (웹) */}

  Future<void> dispose() async {/* no-op (웹) */}
}
