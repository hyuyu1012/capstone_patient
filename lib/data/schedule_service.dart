import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_item.dart';
import '../sensing/med_result_writer.dart';

/// Reads the `patients/{patientId}/schedules` subcollection the guardian app
/// writes to, and writes back the sensor results (taken/eaten) the YAMNet
/// sensing engine produces. The maps come from [MedResultWriter] so the field
/// shape stays in sync with the guardian/UI model.
class ScheduleService {
  ScheduleService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _schedules(String patientId) => _db
      .collection('patients')
      .doc(patientId)
      .collection('schedules');

  Stream<List<ScheduleItem>> schedulesFor(String patientId) {
    return _schedules(patientId).orderBy('time').snapshots().map((snap) => snap
        .docs
        .map((d) => ScheduleItem.fromMap({...d.data(), 'id': d.id}))
        .toList());
  }

  /// 복약 확정(P2 트리거): schedules/{id}.taken=true + takenAt + 보조 필드.
  Future<void> setTaken(
    String patientId,
    String scheduleId, {
    required String takenAt,
    String detectedBy = 'sensor_p2',
  }) {
    return _schedules(patientId).doc(scheduleId).update(
          MedResultWriter.toScheduleUpdate(
            status: MedStatus.confirmed,
            takenAt: takenAt,
            detectedBy: detectedBy,
          ),
        );
  }

  /// 식사 완료(P1): schedules/{id}.mealStatus=eaten + taken=true + takenAt.
  Future<void> setMeal(
    String patientId,
    String scheduleId, {
    required String eatenAt,
  }) {
    return _schedules(patientId).doc(scheduleId).update(
          MedResultWriter.toMealUpdate(
            status: MealStatus.eaten,
            eatenAt: eatenAt,
          ),
        );
  }

  /// 어느 약인지 미정인 복약: pendingMeds 큐에 적재 → 추후 보호자/Gemini 확인.
  /// [2026-06-09] gap(공백기) 제거 후 현재 호출자가 없다(휴면 — 배선만 유지).
  Future<void> addPendingMed(
    String patientId, {
    required String takenAt,
    int? score,
    String detectedBy = 'sensor_unknown',
  }) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('pendingMeds')
        .add(MedResultWriter.toUnknownEvent(
          takenAt: takenAt,
          score: score,
          detectedBy: detectedBy,
        ));
  }
}
