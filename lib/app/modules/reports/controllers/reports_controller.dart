import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ReportsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;
  final RxInt rangeDays = 30.obs;
  final RxString selectedBatchId = ''.obs;
  final RxString selectedStatus = ''.obs;

  final RxList<BatchOption> batches = <BatchOption>[].obs;
  final RxList<ReportSession> sessions = <ReportSession>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;

  @override
  void onInit() {
    super.onInit();
    _listenBatches();
    _listenSessions();
  }

  void updateRangeDays(int days) {
    rangeDays.value = days;
  }

  void updateBatchId(String batchId) {
    selectedBatchId.value = batchId.trim();
  }

  void updateStatus(String status) {
    selectedStatus.value = status.trim().toLowerCase();
  }

  List<ReportSession> get filteredSessions {
    final int days = rangeDays.value;
    final String batchId = selectedBatchId.value.trim();
    final String status = selectedStatus.value.trim().toLowerCase();
    final DateTime now = DateTime.now();
    final DateTime start = days <= 0
        ? DateTime(2000, 1, 1)
        : DateTime(now.year, now.month, now.day).subtract(
            Duration(days: days - 1),
          );

    final List<ReportSession> filtered = sessions.where((ReportSession s) {
      final bool dateMatch = days <= 0 || !s.date.isBefore(start);
      final bool batchMatch = batchId.isEmpty || s.batchId == batchId;
      final bool statusMatch = status.isEmpty || s.status.toLowerCase() == status;
      return dateMatch && batchMatch && statusMatch;
    }).toList();
    filtered.sort((ReportSession a, ReportSession b) => b.date.compareTo(a.date));
    return filtered;
  }

  int get totalSessions => filteredSessions.length;
  int get totalPresent => filteredSessions.fold<int>(
    0,
    (int sum, ReportSession s) => sum + s.presentCount,
  );
  int get totalLeave => filteredSessions.fold<int>(
    0,
    (int sum, ReportSession s) => sum + s.leaveCount,
  );
  int get totalAbsent => filteredSessions.fold<int>(
    0,
    (int sum, ReportSession s) => sum + s.absentCount,
  );
  double get averageAttendance {
    if (filteredSessions.isEmpty) {
      return 0;
    }
    final double total = filteredSessions.fold<double>(
      0,
      (double sum, ReportSession s) => sum + s.attendancePercent,
    );
    return total / filteredSessions.length;
  }

  String get topBatch {
    if (filteredSessions.isEmpty) {
      return '--';
    }
    final Map<String, List<double>> batchPct = <String, List<double>>{};
    for (final ReportSession s in filteredSessions) {
      final String key = '${s.batchId}|${s.batchName}';
      batchPct.putIfAbsent(key, () => <double>[]).add(s.attendancePercent);
    }
    String best = '--';
    double bestValue = -1;
    batchPct.forEach((String key, List<double> values) {
      if (values.isEmpty) {
        return;
      }
      final double avg =
          values.reduce((double a, double b) => a + b) / values.length;
      if (avg > bestValue) {
        bestValue = avg;
        best = key.split('|').last;
      }
    });
    return best;
  }

  List<BatchOption> get batchOptions {
    final List<BatchOption> sorted = batches.toList();
    sorted.sort((BatchOption a, BatchOption b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  void _listenBatches() {
    _batchesSub?.cancel();
    _batchesSub = _firestore.collection('batches').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<BatchOption> items = snapshot.docs.map((doc) {
          final String name =
              (doc.data()['name'] as String?)?.trim().isNotEmpty == true
              ? (doc.data()['name'] as String).trim()
              : 'Untitled Batch';
          return BatchOption(id: doc.id, name: name);
        }).toList();
        batches.assignAll(items);
      },
    );
  }

  void _listenSessions() {
    _sessionsSub?.cancel();
    isLoading.value = true;
    _sessionsSub = _firestore
        .collection('attendance_sessions')
        .orderBy('date', descending: true)
        .limit(1000)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<ReportSession> mapped = snapshot.docs.map((doc) {
              return ReportSession.fromMap(id: doc.id, map: doc.data());
            }).toList();
            sessions.assignAll(mapped);
            isLoading.value = false;
            errorText.value = '';
          },
          onError: (_) {
            errorText.value = 'Unable to load reports data.';
            isLoading.value = false;
          },
        );
  }

  @override
  void onClose() {
    _batchesSub?.cancel();
    _sessionsSub?.cancel();
    super.onClose();
  }
}

class BatchOption {
  const BatchOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ReportSession {
  const ReportSession({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.presentCount,
    required this.leaveCount,
    required this.absentCount,
    required this.totalStudents,
    required this.status,
  });

  final String id;
  final String batchId;
  final String batchName;
  final DateTime date;
  final int presentCount;
  final int leaveCount;
  final int absentCount;
  final int totalStudents;
  final String status;

  double get attendancePercent {
    if (totalStudents <= 0) {
      return 0;
    }
    return ((presentCount + leaveCount) / totalStudents) * 100;
  }

  factory ReportSession.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final int present = _toInt(map['presentCount']);
    final int leave = _toInt(map['leaveCount']);
    final int total = _toInt(map['totalStudents']);
    final int absentFromMap = _toInt(map['absentCount']);
    final int absent = absentFromMap == 0 && total > 0
        ? (total - present - leave).clamp(0, 1000000)
        : absentFromMap;
    final Timestamp? ts = map['date'] as Timestamp?;
    final DateTime date = ts?.toDate() ?? DateTime.now();
    return ReportSession(
      id: id,
      batchId: (map['batchId'] as String?)?.trim() ?? '',
      batchName: (map['batchName'] as String?)?.trim().isNotEmpty == true
          ? (map['batchName'] as String).trim()
          : 'Unknown Batch',
      date: DateTime(date.year, date.month, date.day),
      presentCount: present,
      leaveCount: leave,
      absentCount: absent,
      totalStudents: total,
      status: (map['status'] as String?)?.trim().isNotEmpty == true
          ? (map['status'] as String).trim()
          : 'open',
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }
}
