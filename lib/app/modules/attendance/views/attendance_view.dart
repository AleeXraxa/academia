import 'package:academia/app/modules/attendance/controllers/attendance_controller.dart';
import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/routes/app_pages.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.put(AttendanceController());
    final bool isTeacher = AppPages.activeRole == UserRole.teacher;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

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
                      AppPages.setActiveRole(UserRole.staff);
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

      return Column(
        children: <Widget>[
          _topSummaryCard(controller, isMobile: isMobile),
          if (!isTeacher) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: controller.showMarkForm.value
                  ? _markForm(context, controller, isMobile: isMobile)
                  : const SizedBox.shrink(),
            ),
            if (!controller.showMarkForm.value) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: controller.openMarkForm,
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text(
                    isMobile ? 'Mark Attendance' : 'Mark Attendance For Today',
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _todaySessionsTable(
              context,
              controller,
              isMobile: isMobile,
              isTeacher: isTeacher,
            ),
          ),
        ],
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
      child: Column(
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
          const Text(
            'Mark Attendance For Today',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select batch and enter number of present students.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            Column(
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: controller.selectedBatchId.value.trim().isEmpty
                      ? null
                      : controller.selectedBatchId.value,
                  decoration: const InputDecoration(
                    labelText: 'Batch',
                    prefixIcon: Icon(Icons.class_rounded),
                  ),
                  items: controller.batches
                      .map(
                        (batch) => DropdownMenuItem<String>(
                          value: batch.id,
                          child: Text(batch.name),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    controller.updateBatch(value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  onChanged: (String value) {
                    controller.presentCountInput.value = value;
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Present Students',
                    prefixIcon: Icon(Icons.groups_2_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Batch Size: ${controller.selectedBatchStudentsCount}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedBatchId.value.trim().isEmpty
                        ? null
                        : controller.selectedBatchId.value,
                    decoration: const InputDecoration(
                      labelText: 'Batch',
                      prefixIcon: Icon(Icons.class_rounded),
                    ),
                    items: controller.batches
                        .map(
                          (batch) => DropdownMenuItem<String>(
                            value: batch.id,
                            child: Text(batch.name),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      controller.updateBatch(value);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (String value) {
                      controller.presentCountInput.value = value;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Present Students',
                      prefixIcon: Icon(Icons.groups_2_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Batch Size: ${controller.selectedBatchStudentsCount}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
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
                        final int? parsed = int.tryParse(
                          controller.presentCountInput.value.trim(),
                        );
                        if (parsed == null) {
                          return;
                        }

                        try {
                          await controller.saveTodayAttendance(
                            presentCount: parsed,
                          );
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
                label: Text(controller.isSaving.value ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
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
          if (!isMobile) const _AttendanceSessionHeader(),
          Expanded(
            child: Obx(() {
              if (controller.todaySessions.isEmpty) {
                return const Center(
                  child: Text('No attendance sessions saved for today.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: controller.todaySessions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (BuildContext context, int index) {
                  final AdminAttendanceSession item =
                      controller.todaySessions[index];
                  if (isMobile) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 170 + (index * 20)),
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
                                  'Present',
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
                                  label: const Text('Mark Attendance'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.presentCount}',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.absentCount}',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.leaveCount}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.totalStudents}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
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
                                    label: const Text('Mark'),
                                  ),
                                )
                              : _statusPill(item.status),
                        ),
                      ],
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

  Widget _statusPill(String status) {
    final String normalized = status.trim().toLowerCase();
    final Color bg = normalized == 'closed'
        ? const Color(0xFFE8EEFF)
        : const Color(0xFFDEF7E8);
    final Color fg = normalized == 'closed'
        ? const Color(0xFF1E4ED8)
        : const Color(0xFF15803D);

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
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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

    final Set<String> presentIds = <String>{};
    final Set<String> leaveIds = <String>{};
    String warningText = '';

    await _showSaasDialog(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _dialogHeader(
                icon: Icons.checklist_rounded,
                title: 'Mark Attendance',
                subtitle:
                    '${session.batchName} - Present max ${session.presentCount}',
                accent: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (warningText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3DC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF2D7A2)),
                  ),
                  child: Text(
                    warningText,
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 12,
                    ),
                  ),
                ),
              if (warningText.isNotEmpty) const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: students.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (BuildContext context, int index) {
                    final student = students[index];
                    final bool isPresent = presentIds.contains(student.id);
                    final bool isLeave = leaveIds.contains(student.id);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFDFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5EAF5)),
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
                                warningText = '';
                                if (isPresent) {
                                  presentIds.remove(student.id);
                                  return;
                                }
                                if (presentIds.length >= session.presentCount) {
                                  warningText =
                                      'You can select max ${session.presentCount} students as Present.';
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
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
                      await controller.submitTeacherAttendance(
                        sessionId: session.id,
                        presentStudentIds: presentIds.toList(),
                        leaveStudentIds: leaveIds.toList(),
                        absentStudentIds: absentIds,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Submit'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
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
              onPressed: () => Navigator.of(context).pop(),
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
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'saas_dialog',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 220),
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
