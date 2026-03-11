part of 'attendance_view.dart';

extension _AttendanceViewDialogsPart on AttendanceView {
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
    String searchText = draft.search;
    String reasonText = session.notConductedTeacherReason;
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
    String? reasonError;

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
                final String searchQuery = searchText.trim().toLowerCase();
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
                            if (!session.classConducted) ...<Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFF9A3412),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Admin marked this session as not conducted. Reason is required before submission.',
                                        style: const TextStyle(
                                          color: Color(0xFF9A3412),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: reasonText,
                                maxLines: 2,
                                onChanged: (String value) {
                                  setState(() {
                                    reasonText = value;
                                    reasonError = null;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText:
                                      'Reason for class not conducted',
                                  hintText:
                                      'Example: Trainer unavailable, but students were present.',
                                  errorText: reasonError,
                                  prefixIcon: const Icon(
                                    Icons.edit_note_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
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
                            TextFormField(
                              initialValue: searchText,
                              onChanged: (String value) {
                                setState(() {
                                  searchText = value;
                                });
                              },
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
                                          search: searchText,
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
                                        if (!session.classConducted &&
                                            reasonText.trim().isEmpty) {
                                          setState(() {
                                            reasonError =
                                                'Please provide a reason.';
                                          });
                                          return;
                                        }
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
                                                notConductedReason:
                                                    reasonText,
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
                                            notConductedReason:
                                                reasonText,
                                          );
                                          controller.cacheTeacherDraft(
                                            sessionId: session.id,
                                            presentStudentIds: presentIds
                                                .toList(),
                                            leaveStudentIds: leaveIds.toList(),
                                            search: searchText,
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
              if (!session.classConducted)
                _sessionMiniChip(
                  'Not Conducted',
                  session.notConductedTeacherReason.isNotEmpty
                      ? session.notConductedTeacherReason
                      : 'Reason required',
                  const Color(0xFFFFF3DC),
                  const Color(0xFF9A3412),
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
          if (session.auditLogs.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4EAF7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Audit Timeline (${session.auditLogs.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: session.auditLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (BuildContext context, int index) {
                        final AttendanceAuditLog log =
                            session.auditLogs[index];
                        final DateTime at = log.at ?? DateTime(2000, 1, 1);
                        final String date =
                            '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}';
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4EAF7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${log.role.toUpperCase()} corrected on $date',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (log.note.trim().isNotEmpty) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  log.note,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                final bool isNoteRequired = controller.requireCorrectionNote.value;
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
                      decoration: InputDecoration(
                        labelText: isNoteRequired
                            ? 'Correction note *'
                            : 'Correction note (optional)',
                        hintText: isNoteRequired
                            ? 'Reason for this correction (required)...'
                            : 'Reason for this correction...',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    if (isNoteRequired) ...<Widget>[
                      const SizedBox(height: 6),
                      const Text(
                        'Required by Settings policy.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                            await _runGuardedDialogAction(
                              context: context,
                              action: () async {
                                await controller.adminCorrectSession(
                                  session: session,
                                  presentStudentIds: presentIds.toList(),
                                  leaveStudentIds: leaveIds.toList(),
                                  note: noteController.text,
                                );
                                _closeActiveDialog();
                              },
                            );
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
    bool confirmed = false;
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.rate_review_rounded,
            title: 'Review Submission',
            subtitle: 'Please confirm attendance counts before final submit.',
            accent: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4EAF7)),
            ),
            child: Text(
              batchName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _sessionMiniChip(
                'Target',
                '$expectedTarget',
                const Color(0xFFE8EEFF),
                const Color(0xFF1E4ED8),
              ),
              _sessionMiniChip(
                'Present',
                '$present',
                const Color(0xFFDCFCE7),
                const Color(0xFF166534),
              ),
              _sessionMiniChip(
                'Leave',
                '$leave',
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: _closeActiveDialog,
                child: const Text('Back'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  confirmed = true;
                  _closeActiveDialog();
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Submit'),
              ),
            ],
          ),
        ],
      ),
    );
    return confirmed;
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    AppNotifier.showError(
      'Something went wrong',
      message: message.replaceFirst('Exception: ', ''),
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

  Future<void> _runGuardedDialogAction({
    required BuildContext context,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (e) {
      if (AppNotifier.isNetworkError(e)) {
        AppNotifier.showRetry(
          title: 'Network error',
          message: 'Unable to sync. Check connection and retry.',
          onRetry: () => _runGuardedDialogAction(
            context: context,
            action: action,
          ),
        );
        return;
      }
      AppNotifier.showError(
        'Something went wrong',
        message: AppNotifier.cleanMessage(e),
      );
    }
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
