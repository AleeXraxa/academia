import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ReportsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;
  final RxInt rangeDays = 30.obs;
  final RxString selectedBatchId = ''.obs;
  final RxString selectedStatus = ''.obs;
  final RxString searchQuery = ''.obs;

  final RxList<BatchOption> batches = <BatchOption>[].obs;
  final RxList<ReportSession> sessions = <ReportSession>[].obs;
  final RxList<StudentMeta> students = <StudentMeta>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studentsSub;

  @override
  void onInit() {
    super.onInit();
    _listenBatches();
    _listenStudents();
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

  void updateSearch(String value) {
    searchQuery.value = value.trim().toLowerCase();
  }

  List<ReportSession> get filteredSessions {
    final int days = rangeDays.value;
    final String batchId = selectedBatchId.value.trim();
    final String status = selectedStatus.value.trim().toLowerCase();
    final String q = searchQuery.value.trim().toLowerCase();
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
      final bool searchMatch = q.isEmpty ||
          s.batchName.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q);
      return dateMatch && batchMatch && statusMatch && searchMatch;
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
    final BatchComparison comparison = bestWorstBatches;
    return comparison.bestName.isEmpty ? '--' : comparison.bestName;
  }

  String get worstBatch {
    final BatchComparison comparison = bestWorstBatches;
    return comparison.worstName.isEmpty ? '--' : comparison.worstName;
  }

  List<BatchOption> get batchOptions {
    final List<BatchOption> sorted = batches.toList();
    sorted.sort((BatchOption a, BatchOption b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  Map<String, String> get teacherNameById {
    final Map<String, String> map = <String, String>{};
    for (final BatchOption batch in batches) {
      final String id = batch.teacherId.trim();
      if (id.isEmpty) {
        continue;
      }
      final String name = batch.teacherName.trim();
      map[id] = name.isEmpty ? map[id] ?? 'Teacher $id' : name;
    }
    return map;
  }

  Map<String, StudentMeta> get studentsById {
    final Map<String, StudentMeta> map = <String, StudentMeta>{};
    for (final StudentMeta student in students) {
      map[student.id] = student;
    }
    return map;
  }

  List<StudentAttendanceRow> get studentRows {
    final Map<String, StudentAttendanceRow> rows =
        <String, StudentAttendanceRow>{};
    final Map<String, StudentMeta> byId = studentsById;

    for (final ReportSession session in filteredSessions) {
      if (!session.teacherSubmitted) {
        continue;
      }
      for (final String id in session.presentStudentIds) {
        final StudentMeta meta = byId[id] ?? StudentMeta.unknown(id);
        rows.update(
          id,
          (StudentAttendanceRow value) => value.copyWith(present: value.present + 1, sessions: value.sessions + 1),
          ifAbsent: () => StudentAttendanceRow.fromMeta(meta, present: 1),
        );
      }
      for (final String id in session.leaveStudentIds) {
        final StudentMeta meta = byId[id] ?? StudentMeta.unknown(id);
        rows.update(
          id,
          (StudentAttendanceRow value) => value.copyWith(leave: value.leave + 1, sessions: value.sessions + 1),
          ifAbsent: () => StudentAttendanceRow.fromMeta(meta, leave: 1),
        );
      }
      for (final String id in session.absentStudentIds) {
        final StudentMeta meta = byId[id] ?? StudentMeta.unknown(id);
        rows.update(
          id,
          (StudentAttendanceRow value) => value.copyWith(absent: value.absent + 1, sessions: value.sessions + 1),
          ifAbsent: () => StudentAttendanceRow.fromMeta(meta, absent: 1),
        );
      }
    }

    final List<StudentAttendanceRow> list = rows.values.toList();
    list.sort((a, b) => b.attendancePercent.compareTo(a.attendancePercent));
    if (searchQuery.value.trim().isEmpty) {
      return list;
    }
    final String q = searchQuery.value.trim().toLowerCase();
    return list.where((StudentAttendanceRow row) {
      return row.name.toLowerCase().contains(q) ||
          row.studentId.toLowerCase().contains(q) ||
          row.batchName.toLowerCase().contains(q);
    }).toList();
  }

  List<StudentAttendanceRow> get lowAttendanceStudents {
    return studentRows.where((row) => row.attendancePercent < 70).toList();
  }

  List<BatchAttendanceRow> get batchRows {
    final Map<String, BatchAttendanceRow> rows = <String, BatchAttendanceRow>{};
    for (final ReportSession session in filteredSessions) {
      final String key = session.batchId;
      rows.update(
        key,
        (BatchAttendanceRow value) => value.copyWith(
          sessions: value.sessions + 1,
          present: value.present + session.presentCount,
          leave: value.leave + session.leaveCount,
          absent: value.absent + session.absentCount,
          totalStudents: value.totalStudents + session.totalStudents,
        ),
        ifAbsent: () => BatchAttendanceRow(
          batchId: session.batchId,
          batchName: session.batchName,
          sessions: 1,
          present: session.presentCount,
          leave: session.leaveCount,
          absent: session.absentCount,
          totalStudents: session.totalStudents,
        ),
      );
    }
    final List<BatchAttendanceRow> list = rows.values.toList();
    list.sort((a, b) => b.attendancePercent.compareTo(a.attendancePercent));
    return list;
  }

  List<TeacherAttendanceRow> get teacherRows {
    final Map<String, String> teacherNames = teacherNameById;
    final Map<String, TeacherAttendanceRow> rows =
        <String, TeacherAttendanceRow>{};
    for (final ReportSession session in filteredSessions) {
      BatchOption? batch;
      for (final BatchOption item in batches) {
        if (item.id == session.batchId) {
          batch = item;
          break;
        }
      }
      final String teacherId = batch?.teacherId ?? '';
      if (teacherId.isEmpty) {
        continue;
      }
      final String teacherName =
          batch?.teacherName.trim().isNotEmpty == true
              ? batch!.teacherName
              : (teacherNames[teacherId] ?? 'Teacher $teacherId');
      rows.update(
        teacherId,
        (TeacherAttendanceRow value) => value.copyWith(
          sessions: value.sessions + 1,
          submitted: value.submitted + (session.teacherSubmitted ? 1 : 0),
          present: value.present + session.presentCount,
          leave: value.leave + session.leaveCount,
          absent: value.absent + session.absentCount,
          totalStudents: value.totalStudents + session.totalStudents,
        ),
        ifAbsent: () => TeacherAttendanceRow(
          teacherId: teacherId,
          teacherName: teacherName,
          sessions: 1,
          submitted: session.teacherSubmitted ? 1 : 0,
          present: session.presentCount,
          leave: session.leaveCount,
          absent: session.absentCount,
          totalStudents: session.totalStudents,
        ),
      );
    }
    final List<TeacherAttendanceRow> list = rows.values.toList();
    list.sort((a, b) => b.attendancePercent.compareTo(a.attendancePercent));
    return list;
  }

  List<DayAttendanceRow> get dayRows {
    final Map<String, DayAttendanceRow> rows = <String, DayAttendanceRow>{};
    for (final ReportSession session in filteredSessions) {
      final String key = _dateKey(session.date);
      rows.update(
        key,
        (DayAttendanceRow value) => value.copyWith(
          sessions: value.sessions + 1,
          present: value.present + session.presentCount,
          leave: value.leave + session.leaveCount,
          absent: value.absent + session.absentCount,
          totalStudents: value.totalStudents + session.totalStudents,
        ),
        ifAbsent: () => DayAttendanceRow(
          date: session.date,
          sessions: 1,
          present: session.presentCount,
          leave: session.leaveCount,
          absent: session.absentCount,
          totalStudents: session.totalStudents,
        ),
      );
    }
    final List<DayAttendanceRow> list = rows.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  BatchComparison get bestWorstBatches {
    final List<BatchAttendanceRow> list = batchRows;
    if (list.isEmpty) {
      return const BatchComparison.empty();
    }
    final BatchAttendanceRow best = list.first;
    final BatchAttendanceRow worst = list.last;
    return BatchComparison(
      bestName: best.batchName,
      bestPercent: best.attendancePercent,
      worstName: worst.batchName,
      worstPercent: worst.attendancePercent,
    );
  }

  List<ReportSession> get highAbsenceSessions {
    return filteredSessions.where((ReportSession session) {
      if (session.totalStudents <= 0) {
        return false;
      }
      final double ratio = session.absentCount / session.totalStudents;
      return ratio >= 0.3;
    }).toList();
  }

  List<ReportSession> get notConductedSessions {
    return filteredSessions
        .where((ReportSession s) => !s.classConducted)
        .toList();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _listenBatches() {
    _batchesSub?.cancel();
    _batchesSub = _firestore.collection('batches').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<BatchOption> items = snapshot.docs.map((doc) {
          final Map<String, dynamic> data = doc.data();
          final String name =
              (data['name'] as String?)?.trim().isNotEmpty == true
                  ? (data['name'] as String).trim()
                  : 'Untitled Batch';
          return BatchOption(
            id: doc.id,
            name: name,
            teacherId: (data['teacherId'] as String? ?? '').trim(),
            teacherName: (data['teacherName'] as String? ?? '').trim(),
          );
        }).toList();
        batches.assignAll(items);
      },
    );
  }

  void _listenStudents() {
    _studentsSub?.cancel();
    _studentsSub = _firestore.collection('students').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<StudentMeta> items = snapshot.docs.map((doc) {
          final Map<String, dynamic> data = doc.data();
          return StudentMeta(
            id: doc.id,
            name: (data['name'] as String? ?? '').trim(),
            studentId: (data['studentId'] as String? ?? '').trim(),
            batchId: (data['batchId'] as String? ?? '').trim(),
            batchName: (data['batchName'] as String? ?? '').trim(),
            status: (data['status'] as String? ?? '').trim(),
          );
        }).toList();
        students.assignAll(items);
      },
      onError: (_) {
        students.clear();
      },
    );
  }

  void _listenSessions() {
    _sessionsSub?.cancel();
    isLoading.value = true;
    _sessionsSub = _firestore
        .collection('attendance_sessions')
        .orderBy('date', descending: true)
        .limit(1500)
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
    _studentsSub?.cancel();
    super.onClose();
  }
}

class BatchOption {
  const BatchOption({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.teacherName,
  });

  final String id;
  final String name;
  final String teacherId;
  final String teacherName;
}

class StudentMeta {
  const StudentMeta({
    required this.id,
    required this.name,
    required this.studentId,
    required this.batchId,
    required this.batchName,
    required this.status,
  });

  final String id;
  final String name;
  final String studentId;
  final String batchId;
  final String batchName;
  final String status;

  factory StudentMeta.unknown(String id) {
    return StudentMeta(
      id: id,
      name: 'Student $id',
      studentId: id,
      batchId: '',
      batchName: '--',
      status: 'active',
    );
  }
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
    required this.teacherSubmitted,
    required this.classConducted,
    required this.presentStudentIds,
    required this.leaveStudentIds,
    required this.absentStudentIds,
    required this.notConductedReason,
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
  final bool teacherSubmitted;
  final bool classConducted;
  final List<String> presentStudentIds;
  final List<String> leaveStudentIds;
  final List<String> absentStudentIds;
  final String notConductedReason;

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
    final List<String> presentIds =
        ((map['presentStudentIds'] as List?) ?? <dynamic>[])
            .map((dynamic id) => '$id'.trim())
            .where((String id) => id.isNotEmpty)
            .toList();
    final List<String> leaveIds =
        ((map['leaveStudentIds'] as List?) ?? <dynamic>[])
            .map((dynamic id) => '$id'.trim())
            .where((String id) => id.isNotEmpty)
            .toList();
    final List<String> absentIds =
        ((map['absentStudentIds'] as List?) ?? <dynamic>[])
            .map((dynamic id) => '$id'.trim())
            .where((String id) => id.isNotEmpty)
            .toList();
    final bool teacherSubmitted = (map['teacherSubmitted'] as bool?) ??
        (presentIds.isNotEmpty || leaveIds.isNotEmpty || absentIds.isNotEmpty);

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
      teacherSubmitted: teacherSubmitted,
      classConducted: (map['classConducted'] as bool?) ?? true,
      presentStudentIds: presentIds,
      leaveStudentIds: leaveIds,
      absentStudentIds: absentIds,
      notConductedReason:
          (map['notConductedTeacherReason'] as String? ?? '').trim(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }
}

class StudentAttendanceRow {
  const StudentAttendanceRow({
    required this.studentId,
    required this.name,
    required this.batchId,
    required this.batchName,
    required this.sessions,
    required this.present,
    required this.leave,
    required this.absent,
  });

  final String studentId;
  final String name;
  final String batchId;
  final String batchName;
  final int sessions;
  final int present;
  final int leave;
  final int absent;

  double get attendancePercent {
    if (sessions <= 0) {
      return 0;
    }
    return ((present + leave) / sessions) * 100;
  }

  StudentAttendanceRow copyWith({
    int? sessions,
    int? present,
    int? leave,
    int? absent,
  }) {
    return StudentAttendanceRow(
      studentId: studentId,
      name: name,
      batchId: batchId,
      batchName: batchName,
      sessions: sessions ?? this.sessions,
      present: present ?? this.present,
      leave: leave ?? this.leave,
      absent: absent ?? this.absent,
    );
  }

  factory StudentAttendanceRow.fromMeta(
    StudentMeta meta, {
    int present = 0,
    int leave = 0,
    int absent = 0,
  }) {
    return StudentAttendanceRow(
      studentId: meta.studentId.isNotEmpty ? meta.studentId : meta.id,
      name: meta.name.isNotEmpty ? meta.name : 'Student ${meta.id}',
      batchId: meta.batchId,
      batchName: meta.batchName.isNotEmpty ? meta.batchName : '--',
      sessions: present + leave + absent,
      present: present,
      leave: leave,
      absent: absent,
    );
  }
}

class BatchAttendanceRow {
  const BatchAttendanceRow({
    required this.batchId,
    required this.batchName,
    required this.sessions,
    required this.present,
    required this.leave,
    required this.absent,
    required this.totalStudents,
  });

  final String batchId;
  final String batchName;
  final int sessions;
  final int present;
  final int leave;
  final int absent;
  final int totalStudents;

  double get attendancePercent {
    if (totalStudents <= 0) {
      return 0;
    }
    return ((present + leave) / totalStudents) * 100;
  }

  BatchAttendanceRow copyWith({
    int? sessions,
    int? present,
    int? leave,
    int? absent,
    int? totalStudents,
  }) {
    return BatchAttendanceRow(
      batchId: batchId,
      batchName: batchName,
      sessions: sessions ?? this.sessions,
      present: present ?? this.present,
      leave: leave ?? this.leave,
      absent: absent ?? this.absent,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }
}

class TeacherAttendanceRow {
  const TeacherAttendanceRow({
    required this.teacherId,
    required this.teacherName,
    required this.sessions,
    required this.submitted,
    required this.present,
    required this.leave,
    required this.absent,
    required this.totalStudents,
  });

  final String teacherId;
  final String teacherName;
  final int sessions;
  final int submitted;
  final int present;
  final int leave;
  final int absent;
  final int totalStudents;

  double get attendancePercent {
    if (totalStudents <= 0) {
      return 0;
    }
    return ((present + leave) / totalStudents) * 100;
  }

  double get submissionRate {
    if (sessions <= 0) {
      return 0;
    }
    return (submitted / sessions) * 100;
  }

  TeacherAttendanceRow copyWith({
    int? sessions,
    int? submitted,
    int? present,
    int? leave,
    int? absent,
    int? totalStudents,
  }) {
    return TeacherAttendanceRow(
      teacherId: teacherId,
      teacherName: teacherName,
      sessions: sessions ?? this.sessions,
      submitted: submitted ?? this.submitted,
      present: present ?? this.present,
      leave: leave ?? this.leave,
      absent: absent ?? this.absent,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }
}

class DayAttendanceRow {
  const DayAttendanceRow({
    required this.date,
    required this.sessions,
    required this.present,
    required this.leave,
    required this.absent,
    required this.totalStudents,
  });

  final DateTime date;
  final int sessions;
  final int present;
  final int leave;
  final int absent;
  final int totalStudents;

  double get attendancePercent {
    if (totalStudents <= 0) {
      return 0;
    }
    return ((present + leave) / totalStudents) * 100;
  }

  DayAttendanceRow copyWith({
    int? sessions,
    int? present,
    int? leave,
    int? absent,
    int? totalStudents,
  }) {
    return DayAttendanceRow(
      date: date,
      sessions: sessions ?? this.sessions,
      present: present ?? this.present,
      leave: leave ?? this.leave,
      absent: absent ?? this.absent,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }
}

class BatchComparison {
  const BatchComparison({
    required this.bestName,
    required this.bestPercent,
    required this.worstName,
    required this.worstPercent,
  });

  final String bestName;
  final double bestPercent;
  final String worstName;
  final double worstPercent;

  const BatchComparison.empty()
      : bestName = '',
        bestPercent = 0,
        worstName = '',
        worstPercent = 0;
}
