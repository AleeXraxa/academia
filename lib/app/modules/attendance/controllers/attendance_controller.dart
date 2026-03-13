import 'dart:async';

import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/data/repositories/attendance_repository.dart';
import 'package:academia/app/services/audit_log_service.dart';
import 'package:academia/app/services/attendance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AttendanceController extends GetxController {
  final AttendanceService _attendanceService = AttendanceService(
    repository: AttendanceRepository(),
  );
  final AuditLogService _auditLogService = AuditLogService();
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
  final RxBool isCompactTable = false.obs;
  final RxString tableSortBy = 'batch'.obs;
  final RxBool tableSortAscending = true.obs;
  final RxBool showMarkForm = false.obs;
  final RxString generationMode = 'scheduled'.obs;
  final RxInt mobileTabIndex = 0.obs;
  final RxInt historyRangeDays = 7.obs;
  final RxInt historyPageSize = 20.obs;
  final RxString historyBatchId = ''.obs;
  final RxString historyTeacherId = ''.obs;
  final RxString historyStatus = ''.obs;
  final RxString historySearch = ''.obs;
  final RxList<String> selectedGenerationBatchIds = <String>[].obs;
  final RxMap<String, String> generationPresentByBatchId =
      <String, String>{}.obs;
  final RxMap<String, bool> generationConductedByBatchId = <String, bool>{}.obs;
  final RxString selectedBatchId = ''.obs;
  final RxString selectedBatchName = ''.obs;
  final RxString presentCountInput = ''.obs;
  final RxString errorText = ''.obs;
  final RxMap<String, TeacherAttendanceDraft> teacherDrafts =
      <String, TeacherAttendanceDraft>{}.obs;
  final RxMap<String, QueuedTeacherSubmission> queuedTeacherSubmissions =
      <String, QueuedTeacherSubmission>{}.obs;
  final RxBool requireCorrectionNote = true.obs;
  final RxBool lockSubmittedSessions = true.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _todaySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _settingsSubscription;
  static const int _historyPageStep = 20;

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
    _listenAttendancePolicy();
    _listenBatches();
    _listenTodaySessions();
    _listenHistorySessions();
  }

  void openMarkForm() {
    generationMode.value = 'scheduled';
    showMarkForm.value = true;
    try {
      _prepareGenerationState();
    } catch (_) {
      selectedGenerationBatchIds.clear();
      generationPresentByBatchId.clear();
    }
  }

  void openExtraMarkForm() {
    generationMode.value = 'extra';
    showMarkForm.value = true;
    try {
      _prepareGenerationState();
    } catch (_) {
      selectedGenerationBatchIds.clear();
      generationPresentByBatchId.clear();
    }
  }

  void updateMobileTab(int index) {
    mobileTabIndex.value = index;
  }

  void toggleCompactTable() {
    isCompactTable.value = !isCompactTable.value;
  }

  void updateTableSort(String sortBy) {
    final String key = sortBy.trim().toLowerCase();
    if (key.isEmpty) {
      return;
    }
    if (tableSortBy.value == key) {
      tableSortAscending.value = !tableSortAscending.value;
      return;
    }
    tableSortBy.value = key;
    tableSortAscending.value = true;
  }

  List<AdminAttendanceSession> get sortedTodaySessions {
    final List<AdminAttendanceSession> sorted = todaySessions.toList();
    final String sortBy = tableSortBy.value;
    final bool asc = tableSortAscending.value;
    int compareText(String a, String b) =>
        asc ? a.compareTo(b) : b.compareTo(a);
    int compareNum(num a, num b) => asc ? a.compareTo(b) : b.compareTo(a);
    double attendancePct(AdminAttendanceSession session) {
      if (session.totalStudents <= 0) {
        return 0;
      }
      return ((session.presentCount + session.leaveCount) /
              session.totalStudents) *
          100;
    }

    sorted.sort((AdminAttendanceSession a, AdminAttendanceSession b) {
      switch (sortBy) {
        case 'present':
          return compareNum(a.presentCount, b.presentCount);
        case 'absent':
          return compareNum(a.absentCount, b.absentCount);
        case 'leave':
          return compareNum(a.leaveCount, b.leaveCount);
        case 'total':
          return compareNum(a.totalStudents, b.totalStudents);
        case 'attendance':
          return compareNum(attendancePct(a), attendancePct(b));
        case 'status':
          return compareText(a.status.toLowerCase(), b.status.toLowerCase());
        case 'batch':
        default:
          return compareText(
            a.batchName.toLowerCase(),
            b.batchName.toLowerCase(),
          );
      }
    });
    return sorted;
  }

  void updateHistoryRangeDays(int days) {
    historyRangeDays.value = days;
    resetHistoryPagination();
  }

  void updateHistoryBatchId(String batchId) {
    historyBatchId.value = batchId.trim();
    resetHistoryPagination();
  }

  void updateHistoryTeacherId(String teacherId) {
    historyTeacherId.value = teacherId.trim();
    resetHistoryPagination();
  }

  void updateHistoryStatus(String status) {
    historyStatus.value = status.trim().toLowerCase();
    resetHistoryPagination();
  }

  void updateHistorySearch(String search) {
    historySearch.value = search.trim().toLowerCase();
    resetHistoryPagination();
  }

  void resetHistoryPagination() {
    historyPageSize.value = _historyPageStep;
  }

  void loadMoreHistorySessions() {
    final int total = filteredHistorySessions.length;
    if (historyPageSize.value >= total) {
      return;
    }
    historyPageSize.value = (historyPageSize.value + _historyPageStep).clamp(
      0,
      total,
    );
  }

  List<BatchModel> get teacherAssignedBatches {
    final String teacherUid = (_auth.currentUser?.uid ?? '').trim();
    if (teacherUid.isEmpty) {
      return <BatchModel>[];
    }
    return batches
        .where(
          (BatchModel batch) => (batch.teacherId ?? '').trim() == teacherUid,
        )
        .toList();
  }

  List<AdminAttendanceSession> get teacherOpenSessionsToday {
    if (!Get.find<AppSession>().isTeacher) {
      return <AdminAttendanceSession>[];
    }
    final List<AdminAttendanceSession> open = todaySessions.where((
      AdminAttendanceSession session,
    ) {
      final String normalized = session.status.trim().toLowerCase();
      return !session.teacherSubmitted &&
          (normalized == 'open' || normalized == 'active');
    }).toList();
    open.sort((AdminAttendanceSession a, AdminAttendanceSession b) {
      return a.batchName.toLowerCase().compareTo(b.batchName.toLowerCase());
    });
    return open;
  }

  List<AdminAttendanceSession> get teacherTaskFirstTodaySessions {
    final List<AdminAttendanceSession> sessions = todaySessions.toList();
    sessions.sort((AdminAttendanceSession a, AdminAttendanceSession b) {
      final int ap = (a.teacherSubmitted || !_isOpen(a.status)) ? 1 : 0;
      final int bp = (b.teacherSubmitted || !_isOpen(b.status)) ? 1 : 0;
      if (ap != bp) {
        return ap.compareTo(bp);
      }
      return a.batchName.toLowerCase().compareTo(b.batchName.toLowerCase());
    });
    return sessions;
  }

  int get teacherTodayAssignedSessions => todaySessions.length;
  int get teacherTodaySubmittedSessions => todaySessions
      .where((AdminAttendanceSession s) => s.teacherSubmitted)
      .length;
  int get teacherTodayPendingSessions =>
      (teacherTodayAssignedSessions - teacherTodaySubmittedSessions).clamp(
        0,
        1000000,
      );

  List<AdminAttendanceSession> get teacherRecentSubmittedSessions {
    final List<AdminAttendanceSession> submitted = historySessions.where((
      AdminAttendanceSession session,
    ) {
      return session.teacherSubmitted;
    }).toList();
    submitted.sort((AdminAttendanceSession a, AdminAttendanceSession b) {
      final DateTime ad =
          a.date ??
          DateTime.tryParse('${a.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      final DateTime bd =
          b.date ??
          DateTime.tryParse('${b.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      return bd.compareTo(ad);
    });
    return submitted.take(7).toList();
  }

  double get teacherLast5DaysSubmissionRate {
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 4));
    final List<AdminAttendanceSession> window = historySessions.where((
      AdminAttendanceSession session,
    ) {
      final DateTime date =
          session.date ??
          DateTime.tryParse('${session.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      return !date.isBefore(start);
    }).toList();
    if (window.isEmpty) {
      return 0;
    }
    final int submitted = window.where((AdminAttendanceSession s) {
      return s.teacherSubmitted;
    }).length;
    return (submitted / window.length) * 100;
  }

  double get teacherLast5DaysAverageAttendance {
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 4));
    final List<AdminAttendanceSession> window = historySessions.where((
      AdminAttendanceSession session,
    ) {
      final DateTime date =
          session.date ??
          DateTime.tryParse('${session.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      return !date.isBefore(start) && session.totalStudents > 0;
    }).toList();
    if (window.isEmpty) {
      return 0;
    }
    final double totalPercent = window.fold<double>(0, (
      double sum,
      AdminAttendanceSession session,
    ) {
      return sum +
          ((session.presentCount + session.leaveCount) /
                  session.totalStudents) *
              100;
    });
    return totalPercent / window.length;
  }

  int get teacherOnTimeSubmissionStreakDays {
    final Map<String, List<AdminAttendanceSession>> byDate =
        <String, List<AdminAttendanceSession>>{};
    for (final AdminAttendanceSession session in historySessions) {
      byDate
          .putIfAbsent(session.dateKey, () => <AdminAttendanceSession>[])
          .add(session);
    }
    if (byDate.isEmpty) {
      return 0;
    }

    final List<DateTime> dates =
        byDate.keys
            .map((String key) => DateTime.tryParse('$key 00:00:00'))
            .whereType<DateTime>()
            .toList()
          ..sort((DateTime a, DateTime b) => b.compareTo(a));

    int streak = 0;
    for (final DateTime date in dates) {
      final String key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final List<AdminAttendanceSession> sessions =
          byDate[key] ?? <AdminAttendanceSession>[];
      if (sessions.isEmpty) {
        continue;
      }
      final bool allSubmitted = sessions.every((
        AdminAttendanceSession session,
      ) {
        return session.teacherSubmitted;
      });
      if (!allSubmitted) {
        break;
      }
      streak += 1;
    }
    return streak;
  }

  bool hasTeacherDraft(String sessionId) {
    return teacherDrafts.containsKey(sessionId.trim());
  }

  TeacherAttendanceDraft draftForSession(String sessionId) {
    return teacherDrafts[sessionId.trim()] ?? TeacherAttendanceDraft.empty();
  }

  void cacheTeacherDraft({
    required String sessionId,
    required List<String> presentStudentIds,
    required List<String> leaveStudentIds,
    String search = '',
    String filter = 'all',
  }) {
    final String id = sessionId.trim();
    if (id.isEmpty) {
      return;
    }
    teacherDrafts[id] = TeacherAttendanceDraft(
      presentStudentIds: presentStudentIds,
      leaveStudentIds: leaveStudentIds,
      search: search,
      filter: filter,
      updatedAt: DateTime.now(),
    );
    teacherDrafts.refresh();
  }

  void clearTeacherDraft(String sessionId) {
    teacherDrafts.remove(sessionId.trim());
    teacherDrafts.refresh();
  }

  bool isQueuedTeacherSubmission(String sessionId) {
    return queuedTeacherSubmissions.containsKey(sessionId.trim());
  }

  int get queuedTeacherSubmissionCount => queuedTeacherSubmissions.length;

  void queueTeacherSubmission({
    required String sessionId,
    required List<String> presentStudentIds,
    required List<String> leaveStudentIds,
    required List<String> absentStudentIds,
    required String reason,
    String notConductedReason = '',
  }) {
    final String id = sessionId.trim();
    if (id.isEmpty) {
      return;
    }
    queuedTeacherSubmissions[id] = QueuedTeacherSubmission(
      sessionId: id,
      presentStudentIds: presentStudentIds,
      leaveStudentIds: leaveStudentIds,
      absentStudentIds: absentStudentIds,
      reason: reason,
      notConductedReason: notConductedReason,
      queuedAt: DateTime.now(),
    );
    queuedTeacherSubmissions.refresh();
  }

  Future<void> retryQueuedTeacherSubmission(String sessionId) async {
    final String id = sessionId.trim();
    final QueuedTeacherSubmission? queued = queuedTeacherSubmissions[id];
    if (queued == null) {
      return;
    }
    await _submitTeacherAttendanceInternal(
      sessionId: queued.sessionId,
      presentStudentIds: queued.presentStudentIds,
      leaveStudentIds: queued.leaveStudentIds,
      absentStudentIds: queued.absentStudentIds,
      notConductedReason: queued.notConductedReason,
    );
    queuedTeacherSubmissions.remove(id);
    queuedTeacherSubmissions.refresh();
    clearTeacherDraft(id);
  }

  List<AdminAttendanceSession> get filteredHistorySessions {
    return AttendanceHistoryQuery.apply(
      sessions: historySessions,
      rangeDays: historyRangeDays.value,
      selectedBatch: historyBatchId.value.trim(),
      selectedTeacherId: historyTeacherId.value.trim(),
      selectedStatus: historyStatus.value.trim().toLowerCase(),
      search: historySearch.value.trim().toLowerCase(),
      teacherIdForBatch: _teacherIdForBatch,
    );
  }

  List<AdminAttendanceSession> get pagedHistorySessions {
    final List<AdminAttendanceSession> filtered = filteredHistorySessions;
    if (filtered.length <= historyPageSize.value) {
      return filtered;
    }
    return filtered.take(historyPageSize.value).toList();
  }

  bool get hasMoreHistorySessions {
    return filteredHistorySessions.length > pagedHistorySessions.length;
  }

  int get historyCorrectedSessionsCount =>
      filteredHistorySessions.where((AdminAttendanceSession session) {
        return session.auditLogs.isNotEmpty;
      }).length;

  int get historyHighAbsenceSessionCount =>
      filteredHistorySessions.where((AdminAttendanceSession session) {
        if (session.totalStudents <= 0) {
          return false;
        }
        return (session.absentCount / session.totalStudents) >= 0.3;
      }).length;

  List<String> get historyAbsentStreakStudentIds {
    return AttendanceHistoryInsights.absentStreakStudentIds(
      sessions: filteredHistorySessions,
      minDays: 3,
    );
  }

  int get historyAbsentStreakStudentsCount =>
      historyAbsentStreakStudentIds.length;

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
    final double total = filteredHistorySessions.fold<double>(0, (
      double sum,
      AdminAttendanceSession session,
    ) {
      if (session.totalStudents <= 0) {
        return sum;
      }
      return sum +
          ((session.presentCount + session.leaveCount) /
                  session.totalStudents) *
              100;
    });
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
          ((session.presentCount + session.leaveCount) /
              session.totalStudents) *
          100;
      batchScores.putIfAbsent(key, () => <double>[]).add(percent);
    }
    if (batchScores.isEmpty) {
      return '--';
    }
    String bestName = '--';
    double bestAvg = -1;
    batchScores.forEach((String key, List<double> values) {
      final double avg =
          values.reduce((double a, double b) => a + b) / values.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestName = key.split('|').last;
      }
    });
    return bestName;
  }

  List<HistoryTeacherOption> get historyTeacherOptions {
    final Map<String, String> byId = <String, String>{};
    for (final BatchModel batch in batches) {
      final String id = (batch.teacherId ?? '').trim();
      if (id.isEmpty) {
        continue;
      }
      final String name = (batch.teacherName ?? '').trim();
      if (name.isNotEmpty) {
        byId[id] = name;
      } else {
        byId[id] = byId[id] ?? 'Teacher $id';
      }
    }
    final List<HistoryTeacherOption> options = byId.entries
        .map(
          (MapEntry<String, String> entry) =>
              HistoryTeacherOption(id: entry.key, name: entry.value),
        )
        .toList();
    options.sort(
      (HistoryTeacherOption a, HistoryTeacherOption b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return options;
  }

  void closeMarkForm() {
    showMarkForm.value = false;
    generationMode.value = 'scheduled';
    selectedGenerationBatchIds.clear();
    generationPresentByBatchId.clear();
    generationConductedByBatchId.clear();
    selectedBatchId.value = '';
    selectedBatchName.value = '';
    presentCountInput.value = '';
  }

  List<BatchModel> get todayScheduledBatches {
    return batches.where(_isBatchScheduledToday).toList();
  }

  List<BatchModel> get todayUnscheduledActiveBatches {
    return batches
        .where(
          (BatchModel batch) =>
              _isBatchActiveForGeneration(batch) &&
              !_isBatchScheduledToday(batch),
        )
        .toList();
  }

  List<BatchModel> get generationCandidateBatches {
    if (generationMode.value == 'extra') {
      return todayUnscheduledActiveBatches;
    }
    final List<BatchModel> scheduled = todayScheduledBatches;
    if (scheduled.isNotEmpty) {
      return scheduled;
    }
    return batches.where(_isBatchActiveForGeneration).toList();
  }

  bool get isUsingScheduleFallback {
    return todayScheduledBatches.isEmpty &&
        generationCandidateBatches.isNotEmpty;
  }

  bool isBatchSelectedForGeneration(String batchId) {
    final String id = batchId.trim();
    return selectedGenerationBatchIds.any(
      (String selectedId) => selectedId == id,
    );
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
    final String docId = '${todayKey}_$batchId';
    if (presentCount < 0) {
      throw Exception('Present count cannot be negative.');
    }

    isSaving.value = true;
    try {
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await _attendanceService.getSession(docId);
      if (existing.exists) {
        throw Exception('Session already generated for the $batchName batch');
      }
      final int totalStudents = selectedBatchStudentsCount;
      if (totalStudents <= 0) {
        throw Exception(
          'Cannot generate session for $batchName because no students are assigned to this batch yet.',
        );
      }
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
          'classConducted': true,
          'status': 'open',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        merge: true,
      );

      await _auditLogService.log(
        action: 'generate',
        entityType: 'session',
        entityId: docId,
        entityName: batchName,
        meta: <String, dynamic>{
          'dateKey': todayKey,
          'presentCount': presentCount,
          'absentCount': absentCount,
          'totalStudents': totalStudents,
          'classConducted': true,
        },
      );

      closeMarkForm();
      errorText.value = '';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveTodayAttendanceForSelectedBatches() async {
    if (selectedGenerationBatchIds.isEmpty) {
      throw Exception('Select at least one batch to generate sessions.');
    }
    final DateTime today = DateTime.now();
    final String dateKey = todayKey;
    final Map<String, BatchModel> byId = <String, BatchModel>{
      for (final BatchModel batch in batches) batch.id: batch,
    };
    final List<String> selectedIds = selectedGenerationBatchIds.toList();
    for (final String batchId in selectedIds) {
      final BatchModel batch = byId[batchId]!;
      final int totalStudents = batch.studentsCount ?? 0;
      final String rawInput = (generationPresentByBatchId[batchId] ?? '')
          .trim();
      final int presentCount = rawInput.isEmpty
          ? totalStudents
          : int.tryParse(rawInput) ?? -1;
      if (totalStudents <= 0) {
        throw Exception(
          'Batch "${batch.name}" has no students yet. Please assign students first.',
        );
      }
      if (presentCount < 0) {
        throw Exception('Enter a valid present count for ${batch.name}.');
      }
      if (presentCount > totalStudents) {
        throw Exception(
          'Present count cannot exceed total students for ${batch.name}.',
        );
      }
    }

    final Map<String, Map<String, dynamic>> sessionsPayload =
        <String, Map<String, dynamic>>{};
    final bool isExtraMode = generationMode.value == 'extra';
    for (final String batchId in selectedIds) {
      final BatchModel batch = byId[batchId]!;
      final int totalStudents = batch.studentsCount ?? 0;
      final String rawInput = (generationPresentByBatchId[batchId] ?? '')
          .trim();
      final int presentCount = rawInput.isEmpty
          ? totalStudents
          : int.tryParse(rawInput) ?? totalStudents;
      final int leaveCount = 0;
      final bool classConducted = generationConductedByBatchId[batchId] ?? true;
      final String docId = '${dateKey}_$batchId${isExtraMode ? '_extra' : ''}';

      sessionsPayload[docId] = <String, dynamic>{
        'id': docId,
        'dateKey': dateKey,
        'date': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day),
        ),
        'batchId': batchId,
        'batchName': batch.name,
        'teacherId': batch.teacherId,
        'teacherName': batch.teacherName,
        'presentCount': presentCount,
        'leaveCount': leaveCount,
        'absentCount': (totalStudents - presentCount - leaveCount).clamp(
          0,
          totalStudents,
        ),
        'totalStudents': totalStudents,
        'status': 'open',
        'presentStudentIds': <String>[],
        'leaveStudentIds': <String>[],
        'absentStudentIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isExtraSession': isExtraMode,
        'classConducted': classConducted,
      };
    }

    await _attendanceService.batchSetSessions(sessionsPayload);
    for (final String batchId in selectedIds) {
      final BatchModel batch = byId[batchId]!;
      await _auditLogService.log(
        action: 'generate',
        entityType: 'session',
        entityId: '${dateKey}_$batchId${isExtraMode ? '_extra' : ''}',
        entityName: batch.name,
        meta: <String, dynamic>{
          'dateKey': dateKey,
          'isExtraSession': isExtraMode,
        },
      );
    }

    closeMarkForm();
    errorText.value = '';
  }

  Future<void> submitTeacherAttendance({
    required String sessionId,
    required List<String> presentStudentIds,
    required List<String> leaveStudentIds,
    required List<String> absentStudentIds,
    String notConductedReason = '',
  }) async {
    await _submitTeacherAttendanceInternal(
      sessionId: sessionId,
      presentStudentIds: presentStudentIds,
      leaveStudentIds: leaveStudentIds,
      absentStudentIds: absentStudentIds,
      notConductedReason: notConductedReason,
    );
  }

  Future<void> _submitTeacherAttendanceInternal({
    required String sessionId,
    required List<String> presentStudentIds,
    required List<String> leaveStudentIds,
    required List<String> absentStudentIds,
    String notConductedReason = '',
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> sessionSnapshot =
        await _attendanceService.getSession(sessionId);
    if (!sessionSnapshot.exists) {
      throw Exception('Session not found.');
    }
    final Map<String, dynamic> sessionMap =
        sessionSnapshot.data() ?? <String, dynamic>{};
    final String batchId = (sessionMap['batchId'] as String? ?? '').trim();
    final String status = (sessionMap['status'] as String? ?? '')
        .trim()
        .toLowerCase();
    final bool alreadySubmitted =
        (sessionMap['teacherSubmitted'] as bool?) ?? false;
    final int expectedPresentTarget = _toInt(sessionMap['presentCount']);
    final bool classConducted = (sessionMap['classConducted'] as bool?) ?? true;
    final String trimmedReason = notConductedReason.trim();
    final String uid = (_auth.currentUser?.uid ?? '').trim();

    if (uid.isEmpty) {
      throw Exception('Authentication required.');
    }
    if (batchId.isEmpty) {
      throw Exception('Invalid session batch.');
    }
    if (_teacherIdForBatch(batchId) != uid) {
      throw Exception('You are not authorized to submit this session.');
    }
    if (!(status == 'open' || status == 'active')) {
      throw Exception('This session is no longer open for submission.');
    }
    if (alreadySubmitted) {
      throw Exception('Attendance already submitted for this session.');
    }
    if (!classConducted && trimmedReason.isEmpty) {
      throw Exception('Please provide a reason for class not conducted.');
    }

    final List<StudentModel> batchStudents = await fetchStudentsForBatch(
      batchId,
    );
    final Set<String> allowedIds = batchStudents
        .map((StudentModel student) => student.id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    if (allowedIds.isEmpty) {
      throw Exception('No students found for this batch.');
    }

    final Set<String> presentIds = presentStudentIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Set<String> leaveIds = leaveStudentIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    if (presentIds.any((String id) => !allowedIds.contains(id)) ||
        leaveIds.any((String id) => !allowedIds.contains(id))) {
      throw Exception('Attendance contains students outside assigned batch.');
    }
    if (presentIds.any((String id) => leaveIds.contains(id))) {
      throw Exception('A student cannot be both present and on leave.');
    }
    if (expectedPresentTarget > 0 &&
        presentIds.length > expectedPresentTarget) {
      throw Exception(
        'Present selection cannot exceed target ($expectedPresentTarget).',
      );
    }

    final Object? totalRaw = sessionMap['totalStudents'];
    final int totalStudents = totalRaw is int
        ? totalRaw
        : int.tryParse('$totalRaw') ?? 0;
    final int presentCount = presentIds.length;
    final int leaveCount = leaveIds.length;
    final List<String> normalizedAbsentStudentIds = allowedIds
        .where(
          (String id) => !presentIds.contains(id) && !leaveIds.contains(id),
        )
        .toList();
    final int computedAbsentCount = (totalStudents - presentCount - leaveCount)
        .clamp(0, 1000000);

    final String actorEmail = (_auth.currentUser?.email ?? '').trim();
    final Map<String, dynamic> submitAudit = <String, dynamic>{
      'action': 'submit',
      'entityType': 'attendance',
      'entityId': sessionId,
      'entityName': (sessionMap['batchName'] as String? ?? '').trim(),
      'actorId': uid,
      'actorEmail': actorEmail,
      'actorName': '',
      'actorRole': Get.find<AppSession>().roleOrStaff.name,
      'note': classConducted ? '' : trimmedReason,
      'meta': <String, dynamic>{
        'dateKey': (sessionMap['dateKey'] as String? ?? '').trim(),
        'presentCount': presentCount,
        'leaveCount': leaveCount,
        'absentCount': computedAbsentCount,
        'classConducted': classConducted,
      },
      'at': Timestamp.now(),
    };

    await _attendanceService.updateSession(
      sessionId: sessionId,
      data: <String, dynamic>{
        'presentCount': presentCount,
        'leaveCount': leaveCount,
        'absentCount': computedAbsentCount,
        'presentStudentIds': presentIds.toList(),
        'leaveStudentIds': leaveIds.toList(),
        'absentStudentIds': normalizedAbsentStudentIds
            .take(computedAbsentCount)
            .toList(),
        'teacherMarkedBy': uid,
        'teacherMarkedAt': FieldValue.serverTimestamp(),
        'teacherSubmitted': true,
        'status': 'submitted_by_teacher',
        'auditLogs': FieldValue.arrayUnion(<Map<String, dynamic>>[submitAudit]),
        if (!classConducted) ...<String, dynamic>{
          'notConductedTeacherReason': trimmedReason,
          'notConductedTeacherBy': uid,
          'notConductedTeacherAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await _auditLogService.log(
      action: 'submit',
      entityType: 'attendance',
      entityId: sessionId,
      entityName: (sessionMap['batchName'] as String? ?? '').trim(),
      note: classConducted ? '' : trimmedReason,
      meta: <String, dynamic>{
        'dateKey': (sessionMap['dateKey'] as String? ?? '').trim(),
        'presentCount': presentStudentIds.length,
        'leaveCount': leaveStudentIds.length,
        'absentCount': absentStudentIds.length,
        'classConducted': classConducted,
      },
    );
  }

  bool _isOpen(String status) {
    final String normalized = status.trim().toLowerCase();
    return normalized == 'open' || normalized == 'active';
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  Future<List<StudentModel>> fetchStudentsForBatch(String batchId) {
    return _attendanceService.fetchStudentsForBatch(batchId);
  }

  Future<Map<String, String>> fetchStudentNamesByIds(List<String> ids) {
    return _attendanceService.fetchStudentNamesByIds(ids);
  }

  Future<void> adminCorrectSession({
    required AdminAttendanceSession session,
    required List<String> presentStudentIds,
    required List<String> leaveStudentIds,
    required String note,
  }) async {
    final String trimmedNote = note.trim();
    if (requireCorrectionNote.value && trimmedNote.isEmpty) {
      throw Exception(
        'Correction note is required by settings. Please enter a reason before saving.',
      );
    }

    final Set<String> presentSet = presentStudentIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Set<String> leaveSet = leaveStudentIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    leaveSet.removeWhere((String id) => presentSet.contains(id));

    final List<StudentModel> students = await fetchStudentsForBatch(
      session.batchId,
    );
    final List<String> allIds = students.map((StudentModel s) => s.id).toList();
    final List<String> absentIds = allIds
        .where(
          (String id) => !presentSet.contains(id) && !leaveSet.contains(id),
        )
        .toList();

    final int totalStudents = session.totalStudents > 0
        ? session.totalStudents
        : allIds.length;
    final int presentCount = presentSet.length;
    final int leaveCount = leaveSet.length;
    final int absentCount = (totalStudents - presentCount - leaveCount).clamp(
      0,
      1000000,
    );
    final String uid = _auth.currentUser?.uid ?? '';
    final String role = Get.find<AppSession>().roleOrStaff.name;
    final Map<String, dynamic> auditItem = <String, dynamic>{
      'action': 'admin_correction',
      'uid': uid,
      'role': role,
      'note': trimmedNote,
      'presentCount': presentCount,
      'leaveCount': leaveCount,
      'absentCount': absentCount,
      'at': Timestamp.now(),
    };

    await _attendanceService.updateSession(
      sessionId: session.id,
      data: <String, dynamic>{
        'presentStudentIds': presentSet.toList(),
        'leaveStudentIds': leaveSet.toList(),
        'absentStudentIds': absentIds.take(absentCount).toList(),
        'presentCount': presentCount,
        'leaveCount': leaveCount,
        'absentCount': absentCount,
        'status': 'completed',
        'teacherSubmitted': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'correctedBy': uid,
        'correctedRole': role,
        'correctedAt': FieldValue.serverTimestamp(),
        'auditLogs': FieldValue.arrayUnion(<Map<String, dynamic>>[auditItem]),
      },
    );

    await _auditLogService.log(
      action: 'correct',
      entityType: 'attendance',
      entityId: session.id,
      entityName: session.batchName,
      note: trimmedNote,
      meta: <String, dynamic>{
        'dateKey': session.dateKey,
        'presentCount': presentCount,
        'leaveCount': leaveCount,
        'absentCount': absentCount,
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

  void _listenAttendancePolicy() {
    _settingsSubscription?.cancel();
    _settingsSubscription = FirebaseFirestore.instance
        .collection('app_settings')
        .doc('general')
        .snapshots()
        .listen(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) {
            final Map<String, dynamic> map =
                snapshot.data() ?? <String, dynamic>{};
            lockSubmittedSessions.value =
                (map['lockSubmittedSessions'] as bool?) ?? true;
            requireCorrectionNote.value =
                (map['requireCorrectionNote'] as bool?) ?? true;
          },
          onError: (_) {
            lockSubmittedSessions.value = true;
            requireCorrectionNote.value = true;
          },
        );
  }

  void _listenTodaySessions() {
    _todaySubscription?.cancel();
    _todaySubscription = _attendanceService
        .watchSessionsByDateKey(todayKey)
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<AdminAttendanceSession> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      AdminAttendanceSession.fromMap(
                        id: doc.id,
                        map: doc.data(),
                      ),
                )
                .toList();
            _rawTodaySessions
              ..clear()
              ..addAll(mapped);
            _applySessionVisibility();
          },
          onError: (_) {
            errorText.value = 'Unable to load today sessions.';
          },
        );
  }

  void _listenHistorySessions() {
    _historySubscription?.cancel();
    _historySubscription = _attendanceService
        .watchRecentSessions(limit: 300)
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<AdminAttendanceSession> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      AdminAttendanceSession.fromMap(
                        id: doc.id,
                        map: doc.data(),
                      ),
                )
                .toList();
            _rawHistorySessions
              ..clear()
              ..addAll(mapped);
            _applySessionVisibility();
            if (historyPageSize.value < _historyPageStep) {
              resetHistoryPagination();
            }
          },
          onError: (_) {
            errorText.value = 'Unable to load attendance history.';
          },
        );
  }

  void _prepareGenerationState() {
    selectedGenerationBatchIds.clear();
    generationPresentByBatchId.clear();
    generationConductedByBatchId.clear();
    for (final BatchModel batch in generationCandidateBatches) {
      generationPresentByBatchId[batch.id] = '';
      generationConductedByBatchId[batch.id] = true;
    }
  }

  bool isBatchClassConducted(String batchId) {
    return generationConductedByBatchId[batchId.trim()] ?? true;
  }

  void updateBatchConducted({
    required String batchId,
    required bool conducted,
  }) {
    generationConductedByBatchId[batchId.trim()] = conducted;
    generationConductedByBatchId.refresh();
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
    if (schedule == 'REGULAR' ||
        schedule == 'DAILY' ||
        schedule == 'MONDAY-TUESDAY-WEDNESDAY-THURSDAY-FRIDAY-SATURDAY') {
      return weekday >= DateTime.monday && weekday <= DateTime.saturday;
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
    if (days.length == 6 &&
        days[0] == 'monday' &&
        days[1] == 'tuesday' &&
        days[2] == 'wednesday' &&
        days[3] == 'thursday' &&
        days[4] == 'friday' &&
        days[5] == 'saturday') {
      return weekday >= DateTime.monday && weekday <= DateTime.saturday;
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

  String _teacherIdForBatch(String batchId) {
    final String normalized = batchId.trim();
    if (normalized.isEmpty) {
      return '';
    }
    for (final BatchModel batch in batches) {
      if (batch.id.trim() == normalized) {
        return (batch.teacherId ?? '').trim();
      }
    }
    return '';
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
    _settingsSubscription?.cancel();
    super.onClose();
  }
}

class AttendanceHistoryQuery {
  static List<AdminAttendanceSession> apply({
    required List<AdminAttendanceSession> sessions,
    required int rangeDays,
    required String selectedBatch,
    required String selectedTeacherId,
    required String selectedStatus,
    required String search,
    required String Function(String batchId) teacherIdForBatch,
  }) {
    final DateTime now = DateTime.now();
    final DateTime startDate = rangeDays <= 0
        ? DateTime(2000, 1, 1)
        : DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: rangeDays - 1));

    final List<AdminAttendanceSession> filtered = sessions.where((
      AdminAttendanceSession session,
    ) {
      final bool batchMatch =
          selectedBatch.isEmpty || session.batchId.trim() == selectedBatch;
      final bool teacherMatch =
          selectedTeacherId.isEmpty ||
          teacherIdForBatch(session.batchId) == selectedTeacherId;
      final bool statusMatch =
          selectedStatus.isEmpty ||
          session.status.trim().toLowerCase() == selectedStatus;
      final bool searchMatch =
          search.isEmpty ||
          session.batchName.toLowerCase().contains(search) ||
          session.id.toLowerCase().contains(search);
      final DateTime sessionDate =
          session.date ??
          DateTime.tryParse('${session.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      final bool dateMatch = rangeDays <= 0 || !sessionDate.isBefore(startDate);
      return batchMatch &&
          teacherMatch &&
          statusMatch &&
          searchMatch &&
          dateMatch;
    }).toList();

    filtered.sort((AdminAttendanceSession a, AdminAttendanceSession b) {
      final DateTime ad =
          a.date ??
          DateTime.tryParse('${a.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      final DateTime bd =
          b.date ??
          DateTime.tryParse('${b.dateKey} 00:00:00') ??
          DateTime(2000, 1, 1);
      return bd.compareTo(ad);
    });
    return filtered;
  }
}

class AttendanceHistoryInsights {
  static List<String> absentStreakStudentIds({
    required List<AdminAttendanceSession> sessions,
    int minDays = 3,
  }) {
    if (sessions.isEmpty || minDays <= 1) {
      return <String>[];
    }

    final Map<String, Set<String>> absentByDateKey = <String, Set<String>>{};
    for (final AdminAttendanceSession session in sessions) {
      absentByDateKey
          .putIfAbsent(session.dateKey, () => <String>{})
          .addAll(session.absentStudentIds);
    }

    final List<DateTime> orderedDates =
        absentByDateKey.keys
            .map((String key) => DateTime.tryParse('$key 00:00:00'))
            .whereType<DateTime>()
            .toList()
          ..sort((DateTime a, DateTime b) => a.compareTo(b));
    if (orderedDates.isEmpty) {
      return <String>[];
    }

    final Map<String, int> streakByStudent = <String, int>{};
    final Set<String> matched = <String>{};
    DateTime? previousDate;
    for (final DateTime date in orderedDates) {
      final String dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final Set<String> absentToday = absentByDateKey[dateKey] ?? <String>{};

      if (previousDate != null && date.difference(previousDate).inDays != 1) {
        streakByStudent.clear();
      }

      final List<String> existingStudents = streakByStudent.keys.toList();
      for (final String studentId in existingStudents) {
        if (!absentToday.contains(studentId)) {
          streakByStudent[studentId] = 0;
        }
      }

      for (final String studentId in absentToday) {
        final int next = (streakByStudent[studentId] ?? 0) + 1;
        streakByStudent[studentId] = next;
        if (next >= minDays) {
          matched.add(studentId);
        }
      }

      previousDate = date;
    }

    final List<String> ids = matched.toList()..sort();
    return ids;
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
    required this.classConducted,
    required this.notConductedTeacherReason,
    required this.auditLogs,
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
  final bool classConducted;
  final String notConductedTeacherReason;
  final List<AttendanceAuditLog> auditLogs;

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
    final List<AttendanceAuditLog> auditLogs =
        ((map['auditLogs'] as List?) ?? <dynamic>[])
            .whereType<Map>()
            .map(
              (Map item) =>
                  AttendanceAuditLog.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList();
    final bool teacherSubmitted =
        (map['teacherSubmitted'] as bool?) ??
        (presentStudentIds.isNotEmpty ||
            leaveStudentIds.isNotEmpty ||
            absentStudentIds.isNotEmpty);
    final bool classConducted = (map['classConducted'] as bool?) ?? true;
    final String notConductedTeacherReason =
        (map['notConductedTeacherReason'] as String? ?? '').trim();
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
      classConducted: classConducted,
      notConductedTeacherReason: notConductedTeacherReason,
      auditLogs: auditLogs,
    );
  }
}

class AttendanceAuditLog {
  const AttendanceAuditLog({
    required this.action,
    required this.uid,
    required this.role,
    required this.note,
    required this.presentCount,
    required this.leaveCount,
    required this.absentCount,
    this.at,
  });

  final String action;
  final String uid;
  final String role;
  final String note;
  final int presentCount;
  final int leaveCount;
  final int absentCount;
  final DateTime? at;

  factory AttendanceAuditLog.fromMap(Map<String, dynamic> map) {
    final Object? presentRaw = map['presentCount'];
    final Object? leaveRaw = map['leaveCount'];
    final Object? absentRaw = map['absentCount'];
    return AttendanceAuditLog(
      action: (map['action'] as String? ?? '').trim(),
      uid: (map['uid'] as String? ?? '').trim(),
      role: (map['role'] as String? ?? '').trim(),
      note: (map['note'] as String? ?? '').trim(),
      presentCount: presentRaw is int
          ? presentRaw
          : int.tryParse('$presentRaw') ?? 0,
      leaveCount: leaveRaw is int ? leaveRaw : int.tryParse('$leaveRaw') ?? 0,
      absentCount: absentRaw is int
          ? absentRaw
          : int.tryParse('$absentRaw') ?? 0,
      at: (map['at'] as Timestamp?)?.toDate(),
    );
  }
}

class HistoryTeacherOption {
  const HistoryTeacherOption({required this.id, required this.name});

  final String id;
  final String name;
}

class TeacherAttendanceDraft {
  const TeacherAttendanceDraft({
    required this.presentStudentIds,
    required this.leaveStudentIds,
    required this.search,
    required this.filter,
    required this.updatedAt,
  });

  factory TeacherAttendanceDraft.empty() {
    return TeacherAttendanceDraft(
      presentStudentIds: const <String>[],
      leaveStudentIds: const <String>[],
      search: '',
      filter: 'all',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final List<String> presentStudentIds;
  final List<String> leaveStudentIds;
  final String search;
  final String filter;
  final DateTime updatedAt;
}

class QueuedTeacherSubmission {
  const QueuedTeacherSubmission({
    required this.sessionId,
    required this.presentStudentIds,
    required this.leaveStudentIds,
    required this.absentStudentIds,
    required this.reason,
    required this.queuedAt,
    this.notConductedReason = '',
  });

  final String sessionId;
  final List<String> presentStudentIds;
  final List<String> leaveStudentIds;
  final List<String> absentStudentIds;
  final String reason;
  final DateTime queuedAt;
  final String notConductedReason;
}
