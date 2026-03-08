import 'package:academia/app/modules/attendance/controllers/attendance_controller.dart';
import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          child: IndexedStack(
            index: tabIndex,
            children: <Widget>[
              _teacherDashboardBody(controller),
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

  Widget _teacherDashboardBody(AttendanceController controller) {
    final int totalSessions = controller.todaySessions.length;
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
    return _teacherTabBackground(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _topSummaryCard(controller, isMobile: true),
          const SizedBox(height: AppSpacing.md),
          _teacherSectionCard(
            title: 'Today Snapshot',
            subtitle: 'Quick attendance counters for current day.',
            child: Column(
              children: <Widget>[
                _dashboardStatCard(
                  'Today Sessions',
                  '$totalSessions',
                  Icons.event,
                ),
                const SizedBox(height: 10),
                _dashboardStatCard(
                  'Present Students',
                  '$totalPresent',
                  Icons.check_circle_rounded,
                ),
                const SizedBox(height: 10),
                _dashboardStatCard(
                  'Leave Students',
                  '$totalLeave',
                  Icons.time_to_leave_rounded,
                ),
                const SizedBox(height: 10),
                _dashboardStatCard(
                  'Absent Students',
                  '$totalAbsent',
                  Icons.cancel_rounded,
                ),
              ],
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

  Widget _teacherHistoryBody(
    BuildContext context,
    AttendanceController controller,
  ) {
    final List<AdminAttendanceSession> submitted =
        controller.filteredHistorySessions;
    final List<BatchModel> assignedBatches = controller.teacherAssignedBatches;
    return _teacherTabBackground(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _teacherSectionCard(
            title: 'Filters',
            subtitle: 'Narrow down by date range and batch.',
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
                      ? null
                      : controller.historyBatchId.value,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Batch',
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
                  onChanged: (String? value) {
                    controller.updateHistoryBatchId(value ?? '');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _teacherSectionCard(
            title: 'Insights',
            subtitle: 'Performance summary for selected filters.',
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _historyKpi(
                        label: 'Sessions',
                        value: '${controller.historyTotalSessions}',
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
                        value: '${controller.historyTotalPresent}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Leave',
                        value: '${controller.historyTotalLeave}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _historyKpi(
                        label: 'Absent',
                        value: '${controller.historyTotalAbsent}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _historyKpi(
                  label: 'Best Batch',
                  value: controller.historyBestBatch,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _teacherSectionCard(
            title: 'Timeline',
            subtitle: 'Session-by-session attendance history.',
            child: Column(
              children: <Widget>[
                if (submitted.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Text(
                        'No sessions found for selected filters.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...submitted.map((AdminAttendanceSession item) {
                    return Padding(
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
                              ],
                            ),
                            const SizedBox(height: 10),
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
                                label: const Text('View'),
                              ),
                            ),
                          ],
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
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
              fontSize: 15,
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
                      return const Center(child: CircularProgressIndicator());
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

                            return ListView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              children: <Widget>[
                                _teacherSectionCard(
                                  title: 'Profile',
                                  subtitle: 'Manage your professional details.',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Container(
                                            width: 62,
                                            height: 62,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: <Color>[
                                                  Color(0xFF1E4ED8),
                                                  Color(0xFF2F5DFF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.school_rounded,
                                              color: Colors.white,
                                              size: 30,
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
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  email.isEmpty ? '--' : email,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _profileInfoTile(
                                        icon: Icons.workspace_premium_rounded,
                                        label: 'Expertise',
                                        value: expertise.isEmpty
                                            ? '--'
                                            : expertise,
                                      ),
                                      const SizedBox(height: 10),
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
                                      const SizedBox(height: 16),
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
    final TextEditingController nameController = TextEditingController(
      text: initialName,
    );
    final TextEditingController expertiseController = TextEditingController(
      text: initialExpertise,
    );
    final TextEditingController educationController = TextEditingController(
      text: initialEducation,
    );
    final TextEditingController experienceController = TextEditingController(
      text: initialExperience,
    );
    final String normalizedEmail = email.trim();
    final TextEditingController emailController = TextEditingController(
      text: normalizedEmail,
    );
    bool isSaving = false;
    String? nameError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, void Function(void Function()) setState) {
            final EdgeInsets keyboardInsets = MediaQuery.of(
              modalContext,
            ).viewInsets;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 160),
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
                                : () => Navigator.of(modalContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: isSaving
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
                    isMobile
                        ? 'Generate Session'
                        : 'Generate Session for Today',
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
    final List<BatchModel> scheduledBatches =
        controller.generationCandidateBatches;
    final int selectedCount = controller.selectedGenerationBatchIds.length;
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
          Text(
            controller.isUsingScheduleFallback
                ? 'No day-pattern batches for today, showing active batches for manual generation.'
                : 'Select scheduled batches for today and enter present count for each selected batch.',
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
              child: const Text(
                'No batches are scheduled for today.',
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
                  final bool isSelected = controller.selectedGenerationBatchIds
                      .contains(batch.id);
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
                                  labelText: 'Present Students',
                                  hintText: '0 - $total',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    labelText: 'Present',
                                    hintText: '0 - $total',
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
                                  label: const Text('View Attendance'),
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
                              : (!isTeacher && item.teacherSubmitted)
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonalIcon(
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

    final String schedule = batch.schedule.trim().toUpperCase();
    if (schedule == 'MWF' || schedule == 'TTS') {
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
