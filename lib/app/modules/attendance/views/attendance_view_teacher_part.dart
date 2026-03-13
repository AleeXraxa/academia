part of 'attendance_view.dart';

extension _AttendanceViewTeacherPart on AttendanceView {
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
    return Obx(() {
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
                                  if (!item.classConducted)
                                    _sessionMiniChip(
                                      'Not Conducted',
                                      item.notConductedTeacherReason.isNotEmpty
                                          ? item.notConductedTeacherReason
                                          : 'Reason required',
                                      const Color(0xFFFFF3DC),
                                      const Color(0xFF9A3412),
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
    });
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
    return Obx(() {
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
      final List<BatchModel> assignedBatches =
          controller.teacherAssignedBatches;
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
      final int totalStrength =
          (totalPresent + totalLeave + totalAbsent).clamp(0, 1000000);
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _historyRangeChip(
                      label: 'Today',
                      active: controller.historyRangeDays.value == 1,
                      onTap: () => controller.updateHistoryRangeDays(1),
                    ),
                    _historyRangeChip(
                      label: '7D',
                      active: controller.historyRangeDays.value == 7,
                      onTap: () => controller.updateHistoryRangeDays(7),
                    ),
                    _historyRangeChip(
                      label: '30D',
                      active: controller.historyRangeDays.value == 30,
                      onTap: () => controller.updateHistoryRangeDays(30),
                    ),
                    _historyRangeChip(
                      label: 'All',
                      active: controller.historyRangeDays.value == 0,
                      onTap: () => controller.updateHistoryRangeDays(0),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppDropdownFormField<String>(
                  value: controller.historyBatchId.value.isEmpty
                      ? ''
                      : controller.historyBatchId.value,
                  labelText: 'Batch',
                  prefixIcon: Icons.class_rounded,
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Batches'),
                    ),
                    ...assignedBatches.map(
                      (BatchModel batch) => DropdownMenuItem<String>(
                        value: batch.id,
                        child: Text(
                          batch.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? value) =>
                      controller.updateHistoryBatchId(value ?? ''),
                ),
                const SizedBox(height: 10),
                AppDropdownFormField<String>(
                  value: controller.historyStatus.value.isEmpty
                      ? ''
                      : controller.historyStatus.value,
                  labelText: 'Status',
                  prefixIcon: Icons.flag_rounded,
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
                                  if (!item.classConducted)
                                    _sessionMiniChip(
                                      'Not Conducted',
                                      item.notConductedTeacherReason.isNotEmpty
                                          ? item.notConductedTeacherReason
                                          : 'Reason required',
                                      const Color(0xFFFFF3DC),
                                      const Color(0xFF9A3412),
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
    });
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
        constraints: const BoxConstraints(
          minHeight: _kMobileButtonHeight,
          minWidth: 74,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF1E4ED8), Color(0xFF2F5DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF7F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF2A56ED) : const Color(0xFFE4EAF7),
            width: active ? 1.1 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (active)
              const BoxShadow(
                color: Color(0x221E4ED8),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF43506A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
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
                                      await NetworkGuard.run(batch.commit());
                                      await AuditLogService().log(
                                        action: 'update',
                                        entityType: 'teacher',
                                        entityId: uid,
                                        entityName: name,
                                        meta: <String, dynamic>{
                                          'email': normalizedEmail,
                                          'expertise': expertiseController.text
                                              .trim(),
                                          'education': educationController.text
                                              .trim(),
                                          'experience': experienceController.text
                                              .trim(),
                                        },
                                      );

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

}

