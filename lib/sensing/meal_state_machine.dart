// ─────────────────────────────────────────────────────────────
// meal_state_machine.dart  (2026-06-05 신규)
//
// P1(식사) 단계에서 M_chew(씹는 소리)의 흐름만 보고 식사 상태를 판정한다.
// MedicationScorer는 M_chew를 "복약 오탐 차단(foodConflict)"용으로만 쓰고
// 식사 상태(inProgress/eaten)를 만들지 않으므로, 그 빠진 조각을 채운다.
//
// 규칙 (med_result_writer.dart의 MealStatus 정의를 따름):
//   notEaten   : 초기/씹기 부족.
//   inProgress : 씹기가 충분히(kMinChews) 감지됨 → 식사 중.
//   eaten      : 식사 중이던 상태에서 마지막 씹기 후 kSilenceToEaten(3분) 무음.
//                또는 P1 창이 닫힐 때 식사 중이었으면 마무리로 eaten 처리.
//
// 순수 Dart — 시각을 인자로 받아 단위 테스트가 가능하다(컨트롤러와 동일 방침).
// MedSensingService가 P1 동안 onChew/tick을, P1을 벗어날 때 finalizeOnExit를
// 호출한다. eaten이 되면 그 식사 id로 controller.notifyMealCompleted()(식후약
// P2 트리거) + Firestore setMeal을 수행한다.
// ─────────────────────────────────────────────────────────────

import 'med_result_writer.dart' show MealStatus;

class MealStateMachine {
  /// 식사로 인정하기까지 필요한 최소 M_chew 횟수(스파이크성 단발 오탐 방지).
  /// YAMNet의 chewingRequiredFrames(3)와 같은 취지.
  static const int kMinChews = 3;

  /// 식사 중 상태에서 이 시간만큼 씹기가 없으면 식사 완료로 본다.
  static const Duration kSilenceToEaten = Duration(minutes: 3);

  MealStatus _status = MealStatus.notEaten;
  int _chewCount = 0;
  DateTime? _lastChewAt;

  MealStatus get status => _status;

  /// 새 식사 창에 진입할 때 호출(상태 초기화).
  void reset() {
    _status = MealStatus.notEaten;
    _chewCount = 0;
    _lastChewAt = null;
  }

  /// 씹는 소리(임계값 넘은 chunk)가 감지될 때마다 호출.
  void onChew(DateTime now) {
    if (_status == MealStatus.eaten) return; // 이미 끝난 식사
    _lastChewAt = now;
    _chewCount++;
    if (_chewCount >= kMinChews) {
      _status = MealStatus.inProgress;
    }
  }

  /// 청크마다 현재 시각으로 호출. 방금 eaten으로 바뀌었으면 true.
  bool tick(DateTime now) {
    if (_status == MealStatus.inProgress &&
        _lastChewAt != null &&
        now.difference(_lastChewAt!) >= kSilenceToEaten) {
      _status = MealStatus.eaten;
      return true;
    }
    return false;
  }

  /// P1 창이 닫힐 때 호출. 식사 중이었으면 eaten으로 마무리하고 true 반환
  /// (식사창 끝까지 먹어 3분 무음을 못 채운 경우의 안전망).
  bool finalizeOnExit() {
    if (_status == MealStatus.inProgress) {
      _status = MealStatus.eaten;
      return true;
    }
    return false;
  }
}
