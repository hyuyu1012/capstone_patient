import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient.dart';

class PatientLinkException implements Exception {
  PatientLinkException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Patient-side counterpart to the guardian app's PatientService. The guardian
/// creates the `patients/{id}` doc (with an `inviteCode`); here the patient
/// "claims" it by setting `userId = own uid`, then reads it back live.
class PatientLinkService {
  PatientLinkService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _patients =>
      _db.collection('patients');

  /// Finds the patient with [code] and stamps it with [patientUid]. Idempotent
  /// for the same uid; refuses a doc already claimed by someone else.
  Future<Patient> claimByInviteCode({
    required String code,
    required String patientUid,
  }) async {
    final normalized = code.toUpperCase().trim();
    final query = await _patients
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw PatientLinkException('잘못된 초대 코드예요. 다시 확인해주세요.');
    }
    final doc = query.docs.first;
    final data = doc.data();
    final existing = data['userId'] as String?;
    if (existing != null && existing != patientUid) {
      throw PatientLinkException('이미 다른 계정에 연결된 환자예요.');
    }
    if (existing == null) {
      await doc.reference.update({'userId': patientUid});
    }
    return Patient.fromMap({...data, 'id': doc.id, 'userId': patientUid});
  }

  /// Live patient doc claimed by [patientUid] (null until claimed).
  Stream<Patient?> myPatient(String patientUid) {
    return _patients
        .where('userId', isEqualTo: patientUid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : Patient.fromMap({...snap.docs.first.data(), 'id': snap.docs.first.id}));
  }
}
