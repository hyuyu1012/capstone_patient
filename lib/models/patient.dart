/// The cared-for parent. Stored as `patients/{id}` in Firestore. `userId` is
/// null until the patient signs up in the patient-side app; `guardianIds` lists
/// every guardian that has joined via the [inviteCode].
class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.relation,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.gender,
    this.note,
    this.userId,
    required this.guardianIds,
    required this.inviteCode,
  });

  final String id;
  final String name; // "이순자"
  final String relation; // "어머니"
  final int birthYear;
  final int birthMonth;
  final int birthDay;
  final String gender; // 'female' | 'male'
  final String? note;
  final String? userId;
  final List<String> guardianIds;
  final String inviteCode;

  int get age {
    final today = DateTime.now();
    var a = today.year - birthYear;
    if (birthMonth > today.month ||
        (birthMonth == today.month && birthDay > today.day)) {
      a -= 1;
    }
    return a;
  }

  String get profileInitial => name.isEmpty ? '' : name.substring(0, 1);

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
        id: map['id'] as String,
        name: map['name'] as String,
        relation: map['relation'] as String,
        birthYear: (map['birthYear'] as num).toInt(),
        birthMonth: (map['birthMonth'] as num).toInt(),
        birthDay: (map['birthDay'] as num).toInt(),
        gender: map['gender'] as String,
        note: map['note'] as String?,
        userId: map['userId'] as String?,
        guardianIds: List<String>.from(map['guardianIds'] as List? ?? const []),
        inviteCode: map['inviteCode'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'relation': relation,
        'birthYear': birthYear,
        'birthMonth': birthMonth,
        'birthDay': birthDay,
        'gender': gender,
        'note': note,
        'userId': userId,
        'guardianIds': guardianIds,
        'inviteCode': inviteCode,
      };
}

/// A family member who can monitor the patient (설정 → 가족·보호자).
class Guardian {
  const Guardian({
    required this.id,
    required this.name,
    required this.relation,
    required this.active,
  });

  final String id;
  final String name; // "이지원"
  final String relation; // "딸"
  final bool active;

  factory Guardian.fromMap(Map<String, dynamic> map) => Guardian(
        id: map['id'] as String,
        name: map['name'] as String,
        relation: map['relation'] as String,
        active: map['active'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'relation': relation,
        'active': active,
      };
}
