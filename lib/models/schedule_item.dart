/// A single dose or meal on a given day. Mirrors the `ScheduleItem` sketch in
/// the design handoff README.
enum ScheduleKind {
  med,
  meal;

  /// Korean label used in row metadata ("약" / "식사").
  String get label => this == ScheduleKind.med ? '약' : '식사';

  static ScheduleKind fromName(String name) =>
      name == 'meal' ? ScheduleKind.meal : ScheduleKind.med;
}

/// How a medication relates to meals. Drives *when* the sensor opens the P2
/// (medication) monitoring window:
///   - [after]  : triggered by *detected meal completion* (M_chew stops ~3min);
///                if the meal is never detected, no window opens (no fallback).
///   - [before] : clock-based window at the medication's scheduled [time].
///   - [none]   : meal-independent → pure clock-based window at [time]
///                (skips the P1 meal phase entirely).
/// Only meaningful for [ScheduleKind.med]; meal rows are always [none].
enum MealRelation {
  before, // 식전
  after, // 식후
  none; // 식사무관

  /// Korean label for row metadata ("식전" / "식후" / "").
  String get label => switch (this) {
        MealRelation.before => '식전',
        MealRelation.after => '식후',
        MealRelation.none => '',
      };

  /// Parses the Firestore string. Unknown/missing → [none], so schedules the
  /// guardian app wrote before this field existed still load correctly.
  static MealRelation fromName(String? name) => switch (name) {
        'before' => MealRelation.before,
        'after' => MealRelation.after,
        _ => MealRelation.none,
      };
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.time,
    this.dose,
    this.taken = false,
    this.takenAt,
    this.skipped = false,
    this.mealRelation = MealRelation.none,
    this.mealId,
  });

  final String id;
  final ScheduleKind kind;
  final String name;
  final String? dose; // med only — e.g. "1정"
  final String time; // "HH:mm" scheduled time
  final bool taken;
  final String? takenAt; // "HH:mm" completion time

  /// 보호자가 오늘 하루 의도적으로 건너뛴 항목. 완료(taken)와 상호 배타적이며,
  /// 건너뛴 일정은 "건너뜀"으로 표시한다 (보호자 앱이 이 필드를 쓴다).
  final bool skipped;
  final MealRelation mealRelation; // med only — 식전/식후/식사무관

  /// 식후약(after)이 연결된 식사의 스케줄 id. 보호자 앱이 등록 시 기록한다.
  /// 있으면 식사 연결을 시간추정 대신 이 id로 정확히 한다(없으면 시간추정 폴백).
  final String? mealId;

  /// Minutes since midnight for the scheduled [time] — handy for the 24h ring.
  int get scheduledMinutes => _toMinutes(time);

  /// Minutes since midnight for [takenAt], falling back to the scheduled time.
  int get markerMinutes => taken && takenAt != null ? _toMinutes(takenAt!) : scheduledMinutes;

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  ScheduleItem copyWith({
    bool? taken,
    String? takenAt,
    bool? skipped,
    bool clearTakenAt = false,
    MealRelation? mealRelation,
    String? mealId,
  }) {
    return ScheduleItem(
      id: id,
      kind: kind,
      name: name,
      dose: dose,
      time: time,
      taken: taken ?? this.taken,
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
      skipped: skipped ?? this.skipped,
      mealRelation: mealRelation ?? this.mealRelation,
      mealId: mealId ?? this.mealId,
    );
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) => ScheduleItem(
        id: map['id'] as String,
        kind: ScheduleKind.fromName(map['kind'] as String),
        name: map['name'] as String,
        dose: map['dose'] as String?,
        time: map['time'] as String,
        taken: map['taken'] as bool? ?? false,
        takenAt: map['takenAt'] as String?,
        skipped: map['skipped'] as bool? ?? false,
        mealRelation: MealRelation.fromName(map['mealRelation'] as String?),
        mealId: map['mealId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'dose': dose,
        'time': time,
        'taken': taken,
        'takenAt': takenAt,
        'skipped': skipped,
        'mealRelation': mealRelation.name,
        'mealId': mealId,
      };
}
