// ─────────────────────────────────────────────────────────────
// med_result_writer.dart  (2026-06-04 신규)
//
// P1/P2가 만들어내는 공유 상태값(meal_status, med_status)의 정의와,
// 이를 UI 팀 Firestore 모델로 변환하는 헬퍼를 모았다.
//
// [중요 — 통합 담당자 읽을 것]
// UI 팀(capstone_guardian / capstone_patient)의 데이터 모델은
//   schedules/{id} : { kind, name, dose, time, taken(bool), takenAt }
// 처럼 복약/식사 결과를 "taken(bool) + takenAt" 으로만 표현한다.
//
// 반면 우리(센서 모듈)는 아래 enum처럼 더 풍부한 상태를 들고 있다.
// 둘을 잇는 방법은 두 가지인데, "오늘 통합" 우선이라 A안을 기본으로 둔다.
//
//   A안 (권장, UI 수정 최소) : taken(bool)은 그대로 쓰고, 우리 enum 상태는
//        별도 필드(detectStatus / mealStatus)로 "추가"만 한다.
//        → UI는 기존대로 bool만 읽고, 통계/기록 화면이 안 깨진다.
//        → toScheduleUpdate()가 이 형태의 맵을 만들어 준다.
//
//   B안 (깔끔하지만 UI 전면 수정) : taken을 enum으로 교체.
//        오늘 일정상 보류. 나중에 여유 생기면 전환.
//
// 실제 Firestore write 호출(ScheduleService.setTaken 등)은 통합 담당자가
// 연결한다. 이 파일은 "무엇을 쓸지"의 형태(맵)만 책임진다.
// ─────────────────────────────────────────────────────────────

/// 식사 진행 상태 (P1이 관리).
///
///   notEaten   : 아직 식사가 확인되지 않음 (초기/타임아웃 미식사).
///   inProgress : P1 진행 중. M_chew가 지속 감지되어 식사 중으로 판단된 상태.
///                ※ 지금은 Firestore에 직접 쓰지 않더라도, 실시간 UI 표시
///                  (예: 환자앱 "식사 중...") 용도로 남겨둔다. (정호님 요청)
///   eaten      : 식사 완료. M_chew 마지막 후 kSilenceToEaten(테스트: 30초) 무음 → P1 정상 종료 시.
enum MealStatus { notEaten, inProgress, eaten }

/// 복약 상태.
///
///   notTaken  : 아직 복약이 확인되지 않음 (초기/미복용).
///   detected  : [내부 전용 — 외부/UI로 내보내지 않음]
///               센서 점수가 임계값을 넘어 "감지됨" 상태를 나타내는 정호님 모듈
///               내부 개념. 외부 전달은 p2면 곧장 confirmed로 변환하므로 이 값이
///               Firestore/UI로 나가는 일은 없다. (2026-06-04)
///   unknown   : 약을 먹은 정황은 있으나 "어느 약인지 센서가 확정 못 함" → Gemini로
///               넘겨 "어떤 약 드셨어요?" 재확인. (식전/식후 동시 등록 시 단정 불가)
///               [2026-06-09] gap(공백기) 제거로 현재 이 상태를 만드는 경로는
///               없다(pendingMeds 배선은 유지하되 휴면).
///   confirmed : 복용 확정. P2 창에서 감지되면 그 모드의 약으로 확정하거나,
///               Gemini/보호자 확인으로 확정된 상태. UI의 taken=true 와 매핑.
///   missed    : 복약 창이 끝날 때까지 확정되지 않음 → 보호자 알림 대상.
enum MedStatus { notTaken, detected, unknown, confirmed, missed }

extension MealStatusX on MealStatus {
  /// Firestore/로그에 쓸 문자열 키.
  String get key {
    switch (this) {
      case MealStatus.notEaten:
        return 'not_eaten';
      case MealStatus.inProgress:
        return 'in_progress';
      case MealStatus.eaten:
        return 'eaten';
    }
  }
}

extension MedStatusX on MedStatus {
  String get key {
    switch (this) {
      case MedStatus.notTaken:
        return 'not_taken';
      case MedStatus.detected:
        return 'detected';
      case MedStatus.unknown:
        return 'unknown';
      case MedStatus.confirmed:
        return 'confirmed';
      case MedStatus.missed:
        return 'missed';
    }
  }

  /// UI 팀 모델의 taken(bool)으로 환산한 값 (A안 매핑).
  /// confirmed 일 때만 true. detected·unknown은 아직 미확정이므로 false.
  bool get asTakenBool => this == MedStatus.confirmed;

  /// Gemini 재확인이 필요한 상태인가.
  /// detected(스케줄 일치) + unknown(라벨 미정) 모두 Gemini가 최종 확인한다.
  bool get needsGemini =>
      this == MedStatus.detected || this == MedStatus.unknown;
}

/// 복약 감지 결과를 UI 팀의 schedules/{id} 문서 업데이트 맵으로 변환한다 (A안).
///
/// [주의] 이 메서드는 "어느 약인지 확정된" 경우에만 쓴다 (detected/confirmed).
/// 어느 약인지 모르는 unknown 감지는 toUnknownEvent()를 쓰고 scheduleId에 직접
/// 쓰지 않는다(잘못된 약에 기록될 위험).
///
/// 통합 담당자는 이 맵을 그대로 Firestore update에 넘기면 된다:
///   await FirebaseFirestore.instance
///       .collection('patients').doc(patientId)
///       .collection('schedules').doc(scheduleId)
///       .update(MedResultWriter.toScheduleUpdate(...));
///
/// - [status]    : MedStatus (detected/confirmed/missed 등). taken은 자동 환산.
/// - [takenAt]   : 감지/확정 시각. "HH:mm" 형식 (UI takenAt 포맷과 동일).
/// - [detectedBy]: 'sensor_p2' / 'gemini' / 'manual' 등 출처.
class MedResultWriter {
  static Map<String, dynamic> toScheduleUpdate({
    required MedStatus status,
    String? takenAt,
    String detectedBy = 'sensor_p2',
  }) {
    return {
      // ── UI 팀이 읽는 기존 필드 (A안: 그대로 유지) ──
      'taken': status.asTakenBool,
      'takenAt': status.asTakenBool ? takenAt : null,
      // ── 우리가 추가하는 보조 필드 (UI는 무시해도 동작) ──
      'detectStatus': status.key, // detected / confirmed / missed ...
      'detectedBy': detectedBy,
    };
  }

  /// "어느 약인지 모르는" 복약 감지 이벤트 (unknown).
  ///
  /// 스케줄 시간과 안 맞는 감지 등 어느 약인지 특정 못 하는 경우가 여기 해당.
  /// scheduleId에 직접 쓰지 않고, 별도 컬렉션(예: patients/{id}/pendingMeds)에
  /// 쌓아 두면 Gemini/보호자가 나중에 어느 약인지 확정한다.
  ///
  /// [2026-06-09] gap(공백기) 제거 후 현재 이 헬퍼를 호출하는 경로는 없다(휴면).
  ///
  /// 통합 담당자는 이 맵을 pendingMeds 같은 큐 컬렉션에 add 하면 된다:
  ///   await FirebaseFirestore.instance
  ///       .collection('patients').doc(patientId)
  ///       .collection('pendingMeds').add(MedResultWriter.toUnknownEvent(...));
  ///
  /// - [takenAt]   : 감지 시각 "HH:mm".
  /// - [detectedBy]: 'sensor_p1'(식사 중) 등 출처.
  /// - [score]     : 감지 당시 점수(디버그/신뢰도 참고용).
  static Map<String, dynamic> toUnknownEvent({
    String? takenAt,
    String detectedBy = 'sensor_p1',
    int? score,
  }) {
    return {
      'detectStatus': MedStatus.unknown.key, // 'unknown'
      'detectedBy': detectedBy,
      'takenAt': takenAt,
      'score': score,
      'needsGemini': true, // Gemini가 "어느 약 드셨어요?" 확인해야 함
    };
  }

  /// 식사 상태를 dailyLogs 또는 공유 상태 문서에 쓸 맵으로 변환.
  /// (UI가 식사도 schedules의 taken으로 관리하면 toScheduleUpdate를 쓰면 되고,
  ///  별도 meal 상태 필드를 둔다면 이 맵을 사용.)
  static Map<String, dynamic> toMealUpdate({
    required MealStatus status,
    String? eatenAt,
  }) {
    return {
      'mealStatus': status.key, // not_eaten / in_progress / eaten
      'taken': status == MealStatus.eaten, // UI bool 호환 (식사 완료=true)
      'takenAt': status == MealStatus.eaten ? eatenAt : null,
    };
  }
}
