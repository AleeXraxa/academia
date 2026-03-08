import 'dart:async';

import 'package:academia/app/data/models/batch_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AttendanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxList<AdminAttendanceSession> todaySessions =
      <AdminAttendanceSession>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool showMarkForm = false.obs;
  final RxString selectedBatchId = ''.obs;
  final RxString selectedBatchName = ''.obs;
  final RxString presentCountInput = ''.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _todaySubscription;

  String get todayKey {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get todayLabel {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get selectedBatchStudentsCount {
    final String id = selectedBatchId.value.trim();
    if (id.isEmpty) {
      return 0;
    }
    for (final BatchModel batch in batches) {
      if (batch.id == id) {
        return batch.studentsCount ?? 0;
      }
    }
    return 0;
  }

  @override
  void onInit() {
    super.onInit();
    _listenBatches();
    _listenTodaySessions();
  }

  void openMarkForm() {
    showMarkForm.value = true;
  }

  void closeMarkForm() {
    showMarkForm.value = false;
    selectedBatchId.value = '';
    selectedBatchName.value = '';
    presentCountInput.value = '';
  }

  void updateBatch(String batchId) {
    selectedBatchId.value = batchId;
    String label = '';
    for (final BatchModel batch in batches) {
      if (batch.id == batchId) {
        label = batch.name;
        break;
      }
    }
    selectedBatchName.value = label;
  }

  Future<void> saveTodayAttendance({required int presentCount}) async {
    final String batchId = selectedBatchId.value.trim();
    final String batchName = selectedBatchName.value.trim();
    if (batchId.isEmpty || batchName.isEmpty) {
      throw Exception('Select a batch first.');
    }
    if (presentCount < 0) {
      throw Exception('Present count cannot be negative.');
    }

    isSaving.value = true;
    try {
      final String docId = '${todayKey}_$batchId';
      final DocumentReference<Map<String, dynamic>> sessionDoc = _firestore
          .collection('attendance_sessions')
          .doc(docId);
      final DocumentSnapshot<Map<String, dynamic>> existing = await sessionDoc
          .get();
      if (existing.exists) {
        throw Exception('Session already generated for the $batchName batch');
      }
      final int totalStudents = selectedBatchStudentsCount;
      if (presentCount > totalStudents) {
        throw Exception('Present count cannot exceed batch size ($totalStudents).');
      }
      final int absentCount = (totalStudents - presentCount).clamp(0, 1000000);

      await sessionDoc.set(
        <String, dynamic>{
          'dateKey': todayKey,
          'date': Timestamp.fromDate(
            DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ),
          ),
          'batchId': batchId,
          'batchName': batchName,
          'totalStudents': totalStudents,
          'presentCount': presentCount,
          'absentCount': absentCount,
          'status': 'open',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      closeMarkForm();
      errorText.value = '';
    } finally {
      isSaving.value = false;
    }
  }

  void _listenBatches() {
    _batchesSubscription?.cancel();
    isLoading.value = true;

    _batchesSubscription = _firestore
        .collection('batches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<BatchModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      BatchModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            batches.assignAll(mapped);
            isLoading.value = false;
            errorText.value = '';
          },
          onError: (_) {
            errorText.value = 'Unable to load batches.';
            isLoading.value = false;
          },
        );
  }

  void _listenTodaySessions() {
    _todaySubscription?.cancel();
    _todaySubscription = _firestore
        .collection('attendance_sessions')
        .where('dateKey', isEqualTo: todayKey)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<AdminAttendanceSession> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      AdminAttendanceSession.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            todaySessions.assignAll(mapped);
          },
          onError: (_) {},
        );
  }

  @override
  void onClose() {
    _batchesSubscription?.cancel();
    _todaySubscription?.cancel();
    super.onClose();
  }
}

class AdminAttendanceSession {
  const AdminAttendanceSession({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.presentCount,
    required this.totalStudents,
    required this.absentCount,
    required this.status,
  });

  final String id;
  final String batchId;
  final String batchName;
  final int presentCount;
  final int totalStudents;
  final int absentCount;
  final String status;

  factory AdminAttendanceSession.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final Object? presentRaw = map['presentCount'];
    final Object? totalRaw = map['totalStudents'];
    final Object? absentRaw = map['absentCount'];

    return AdminAttendanceSession(
      id: id,
      batchId: (map['batchId'] as String?) ?? '',
      batchName: (map['batchName'] as String?) ?? 'Unknown Batch',
      presentCount: presentRaw is int ? presentRaw : int.tryParse('$presentRaw') ?? 0,
      totalStudents: totalRaw is int ? totalRaw : int.tryParse('$totalRaw') ?? 0,
      absentCount: absentRaw is int ? absentRaw : int.tryParse('$absentRaw') ?? 0,
      status: ((map['status'] as String?) ?? 'open').trim(),
    );
  }
}
