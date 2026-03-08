import 'dart:async';

import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxList<UserModel> teachers = <UserModel>[].obs;
  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;
  final Rx<DateTime> lastSyncedAt = DateTime.now().obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studentsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _teachersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _todaySessionsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _recentSessionsSubscription;

  final List<Map<String, dynamic>> _todaySessionMaps = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _recentSessionMaps = <Map<String, dynamic>>[];

  int get totalStudents => students.length;
  int get activeStudents => students
      .where((StudentModel student) => _studentStatus(student) == 'active')
      .length;
  int get completedStudents => students
      .where((StudentModel student) => _studentStatus(student) == 'completed')
      .length;
  int get dropStudents => students
      .where((StudentModel student) => _studentStatus(student) == 'drop')
      .length;
  int get assignedStudents => students
      .where((StudentModel student) => (student.batchId ?? '').trim().isNotEmpty)
      .length;

  int get totalBatches => batches.length;
  int get activeBatches => batches
      .where((BatchModel batch) => _batchStatus(batch) == 'active')
      .length;
  int get completedBatches => batches
      .where((BatchModel batch) => _batchStatus(batch) == 'completed')
      .length;

  int get totalTeachers => teachers.length;
  int get approvedTeachers => teachers
      .where((UserModel teacher) => _userStatus(teacher) == 'approved')
      .length;

  int get totalUsers => users.length;
  int get pendingUsers => users
      .where((UserModel user) => _userStatus(user) == 'pending')
      .length;

  int get totalBatchSeatLoad =>
      batches.fold<int>(0, (int sum, BatchModel b) => sum + (b.studentsCount ?? 0));

  double get studentAssignmentRate {
    if (totalStudents == 0) {
      return 0;
    }
    return assignedStudents / totalStudents;
  }

  double get activeBatchRate {
    if (totalBatches == 0) {
      return 0;
    }
    return activeBatches / totalBatches;
  }

  String get todayKey {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get todayPresentCount => _todaySessionMaps.fold<int>(
    0,
    (int sum, Map<String, dynamic> session) =>
        sum + _toInt(session['presentCount']),
  );

  int get todayTotalStudentsCount => _todaySessionMaps.fold<int>(
    0,
    (int sum, Map<String, dynamic> session) =>
        sum + _toInt(session['totalStudents']),
  );

  double get todayAttendanceRate {
    if (todayTotalStudentsCount <= 0) {
      return 0;
    }
    return (todayPresentCount / todayTotalStudentsCount) * 100;
  }

  int get sessionsToday => _todaySessionMaps.length;

  int get sessionsCompleted => _todaySessionMaps.where((
    Map<String, dynamic> session,
  ) {
    final String status =
        (session['status'] as String? ?? '').trim().toLowerCase();
    final bool submitted = session['teacherSubmitted'] == true;
    return submitted || status == 'submitted_by_teacher' || status == 'completed';
  }).length;

  int get sessionsPending => (sessionsToday - sessionsCompleted).clamp(0, 1000000);

  double get overallAttendanceRate {
    int present = 0;
    int leave = 0;
    int total = 0;
    for (final Map<String, dynamic> session in _recentSessionMaps) {
      present += _toInt(session['presentCount']);
      leave += _toInt(session['leaveCount']);
      total += _toInt(session['totalStudents']);
    }
    if (total <= 0) {
      return 0;
    }
    return ((present + leave) / total) * 100;
  }

  int get assignedBatches => batches.where((BatchModel batch) {
    final String teacherId = (batch.teacherId ?? '').trim();
    return teacherId.isNotEmpty;
  }).length;

  int get unassignedBatches => (totalBatches - assignedBatches).clamp(0, 1000000);

  double get studentsPerBatch {
    if (totalBatches <= 0) {
      return 0;
    }
    return totalStudents / totalBatches;
  }

  List<WeekdayAttendancePoint> get weeklyAttendanceTrend {
    final DateTime now = DateTime.now();
    final DateTime weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final DateTime weekEnd = weekStart.add(const Duration(days: 4));

    final Map<int, int> attendedByWeekday = <int, int>{};
    final Map<int, int> totalByWeekday = <int, int>{};
    for (int day = 1; day <= 5; day++) {
      attendedByWeekday[day] = 0;
      totalByWeekday[day] = 0;
    }

    for (final Map<String, dynamic> session in _recentSessionMaps) {
      final Timestamp? ts = session['date'] as Timestamp?;
      final DateTime? date = ts?.toDate();
      if (date == null) {
        continue;
      }
      final DateTime normalized = DateTime(date.year, date.month, date.day);
      if (normalized.isBefore(weekStart) || normalized.isAfter(weekEnd)) {
        continue;
      }
      final int weekday = normalized.weekday;
      if (weekday < DateTime.monday || weekday > DateTime.friday) {
        continue;
      }
      final int present = _toInt(session['presentCount']);
      final int leave = _toInt(session['leaveCount']);
      final int total = _toInt(session['totalStudents']);
      attendedByWeekday[weekday] = (attendedByWeekday[weekday] ?? 0) + present + leave;
      totalByWeekday[weekday] = (totalByWeekday[weekday] ?? 0) + total;
    }

    const List<String> labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final List<WeekdayAttendancePoint> points = <WeekdayAttendancePoint>[];
    for (int weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
      final int attended = attendedByWeekday[weekday] ?? 0;
      final int total = totalByWeekday[weekday] ?? 0;
      final double percent = total <= 0 ? 0 : (attended / total) * 100;
      points.add(
        WeekdayAttendancePoint(
          label: labels[weekday - 1],
          percent: percent,
        ),
      );
    }
    return points;
  }

  int get atRiskStudents {
    final Map<String, int> totalByStudent = <String, int>{};
    final Map<String, int> attendedByStudent = <String, int>{};

    for (final Map<String, dynamic> session in _recentSessionMaps) {
      final List<String> present = _toStringList(session['presentStudentIds']);
      final List<String> leave = _toStringList(session['leaveStudentIds']);
      final List<String> absent = _toStringList(session['absentStudentIds']);

      for (final String id in present) {
        totalByStudent[id] = (totalByStudent[id] ?? 0) + 1;
        attendedByStudent[id] = (attendedByStudent[id] ?? 0) + 1;
      }
      for (final String id in leave) {
        totalByStudent[id] = (totalByStudent[id] ?? 0) + 1;
        attendedByStudent[id] = (attendedByStudent[id] ?? 0) + 1;
      }
      for (final String id in absent) {
        totalByStudent[id] = (totalByStudent[id] ?? 0) + 1;
      }
    }

    int count = 0;
    totalByStudent.forEach((String id, int total) {
      if (total <= 0) {
        return;
      }
      final int attended = attendedByStudent[id] ?? 0;
      final double rate = (attended / total) * 100;
      if (rate < 70) {
        count += 1;
      }
    });
    return count;
  }

  @override
  void onInit() {
    super.onInit();
    _listenBatches();
    _listenStudents();
    _listenTeachers();
    _listenUsers();
    _listenTodaySessions();
    _listenRecentSessions();
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
            _syncTick();
          },
          onError: (_) {
            errorText.value = 'Unable to load dashboard data.';
            isLoading.value = false;
          },
        );
  }

  void _listenStudents() {
    _studentsSubscription?.cancel();
    _studentsSubscription = _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<StudentModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      StudentModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            students.assignAll(mapped);
            _syncTick();
          },
          onError: (_) {
            errorText.value = 'Unable to load dashboard data.';
            isLoading.value = false;
          },
        );
  }

  void _listenTeachers() {
    _teachersSubscription?.cancel();
    _teachersSubscription = _firestore.collection('teachers').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<UserModel> mapped = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  UserModel.fromMap(id: doc.id, map: doc.data()),
            )
            .toList();
        teachers.assignAll(mapped);
        _syncTick();
      },
      onError: (_) {
        errorText.value = 'Unable to load dashboard data.';
        isLoading.value = false;
      },
    );
  }

  void _listenUsers() {
    _usersSubscription?.cancel();
    _usersSubscription = _firestore.collection('users').snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<UserModel> mapped = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  UserModel.fromMap(id: doc.id, map: doc.data()),
            )
            .toList();
        users.assignAll(mapped);
        _syncTick();
      },
      onError: (_) {
        errorText.value = 'Unable to load dashboard data.';
        isLoading.value = false;
      },
    );
  }

  void _syncTick() {
    errorText.value = '';
    isLoading.value = false;
    lastSyncedAt.value = DateTime.now();
  }

  void _listenTodaySessions() {
    _todaySessionsSubscription?.cancel();
    _todaySessionsSubscription = _firestore
        .collection('attendance_sessions')
        .where('dateKey', isEqualTo: todayKey)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _todaySessionMaps
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      doc.data(),
                ),
              );
            _syncTick();
          },
          onError: (_) {
            errorText.value = 'Unable to load dashboard attendance insights.';
            isLoading.value = false;
          },
        );
  }

  void _listenRecentSessions() {
    _recentSessionsSubscription?.cancel();
    _recentSessionsSubscription = _firestore
        .collection('attendance_sessions')
        .orderBy('date', descending: true)
        .limit(500)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _recentSessionMaps
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      doc.data(),
                ),
              );
            _syncTick();
          },
          onError: (_) {
            errorText.value = 'Unable to load dashboard attendance insights.';
            isLoading.value = false;
          },
        );
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  List<String> _toStringList(Object? value) {
    return ((value as List?) ?? <dynamic>[])
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  String _studentStatus(StudentModel student) {
    final String normalized = student.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'active';
    }
    return normalized;
  }

  String _batchStatus(BatchModel batch) {
    final String normalized = (batch.status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'active';
    }
    return normalized;
  }

  String _userStatus(UserModel user) {
    final String normalized = user.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'approved';
    }
    return normalized;
  }

  @override
  void onClose() {
    _batchesSubscription?.cancel();
    _studentsSubscription?.cancel();
    _teachersSubscription?.cancel();
    _usersSubscription?.cancel();
    _todaySessionsSubscription?.cancel();
    _recentSessionsSubscription?.cancel();
    super.onClose();
  }
}

class WeekdayAttendancePoint {
  const WeekdayAttendancePoint({
    required this.label,
    required this.percent,
  });

  final String label;
  final double percent;
}
