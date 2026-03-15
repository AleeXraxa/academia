part of 'attendance_view.dart';

extension _AttendanceViewAdminPart on AttendanceView {
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
                                Obx(() {
                                  final bool isConducted =
                                      controller
                                          .generationConductedByBatchId[batch
                                          .id] ??
                                      true;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              'Class Conducted',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Switch.adaptive(
                                            value: isConducted,
                                            onChanged: isSelected
                                                ? (bool value) {
                                                    controller
                                                        .updateBatchConducted(
                                                          batchId: batch.id,
                                                          conducted: value,
                                                        );
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                      if (!isConducted) ...<Widget>[
                                        const SizedBox(height: 6),
                                        _sessionMiniChip(
                                          'Not Conducted',
                                          'Reason required by teacher',
                                          const Color(0xFFFFF3DC),
                                          const Color(0xFF9A3412),
                                        ),
                                      ],
                                    ],
                                  );
                                }),
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
                                Expanded(
                                  flex: 2,
                                  child: Obx(() {
                                    final bool isConducted =
                                        controller
                                            .generationConductedByBatchId[batch
                                            .id] ??
                                        true;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Class Conducted',
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: isConducted,
                                          onChanged: isSelected
                                              ? (bool value) {
                                                  controller
                                                      .updateBatchConducted(
                                                        batchId: batch.id,
                                                        conducted: value,
                                                      );
                                                }
                                              : null,
                                        ),
                                      ],
                                    );
                                  }),
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
                          await _runGuardedDialogAction(
                            context: context,
                            action: () async {
                              await controller
                                  .saveTodayAttendanceForSelectedBatches();
                            },
                          );
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
                              if (!item.classConducted)
                                _sessionMiniChip(
                                  'Not Conducted',
                                  item.notConductedTeacherReason.isNotEmpty
                                      ? item.notConductedTeacherReason
                                      : 'Reason required',
                                  const Color(0xFFFFF3DC),
                                  const Color(0xFF9A3412),
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
                    _teacherSessionGroup(
                      title: 'Pending Sessions Today',
                      emptyTitle: 'No Pending Sessions',
                      emptySubtitle:
                          'Great work. You are up to date for current attendance tasks.',
                      sessions: pending,
                      itemBuilder: teacherCard,
                    ),
                    const SizedBox(height: 10),
                    _teacherSessionGroup(
                      title: 'Submitted Sessions',
                      emptyTitle: 'No Submitted Sessions',
                      emptySubtitle:
                          'Submitted sessions will appear here once attendance is marked.',
                      sessions: submitted,
                      itemBuilder: teacherCard,
                    ),
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
                              flex: 3,
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
                                  : (!item.classConducted)
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _statusPill(item.status),
                                        const SizedBox(height: 4),
                                        Text(
                                          item
                                                  .notConductedTeacherReason
                                                  .isNotEmpty
                                              ? item.notConductedTeacherReason
                                              : 'Not Conducted',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF9A3412),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
      final List<AdminAttendanceSession> filteredSessions =
          controller.filteredHistorySessions;
      final List<AdminAttendanceSession> sessions =
          controller.pagedHistorySessions;
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
                    controller.hasMoreHistorySessions
                        ? '${sessions.length}/${filteredSessions.length} records'
                        : '${filteredSessions.length} records',
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
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double maxWidth = constraints.maxWidth;
                  final bool singleColumn = maxWidth < 620;
                  final bool twoColumns = maxWidth >= 620 && maxWidth < 1080;
                  final double compactWidth = (maxWidth - 10).clamp(
                    180.0,
                    maxWidth,
                  );
                  final double pairedWidth = ((maxWidth - 10) / 2).clamp(
                    180.0,
                    420.0,
                  );

                  double fieldWidth(double desktopWidth) {
                    if (singleColumn) {
                      return compactWidth;
                    }
                    if (twoColumns) {
                      return pairedWidth;
                    }
                    return desktopWidth;
                  }

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SizedBox(
                        width: fieldWidth(180),
                        child: AppDropdownFormField<int>(
                          value: controller.historyRangeDays.value,
                          labelText: 'Date Range',
                          prefixIcon: Icons.date_range_rounded,
                          items: const <DropdownMenuItem<int>>[
                            DropdownMenuItem<int>(
                              value: 1,
                              child: Text('Today'),
                            ),
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
                        width: fieldWidth(220),
                        child: AppDropdownFormField<String>(
                          value: controller.historyBatchId.value.isEmpty
                              ? ''
                              : controller.historyBatchId.value,
                          labelText: 'Batch',
                          prefixIcon: Icons.class_rounded,
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All batches'),
                            ),
                            ...controller.batches.map(
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
                      ),
                      SizedBox(
                        width: fieldWidth(220),
                        child: AppDropdownFormField<String>(
                          value: controller.historyTeacherId.value.isEmpty
                              ? ''
                              : controller.historyTeacherId.value,
                          labelText: 'Teacher',
                          prefixIcon: Icons.person_rounded,
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All teachers'),
                            ),
                            ...teachers.map(
                              (HistoryTeacherOption option) =>
                                  DropdownMenuItem<String>(
                                    value: option.id,
                                    child: Text(
                                      option.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            ),
                          ],
                          onChanged: (String? value) =>
                              controller.updateHistoryTeacherId(value ?? ''),
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth(210),
                        child: AppDropdownFormField<String>(
                          value: controller.historyStatus.value.isEmpty
                              ? ''
                              : controller.historyStatus.value,
                          labelText: 'Status',
                          prefixIcon: Icons.flag_rounded,
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
                        width: fieldWidth(isMobile ? 220 : 260),
                        child: TextField(
                          onChanged: controller.updateHistorySearch,
                          decoration: const InputDecoration(
                            labelText: 'Search batch or session id',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _anomalyInsightCard(
                  icon: Icons.warning_amber_rounded,
                  title: '3-Day Absent Streak',
                  value: '${controller.historyAbsentStreakStudentsCount}',
                  subtitle: 'Students absent for 3 consecutive days',
                  color: const Color(0xFFB45309),
                  onTap: () => _openAbsentStreakDialog(context, controller),
                ),
                _anomalyInsightCard(
                  icon: Icons.trending_down_rounded,
                  title: 'High Absence Sessions',
                  value: '${controller.historyHighAbsenceSessionCount}',
                  subtitle: 'Sessions with >=30% absent ratio',
                  color: const Color(0xFFB91C1C),
                ),
                _anomalyInsightCard(
                  icon: Icons.fact_check_rounded,
                  title: 'Corrected Sessions',
                  value: '${controller.historyCorrectedSessionsCount}',
                  subtitle: 'Audit trail available',
                  color: const Color(0xFF0F766E),
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
                          Expanded(flex: 3, child: Text('Status')),
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
                                flex: 3,
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
                                      semanticsLabel:
                                          'View attendance details for ${item.batchName}',
                                      onTap: () => _openViewAttendanceDialog(
                                        context,
                                        controller,
                                        item,
                                      ),
                                    ),
                                    _historyActionIcon(
                                      icon: Icons.edit_rounded,
                                      color: const Color(0xFF0F766E),
                                      semanticsLabel:
                                          'Edit attendance for ${item.batchName}',
                                      onTap: () =>
                                          _openAdminEditAttendanceDialog(
                                            context,
                                            controller,
                                            item,
                                          ),
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
            if (controller.hasMoreHistorySessions) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Semantics(
                  button: true,
                  label: 'Load more attendance history records',
                  child: FilledButton.tonalIcon(
                    onPressed: controller.loadMoreHistorySessions,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(
                      'Load More (${filteredSessions.length - sessions.length} remaining)',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _historyActionIcon({
    required IconData icon,
    required Color color,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  Widget _anomalyInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final Widget card = Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
        ],
      ),
    );
    if (onTap == null) {
      return card;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: card,
    );
  }

  Future<void> _openAbsentStreakDialog(
    BuildContext context,
    AttendanceController controller,
  ) async {
    final List<String> ids = controller.historyAbsentStreakStudentIds;
    if (ids.isEmpty) {
      await _showErrorDialog(
        context,
        'No students found with 3 consecutive absent days for current filters.',
      );
      return;
    }
    final Map<String, String> namesById = await controller
        .fetchStudentNamesByIds(ids);
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.warning_amber_rounded,
            title: '3-Day Absent Streak',
            subtitle: 'Students with consecutive absences in selected range.',
            accent: const Color(0xFFB45309),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (BuildContext context, int index) {
                final String id = ids[index];
                final String name = namesById[id] ?? 'Student $id';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF2D7A2)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        id,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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

  Widget _teacherSessionGroup({
    required String title,
    required String emptyTitle,
    required String emptySubtitle,
    required List<AdminAttendanceSession> sessions,
    required Widget Function(AdminAttendanceSession session, int index)
    itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          _compactEmptyStateCard(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: Icons.event_available_rounded,
          )
        else
          ...List<Widget>.generate(sessions.length, (int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: itemBuilder(sessions[index], index),
            );
          }),
      ],
    );
  }

  Widget _compactEmptyStateCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF7)),
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
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            flex: 3,
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
    final String label = normalized
        .replaceAll('_', ' ')
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
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
          label.isEmpty ? 'Unknown' : label,
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

  Widget _adminMobileShell(
    BuildContext context,
    AttendanceController controller,
  ) {
    return Obx(() {
      final int tabIndex = controller.mobileTabIndex.value;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_adminMobileTabTitle(tabIndex)),
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          actions: <Widget>[
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
          ],
        ),
        body: SafeArea(
          child: _adminMobileBackground(
            child: IndexedStack(
              index: tabIndex,
              children: <Widget>[
                _adminMobileSessionsTab(context, controller),
                _adminMobileHistoryTab(context, controller),
                _adminMobileBatchesTab(controller),
                _adminMobileStudentsTab(controller),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          height: 58,
          backgroundColor: AppColors.background,
          color: AppColors.surface,
          buttonBackgroundColor: AppColors.accent.withValues(alpha: 0.18),
          index: tabIndex,
          onTap: controller.updateMobileTab,
          items: <Widget>[
            Icon(Icons.fact_check_rounded, color: AppColors.textSecondary),
            Icon(Icons.history_rounded, color: AppColors.textSecondary),
            Icon(Icons.class_rounded, color: AppColors.textSecondary),
            Icon(Icons.people_alt_rounded, color: AppColors.textSecondary),
          ],
        ),
      );
    });
  }

  String _adminMobileTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Sessions';
      case 1:
        return 'History';
      case 2:
        return 'Batches';
      default:
        return 'Students';
    }
  }

  Widget _adminMobileBackground({required Widget child}) {
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

  Widget _adminMobileSessionsTab(
    BuildContext context,
    AttendanceController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: <Widget>[
          _topSummaryCard(controller, isMobile: true),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => AnimatedSize(
              duration: _kBaseMotion,
              curve: Curves.easeOutCubic,
              child: controller.showMarkForm.value
                  ? _markForm(context, controller, isMobile: true)
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
                  label: const Text('Generate Session'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.openExtraMarkForm,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Generate Extra'),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 520,
            child: _todaySessionsTable(
              context,
              controller,
              isMobile: true,
              isTeacher: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminMobileHistoryTab(
    BuildContext context,
    AttendanceController controller,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: _adminHistorySection(context, controller, isMobile: true),
    );
  }

  Widget _adminMobileBatchesTab(AttendanceController controller) {
    return Obx(() {
      final List<BatchModel> items = controller.batches;
      if (items.isEmpty) {
        return const Center(
          child: Text(
            'No batches available.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          return _adminMobileBatchCard(context, items[index]);
        },
      );
    });
  }

  Widget _adminMobileBatchCard(BuildContext context, BatchModel batch) {
    final String teacherName = (batch.teacherName ?? '').trim();
    final String scheduleLabel = _batchPatternLabel(batch);
    final int studentsCount = batch.studentsCount ?? 0;
    return InkWell(
      onTap: () => _openAdminBatchDetailDialog(context, batch),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              batch.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Schedule: $scheduleLabel',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Students: $studentsCount',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              teacherName.isEmpty
                  ? 'Teacher: Unassigned'
                  : 'Teacher: $teacherName',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminMobileStudentsTab(AttendanceController controller) {
    return Obx(() {
      final String query = controller.adminStudentAppliedSearch.value
          .trim()
          .toLowerCase();
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<StudentModel> items =
                  snapshot.data?.docs
                      .map(
                        (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                            StudentModel.fromMap(id: doc.id, map: doc.data()),
                      )
                      .toList() ??
                  <StudentModel>[];
              final List<StudentModel> filtered = query.isEmpty
                  ? items
                  : items.where((StudentModel student) {
                      final String name = student.name.toLowerCase();
                      final String studentId = (student.studentId ?? '')
                          .toLowerCase();
                      final String batchName = (student.batchName ?? '')
                          .toLowerCase();
                      return name.contains(query) ||
                          studentId.contains(query) ||
                          batchName.contains(query);
                    }).toList();
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Student Search',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.adminStudentAppliedSearch.value
                                        .trim()
                                        .isEmpty
                                    ? 'Tap search to filter students.'
                                    : 'Filter: ${controller.adminStudentAppliedSearch.value}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () => _openAdminStudentSearchDialog(
                            context,
                            controller,
                          ),
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Search'),
                        ),
                        if (controller.adminStudentAppliedSearch.value
                            .trim()
                            .isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              controller.adminStudentAppliedSearch.value = '';
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Clear'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No students found.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (BuildContext context, int index) {
                              return _adminMobileStudentCard(
                                context,
                                filtered[index],
                              );
                            },
                          ),
                  ),
                ],
              );
            },
      );
    });
  }

  Future<void> _openAdminStudentSearchDialog(
    BuildContext context,
    AttendanceController controller,
  ) async {
    final TextEditingController searchController = TextEditingController(
      text: controller.adminStudentAppliedSearch.value,
    );
    await _showSaasDialog(
      context: context,
      child: StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _dialogHeader(
                    icon: Icons.search_rounded,
                    title: 'Search Students',
                    subtitle: 'Find by name, ID, or batch',
                    accent: AppColors.accent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            snapshot,
                          ) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final String query = searchController.text
                                .trim()
                                .toLowerCase();
                            final List<StudentModel> items =
                                snapshot.data?.docs
                                    .map(
                                      (
                                        QueryDocumentSnapshot<
                                          Map<String, dynamic>
                                        >
                                        doc,
                                      ) => StudentModel.fromMap(
                                        id: doc.id,
                                        map: doc.data(),
                                      ),
                                    )
                                    .toList() ??
                                <StudentModel>[];
                            final List<StudentModel> filtered = query.isEmpty
                                ? items
                                : items.where((StudentModel student) {
                                    final String name = student.name
                                        .toLowerCase();
                                    final String studentId =
                                        (student.studentId ?? '').toLowerCase();
                                    final String batchName =
                                        (student.batchName ?? '').toLowerCase();
                                    return name.contains(query) ||
                                        studentId.contains(query) ||
                                        batchName.contains(query);
                                  }).toList();
                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No students found.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (BuildContext context, int index) {
                                final StudentModel student = filtered[index];
                                final String studentId =
                                    (student.studentId ?? '').trim();
                                final String batchName =
                                    (student.batchName ?? '').trim();
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  leading: const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFFE8EEFF),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 16,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  title: Text(student.name),
                                  subtitle: Text(
                                    [studentId, batchName]
                                        .where(
                                          (String value) => value.isNotEmpty,
                                        )
                                        .join(' � '),
                                  ),
                                  onTap: () {
                                    controller.adminStudentAppliedSearch.value =
                                        student.name;
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            );
                          },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () {
                        controller.adminStudentAppliedSearch.value =
                            searchController.text;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply Filter'),
                    ),
                  ),
                ],
              );
            },
      ),
    );
  }

  Widget _adminMobileStudentCard(BuildContext context, StudentModel student) {
    final String studentId = (student.studentId ?? '').trim();
    final String batchName = (student.batchName ?? '').trim();
    final String status = student.status.trim().isNotEmpty
        ? student.status.trim()
        : 'active';
    return InkWell(
      onTap: () => _openAdminStudentDetailDialog(context, student),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            if (studentId.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'ID: $studentId',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Batch: ${batchName.isEmpty ? '--' : batchName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Status: $status',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '--' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdminBatchDetailDialog(
    BuildContext context,
    BatchModel batch,
  ) async {
    final String teacherName = (batch.teacherName ?? '').trim();
    final String scheduleLabel = _batchPatternLabel(batch);
    final String studentsCount = '${batch.studentsCount ?? 0}';
    final String status = (batch.status ?? '').trim().isEmpty
        ? 'Active'
        : (batch.status ?? '').trim();
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.class_rounded,
            title: batch.name,
            subtitle: 'Batch details',
            accent: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          _detailRow(label: 'Schedule', value: scheduleLabel),
          _detailRow(label: 'Students', value: studentsCount),
          _detailRow(
            label: 'Teacher',
            value: teacherName.isEmpty ? 'Unassigned' : teacherName,
          ),
          _detailRow(label: 'Status', value: status),
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

  Future<void> _openAdminStudentDetailDialog(
    BuildContext context,
    StudentModel student,
  ) async {
    final String studentId = (student.studentId ?? '').trim();
    final String email = (student.email ?? '').trim();
    final String contact = (student.contactNo ?? '').trim();
    final String parent = (student.parentContact ?? '').trim();
    final String gender = (student.gender ?? '').trim();
    final String batchName = (student.batchName ?? '').trim();
    final String status = student.status.trim().isNotEmpty
        ? student.status.trim()
        : 'Active';
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.person_rounded,
            title: student.name,
            subtitle: 'Student details',
            accent: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          _detailRow(label: 'Student ID', value: studentId),
          _detailRow(label: 'Batch', value: batchName),
          _detailRow(label: 'Status', value: status),
          _detailRow(label: 'Email', value: email),
          _detailRow(label: 'Contact', value: contact),
          _detailRow(label: 'Parent', value: parent),
          _detailRow(label: 'Gender', value: gender),
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
}
