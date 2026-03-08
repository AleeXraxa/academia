import 'dart:async';

import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/data/repositories/attendance_repository.dart';
import 'package:academia/app/services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AttendanceController extends GetxController {
  final AttendanceService _attendanceService = AttendanceService(
    repository: AttendanceRepository(),
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxList<AdminAttendanceSession> todaySessions =
      <AdminAttendanceSession>[].obs;
  final List<AdminAttendanceSession> _rawTodaySessions =
      <AdminAttendanceSession>[];
  final RxList<AdminAttendanceSession> historySessions =
      <AdminAttendanceSession>[].obs;
  final List<AdminAttendanceSession> _rawHistorySessions =
      <AdminAttendanceSession>[];

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool showMarkForm = false.obs;
  final RxInt mobileTabIndex = 0.obs;
  final RxInt historyRangeDays = 7.obs;
  final RxString historyBatchId = ''.obs;
  final RxList<String> selectedGenerationBatchIds = <String>[].obs;
  final RxMap<String, String> generationPresentByBatchId = <String, String>{}.obs;
  final RxString selectedBatchId = ''.obs;
  final RxString selectedBatchName = ''.obs;
  final RxString presentCountInput = ''.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _todaySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySubscription;

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
    _listenHistorySessions();
  }

  void openMarkForm() {
    _prepareGenerationState();
    showMarkForm.value = true;
  }

  void updateMobileTab(int index) {
    mobileTabIndex.value = index;
  }

  void updateHistoryRangeDays(int days) {
    historyRangeDays.value = days;
  }

  void updateHistoryBatchId(String batchId) {
    historyBatchId.value = batchId.trim();
  }

  List<BatchModel> get teacherAssignedBatches {
    final String teacherUid = (_auth.currentUser?.uid ?? '').trim();
    if (teacherUid.isEmpty) {
      return <BatchModel>[];
    }
    return batches
        .where((BatchModel batch) => (batch.teacherId ?? '').trim() == teacherUid)
        .toList();
  }

  List<AdminAttendanceSession> get filteredHistorySessions {
    final int rangeDays = historyRangeDays.value;
    final String selectedBatch = historyBatchId.value.trim();
    final DateTime now = DateTime.now();
    final DateTime startDate = rangeDays <= 0
        ? DateTime(2000, 1, 1)
        : DateTime(now.year, now.month, now.day).subtract(
            Duration(days: rangeDays - 1),
          );

    final List<AdminAttendanceSession> filtered = historySessions.where((
      AdminAttendanceSession session,
    ) {
      final bool batchMatch =
          selectedBatch.isEmpty || session.batchId.trim() == selectedBatch;
      final DateTime sessionDate =
          session.date ??
          DateTime.tryParse('${session.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      final bool dateMatch = rangeDays <= 0 || !sessionDate.isBefore(startDate);
      return batchMatch && dateMatch;
    }).toList();

    filtered.sort((AdminAttendanceSession a, AdminAttendanceSession b) {
      final DateTime ad =
          a.date ?? DateTime.tryParse('${a.dateKey} 00:00:00') ?? DateTime(2000, 1, 1);
      final DateTime bd =
          b.date ?? DateTime.tryParse('${b.dateKey} 00:00:00') ?? DateTime(2000, 1, 1);
      return bd.compareTo(ad);
    });
    return filtered;
  }

  int get historyTotalSessions => filteredHistorySessions.length;
  int get historyTotalPresent => filteredHistorySessions.fold<int>(
    0,
    (int sum, AdminAttendanceSession session) => sum + session.presentCount,
  );
  int get historyTotalLeave => filteredHistorySessions.fold<int>(
    0,
    (int sum, AdminAttendanceSession session) => sum + session.leaveCount,
  );
  int get historyTotalAbsent => filteredHistorySessions.fold<int>(
    0,
    (int sum, AdminAttendanceSession session) => sum + session.absentCount,
  );
  double get historyAverageAttendancePercentage {
    if (filteredHistorySessions.isEmpty) {
      return 0;
    }
    final double total = filteredHistorySessions.fold<double>(
      0,
      (double sum, AdminAttendanceSession session) {
        if (session.totalStudents <= 0) {
          return sum;
        }
        return sum +
            ((session.presentCount + session.leaveCount) / session.totalStudents) *
                100;
      },
    );
    return total / filteredHistorySessions.length;
  }

  String get historyBestBatch {
    if (filteredHistorySessions.isEmpty) {
      return '--';
    }
    final Map<String, List<double>> batchScores = <String, List<double>>{};
    for (final AdminAttendanceSession session in filteredHistorySessions) {
      if (session.totalStudents <= 0) {
        continue;
      }
      final String key = '${session.batchId}|${session.batchName}';
      final double percent =
          ((session.presentCount + session.leaveCount) / session.totalStudents) *
          100;
      batchScores.putIfAbsent(key, () => <double>[]).add(percent);
    }
    if (batchScores.isEmpty) {
      return '--';
    }
    String bestName = '--';
    double bestAvg = -1;
    batchScores.forEach((String key, List<double> values) {
      final double avg = values.reduce((double a, double b) => a + b) / values.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestName = key.split('|').last;
      }
    });
    return bestName;
  }

  void closeMarkForm() {
    showMarkForm.value = false;
    selectedGenerationBatchIds.clear();
    generationPresentByBatchId.clear();
    selectedBatchId.value = '';
    selectedBatchName.value = '';
    presentCountInput.value = '';
  }

  List<BatchModel> get todayScheduledBatches {
    return batches.where(_isBatchScheduledToday).toList();
  }

  List<BatchModel> get generationCandidateBatches {
    final List<BatchModel> scheduled = todayScheduledBatches;
    if (scheduled.isNotEmpty) {
      return scheduled;
    }
    return batches.where(_isBatchActiveForGeneration).toList();
  }

  bool get isUsingScheduleFallback {
    return todayScheduledBatches.isEmpty && generationCandidateBatches.isNotEmpty;
  }

  bool isBatchSelectedForGeneration(String batchId) {
    final String id = batchId.trim();
    return selectedGenerationBatchIds.any((String selectedId) => selectedId == id);
  }

  String presentInputForBatch(String batchId) {
    return generationPresentByBatchId[batchId.trim()] ?? '';
  }

  void toggleBatchForGeneration({
    required String batchId,
    required bool selected,
  }) {
    final String id = batchId.trim();
    if (id.isEmpty) {
      return;
    }
    final List<String> nextSelected = selectedGenerationBatchIds.toList();
    if (selected) {
      if (!nextSelected.contains(id)) {
        nextSelected.add(id);
        selectedGenerationBatchIds.assignAll(nextSelected);
      }
      generationPresentByBatchId[id] = generationPresentByBatchId[id] ?? '';
      generationPresentByBatchId.refresh();
      return;
    }
    nextSelected.remove(id);
    selectedGenerationBatchIds.assignAll(nextSelected);
    generationPresentByBatchId[id] = '';
    generationPresentByBatchId.refresh();
  }

  void updatePresentInputForBatch({
    required String batchId,
    required String value,
  }) {
    generationPresentByBatchId[batchId.trim()] = value;
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
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await _attendanceService.getSession(docId);
      if (existing.exists) {
        throw Exception('Session already generated for the $batchName batch');
      }
      final int totalStudents = selectedBatchStudentsCount;
      if (presentCount > totalStudents) {
        throw Exception(
          'Present count cannot exceed batch size ($totalStudents).',
        );
      }
      final int absentCount = (totalStudents - presentCount).clamp(0, 1000000);

      await _attendanceService.setSession(
        sessionId: docId,
        data: <String, dynamic>{
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
        'leaveCount': 0,
        'absentCount': absentCount,
        'status': 'open',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        },
        merge: true,
      );

      closeMarkForm();
      errorText.value = '';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveTodayAttendanceForSelectedBatches() async {
    final List<BatchModel> todayBatches = generationCandidateBatches;
    final List<String> selectedIds = selectedGenerationBatchIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toList();

    if (todayBatches.isEmpty) {
      throw Exception('No batches are scheduled for today.');
    }
    if (selectedIds.isEmpty) {
      throw Exception('Select at least one batch to generate session.');
    }

    final Map<String, BatchModel> byId = <String, BatchModel>{
      for (final BatchModel batch in todayBatches) batch.id: batch,
    };

    isSaving.value = true;
    try {
      for (final String batchId in selectedIds) {
        final BatchModel? batch = byId[batchId];
        if (batch == null) {
          throw Exception('Selected batch is not scheduled for today.');
        }
        final String rawInput = (generationPresentByBatchId[batchId] ?? '').trim();
        final int? presentCount = int.tryParse(rawInput);
        if (presentCount == null) {
          throw Exception('Enter valid present count for ${batch.name}.');
        }
        if (presentCount < 0) {
          throw Exception('Present count cannot be negative for ${batch.name}.');
        }
        final int totalStudents = batch.studentsCount ?? 0;
        if (presentCount > totalStudents) {
          throw Exception(
            'Present count cannot exceed batch size ($totalStudents) for ${batch.name}.',
          );
        }
      }

      for (final String batchId in selectedIds) {
        final BatchModel batch = byId[batchId]!;
        final String docId = '${todayKey}_$batchId';
        final DocumentSnapshot<Map<String, dynamic>> existing =
            await _attendanceService.getSession(docId);
        if (existing.exists) {
          throw Exception(
            'Session already generated for the ${batch.name} batch',
          );
        }
      }

      final Map<String, Map<String, dynamic>> sessionsPayload =
          <String, Map<String, dynamic>>{};
      for (final String batchId in selectedIds) {
        final BatchModel batch = byId[batchId]!;
        final int totalStudents = batch.studentsCount ?? 0;
        final int presentCount = int.parse(
          (generationPresentByBatchId[batchId] ?? '0').trim(),
        );
        final int absentCount = (totalStudents - presentCount).clamp(0, 1000000);
        sessionsPayload['${todayKey}_$batchId'] = <String, dynamic>{
          'dateKey': todayKey,
          'date': Timestamp.fromDate(
            DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ),
          ),
          'batchId': batchId,
          'batchName': batch.name,
          'totalStudents': totalStudents,
          'presentCount': presentCount,
          'leaveCount': 0,
          'absentCount': absentCount,
          'status': 'open',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };
      }

      await _attendanceService.batchSetSessions(sessionsPayload);
      closeMarkForm();
      errorText.value = '';
    } finally {
      isSaving.value = false;
    }
  }

  Future<List<StudentModel>> fetchStudentsForBatch(String batchId) async {
    return _attendanceService.fetchStudentsForBatch(batchId);
  }

  Future<Map<String, String>> fetchStudentNamesByIds(List<String> studentIds) async {
    return _attendanceService.fetchStudentNamesByIds(studentIds);
  }

  Future<void> submitTeacherAttendance({
    required String sessionId,
    required List<String> presentStudentIds,
    required List<String> leaveStudentIds,
    required List<String> absentStudentIds,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> sessionSnapshot =
        await _attendanceService.getSession(sessionId);
    final Map<String, dynamic> sessionMap =
        sessionSnapshot.data() ?? <String, dynamic>{};
    final Object? totalRaw = sessionMap['totalStudents'];
    final int totalStudents = totalRaw is int
        ? totalRaw
        : int.tryParse('$totalRaw') ?? 0;
    final int presentCount = presentStudentIds.length;
    final int leaveCount = leaveStudentIds.length;
    final int computedAbsentCount = (totalStudents - presentCount - leaveCount)
        .clamp(0, 1000000);
    final List<String> normalizedAbsentStudentIds =
        absentStudentIds.length <= computedAbsentCount
        ? absentStudentIds
        : absentStudentIds.take(computedAbsentCount).toList();

    final String uid = _auth.currentUser?.uid ?? '';
    await _attendanceService.updateSession(
      sessionId: sessionId,
      data: <String, dynamic>{
          'presentCount': presentCount,
          'leaveCount': leaveCount,
          'absentCount': computedAbsentCount,
          'presentStudentIds': presentStudentIds,
          'leaveStudentIds': leaveStudentIds,
          'absentStudentIds': normalizedAbsentStudentIds,
          'teacherMarkedBy': uid,
          'teacherMarkedAt': FieldValue.serverTimestamp(),
          'teacherSubmitted': true,
          'status': 'submitted_by_teacher',
          'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  void _listenBatches() {
    _batchesSubscription?.cancel();
    isLoading.value = true;

    _batchesSubscription = _attendanceService.watchBatches().listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<BatchModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      BatchModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            batches.assignAll(mapped);
            _applySessionVisibility();
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
    _todaySubscription = _attendanceService
        .watchSessionsByDateKey(todayKey)
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<AdminAttendanceSession> mapped = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    AdminAttendanceSession.fromMap(id: doc.id, map: doc.data()),
              )
              .toList();
          _rawTodaySessions
            ..clear()
            ..addAll(mapped);
          _applySessionVisibility();
        }, onError: (_) {});
  }

  void _listenHistorySessions() {
    _historySubscription?.cancel();
    _historySubscription = _attendanceService
        .watchRecentSessions(limit: 300)
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<AdminAttendanceSession> mapped = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    AdminAttendanceSession.fromMap(id: doc.id, map: doc.data()),
              )
              .toList();
          _rawHistorySessions
            ..clear()
            ..addAll(mapped);
          _applySessionVisibility();
        }, onError: (_) {});
  }

  void _prepareGenerationState() {
    selectedGenerationBatchIds.clear();
    generationPresentByBatchId.clear();
    for (final BatchModel batch in generationCandidateBatches) {
      generationPresentByBatchId[batch.id] = '';
    }
  }

  bool _isBatchActiveForGeneration(BatchModel batch) {
    final String status = (batch.status ?? '').trim().toLowerCase();
    if (status.isEmpty) {
      return true;
    }
    return status == 'active' || status == 'approved' || status == 'ongoing';
  }

  bool _isBatchScheduledToday(BatchModel batch) {
    final String status = (batch.status ?? '').trim().toLowerCase();
    if (status.isNotEmpty &&
        status != 'active' &&
        status != 'approved' &&
        status != 'ongoing') {
      return false;
    }

    final int weekday = DateTime.now().weekday;
    final String todayName = _weekdayName(weekday).toLowerCase();
    final List<String> days = (batch.days ?? <String>[])
        .map((String day) => day.trim().toLowerCase())
        .where((String day) => day.isNotEmpty)
        .toList();

    if (days.contains(todayName)) {
      return true;
    }

    final String schedule = (batch.schedule).trim().toUpperCase();
    if (schedule == 'MWF' || schedule == 'MONDAY-WEDNESDAY-FRIDAY') {
      return weekday == DateTime.monday ||
          weekday == DateTime.wednesday ||
          weekday == DateTime.friday;
    }
    if (schedule == 'TTS' || schedule == 'TUESDAY-THURSDAY-SATURDAY') {
      return weekday == DateTime.tuesday ||
          weekday == DateTime.thursday ||
          weekday == DateTime.saturday;
    }

    if (days.length == 3 &&
        days[0] == 'monday' &&
        days[1] == 'wednesday' &&
        days[2] == 'friday') {
      return weekday == DateTime.monday ||
          weekday == DateTime.wednesday ||
          weekday == DateTime.friday;
    }
    if (days.length == 3 &&
        days[0] == 'tuesday' &&
        days[1] == 'thursday' &&
        days[2] == 'saturday') {
      return weekday == DateTime.tuesday ||
          weekday == DateTime.thursday ||
          weekday == DateTime.saturday;
    }

    return false;
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      default:
        return 'Sunday';
    }
  }

  void _applySessionVisibility() {
    if (!Get.find<AppSession>().isTeacher) {
      todaySessions.assignAll(_rawTodaySessions);
      historySessions.assignAll(_rawHistorySessions);
      return;
    }

    final String teacherUid = (_auth.currentUser?.uid ?? '').trim();
    if (teacherUid.isEmpty) {
      todaySessions.clear();
      historySessions.clear();
      return;
    }

    final Set<String> allowedBatchIds = batches
        .where(
          (BatchModel batch) => (batch.teacherId ?? '').trim() == teacherUid,
        )
        .map((BatchModel batch) => batch.id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    if (allowedBatchIds.isEmpty) {
      todaySessions.clear();
      historySessions.clear();
      return;
    }

    todaySessions.assignAll(
      _rawTodaySessions.where((AdminAttendanceSession session) {
        return allowedBatchIds.contains(session.batchId.trim());
      }).toList(),
    );
    historySessions.assignAll(
      _rawHistorySessions.where((AdminAttendanceSession session) {
        return allowedBatchIds.contains(session.batchId.trim());
      }).toList(),
    );
  }

  @override
  void onClose() {
    _batchesSubscription?.cancel();
    _todaySubscription?.cancel();
    _historySubscription?.cancel();
    super.onClose();
  }
}

class AdminAttendanceSession {
  const AdminAttendanceSession({
    required this.id,
    required this.dateKey,
    this.date,
    required this.batchId,
    required this.batchName,
    required this.presentCount,
    required this.leaveCount,
    required this.totalStudents,
    required this.absentCount,
    required this.status,
    required this.teacherSubmitted,
    required this.presentStudentIds,
    required this.leaveStudentIds,
    required this.absentStudentIds,
  });

  final String id;
  final String dateKey;
  final DateTime? date;
  final String batchId;
  final String batchName;
  final int presentCount;
  final int leaveCount;
  final int totalStudents;
  final int absentCount;
  final String status;
  final bool teacherSubmitted;
  final List<String> presentStudentIds;
  final List<String> leaveStudentIds;
  final List<String> absentStudentIds;

  factory AdminAttendanceSession.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final Object? presentRaw = map['presentCount'];
    final Object? leaveRaw =
        map['leaveCount'] ?? (map['leaveStudentIds'] as List?)?.length;
    final Object? totalRaw = map['totalStudents'];
    final Object? absentRaw = map['absentCount'];
    final List<String> presentStudentIds =
        ((map['presentStudentIds'] as List?) ?? <dynamic>[])
            .map((dynamic id) => '$id'.trim())
            .where((String id) => id.isNotEmpty)
            .toList();
    final List<String> leaveStudentIds =
        ((map['leaveStudentIds'] as List?) ?? <dynamic>[])
            .map((dynamic id) => '$id'.trim())
            .where((String id) => id.isNotEmpty)
            .toList();
    final List<String> absentStudentIds =
        ((map['absentStudentIds'] as List?) ?? <dynamic>[])
            .map((dynamic id) => '$id'.trim())
            .where((String id) => id.isNotEmpty)
            .toList();
    final bool teacherSubmitted =
        (map['teacherSubmitted'] as bool?) ??
        (presentStudentIds.isNotEmpty ||
            leaveStudentIds.isNotEmpty ||
            absentStudentIds.isNotEmpty);
    final int presentCount = presentRaw is int
        ? presentRaw
        : int.tryParse('$presentRaw') ?? 0;
    final int leaveCount = leaveRaw is int
        ? leaveRaw
        : int.tryParse('$leaveRaw') ?? 0;
    final int totalStudents = totalRaw is int
        ? totalRaw
        : int.tryParse('$totalRaw') ?? 0;
    final int absentFromMap = absentRaw is int
        ? absentRaw
        : int.tryParse('$absentRaw') ?? 0;
    final int derivedAbsent = (totalStudents - presentCount - leaveCount).clamp(
      0,
      1000000,
    );

    return AdminAttendanceSession(
      id: id,
      dateKey: (map['dateKey'] as String?) ?? '',
      date: (map['date'] as Timestamp?)?.toDate(),
      batchId: (map['batchId'] as String?) ?? '',
      batchName: (map['batchName'] as String?) ?? 'Unknown Batch',
      presentCount: presentCount,
      leaveCount: leaveCount,
      totalStudents: totalStudents,
      absentCount: absentFromMap == derivedAbsent
          ? absentFromMap
          : derivedAbsent,
      status: ((map['status'] as String?) ?? 'open').trim(),
      teacherSubmitted: teacherSubmitted,
      presentStudentIds: presentStudentIds,
      leaveStudentIds: leaveStudentIds,
      absentStudentIds: absentStudentIds,
    );
  }
}
