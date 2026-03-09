import 'package:academia/app/modules/attendance/controllers/attendance_controller.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const Duration _kFastMotion = Duration(milliseconds: 160);
const Duration _kBaseMotion = Duration(milliseconds: 220);
const Duration _kEnterMotion = Duration(milliseconds: 280);
const double _kMobileRadius = 14;
const double _kMobileButtonHeight = 42;
const double _kMobileGap = 10;

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.put(AttendanceController());
    final bool isTeacher = Get.find<AppSession>().isTeacher;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile && isTeacher) {
      return _teacherMobileShell(context, controller);
    }

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Attendance'),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          actions: isTeacher
              ? <Widget>[
                  IconButton(
                    tooltip: 'Logout',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (Get.isRegistered<AttendanceController>()) {
                        Get.delete<AttendanceController>();
                      }
                      Get.find<AppSession>().clear();
                      Get.offAllNamed(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFF7FAFF), Color(0xFFF2F6FD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x142F5DFF),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -20,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x101E4ED8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _attendanceBody(
                    context,
                    controller,
                    isMobile: true,
                    isTeacher: isTeacher,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppShell(
      currentRoute: AppRoutes.attendance,
      child: AppPageScaffold(
        title: 'Attendance',
        subtitle:
            'Admin attendance session setup for today with batch-level present count.',
        child: _attendanceBody(
          context,
          controller,
          isMobile: false,
          isTeacher: isTeacher,
        ),
      ),
    );
  }

  Widget _teacherMobileShell(
    BuildContext context,
    AttendanceController controller,
  ) {
    return Obx(() {
      final int tabIndex = controller.mobileTabIndex.value;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_teacherTabTitle(tabIndex)),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              if (controller.queuedTeacherSubmissionCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: const Color(0xFFFFF3DC),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 16,
                        color: Color(0xFF9A3412),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${controller.queuedTeacherSubmissionCount} submissions queued. Retry when internet is stable.',
                          style: const TextStyle(
                            color: Color(0xFF9A3412),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: _kBaseMotion,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: IndexedStack(
                    key: ValueKey<int>(tabIndex),
                    index: tabIndex,
                    children: <Widget>[
                      _teacherDashboardBody(context, controller),
                      _teacherTabBackground(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _attendanceBody(
                            context,
                            controller,
                            isMobile: true,
                            isTeacher: true,
                          ),
                        ),
                      ),
                      _teacherHistoryBody(context, controller),
                      _teacherProfileBody(context, controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: FlashyTabBar(
          selectedIndex: tabIndex,
          showElevation: true,
          onItemSelected: controller.updateMobileTab,
          items: <FlashyTabBarItem>[
            FlashyTabBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              activeColor: AppColors.accent,
              inactiveColor: AppColors.textSecondary,
            ),
            FlashyTabBarItem(
              icon: const Icon(Icons.fact_check_rounded),
              title: const Text('Attendance'),
              activeColor: AppColors.accent,
              inactiveColor: AppColors.textSecondary,
            ),
            FlashyTabBarItem(
              icon: const Icon(Icons.history_rounded),
              title: const Text('History'),
              activeColor: AppColors.accent,
              inactiveColor: AppColors.textSecondary,
            ),
            FlashyTabBarItem(
              icon: const Icon(Icons.person_rounded),
              title: const Text('Profile'),
              activeColor: AppColors.accent,
              inactiveColor: AppColors.textSecondary,
            ),
          ],
        ),
      );
    });
  }

  String _teacherTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Attendance';
      case 2:
        return 'History';
      default:
        return 'Profile';
    }
  }

  Widget _teacherTabBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF7FAFF), Color(0xFFF2F6FD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x142F5DFF),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x101E4ED8),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _teacherSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _teacherDashboardBody(
    BuildContext context,
    AttendanceController controller,
  ) {
    if (controller.isLoading.value) {
      return _teacherTabBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            _mobileCardSkeleton(height: 150),
            const SizedBox(height: 12),
            _mobileCardSkeleton(height: 210),
            const SizedBox(height: 12),
            _mobileCardSkeleton(height: 210),
          ],
        ),
      );
    }
    final int totalSessions = controller.teacherTodayAssignedSessions;
    final int totalPending = controller.teacherTodayPendingSessions;
    final int totalSubmitted = controller.teacherTodaySubmittedSessions;
    final int totalPresent = controller.todaySessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession session) => sum + session.presentCount,
    );
    final int totalLeave = controller.todaySessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession session) => sum + session.leaveCount,
    );
    final int totalAbsent = controller.todaySessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession session) => sum + session.absentCount,
    );
    final List<AdminAttendanceSession> pendingSessions =
        controller.teacherOpenSessionsToday;
    final List<AdminAttendanceSession> recentTimeline =
        controller.teacherRecentSubmittedSessions;
    return _teacherTabBackground(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  Color(0xFF0F3AA9),
                  Color(0xFF1E4ED8),
                  Color(0xFF2F5DFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x331D4ED8),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Today Workboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date: ${controller.todayLabel}',
                            style: const TextStyle(
                              color: Color(0xFFE5ECFF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => controller.updateMobileTab(1),
                      icon: const Icon(Icons.fact_check_rounded, size: 16),
                      label: const Text('Go to Attendance'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _heroStatTile('Assigned', '$totalSessions'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _heroStatTile('Pending', '$totalPending')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _heroStatTile('Submitted', '$totalSubmitted'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _teacherSectionCard(
            title: 'Session Priority',
            subtitle: 'Your pending attendance sessions for today.',
            child: pendingSessions.isEmpty
                ? _emptyStateCard(
                    title: 'All Sessions Submitted',
                    subtitle:
                        'No pending session right now. You are up to date for today.',
                    icon: Icons.verified_rounded,
                  )
                : Column(
                    children: pendingSessions.map((
                      AdminAttendanceSession item,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFDFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5EAF5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      item.batchName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  _statusPill(item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _sessionMiniChip(
                                    'Expected Present',
                                    '${item.presentCount}',
                                    const Color(0xFFE8EEFF),
                                    const Color(0xFF1E4ED8),
                                  ),
                                  _sessionMiniChip(
                                    'Batch Strength',
                                    '${item.totalStudents}',
                                    const Color(0xFFF3F4F6),
                                    const Color(0xFF334155),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _openTeacherMarkDialog(
                                    context,
                                    controller,
                                    item,
                                  ),
                                  icon: const Icon(Icons.checklist_rounded),
                                  label: const Text('Mark Attendance'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _teacherSectionCard(
            title: 'Today Snapshot',
            subtitle: 'Live KPI cards for your day.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _teacherKpiCard(
                  label: 'Sessions Assigned',
                  value: '$totalSessions',
                  icon: Icons.event_note_rounded,
                  accent: const Color(0xFF1E4ED8),
                ),
                _teacherKpiCard(
                  label: 'Submitted',
                  value: '$totalSubmitted',
                  icon: Icons.check_circle_rounded,
                  accent: const Color(0xFF15803D),
                ),
                _teacherKpiCard(
                  label: 'Present',
                  value: '$totalPresent',
                  icon: Icons.check_circle_rounded,
                  accent: const Color(0xFF15803D),
                ),
                _teacherKpiCard(
                  label: 'Leave',
                  value: '$totalLeave',
                  icon: Icons.time_to_leave_rounded,
                  accent: const Color(0xFF9A3412),
                ),
                _teacherKpiCard(
                  label: 'Absent',
                  value: '$totalAbsent',
                  icon: Icons.cancel_rounded,
                  accent: const Color(0xFFB42318),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _teacherSectionCard(
            title: 'Weekly Personal Performance',
            subtitle: 'Last 5 days submission and attendance quality.',
            child: Column(
              children: <Widget>[
                _dashboardStatCard(
                  'Submission Rate (5D)',
                  '${controller.teacherLast5DaysSubmissionRate.toStringAsFixed(1)}%',
                  Icons.task_alt_rounded,
                ),
                const SizedBox(height: 10),
                _dashboardStatCard(
                  'Average Attendance (5D)',
                  '${controller.teacherLast5DaysAverageAttendance.toStringAsFixed(1)}%',
                  Icons.insights_rounded,
                ),
                const SizedBox(height: 10),
                _dashboardStatCard(
                  'On-time Streak',
                  '${controller.teacherOnTimeSubmissionStreakDays} days',
                  Icons.local_fire_department_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _teacherSectionCard(
            title: 'Recent Activity Timeline',
            subtitle: 'Your latest submitted sessions.',
            child: recentTimeline.isEmpty
                ? _emptyStateCard(
                    title: 'No Recent Submissions',
                    subtitle:
                        'Submit attendance sessions to build your activity history.',
                    icon: Icons.history_toggle_off_rounded,
                  )
                : Column(
                    children: recentTimeline.map((AdminAttendanceSession item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCFDFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5EAF5)),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EEFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.batchName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      _sessionDateLabel(item),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _sessionMiniChip(
                                'Attendance',
                                '${_attendancePercentage(item).toStringAsFixed(1)}%',
                                const Color(0xFFE8EEFF),
                                const Color(0xFF1E4ED8),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x142F5DFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teacherHistoryBody(
    BuildContext context,
    AttendanceController controller,
  ) {
    if (controller.isLoading.value) {
      return _teacherTabBackground(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            _mobileCardSkeleton(height: 160),
            const SizedBox(height: 12),
            _mobileCardSkeleton(height: 180),
            const SizedBox(height: 12),
            _mobileCardSkeleton(height: 260),
          ],
        ),
      );
    }
    final List<AdminAttendanceSession> sessions =
        controller.filteredHistorySessions;
    final List<BatchModel> assignedBatches = controller.teacherAssignedBatches;
    final int totalSessions = sessions.length;
    final int submittedToday = controller.teacherTodaySubmittedSessions;
    final int pendingToday = controller.teacherTodayPendingSessions;
    final int totalPresent = sessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession s) => sum + s.presentCount,
    );
    final int totalLeave = sessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession s) => sum + s.leaveCount,
    );
    final int totalAbsent = sessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession s) => sum + s.absentCount,
    );
    final int totalStrength = (totalPresent + totalLeave + totalAbsent).clamp(
      0,
      1000000,
    );
    final double leaveRatio = totalStrength <= 0
        ? 0
        : (totalLeave / totalStrength) * 100;
    final Map<String, List<double>> byBatch = <String, List<double>>{};
    for (final AdminAttendanceSession s in sessions) {
      if (s.totalStudents <= 0) {
        continue;
      }
      final double pct =
          ((s.presentCount + s.leaveCount) / s.totalStudents) * 100;
      byBatch.putIfAbsent(s.batchName, () => <double>[]).add(pct);
    }
    String bestBatch = '--';
    String lowestBatch = '--';
    double best = -1;
    double lowest = 101;
    byBatch.forEach((String name, List<double> values) {
      final double avg =
          values.reduce((double a, double b) => a + b) / values.length;
      if (avg > best) {
        best = avg;
        bestBatch = name;
      }
      if (avg < lowest) {
        lowest = avg;
        lowestBatch = name;
      }
    });

    return _teacherTabBackground(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _teacherSectionCard(
            title: 'My Performance',
            subtitle: 'Track completion, quality and streak in one place.',
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyKpi(
                        label: 'Submitted Today',
                        value: '$submittedToday',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Pending Today',
                        value: '$pendingToday',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyKpi(
                        label: 'Submission 5D',
                        value:
                            '${controller.teacherLast5DaysSubmissionRate.toStringAsFixed(1)}%',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Avg Attendance 5D',
                        value:
                            '${controller.teacherLast5DaysAverageAttendance.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _historyKpi(
                  label: 'On-time Streak',
                  value: '${controller.teacherOnTimeSubmissionStreakDays} days',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _teacherSectionCard(
            title: 'Filters',
            subtitle: 'Date, batch, status and quick search.',
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyRangeChip(
                        label: '7D',
                        active: controller.historyRangeDays.value == 7,
                        onTap: () => controller.updateHistoryRangeDays(7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyRangeChip(
                        label: '30D',
                        active: controller.historyRangeDays.value == 30,
                        onTap: () => controller.updateHistoryRangeDays(30),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyRangeChip(
                        label: 'All',
                        active: controller.historyRangeDays.value == 0,
                        onTap: () => controller.updateHistoryRangeDays(0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: controller.historyBatchId.value.isEmpty
                      ? ''
                      : controller.historyBatchId.value,
                  decoration: const InputDecoration(
                    labelText: 'Batch',
                    prefixIcon: Icon(Icons.class_rounded),
                  ),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Batches'),
                    ),
                    ...assignedBatches.map(
                      (BatchModel batch) => DropdownMenuItem<String>(
                        value: batch.id,
                        child: Text(batch.name),
                      ),
                    ),
                  ],
                  onChanged: (String? value) =>
                      controller.updateHistoryBatchId(value ?? ''),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: controller.historyStatus.value.isEmpty
                      ? ''
                      : controller.historyStatus.value,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: '', child: Text('All')),
                    DropdownMenuItem<String>(
                      value: 'submitted_by_teacher',
                      child: Text('Submitted'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'completed',
                      child: Text('Corrected/Completed'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'open',
                      child: Text('Open'),
                    ),
                  ],
                  onChanged: (String? value) =>
                      controller.updateHistoryStatus(value ?? ''),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: controller.updateHistorySearch,
                  decoration: const InputDecoration(
                    labelText: 'Search batch or session id',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _teacherSectionCard(
            title: 'Insights',
            subtitle:
                'Quality and attendance distribution for selected filters.',
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyKpi(
                        label: 'Sessions',
                        value: '$totalSessions',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Avg %',
                        value:
                            '${controller.historyAverageAttendancePercentage.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyKpi(
                        label: 'Present',
                        value: '$totalPresent',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Leave Ratio',
                        value: '${leaveRatio.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyKpi(label: 'Best Batch', value: bestBatch),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Lowest Batch',
                        value: lowestBatch,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _teacherSectionCard(
            title: 'Timeline',
            subtitle: 'Premium history timeline with quick drill-down.',
            child: Column(
              children: <Widget>[
                if (sessions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFCFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5EAF5)),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          Icons.history_toggle_off_rounded,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'No history sessions found',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Submit attendance sessions first, then review them here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: () => controller.updateMobileTab(1),
                          icon: const Icon(Icons.fact_check_rounded, size: 16),
                          label: const Text('Go to Attendance'),
                        ),
                      ],
                    ),
                  )
                else
                  ...sessions.asMap().entries.map((
                    MapEntry<int, AdminAttendanceSession> entry,
                  ) {
                    final int index = entry.key;
                    final AdminAttendanceSession item = entry.value;
                    final int total = item.totalStudents <= 0
                        ? 1
                        : item.totalStudents;
                    final int marked =
                        (item.presentCount + item.leaveCount + item.absentCount)
                            .clamp(0, total);
                    final double progress = (marked / total).clamp(0, 1);
                    final bool queued = controller.isQueuedTeacherSubmission(
                      item.id,
                    );
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 160 + (index * 14)),
                      curve: Curves.easeOutCubic,
                      builder: (_, double value, Widget? child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 8),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      item.batchName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _sessionDateLabel(item),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _statusPill(item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _sessionMiniChip(
                                    'Present',
                                    '${item.presentCount}',
                                    const Color(0xFFDCFCE7),
                                    const Color(0xFF166534),
                                  ),
                                  _sessionMiniChip(
                                    'Leave',
                                    '${item.leaveCount}',
                                    const Color(0xFFFFF3DC),
                                    const Color(0xFF9A3412),
                                  ),
                                  _sessionMiniChip(
                                    'Absent',
                                    '${item.absentCount}',
                                    const Color(0xFFFEE2E2),
                                    const Color(0xFF991B1B),
                                  ),
                                  _sessionMiniChip(
                                    'Attendance',
                                    '${_attendancePercentage(item).toStringAsFixed(1)}%',
                                    const Color(0xFFE8EEFF),
                                    const Color(0xFF1E4ED8),
                                  ),
                                  _sessionMiniChip(
                                    'Sync',
                                    queued ? 'Queued' : 'Synced',
                                    queued
                                        ? const Color(0xFFFFF3DC)
                                        : const Color(0xFFDCFCE7),
                                    queued
                                        ? const Color(0xFF9A3412)
                                        : const Color(0xFF166534),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                minHeight: 6,
                                value: progress,
                                borderRadius: BorderRadius.circular(999),
                                color: AppColors.accent,
                                backgroundColor: const Color(0xFFE5EAF5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Marked: $marked / ${item.totalStudents}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _openViewAttendanceDialog(
                                    Get.overlayContext ?? context,
                                    controller,
                                    item,
                                  ),
                                  icon: const Icon(
                                    Icons.visibility_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('View Details'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRangeChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: _kMobileButtonHeight),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E4ED8) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF1E4ED8) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _historyKpi({required String label, required String value}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF5F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teacherProfileBody(
    BuildContext context,
    AttendanceController controller,
  ) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _teacherTabBackground(
      child: uid.isEmpty
          ? const Center(
              child: Text(
                'Unable to load profile.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                    userSnapshot,
                  ) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _teacherTabBackground(
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: <Widget>[
                            _mobileCardSkeleton(height: 180),
                            const SizedBox(height: 12),
                            _mobileCardSkeleton(height: 220),
                            const SizedBox(height: 12),
                            _mobileCardSkeleton(height: 220),
                          ],
                        ),
                      );
                    }
                    final Map<String, dynamic> userData =
                        userSnapshot.data?.data() ?? <String, dynamic>{};
                    final String name =
                        (userData['name'] as String?)?.trim().isNotEmpty == true
                        ? (userData['name'] as String).trim()
                        : 'Teacher';
                    final String email =
                        (userData['email'] as String?)?.trim() ?? '';

                    return StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      stream: FirebaseFirestore.instance
                          .collection('teachers')
                          .doc(uid)
                          .snapshots(),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<
                              DocumentSnapshot<Map<String, dynamic>>
                            >
                            teacherSnapshot,
                          ) {
                            final Map<String, dynamic> teacherData =
                                teacherSnapshot.data?.data() ??
                                <String, dynamic>{};
                            final String expertise =
                                (teacherData['expertise'] as String?)?.trim() ??
                                '';
                            final String education =
                                (teacherData['education'] as String?)?.trim() ??
                                '';
                            final String experience =
                                (teacherData['experience'] as String?)
                                    ?.trim() ??
                                '';

                            final int assignedBatches =
                                controller.teacherAssignedBatches.length;
                            final int submitted30D = controller
                                .filteredHistorySessions
                                .where(
                                  (AdminAttendanceSession session) =>
                                      session.teacherSubmitted,
                                )
                                .length;
                            final int pendingToday =
                                controller.teacherTodayPendingSessions;
                            final int queueCount =
                                controller.queuedTeacherSubmissionCount;
                            final String updatedAt = _readableDateTime(
                              teacherData['updatedAt'] ?? userData['updatedAt'],
                            );
                            final List<String> expertiseTags = expertise
                                .split(',')
                                .map((String e) => e.trim())
                                .where((String e) => e.isNotEmpty)
                                .toList();

                            return ListView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFF0F3AA9),
                                        Color(0xFF1E4ED8),
                                        Color(0xFF2F5DFF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x331D4ED8),
                                        blurRadius: 24,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            child: const Icon(
                                              Icons.school_rounded,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  email.isEmpty ? '--' : email,
                                                  style: const TextStyle(
                                                    color: Color(0xFFE5ECFF),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: <Widget>[
                                          _sessionMiniChip(
                                            'Role',
                                            'Teacher',
                                            const Color(0x1AFFFFFF),
                                            Colors.white,
                                          ),
                                          _sessionMiniChip(
                                            'Profile',
                                            'Verified',
                                            const Color(0x1AFFFFFF),
                                            Colors.white,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        updatedAt.isEmpty
                                            ? 'Last updated: --'
                                            : 'Last updated: $updatedAt',
                                        style: const TextStyle(
                                          color: Color(0xFFDCE6FF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _teacherSectionCard(
                                  title: 'Performance Snapshot',
                                  subtitle:
                                      'Your teaching profile and attendance impact.',
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      _historyKpi(
                                        label: 'Assigned Batches',
                                        value: '$assignedBatches',
                                      ),
                                      _historyKpi(
                                        label: 'Submitted (30D)',
                                        value: '$submitted30D',
                                      ),
                                      _historyKpi(
                                        label: 'Avg Attendance',
                                        value:
                                            '${controller.teacherLast5DaysAverageAttendance.toStringAsFixed(1)}%',
                                      ),
                                      _historyKpi(
                                        label: 'Pending Today',
                                        value: '$pendingToday',
                                      ),
                                      _historyKpi(
                                        label: 'Offline Queue',
                                        value: '$queueCount',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _teacherSectionCard(
                                  title: 'Personal Information',
                                  subtitle:
                                      'Primary account details used in the app.',
                                  child: Column(
                                    children: <Widget>[
                                      _profileInfoTile(
                                        icon: Icons.person_rounded,
                                        label: 'Full Name',
                                        value: name,
                                      ),
                                      const SizedBox(height: 10),
                                      _profileInfoTile(
                                        icon: Icons.email_outlined,
                                        label: 'Email',
                                        value: email.isEmpty ? '--' : email,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _teacherSectionCard(
                                  title: 'Professional Information',
                                  subtitle:
                                      'Your expertise and professional profile.',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      _profileInfoTile(
                                        icon: Icons.school_outlined,
                                        label: 'Education',
                                        value: education.isEmpty
                                            ? '--'
                                            : education,
                                      ),
                                      const SizedBox(height: 10),
                                      _profileInfoTile(
                                        icon: Icons.timeline_rounded,
                                        label: 'Experience',
                                        value: experience.isEmpty
                                            ? '--'
                                            : experience,
                                      ),
                                      const SizedBox(height: 10),
                                      if (expertiseTags.isEmpty)
                                        _profileInfoTile(
                                          icon: Icons.workspace_premium_rounded,
                                          label: 'Expertise',
                                          value: '--',
                                        )
                                      else
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFAFCFF),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE4EAF6),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              const Text(
                                                'Expertise',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: expertiseTags
                                                    .map(
                                                      (
                                                        String tag,
                                                      ) => _sessionMiniChip(
                                                        'Tag',
                                                        tag,
                                                        const Color(0xFFE8EEFF),
                                                        const Color(0xFF1E4ED8),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _teacherSectionCard(
                                  title: 'Security & Account',
                                  subtitle:
                                      'Secure your account and manage sessions.',
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            _openEditTeacherProfileDialog(
                                              context: context,
                                              uid: uid,
                                              initialName: name,
                                              email: email,
                                              initialExpertise: expertise,
                                              initialEducation: education,
                                              initialExperience: experience,
                                            );
                                          },
                                          icon: const Icon(Icons.edit_rounded),
                                          label: const Text('Update Profile'),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _openTeacherPasswordDialog(
                                                context,
                                              ),
                                          icon: const Icon(
                                            Icons.lock_reset_rounded,
                                          ),
                                          label: const Text('Change Password'),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _logoutToLogin,
                                          icon: const Icon(
                                            Icons.logout_rounded,
                                          ),
                                          label: const Text('Logout'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                    );
                  },
            ),
    );
  }

  Widget _profileInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF6)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditTeacherProfileDialog({
    required BuildContext context,
    required String uid,
    required String initialName,
    required String email,
    required String initialExpertise,
    required String initialEducation,
    required String initialExperience,
  }) async {
    final String initialNameNormalized = initialName.trim();
    final String initialExpertiseNormalized = initialExpertise.trim();
    final String initialEducationNormalized = initialEducation.trim();
    final String initialExperienceNormalized = initialExperience.trim();
    final TextEditingController nameController = TextEditingController(
      text: initialNameNormalized,
    );
    final TextEditingController expertiseController = TextEditingController(
      text: initialExpertiseNormalized,
    );
    final TextEditingController educationController = TextEditingController(
      text: initialEducationNormalized,
    );
    final TextEditingController experienceController = TextEditingController(
      text: initialExperienceNormalized,
    );
    final String normalizedEmail = email.trim();
    final TextEditingController emailController = TextEditingController(
      text: normalizedEmail,
    );
    bool isSaving = false;
    String? nameError;

    bool hasChanges() {
      return nameController.text.trim() != initialNameNormalized ||
          expertiseController.text.trim() != initialExpertiseNormalized ||
          educationController.text.trim() != initialEducationNormalized ||
          experienceController.text.trim() != initialExperienceNormalized;
    }

    Future<bool> confirmDiscardIfNeeded(BuildContext modalContext) async {
      if (!hasChanges()) {
        return true;
      }
      final bool? confirm = await showDialog<bool>(
        context: modalContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved profile changes. Do you want to discard them?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep Editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          );
        },
      );
      return confirm ?? false;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, void Function(void Function()) setState) {
            final EdgeInsets keyboardInsets = MediaQuery.of(
              modalContext,
            ).viewInsets;
            return AnimatedPadding(
              duration: _kFastMotion,
              padding: EdgeInsets.only(bottom: keyboardInsets.bottom),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 640),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8E1F4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dialogHeader(
                        icon: Icons.edit_rounded,
                        title: 'Update Profile',
                        subtitle: 'Keep your profile up to date.',
                        accent: AppColors.accent,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: nameController,
                        onChanged: (_) {
                          if (nameError == null) {
                            return;
                          }
                          setState(() {
                            nameError = null;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          errorText: nameError,
                          prefixIcon: const Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: expertiseController,
                        decoration: const InputDecoration(
                          labelText: 'Expertise',
                          prefixIcon: Icon(Icons.workspace_premium_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: educationController,
                        decoration: const InputDecoration(
                          labelText: 'Education',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: experienceController,
                        decoration: const InputDecoration(
                          labelText: 'Experience',
                          prefixIcon: Icon(Icons.timeline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final bool shouldClose =
                                        await confirmDiscardIfNeeded(
                                          modalContext,
                                        );
                                    if (!shouldClose) {
                                      return;
                                    }
                                    if (modalContext.mounted) {
                                      Navigator.of(modalContext).pop();
                                    }
                                  },
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: isSaving || !hasChanges()
                                ? null
                                : () async {
                                    final String name = nameController.text
                                        .trim();
                                    if (name.isEmpty) {
                                      setState(() {
                                        nameError = 'Name is required.';
                                      });
                                      return;
                                    }
                                    setState(() {
                                      isSaving = true;
                                      nameError = null;
                                    });
                                    try {
                                      final WriteBatch batch = FirebaseFirestore
                                          .instance
                                          .batch();
                                      final DocumentReference<
                                        Map<String, dynamic>
                                      >
                                      userDoc = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid);
                                      final DocumentReference<
                                        Map<String, dynamic>
                                      >
                                      teacherDoc = FirebaseFirestore.instance
                                          .collection('teachers')
                                          .doc(uid);

                                      batch.set(userDoc, <String, dynamic>{
                                        'name': name,
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));
                                      batch.set(teacherDoc, <String, dynamic>{
                                        'name': name,
                                        'email': normalizedEmail,
                                        'expertise': expertiseController.text
                                            .trim(),
                                        'education': educationController.text
                                            .trim(),
                                        'experience': experienceController.text
                                            .trim(),
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      }, SetOptions(merge: true));
                                      await batch.commit();

                                      if (modalContext.mounted) {
                                        Navigator.of(modalContext).pop();
                                      }
                                      await _showSaasDialog(
                                        context: context,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            _dialogHeader(
                                              icon: Icons
                                                  .check_circle_outline_rounded,
                                              title: 'Profile Updated',
                                              subtitle:
                                                  'Your profile changes were saved successfully.',
                                              accent: AppColors.success,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: FilledButton(
                                                onPressed: _closeAllDialogs,
                                                child: const Text('OK'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } catch (_) {
                                      await _showErrorDialog(
                                        context,
                                        'Failed to update profile. Please try again.',
                                      );
                                      if (modalContext.mounted) {
                                        setState(() {
                                          isSaving = false;
                                        });
                                      }
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save Changes',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    expertiseController.dispose();
    educationController.dispose();
    experienceController.dispose();
    emailController.dispose();
  }

  Future<void> _openTeacherPasswordDialog(BuildContext context) async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    bool isSaving = false;
    String? passwordError;

    await _showSaasDialog(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext dialogContext, void Function(void Function()) setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _dialogHeader(
                icon: Icons.lock_reset_rounded,
                title: 'Change Password',
                subtitle: 'Use at least 6 characters for a secure password.',
                accent: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  errorText: passwordError,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  OutlinedButton(
                    onPressed: isSaving ? null : _closeActiveDialog,
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final String newPassword = newPasswordController
                                .text
                                .trim();
                            final String confirm = confirmController.text
                                .trim();
                            if (newPassword.length < 6) {
                              setState(() {
                                passwordError =
                                    'Password must be at least 6 characters.';
                              });
                              return;
                            }
                            if (newPassword != confirm) {
                              setState(() {
                                passwordError =
                                    'Password and confirm password do not match.';
                              });
                              return;
                            }
                            setState(() {
                              isSaving = true;
                              passwordError = null;
                            });
                            try {
                              final User? user =
                                  FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                throw Exception('Authentication required.');
                              }
                              await user.updatePassword(newPassword);
                              _closeActiveDialog();
                              await _showSaasDialog(
                                context: context,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    _dialogHeader(
                                      icon: Icons.check_circle_rounded,
                                      title: 'Password Updated',
                                      subtitle:
                                          'Your account password has been changed successfully.',
                                      accent: AppColors.success,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton(
                                        onPressed: _closeActiveDialog,
                                        child: const Text('OK'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } on FirebaseAuthException catch (e) {
                              String message = 'Failed to update password.';
                              if (e.code == 'requires-recent-login') {
                                message =
                                    'For security, please log in again and then change your password.';
                              }
                              await _showErrorDialog(context, message);
                              if (dialogContext.mounted) {
                                setState(() {
                                  isSaving = false;
                                });
                              }
                            } catch (_) {
                              await _showErrorDialog(
                                context,
                                'Failed to update password. Please try again.',
                              );
                              if (dialogContext.mounted) {
                                setState(() {
                                  isSaving = false;
                                });
                              }
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(isSaving ? 'Saving...' : 'Update Password'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    newPasswordController.dispose();
    confirmController.dispose();
  }

  String _readableDateTime(Object? value) {
    DateTime? parsed;
    if (value is Timestamp) {
      parsed = value.toDate();
    } else if (value is DateTime) {
      parsed = value;
    }
    if (parsed == null) {
      return '';
    }
    final String year = parsed.year.toString();
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    final String hour = parsed.hour.toString().padLeft(2, '0');
    final String minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _logoutToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (Get.isRegistered<AttendanceController>()) {
      Get.delete<AttendanceController>();
    }
    Get.find<AppSession>().clear();
    Get.offAllNamed(AppRoutes.login);
  }

  Widget _attendanceBody(
    BuildContext context,
    AttendanceController controller, {
    required bool isMobile,
    required bool isTeacher,
  }) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorText.value.isNotEmpty) {
        return Center(
          child: Text(
            controller.errorText.value,
            style: const TextStyle(color: AppColors.error),
          ),
        );
      }

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double minHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 0;
          final double tableHeight = isMobile ? 420 : 460;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _topSummaryCard(controller, isMobile: isMobile),
                  if (!isTeacher) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Obx(
                      () => AnimatedSize(
                        duration: _kBaseMotion,
                        curve: Curves.easeOutCubic,
                        child: controller.showMarkForm.value
                            ? _markForm(context, controller, isMobile: isMobile)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Obx(() {
                      if (controller.showMarkForm.value) {
                        return const SizedBox.shrink();
                      }
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: controller.openMarkForm,
                            icon: const Icon(Icons.add_task_rounded),
                            label: Text(
                              isMobile
                                  ? 'Generate Session'
                                  : 'Generate Session for Today',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: controller.openExtraMarkForm,
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: Text(
                              isMobile
                                  ? 'Generate Extra'
                                  : 'Generate Extra Session Today',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: tableHeight,
                    child: _todaySessionsTable(
                      context,
                      controller,
                      isMobile: isMobile,
                      isTeacher: isTeacher,
                    ),
                  ),
                  if (!isTeacher) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    _adminHistorySection(
                      context,
                      controller,
                      isMobile: isMobile,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _topSummaryCard(
    AttendanceController controller, {
    required bool isMobile,
  }) {
    final int totalPresent = controller.todaySessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession session) => sum + session.presentCount,
    );
    final int totalAbsent = controller.todaySessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession session) => sum + session.absentCount,
    );
    final int totalLeave = controller.todaySessions.fold<int>(
      0,
      (int sum, AdminAttendanceSession session) => sum + session.leaveCount,
    );
    final String dateLabel = controller.todayLabel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF0F3AA9),
            Color(0xFF1E4ED8),
            Color(0xFF2F5DFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x331D4ED8),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Today\'s Session Window',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Date: $dateLabel',
                        style: const TextStyle(
                          color: Color(0xFFE5ECFF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${controller.todaySessions.length} Sessions',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (isMobile) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _heroStatTile('Present', '$totalPresent')),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _heroStatTile('Leave', '$totalLeave')),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _heroStatTile('Absent', '$totalAbsent')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroStatTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: Color(0xFFE5ECFF), fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _markForm(
    BuildContext context,
    AttendanceController controller, {
    required bool isMobile,
  }) {
    return Obx(() {
      final List<BatchModel> scheduledBatches =
          controller.generationCandidateBatches;
      final int selectedCount = controller.selectedGenerationBatchIds.length;
      final bool isExtraMode = controller.generationMode.value == 'extra';
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isExtraMode
                  ? 'Generate Extra Sessions For Today'
                  : 'Generate Sessions For Today',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              isExtraMode
                  ? 'Select only unscheduled active batches for today and generate extra sessions.'
                  : (controller.isUsingScheduleFallback
                        ? 'No day-pattern batches for today, showing active batches for manual generation.'
                        : 'Select scheduled batches for today and enter present count for each selected batch.'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selected: $selectedCount',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (scheduledBatches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  isExtraMode
                      ? 'No unscheduled active batches available for extra session today.'
                      : 'No batches are scheduled for today.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: isMobile ? 420 : 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: scheduledBatches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final BatchModel batch = scheduledBatches[index];
                    final bool isSelected = controller
                        .isBatchSelectedForGeneration(batch.id);
                    final int total = batch.studentsCount ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFDFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5EAF5)),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        controller.toggleBatchForGeneration(
                                          batchId: batch.id,
                                          selected: value ?? false,
                                        );
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        batch.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _sessionMiniChip(
                                      _batchPatternLabel(batch),
                                      batch.timing?.trim().isEmpty ?? true
                                          ? '--'
                                          : batch.timing!.trim(),
                                      const Color(0xFFE8EEFF),
                                      const Color(0xFF1E4ED8),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  enabled: isSelected,
                                  keyboardType: TextInputType.number,
                                  onChanged: (String value) {
                                    controller.updatePresentInputForBatch(
                                      batchId: batch.id,
                                      value: value,
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Present Students Count',
                                    hintText: '0 - $total',
                                    helperText:
                                        'Enter within batch size. Unchecked rows stay disabled.',
                                    prefixIcon: const Icon(
                                      Icons.groups_2_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Batch Size: $total',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: <Widget>[
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    controller.toggleBatchForGeneration(
                                      batchId: batch.id,
                                      selected: value ?? false,
                                    );
                                  },
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        batch.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_batchPatternLabel(batch)} | Batch Size: $total',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    enabled: isSelected,
                                    keyboardType: TextInputType.number,
                                    onChanged: (String value) {
                                      controller.updatePresentInputForBatch(
                                        batchId: batch.id,
                                        value: value,
                                      );
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Present Count',
                                      hintText: '0 - $total',
                                      helperText: 'Within batch size',
                                      prefixIcon: const Icon(
                                        Icons.groups_2_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    controller.closeMarkForm();
                  },
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          try {
                            await controller
                                .saveTodayAttendanceForSelectedBatches();
                          } catch (e) {
                            await _showErrorDialog(context, '$e');
                          }
                        },
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    controller.isSaving.value
                        ? 'Generating Sessions...'
                        : 'Generate Sessions',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _todaySessionsTable(
    BuildContext context,
    AttendanceController controller, {
    required bool isMobile,
    required bool isTeacher,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.event_note_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Today Sessions',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '${controller.todaySessions.length} records',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) _attendanceSessionHeader(controller),
          Expanded(
            child: Obx(() {
              final List<AdminAttendanceSession> sessions =
                  isTeacher && isMobile
                  ? controller.teacherTaskFirstTodaySessions
                  : controller.sortedTodaySessions;
              if (controller.isLoading.value && sessions.isEmpty) {
                return _sessionsSkeletonList(isMobile: isMobile);
              }
              if (sessions.isEmpty) {
                return _emptyStateCard(
                  title: 'No Sessions Yet',
                  subtitle: isTeacher
                      ? 'No attendance sessions are assigned to you for today.'
                      : 'Generate today sessions first, then they will appear here.',
                  icon: Icons.event_busy_rounded,
                );
              }

              if (isMobile && isTeacher) {
                final List<AdminAttendanceSession> pending = sessions.where((
                  AdminAttendanceSession s,
                ) {
                  return _isOpenSession(s.status) && !s.teacherSubmitted;
                }).toList();
                final List<AdminAttendanceSession> submitted = sessions.where((
                  AdminAttendanceSession s,
                ) {
                  return s.teacherSubmitted || !_isOpenSession(s.status);
                }).toList();

                Widget teacherCard(AdminAttendanceSession item, int index) {
                  final int marked =
                      (item.presentCount + item.leaveCount + item.absentCount)
                          .clamp(
                            0,
                            item.totalStudents <= 0 ? 0 : item.totalStudents,
                          );
                  final int total = item.totalStudents <= 0
                      ? 1
                      : item.totalStudents;
                  final double markProgress = (marked / total).clamp(0, 1);
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 170 + (index * 14)),
                    curve: Curves.easeOutCubic,
                    builder: (_, double value, Widget? child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 8),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFDFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5EAF5)),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.batchName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              _statusPill(item.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _sessionMiniChip(
                                'Target Present',
                                '${item.presentCount}',
                                const Color(0xFFDCFCE7),
                                const Color(0xFF166534),
                              ),
                              _sessionMiniChip(
                                'Leave',
                                '${item.leaveCount}',
                                const Color(0xFFFFF3DC),
                                const Color(0xFF9A3412),
                              ),
                              _sessionMiniChip(
                                'Total',
                                '${item.totalStudents}',
                                const Color(0xFFE8EEFF),
                                const Color(0xFF1E4ED8),
                              ),
                              _sessionMiniChip(
                                'Attendance',
                                '${_attendancePercentage(item).toStringAsFixed(1)}%',
                                const Color(0xFFE8EEFF),
                                const Color(0xFF1E4ED8),
                              ),
                              if (controller.hasTeacherDraft(item.id))
                                _sessionMiniChip(
                                  'Draft',
                                  'Saved',
                                  const Color(0xFFF3F4F6),
                                  const Color(0xFF334155),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            minHeight: 6,
                            value: markProgress,
                            borderRadius: BorderRadius.circular(999),
                            color: AppColors.accent,
                            backgroundColor: const Color(0xFFE5EAF5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Marked: $marked / ${item.totalStudents}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (_isOpenSession(item.status) &&
                              !item.teacherSubmitted) ...<Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonalIcon(
                                onPressed: () => _openTeacherMarkDialog(
                                  context,
                                  controller,
                                  item,
                                ),
                                icon: const Icon(Icons.checklist_rounded),
                                label: const Text('Mark Attendance'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: <Widget>[
                    const Text(
                      'Pending Sessions Today',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pending.isEmpty)
                      const Text(
                        'No pending sessions.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ...List<Widget>.generate(pending.length, (int index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: teacherCard(pending[index], index),
                        );
                      }),
                    const SizedBox(height: 10),
                    const Text(
                      'Submitted Sessions',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (submitted.isEmpty)
                      const Text(
                        'No submitted sessions yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ...List<Widget>.generate(submitted.length, (int index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: teacherCard(submitted[index], index),
                        );
                      }),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (BuildContext context, int index) {
                  final AdminAttendanceSession item = sessions[index];
                  if (isMobile) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 170 + (index * 14)),
                      curve: Curves.easeOutCubic,
                      builder: (_, double value, Widget? child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 8),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFDFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5EAF5)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x0A0F172A),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    item.batchName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                _statusPill(item.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _sessionMiniChip(
                                  isTeacher ? 'Target Present' : 'Present',
                                  '${item.presentCount}',
                                  const Color(0xFFDCFCE7),
                                  const Color(0xFF166534),
                                ),
                                _sessionMiniChip(
                                  'Absent',
                                  '${item.absentCount}',
                                  const Color(0xFFFEE2E2),
                                  const Color(0xFF991B1B),
                                ),
                                _sessionMiniChip(
                                  'Leave',
                                  '${item.leaveCount}',
                                  const Color(0xFFFFF3DC),
                                  const Color(0xFF9A3412),
                                ),
                                _sessionMiniChip(
                                  'Attendance',
                                  '${_attendancePercentage(item).toStringAsFixed(1)}%',
                                  const Color(0xFFE8EEFF),
                                  const Color(0xFF1E4ED8),
                                ),
                                _sessionMiniChip(
                                  'Total',
                                  '${item.totalStudents}',
                                  const Color(0xFFE8EEFF),
                                  const Color(0xFF1E4ED8),
                                ),
                              ],
                            ),
                            if (isTeacher &&
                                _isOpenSession(item.status)) ...<Widget>[
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _openTeacherMarkDialog(
                                    context,
                                    controller,
                                    item,
                                  ),
                                  icon: const Icon(Icons.checklist_rounded),
                                  label: const Text('Submit Attendance'),
                                ),
                              ),
                            ],
                            if (!isTeacher &&
                                item.teacherSubmitted) ...<Widget>[
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _openViewAttendanceDialog(
                                    context,
                                    controller,
                                    item,
                                  ),
                                  icon: const Icon(Icons.visibility_rounded),
                                  label: const Text('View Session Details'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: const Color(0x1A1E4ED8),
                      onTap: () {},
                      child: AnimatedContainer(
                        duration: _kFastMotion,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: controller.isCompactTable.value ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFDFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5EAF5)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 4,
                              child: Text(
                                item.batchName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: controller.isCompactTable.value
                                      ? 12
                                      : 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.presentCount}',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: controller.isCompactTable.value
                                      ? 12
                                      : 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.absentCount}',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: controller.isCompactTable.value
                                      ? 12
                                      : 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.leaveCount}',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                  fontSize: controller.isCompactTable.value
                                      ? 12
                                      : 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.totalStudents}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: controller.isCompactTable.value
                                      ? 12
                                      : 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${_attendancePercentage(item).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: controller.isCompactTable.value
                                      ? 12
                                      : 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: isTeacher && _isOpenSession(item.status)
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.tonalIcon(
                                        onPressed: () => _openTeacherMarkDialog(
                                          context,
                                          controller,
                                          item,
                                        ),
                                        icon: const Icon(
                                          Icons.checklist_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Submit'),
                                      ),
                                    )
                                  : (!isTeacher && item.teacherSubmitted)
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.tonalIcon(
                                        onPressed: () =>
                                            _openViewAttendanceDialog(
                                              context,
                                              controller,
                                              item,
                                            ),
                                        icon: const Icon(
                                          Icons.visibility_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Details'),
                                      ),
                                    )
                                  : _statusPill(item.status),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _adminHistorySection(
    BuildContext context,
    AttendanceController controller, {
    required bool isMobile,
  }) {
    return Obx(() {
      final List<AdminAttendanceSession> sessions =
          controller.filteredHistorySessions;
      final List<HistoryTeacherOption> teachers =
          controller.historyTeacherOptions;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4EAF7)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x100F172A),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0x142F5DFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Attendance History',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Filter, review and correct historical sessions.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFC9D6FF)),
                  ),
                  child: Text(
                    '${sessions.length} records',
                    style: const TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4EAF7)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<int>(
                      value: controller.historyRangeDays.value,
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        prefixIcon: Icon(Icons.date_range_rounded),
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(
                          value: 7,
                          child: Text('Last 7 days'),
                        ),
                        DropdownMenuItem<int>(
                          value: 30,
                          child: Text('Last 30 days'),
                        ),
                        DropdownMenuItem<int>(
                          value: 0,
                          child: Text('All time'),
                        ),
                      ],
                      onChanged: (int? value) =>
                          controller.updateHistoryRangeDays(value ?? 7),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: controller.historyBatchId.value.isEmpty
                          ? ''
                          : controller.historyBatchId.value,
                      decoration: const InputDecoration(
                        labelText: 'Batch',
                        prefixIcon: Icon(Icons.class_rounded),
                      ),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All batches'),
                        ),
                        ...controller.batches.map(
                          (BatchModel batch) => DropdownMenuItem<String>(
                            value: batch.id,
                            child: Text(batch.name),
                          ),
                        ),
                      ],
                      onChanged: (String? value) =>
                          controller.updateHistoryBatchId(value ?? ''),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: controller.historyTeacherId.value.isEmpty
                          ? ''
                          : controller.historyTeacherId.value,
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All teachers'),
                        ),
                        ...teachers.map(
                          (HistoryTeacherOption option) =>
                              DropdownMenuItem<String>(
                                value: option.id,
                                child: Text(option.name),
                              ),
                        ),
                      ],
                      onChanged: (String? value) =>
                          controller.updateHistoryTeacherId(value ?? ''),
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: DropdownButtonFormField<String>(
                      value: controller.historyStatus.value.isEmpty
                          ? ''
                          : controller.historyStatus.value,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text('All status'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'open',
                          child: Text('Open'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'submitted_by_teacher',
                          child: Text('Submitted'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (String? value) =>
                          controller.updateHistoryStatus(value ?? ''),
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 220 : 260,
                    child: TextField(
                      onChanged: controller.updateHistorySearch,
                      decoration: const InputDecoration(
                        labelText: 'Search batch or session id',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _historyKpi(
                  label: 'Sessions',
                  value: '${controller.historyTotalSessions}',
                ),
                _historyKpi(
                  label: 'Avg Attendance',
                  value:
                      '${controller.historyAverageAttendancePercentage.toStringAsFixed(1)}%',
                ),
                _historyKpi(
                  label: 'Present',
                  value: '${controller.historyTotalPresent}',
                ),
                _historyKpi(
                  label: 'Leave',
                  value: '${controller.historyTotalLeave}',
                ),
                _historyKpi(
                  label: 'Absent',
                  value: '${controller.historyTotalAbsent}',
                ),
                _historyKpi(
                  label: 'Best Batch',
                  value: controller.historyBestBatch,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (sessions.isEmpty)
              _emptyStateCard(
                title: 'No History Sessions',
                subtitle: 'No records match current history filters.',
                icon: Icons.history_toggle_off_rounded,
              )
            else if (isMobile)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final AdminAttendanceSession item = sessions[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFDFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5EAF5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.batchName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            _statusPill(item.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_sessionDateLabel(item)} | ${_teacherNameForSession(controller, item)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _sessionMiniChip(
                              'Present',
                              '${item.presentCount}',
                              const Color(0xFFDCFCE7),
                              const Color(0xFF166534),
                            ),
                            _sessionMiniChip(
                              'Leave',
                              '${item.leaveCount}',
                              const Color(0xFFFFF3DC),
                              const Color(0xFF9A3412),
                            ),
                            _sessionMiniChip(
                              'Absent',
                              '${item.absentCount}',
                              const Color(0xFFFEE2E2),
                              const Color(0xFF991B1B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.tonalIcon(
                              onPressed: () => _openViewAttendanceDialog(
                                context,
                                controller,
                                item,
                              ),
                              icon: const Icon(
                                Icons.visibility_rounded,
                                size: 16,
                              ),
                              label: const Text('View'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _openAdminEditAttendanceDialog(
                                context,
                                controller,
                                item,
                              ),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  _copySessionSummary(context, item),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 16,
                              ),
                              label: const Text('Export'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5EAF5)),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F6FE),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5EAF5)),
                        ),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Expanded(flex: 2, child: Text('Date')),
                          Expanded(flex: 3, child: Text('Batch')),
                          Expanded(flex: 2, child: Text('Teacher')),
                          Expanded(flex: 1, child: Text('P')),
                          Expanded(flex: 1, child: Text('L')),
                          Expanded(flex: 1, child: Text('A')),
                          Expanded(flex: 1, child: Text('Total')),
                          Expanded(flex: 2, child: Text('Attendance %')),
                          Expanded(flex: 2, child: Text('Status')),
                          Expanded(flex: 3, child: Text('Actions')),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE5EAF5)),
                      itemBuilder: (BuildContext context, int index) {
                        final AdminAttendanceSession item = sessions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _sessionDateLabel(item),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.batchName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _teacherNameForSession(controller, item),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${item.presentCount}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${item.leaveCount}',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${item.absentCount}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${item.totalStudents}'),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${_attendancePercentage(item).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _statusPill(item.status),
                              ),
                              Expanded(
                                flex: 3,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    _historyActionIcon(
                                      icon: Icons.visibility_rounded,
                                      color: AppColors.accent,
                                      onTap: () => _openViewAttendanceDialog(
                                        context,
                                        controller,
                                        item,
                                      ),
                                    ),
                                    _historyActionIcon(
                                      icon: Icons.edit_rounded,
                                      color: const Color(0xFF0F766E),
                                      onTap: () =>
                                          _openAdminEditAttendanceDialog(
                                            context,
                                            controller,
                                            item,
                                          ),
                                    ),
                                    _historyActionIcon(
                                      icon: Icons.download_rounded,
                                      color: const Color(0xFF4C1D95),
                                      onTap: () =>
                                          _copySessionSummary(context, item),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _historyActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _attendanceSessionHeader(AttendanceController controller) {
    final String sortBy = controller.tableSortBy.value;
    final bool asc = controller.tableSortAscending.value;
    Widget sortable(String label, String key, {int flex = 2}) {
      final bool active = sortBy == key;
      return Expanded(
        flex: flex,
        child: InkWell(
          onTap: () => controller.updateTableSort(key),
          child: Row(
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.accent : AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                active
                    ? (asc
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 14,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF7F9FF), Color(0xFFF4F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9F5)),
      ),
      child: Row(
        children: <Widget>[
          sortable('Batch', 'batch', flex: 4),
          sortable('Present', 'present'),
          sortable('Absent', 'absent'),
          sortable('Leave', 'leave'),
          sortable('Total', 'total'),
          sortable('Attendance %', 'attendance'),
          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Compact rows',
                  child: InkWell(
                    onTap: controller.toggleCompactTable,
                    child: Icon(
                      controller.isCompactTable.value
                          ? Icons.view_day_rounded
                          : Icons.view_headline_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 34, color: AppColors.accent),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionsSkeletonList({required bool isMobile}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5EAF5)),
          ),
          height: isMobile ? 88 : 56,
        );
      },
    );
  }

  Widget _mobileCardSkeleton({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F9),
        borderRadius: BorderRadius.circular(_kMobileRadius),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
    );
  }

  Widget _statusPill(String status) {
    final String normalized = status.trim().toLowerCase();
    final ({Color bg, Color fg}) palette = _statusPalette(normalized);
    final Color bg = palette.bg;
    final Color fg = palette.fg;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
        ),
        child: Text(
          normalized[0].toUpperCase() + normalized.substring(1),
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  ({Color bg, Color fg}) _statusPalette(String normalizedStatus) {
    if (normalizedStatus.contains('submitted') ||
        normalizedStatus == 'completed') {
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534));
    }
    if (normalizedStatus == 'queued') {
      return (bg: const Color(0xFFFFF3DC), fg: const Color(0xFF9A3412));
    }
    if (normalizedStatus == 'open' || normalizedStatus == 'active') {
      return (bg: const Color(0xFFE8EEFF), fg: const Color(0xFF1E4ED8));
    }
    return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFF991B1B));
  }

  Widget _sessionMiniChip(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label: ',
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _batchPatternLabel(BatchModel batch) {
    final List<String> days = (batch.days ?? <String>[])
        .map((String day) => day.trim().toLowerCase())
        .where((String day) => day.isNotEmpty)
        .toList();

    if (days.length == 3 &&
        days[0] == 'monday' &&
        days[1] == 'wednesday' &&
        days[2] == 'friday') {
      return 'MWF';
    }
    if (days.length == 3 &&
        days[0] == 'tuesday' &&
        days[1] == 'thursday' &&
        days[2] == 'saturday') {
      return 'TTS';
    }
    if (days.length == 6 &&
        days[0] == 'monday' &&
        days[1] == 'tuesday' &&
        days[2] == 'wednesday' &&
        days[3] == 'thursday' &&
        days[4] == 'friday' &&
        days[5] == 'saturday') {
      return 'REGULAR';
    }

    final String schedule = batch.schedule.trim().toUpperCase();
    if (schedule == 'MWF' ||
        schedule == 'TTS' ||
        schedule == 'REGULAR' ||
        schedule == 'DAILY') {
      return schedule;
    }

    return 'Schedule';
  }

  bool _isOpenSession(String status) {
    final String normalized = status.trim().toLowerCase();
    return normalized == 'open' || normalized == 'active';
  }

  double _attendancePercentage(AdminAttendanceSession session) {
    final int total = session.totalStudents;
    if (total <= 0) {
      return 0;
    }
    final int attended = session.presentCount + session.leaveCount;
    return (attended / total) * 100;
  }

  String _sessionDateLabel(AdminAttendanceSession session) {
    final DateTime date =
        session.date ??
        DateTime.tryParse('${session.dateKey} 00:00:00') ??
        DateTime(2000, 1, 1);
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _openTeacherMarkDialog(
    BuildContext context,
    AttendanceController controller,
    AdminAttendanceSession session,
  ) async {
    final students = await controller.fetchStudentsForBatch(session.batchId);
    if (students.isEmpty) {
      await _showErrorDialog(
        context,
        'No students found in ${session.batchName} batch.',
      );
      return;
    }

    final TeacherAttendanceDraft draft = controller.draftForSession(session.id);
    final Set<String> allowedIds = students
        .map((StudentModel student) => student.id)
        .toSet();
    final Set<String> presentIds = draft.presentStudentIds
        .where((String id) => allowedIds.contains(id))
        .toSet();
    final Set<String> leaveIds = draft.leaveStudentIds
        .where((String id) => allowedIds.contains(id))
        .toSet();
    final TextEditingController searchController = TextEditingController(
      text: draft.search,
    );
    String statusFilter =
        <String>['all', 'present', 'leave', 'unmarked'].contains(draft.filter)
        ? draft.filter
        : 'all';
    bool isSubmitting = false;
    String syncStatus = controller.isQueuedTeacherSubmission(session.id)
        ? 'Queued for retry'
        : 'Live sync';
    DateTime lastSyncAt = DateTime.now();
    String warningText = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setState) {
                final String searchQuery = searchController.text
                    .trim()
                    .toLowerCase();
                final List<StudentModel> visibleStudents = students.where((
                  StudentModel student,
                ) {
                  final bool isPresent = presentIds.contains(student.id);
                  final bool isLeave = leaveIds.contains(student.id);
                  final bool statusMatch = switch (statusFilter) {
                    'present' => isPresent,
                    'leave' => isLeave,
                    'unmarked' => !isPresent && !isLeave,
                    _ => true,
                  };
                  if (!statusMatch) {
                    return false;
                  }
                  if (searchQuery.isEmpty) {
                    return true;
                  }
                  return student.name.toLowerCase().contains(searchQuery) ||
                      (student.studentId ?? '').toLowerCase().contains(
                        searchQuery,
                      ) ||
                      student.contactNo.toLowerCase().contains(searchQuery);
                }).toList();
                final int total = session.totalStudents > 0
                    ? session.totalStudents
                    : students.length;
                final int expectedTarget = session.presentCount.clamp(0, total);
                final int presentCount = presentIds.length;
                final int leaveCount = leaveIds.length;
                final int absentCount = (total - presentCount - leaveCount)
                    .clamp(0, 1000000);
                final bool presentCapReached = presentCount >= expectedTarget;
                final double progress = expectedTarget <= 0
                    ? 0
                    : (presentCount / expectedTarget).clamp(0, 1);
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E1F4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _dialogHeader(
                        icon: Icons.checklist_rounded,
                        title: 'Submit Attendance',
                        subtitle:
                            '${session.batchName} - Expected present: $expectedTarget',
                        accent: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _sessionMiniChip(
                                  'Present',
                                  '$presentCount',
                                  const Color(0xFFDCFCE7),
                                  const Color(0xFF166534),
                                ),
                                _sessionMiniChip(
                                  'Leave',
                                  '$leaveCount',
                                  const Color(0xFFFFF3DC),
                                  const Color(0xFF9A3412),
                                ),
                                _sessionMiniChip(
                                  'Absent',
                                  '$absentCount',
                                  const Color(0xFFFEE2E2),
                                  const Color(0xFF991B1B),
                                ),
                                _sessionMiniChip(
                                  'Target',
                                  '$expectedTarget',
                                  const Color(0xFFE8EEFF),
                                  const Color(0xFF1E4ED8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              minHeight: 7,
                              value: progress,
                              borderRadius: BorderRadius.circular(999),
                              color: progress >= 1
                                  ? AppColors.success
                                  : AppColors.accent,
                              backgroundColor: const Color(0xFFE5EAF5),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Search student',
                                hintText: 'Name, ID, contact',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _historyRangeChip(
                                  label: 'All',
                                  active: statusFilter == 'all',
                                  onTap: () =>
                                      setState(() => statusFilter = 'all'),
                                ),
                                _historyRangeChip(
                                  label: 'Present',
                                  active: statusFilter == 'present',
                                  onTap: () =>
                                      setState(() => statusFilter = 'present'),
                                ),
                                _historyRangeChip(
                                  label: 'Leave',
                                  active: statusFilter == 'leave',
                                  onTap: () =>
                                      setState(() => statusFilter = 'leave'),
                                ),
                                _historyRangeChip(
                                  label: 'Unmarked',
                                  active: statusFilter == 'unmarked',
                                  onTap: () =>
                                      setState(() => statusFilter = 'unmarked'),
                                ),
                                FilledButton.tonal(
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            warningText = '';
                                            presentIds.clear();
                                            leaveIds.clear();
                                            for (
                                              int i = 0;
                                              i < students.length &&
                                                  i < expectedTarget;
                                              i++
                                            ) {
                                              presentIds.add(students[i].id);
                                            }
                                          });
                                        },
                                  child: const Text('Auto Fill'),
                                ),
                                FilledButton.tonal(
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            warningText = '';
                                            presentIds.clear();
                                            leaveIds.clear();
                                          });
                                        },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (warningText.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3DC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFF2D7A2),
                                  ),
                                ),
                                child: Text(
                                  warningText,
                                  style: const TextStyle(
                                    color: Color(0xFF9A3412),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (warningText.isNotEmpty)
                              const SizedBox(height: AppSpacing.sm),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 360),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: visibleStudents.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.xs),
                                itemBuilder: (BuildContext context, int index) {
                                  final StudentModel student =
                                      visibleStudents[index];
                                  final bool isPresent = presentIds.contains(
                                    student.id,
                                  );
                                  final bool isLeave = leaveIds.contains(
                                    student.id,
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCFDFF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE5EAF5),
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if ((student.studentId ?? '')
                                                  .trim()
                                                  .isNotEmpty)
                                                Text(
                                                  'ID: ${student.studentId}',
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              warningText = '';
                                              if (isPresent) {
                                                presentIds.remove(student.id);
                                                return;
                                              }
                                              if (presentCapReached) {
                                                warningText =
                                                    'You can select max $expectedTarget students as Present.';
                                                return;
                                              }
                                              presentIds.add(student.id);
                                              leaveIds.remove(student.id);
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: isPresent
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFF8FAFF),
                                          ),
                                          child: Text(
                                            'Present',
                                            style: TextStyle(
                                              color: isPresent
                                                  ? const Color(0xFF166534)
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              warningText = '';
                                              if (isLeave) {
                                                leaveIds.remove(student.id);
                                                return;
                                              }
                                              leaveIds.add(student.id);
                                              presentIds.remove(student.id);
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: isLeave
                                                ? const Color(0xFFFFF3DC)
                                                : const Color(0xFFF8FAFF),
                                          ),
                                          child: Text(
                                            'Leave',
                                            style: TextStyle(
                                              color: isLeave
                                                  ? const Color(0xFF9A3412)
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              warningText = '';
                                              leaveIds.remove(student.id);
                                              presentIds.remove(student.id);
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                !isPresent && !isLeave
                                                ? const Color(0xFFFEE2E2)
                                                : const Color(0xFFF8FAFF),
                                          ),
                                          child: Text(
                                            'Absent',
                                            style: TextStyle(
                                              color: !isPresent && !isLeave
                                                  ? const Color(0xFF991B1B)
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFF),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE4EAF7)),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: <Widget>[
                              OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () {
                                        controller.cacheTeacherDraft(
                                          sessionId: session.id,
                                          presentStudentIds: presentIds
                                              .toList(),
                                          leaveStudentIds: leaveIds.toList(),
                                          search: searchController.text,
                                          filter: statusFilter,
                                        );
                                        setState(() {
                                          syncStatus = 'Draft saved';
                                          lastSyncAt = DateTime.now();
                                        });
                                      },
                                child: const Text('Save Draft'),
                              ),
                              if (controller.isQueuedTeacherSubmission(
                                session.id,
                              ))
                                TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          setState(() {
                                            isSubmitting = true;
                                          });
                                          try {
                                            await controller
                                                .retryQueuedTeacherSubmission(
                                                  session.id,
                                                );
                                            setState(() {
                                              syncStatus = 'Queue synced';
                                              isSubmitting = false;
                                              lastSyncAt = DateTime.now();
                                            });
                                          } catch (e) {
                                            setState(() {
                                              isSubmitting = false;
                                            });
                                            await _showErrorDialog(
                                              context,
                                              '$e',
                                            );
                                          }
                                        },
                                  child: const Text('Retry Queue'),
                                ),
                              FilledButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (presentIds.length >
                                            expectedTarget) {
                                          setState(() {
                                            warningText =
                                                'Present selection exceeds target ($expectedTarget).';
                                          });
                                          return;
                                        }
                                        final bool confirmed =
                                            await _confirmTeacherAttendanceSubmit(
                                              context: context,
                                              batchName: session.batchName,
                                              present: presentIds.length,
                                              leave: leaveIds.length,
                                              absent:
                                                  students.length -
                                                  presentIds.length -
                                                  leaveIds.length,
                                              expectedTarget: expectedTarget,
                                            );
                                        if (!confirmed) {
                                          return;
                                        }
                                        setState(() {
                                          isSubmitting = true;
                                        });
                                        final List<String> allIds = students
                                            .map((student) => student.id)
                                            .toList();
                                        final List<String> absentIds = allIds
                                            .where(
                                              (String id) =>
                                                  !presentIds.contains(id) &&
                                                  !leaveIds.contains(id),
                                            )
                                            .toList();
                                        try {
                                          await controller
                                              .submitTeacherAttendance(
                                                sessionId: session.id,
                                                presentStudentIds: presentIds
                                                    .toList(),
                                                leaveStudentIds: leaveIds
                                                    .toList(),
                                                absentStudentIds: absentIds,
                                              );
                                          controller.clearTeacherDraft(
                                            session.id,
                                          );
                                          controller.queuedTeacherSubmissions
                                              .remove(session.id);
                                          controller.queuedTeacherSubmissions
                                              .refresh();
                                          lastSyncAt = DateTime.now();
                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                          }
                                          await _showSaasDialog(
                                            context: context,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                _dialogHeader(
                                                  icon: Icons
                                                      .check_circle_rounded,
                                                  title: 'Attendance Submitted',
                                                  subtitle:
                                                      '${session.batchName} session has been saved.',
                                                  accent: AppColors.success,
                                                ),
                                                const SizedBox(
                                                  height: AppSpacing.md,
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: FilledButton(
                                                    onPressed: () {
                                                      _closeActiveDialog();
                                                      controller
                                                          .updateMobileTab(2);
                                                    },
                                                    child: const Text(
                                                      'View History',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } catch (e) {
                                          controller.queueTeacherSubmission(
                                            sessionId: session.id,
                                            presentStudentIds: presentIds
                                                .toList(),
                                            leaveStudentIds: leaveIds.toList(),
                                            absentStudentIds: absentIds,
                                            reason: '$e',
                                          );
                                          controller.cacheTeacherDraft(
                                            sessionId: session.id,
                                            presentStudentIds: presentIds
                                                .toList(),
                                            leaveStudentIds: leaveIds.toList(),
                                            search: searchController.text,
                                            filter: statusFilter,
                                          );
                                          setState(() {
                                            syncStatus = 'Queued for retry';
                                            isSubmitting = false;
                                            lastSyncAt = DateTime.now();
                                          });
                                          await _showErrorDialog(
                                            context,
                                            'Submission queued locally. Retry once internet is stable.\n$e',
                                          );
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  isSubmitting ? 'Saving...' : 'Submit',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              syncStatus,
                              style: TextStyle(
                                color:
                                    controller.isQueuedTeacherSubmission(
                                      session.id,
                                    )
                                    ? const Color(0xFFB45309)
                                    : AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Last synced: ${lastSyncAt.hour.toString().padLeft(2, '0')}:${lastSyncAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    searchController.dispose();
  }

  Future<void> _openViewAttendanceDialog(
    BuildContext context,
    AttendanceController controller,
    AdminAttendanceSession session,
  ) async {
    final List<String> allStudentIds = <String>[
      ...session.presentStudentIds,
      ...session.leaveStudentIds,
      ...session.absentStudentIds,
    ];
    if (allStudentIds.isEmpty) {
      await _showErrorDialog(
        context,
        'Attendance details are not submitted by teacher yet for ${session.batchName}.',
      );
      return;
    }

    final Map<String, String> namesById = await controller
        .fetchStudentNamesByIds(allStudentIds.toSet().toList());
    final List<String> presentNames = session.presentStudentIds
        .map((String id) => namesById[id] ?? 'Student $id')
        .toList();
    final List<String> leaveNames = session.leaveStudentIds
        .map((String id) => namesById[id] ?? 'Student $id')
        .toList();
    final List<String> absentNames = session.absentStudentIds
        .map((String id) => namesById[id] ?? 'Student $id')
        .toList();

    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.visibility_rounded,
            title: 'Session Attendance',
            subtitle: session.batchName,
            accent: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _sessionMiniChip(
                'Session',
                session.id,
                const Color(0xFFF3F4F6),
                const Color(0xFF334155),
              ),
              _sessionMiniChip(
                'Date',
                _sessionDateLabel(session),
                const Color(0xFFE8EEFF),
                const Color(0xFF1E4ED8),
              ),
              _sessionMiniChip(
                'Status',
                session.status,
                const Color(0xFFE8EEFF),
                const Color(0xFF1E4ED8),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _attendanceGroup(
            title: 'Present (${presentNames.length})',
            names: presentNames,
            bg: const Color(0xFFDCFCE7),
            border: const Color(0xFFBFE9D0),
            text: const Color(0xFF166534),
          ),
          const SizedBox(height: AppSpacing.sm),
          _attendanceGroup(
            title: 'Leave (${leaveNames.length})',
            names: leaveNames,
            bg: const Color(0xFFFFF3DC),
            border: const Color(0xFFF2D7A2),
            text: const Color(0xFF9A3412),
          ),
          const SizedBox(height: AppSpacing.sm),
          _attendanceGroup(
            title: 'Absent (${absentNames.length})',
            names: absentNames,
            bg: const Color(0xFFFEE2E2),
            border: const Color(0xFFF4BFBF),
            text: const Color(0xFF991B1B),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _closeActiveDialog,
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  String _teacherNameForSession(
    AttendanceController controller,
    AdminAttendanceSession session,
  ) {
    for (final BatchModel batch in controller.batches) {
      if (batch.id.trim() == session.batchId.trim()) {
        final String name = (batch.teacherName ?? '').trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    }
    return '--';
  }

  Future<void> _copySessionSummary(
    BuildContext context,
    AdminAttendanceSession session,
  ) async {
    final String text =
        'Session: ${session.id}\n'
        'Date: ${_sessionDateLabel(session)}\n'
        'Batch: ${session.batchName}\n'
        'Present: ${session.presentCount}\n'
        'Leave: ${session.leaveCount}\n'
        'Absent: ${session.absentCount}\n'
        'Total: ${session.totalStudents}\n'
        'Attendance: ${_attendancePercentage(session).toStringAsFixed(1)}%\n'
        'Status: ${session.status}';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      await _showSaasDialog(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _dialogHeader(
              icon: Icons.check_circle_outline_rounded,
              title: 'Export Ready',
              subtitle: 'Session summary copied to clipboard.',
              accent: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _closeActiveDialog,
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openAdminEditAttendanceDialog(
    BuildContext context,
    AttendanceController controller,
    AdminAttendanceSession session,
  ) async {
    final List<StudentModel> students = await controller.fetchStudentsForBatch(
      session.batchId,
    );
    if (students.isEmpty) {
      await _showErrorDialog(
        context,
        'No students are mapped to this batch. Please assign students first.',
      );
      return;
    }
    final Set<String> presentIds = session.presentStudentIds.toSet();
    final Set<String> leaveIds = session.leaveStudentIds.toSet();
    final TextEditingController noteController = TextEditingController();
    try {
      await _showSaasDialog(
        context: context,
        child: StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                final int total = session.totalStudents > 0
                    ? session.totalStudents
                    : students.length;
                final int absent = (total - presentIds.length - leaveIds.length)
                    .clamp(0, 1000000);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _dialogHeader(
                      icon: Icons.edit_note_rounded,
                      title: 'Edit Session Attendance',
                      subtitle: session.batchName,
                      accent: const Color(0xFF0F766E),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _sessionMiniChip(
                          'Present',
                          '${presentIds.length}',
                          const Color(0xFFDCFCE7),
                          const Color(0xFF166534),
                        ),
                        _sessionMiniChip(
                          'Leave',
                          '${leaveIds.length}',
                          const Color(0xFFFFF3DC),
                          const Color(0xFF9A3412),
                        ),
                        _sessionMiniChip(
                          'Absent',
                          '$absent',
                          const Color(0xFFFEE2E2),
                          const Color(0xFF991B1B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (BuildContext context, int index) {
                          final StudentModel student = students[index];
                          final bool isPresent = presentIds.contains(
                            student.id,
                          );
                          final bool isLeave = leaveIds.contains(student.id);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCFDFF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE5EAF5),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isPresent) {
                                        presentIds.remove(student.id);
                                      } else {
                                        presentIds.add(student.id);
                                        leaveIds.remove(student.id);
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: isPresent
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF8FAFF),
                                  ),
                                  child: Text(
                                    'Present',
                                    style: TextStyle(
                                      color: isPresent
                                          ? const Color(0xFF166534)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isLeave) {
                                        leaveIds.remove(student.id);
                                      } else {
                                        leaveIds.add(student.id);
                                        presentIds.remove(student.id);
                                      }
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: isLeave
                                        ? const Color(0xFFFFF3DC)
                                        : const Color(0xFFF8FAFF),
                                  ),
                                  child: Text(
                                    'Leave',
                                    style: TextStyle(
                                      color: isLeave
                                          ? const Color(0xFF9A3412)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Correction note',
                        hintText: 'Reason for this correction...',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: _closeActiveDialog,
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () async {
                            await controller.adminCorrectSession(
                              session: session,
                              presentStudentIds: presentIds.toList(),
                              leaveStudentIds: leaveIds.toList(),
                              note: noteController.text,
                            );
                            _closeActiveDialog();
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Correction'),
                        ),
                      ],
                    ),
                  ],
                );
              },
        ),
      );
    } finally {
      noteController.dispose();
    }
  }

  Widget _attendanceGroup({
    required String title,
    required List<String> names,
    required Color bg,
    required Color border,
    required Color text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(color: text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (names.isEmpty)
            const Text(
              'No students',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: names
                      .map(
                        (String name) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: border),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmTeacherAttendanceSubmit({
    required BuildContext context,
    required String batchName,
    required int present,
    required int leave,
    required int absent,
    required int expectedTarget,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Review Submission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                batchName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Expected Present: $expectedTarget'),
              Text('Present: $present'),
              Text('Leave: $leave'),
              Text('Absent: $absent'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    return confirm ?? false;
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Save',
            subtitle: 'Please review the input and try again.',
            accent: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF5D0D0)),
            ),
            child: Text(
              message.replaceFirst('Exception: ', ''),
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _closeActiveDialog,
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaasDialog({
    required BuildContext context,
    required Widget child,
  }) async {
    await Get.generalDialog<void>(
      barrierDismissible: true,
      barrierLabel: 'saas_dialog',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: _kBaseMotion,
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x220F172A),
                      blurRadius: 30,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, Animation<double> animation, __, Widget dialog) {
        final Animation<double> curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curve),
            child: dialog,
          ),
        );
      },
    );
  }

  void _closeActiveDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
    }
  }

  void _closeAllDialogs() {
    while (Get.isDialogOpen ?? false) {
      Get.back<void>();
    }
  }

  Widget _dialogHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceSessionHeader extends StatelessWidget {
  const _AttendanceSessionHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF7F9FF), Color(0xFFF4F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9F5)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text('Batch', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Present',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Absent',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Leave', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Attendance %',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
