import 'package:academia/app/data/models/attendance_model.dart';
import 'package:academia/app/services/network_guard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<AttendanceModel>> fetchAttendanceByBatch(String batchId) async {
    return <AttendanceModel>[];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBatches() {
    return _firestore
        .collection('batches')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSessionsByDateKey(
    String dateKey,
  ) {
    return _firestore
        .collection('attendance_sessions')
        .where('dateKey', isEqualTo: dateKey)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentSessions({
    int limit = 300,
  }) {
    return _firestore
        .collection('attendance_sessions')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSession(String sessionId) {
    return _firestore.collection('attendance_sessions').doc(sessionId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchSessionsByDateAndBatch({
    required String dateKey,
    required String batchId,
  }) {
    return _firestore
        .collection('attendance_sessions')
        .where('dateKey', isEqualTo: dateKey.trim())
        .where('batchId', isEqualTo: batchId.trim())
        .limit(1)
        .get();
  }

  Future<void> setSession({
    required String sessionId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) {
    return NetworkGuard.run(
      _firestore
          .collection('attendance_sessions')
          .doc(sessionId)
          .set(data, SetOptions(merge: merge)),
    );
  }

  Future<void> updateSession({
    required String sessionId,
    required Map<String, dynamic> data,
  }) {
    return NetworkGuard.run(
      _firestore.collection('attendance_sessions').doc(sessionId).update(data),
    );
  }

  Future<void> batchSetSessions(Map<String, Map<String, dynamic>> sessions) async {
    final WriteBatch writeBatch = _firestore.batch();
    sessions.forEach((String sessionId, Map<String, dynamic> data) {
      final DocumentReference<Map<String, dynamic>> doc = _firestore
          .collection('attendance_sessions')
          .doc(sessionId);
      writeBatch.set(doc, data, SetOptions(merge: true));
    });
    await NetworkGuard.run(writeBatch.commit());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchStudentsForBatch(
    String batchId,
  ) {
    return _firestore
        .collection('students')
        .where('batchId', isEqualTo: batchId.trim())
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchStudentsByIds(
    List<String> ids,
  ) {
    return _firestore
        .collection('students')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
  }
}


