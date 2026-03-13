import 'package:academia/app/data/models/attendance_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/data/repositories/attendance_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  AttendanceService({required AttendanceRepository repository})
    : _repository = repository;

  final AttendanceRepository _repository;

  Future<List<AttendanceModel>> fetchAttendanceByBatch(String batchId) {
    return _repository.fetchAttendanceByBatch(batchId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBatches() {
    return _repository.watchBatches();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSessionsByDateKey(
    String dateKey,
  ) {
    return _repository.watchSessionsByDateKey(dateKey);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentSessions({
    int limit = 300,
  }) {
    return _repository.watchRecentSessions(limit: limit);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getSession(String sessionId) {
    return _repository.getSession(sessionId);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchSessionsByDateAndBatch({
    required String dateKey,
    required String batchId,
  }) {
    return _repository.fetchSessionsByDateAndBatch(
      dateKey: dateKey,
      batchId: batchId,
    );
  }

  Future<void> setSession({
    required String sessionId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) {
    return _repository.setSession(sessionId: sessionId, data: data, merge: merge);
  }

  Future<void> updateSession({
    required String sessionId,
    required Map<String, dynamic> data,
  }) {
    return _repository.updateSession(sessionId: sessionId, data: data);
  }

  Future<void> batchSetSessions(Map<String, Map<String, dynamic>> sessions) {
    return _repository.batchSetSessions(sessions);
  }

  Future<List<StudentModel>> fetchStudentsForBatch(String batchId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _repository.fetchStudentsForBatch(batchId);
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              StudentModel.fromMap(id: doc.id, map: doc.data()),
        )
        .toList();
  }

  Future<Map<String, String>> fetchStudentNamesByIds(List<String> ids) async {
    final List<String> normalized = ids
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toList();
    if (normalized.isEmpty) {
      return <String, String>{};
    }
    final Map<String, String> namesById = <String, String>{};
    const int chunkSize = 10;
    for (int i = 0; i < normalized.length; i += chunkSize) {
      final int end = (i + chunkSize) > normalized.length
          ? normalized.length
          : i + chunkSize;
      final List<String> chunk = normalized.sublist(i, end);
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _repository.fetchStudentsByIds(chunk);
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final String name = (doc.data()['name'] as String?)?.trim() ?? '';
        namesById[doc.id] = name.isEmpty ? 'Student ${doc.id}' : name;
      }
    }
    for (final String id in normalized) {
      namesById[id] = namesById[id] ?? 'Student $id';
    }
    return namesById;
  }
}


