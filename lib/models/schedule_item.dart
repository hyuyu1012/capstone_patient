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
///   - [after]  : triggered by *detected meal completion* (M_chew stops ~3min),
///                with the scheduled [ScheduleItem.time] as a clock fallback.
///   - [before] : window opens ahead of the meal's scheduled time.
///   - [none]   : meal-independent → pure clock-based window at [time]
///                (skips the P1/gap meal phases entirely).
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
    this.mealRelation = MealRelation.none,
  });

  final String id;
  final ScheduleKind kind;
  final String name;
  final String? dose; // med only — e.g. "1정"
  final String time; // "HH:mm" scheduled time
  final bool taken;
  final String? takenAt; // "HH:mm" completion time
  final MealRelation mealRelation; // med only — 식전/식후/식사무관

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
    bool clearTakenAt = false,
    MealRelation? mealRelation,
  }) {
    return ScheduleItem(
      id: id,
      kind: kind,
      name: name,
      dose: dose,
      time: time,
      taken: taken ?? this.taken,
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
      mealRelation: mealRelation ?? this.mealRelation,
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
        mealRelation: MealRelation.fromName(map['mealRelation'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'dose': dose,
        'time': time,
        'taken': taken,
        'takenAt': takenAt,
        'mealRelation': mealRelation.name,
      };
}
