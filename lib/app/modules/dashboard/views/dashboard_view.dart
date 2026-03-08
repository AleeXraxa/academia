import 'package:academia/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    return AppShell(
      currentRoute: AppRoutes.dashboard,
      child: AppPageScaffold(
        title: 'Dashboard',
        subtitle:
            'Premium control center with live academic operations and status insights.',
        actions: <Widget>[
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.reports),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export Insights'),
          ),
          FilledButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.attendance),
            icon: const Icon(Icons.fact_check_rounded),
            label: const Text('Mark Attendance'),
          ),
        ],
        child: Obx(() {
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

          final DateTime syncedAt = controller.lastSyncedAt.value;
          final String syncedTime =
              '${syncedAt.hour.toString().padLeft(2, '0')}:${syncedAt.minute.toString().padLeft(2, '0')}';

          return ListView(
            children: <Widget>[
              _entrance(delayMs: 0, child: _heroPanel(controller, syncedTime)),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                delayMs: 50,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double maxWidth = constraints.maxWidth;
                    final int columns = maxWidth >= 1100
                        ? 3
                        : maxWidth >= 760
                        ? 2
                        : 1;
                    final double gap = AppSpacing.md;
                    final double cardWidth =
                        (maxWidth - (gap * (columns - 1))) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: <Widget>[
                        _kpiCard(
                          width: cardWidth,
                          title: 'Total Students',
                          value: controller.totalStudents.toString(),
                          subtitle: '',
                          icon: Icons.groups_2_rounded,
                          accent: const Color(0xFF2F5DFF),
                        ),
                        _kpiCard(
                          width: cardWidth,
                          title: 'Attendance Today',
                          value:
                              '${controller.todayAttendanceRate.toStringAsFixed(0)}%',
                          subtitle: '',
                          icon: Icons.fact_check_rounded,
                          accent: const Color(0xFF0F766E),
                        ),
                        _kpiCard(
                          width: cardWidth,
                          title: 'Active Batches',
                          value: controller.activeBatches.toString(),
                          subtitle: '',
                          icon: Icons.class_rounded,
                          accent: const Color(0xFF148F52),
                        ),
                        _kpiCard(
                          width: cardWidth,
                          title: 'Pending Approvals',
                          value: controller.pendingUsers.toString(),
                          subtitle: '',
                          icon: Icons.pending_actions_rounded,
                          accent: const Color(0xFF6D28D9),
                        ),
                        _kpiCard(
                          width: cardWidth,
                          title: 'Low Attendance',
                          value: controller.atRiskStudents.toString(),
                          subtitle: '',
                          icon: Icons.warning_amber_rounded,
                          accent: const Color(0xFFB45309),
                        ),
                        _kpiCard(
                          width: cardWidth,
                          title: 'Sessions Today',
                          value: controller.sessionsToday.toString(),
                          subtitle: '',
                          icon: Icons.event_note_rounded,
                          accent: const Color(0xFF1E40AF),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(delayMs: 90, child: _attendanceTrendCard(controller)),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                delayMs: 130,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool singleColumn = constraints.maxWidth < 1080;
                    if (singleColumn) {
                      return Column(
                        children: <Widget>[
                          _opsCard(controller),
                          const SizedBox(height: AppSpacing.md),
                          _workspaceCard(),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(flex: 6, child: _opsCard(controller)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(flex: 5, child: _workspaceCard()),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _attendanceTrendCard(DashboardController controller) {
    final List<WeekdayAttendancePoint> points =
        controller.weeklyAttendanceTrend;
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Weekly Attendance Trend',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mon to Fri attendance performance for current week.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 980
                  ? 5
                  : constraints.maxWidth >= 760
                  ? 3
                  : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: points.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final WeekdayAttendancePoint point = points[index];
                  return _HoverLift(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Get.toNamed(AppRoutes.reports),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              point.label,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${point.percent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: (point.percent / 100).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFFE7ECF5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1E4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _heroPanel(DashboardController controller, String syncedTime) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF0F3AA9),
            Color(0xFF1E4ED8),
            Color(0xFF2F5DFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x331D4ED8),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Operational Intelligence',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Live sync at $syncedTime',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Academia is running smoothly with centralized role, batch, and learner monitoring.',
            style: TextStyle(
              color: Color(0xFFE4ECFF),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _heroMini(
                  title: 'Today Attendance Rate',
                  value:
                      'Today Attendance: ${controller.todayAttendanceRate.toStringAsFixed(0)}%',
                  detail:
                      'Present ${controller.todayPresentCount} / ${controller.todayTotalStudentsCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _heroMini(
                  title: 'Sessions Today',
                  value: 'Sessions Today: ${controller.sessionsToday}',
                  detail:
                      'Completed: ${controller.sessionsCompleted}  |  Pending: ${controller.sessionsPending}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _heroMini(
                  title: 'At Risk Students',
                  value: 'Low Attendance: ${controller.atRiskStudents}',
                  detail: '(<70%)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMini({
    required String title,
    required String value,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(color: Color(0xFFE4ECFF), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFFD7E4FF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required double width,
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return _HoverLift(
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 17),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _opsCard(DashboardController controller) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Operational Pulse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time attendance and academic execution insights.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _opsInsightCard(
            title: 'Overall Attendance',
            primary: '${controller.overallAttendanceRate.toStringAsFixed(0)}%',
            secondary: '',
            accent: const Color(0xFF0F766E),
            icon: Icons.insights_rounded,
            onTap: () => Get.toNamed(AppRoutes.reports),
          ),
          const SizedBox(height: 10),
          _opsInsightCard(
            title: "Today's Sessions",
            primary:
                'Generated: ${controller.sessionsToday}   Completed: ${controller.sessionsCompleted}',
            secondary: 'Pending: ${controller.sessionsPending}',
            accent: const Color(0xFF1E4ED8),
            icon: Icons.event_available_rounded,
            onTap: () => Get.toNamed(AppRoutes.attendance),
          ),
          const SizedBox(height: 10),
          _opsInsightCard(
            title: 'Teacher Coverage',
            primary: 'Batches Assigned: ${controller.assignedBatches}',
            secondary: 'vs Unassigned Batches: ${controller.unassignedBatches}',
            accent: const Color(0xFFB45309),
            icon: Icons.cast_for_education_rounded,
            onTap: () => Get.toNamed(AppRoutes.teachers),
          ),
          const SizedBox(height: 10),
          _opsInsightCard(
            title: 'Batch Utilization',
            primary:
                '${controller.studentsPerBatch.toStringAsFixed(1)} students',
            secondary: 'per batch',
            accent: const Color(0xFF6D28D9),
            icon: Icons.pie_chart_rounded,
            onTap: () => Get.toNamed(AppRoutes.batches),
          ),
        ],
      ),
    );
  }

  Widget _opsInsightCard({
    required String title,
    required String primary,
    required String secondary,
    required Color accent,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return _HoverLift(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 17),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primary,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (secondary.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workspaceCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'High-frequency actions for day-to-day operations.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _moduleTile(
                '+ Generate Session',
                Icons.add_task_rounded,
                AppRoutes.attendance,
              ),
              _moduleTile(
                '+ Add Student',
                Icons.person_add_alt_1_rounded,
                AppRoutes.students,
              ),
              _moduleTile(
                '+ Add Batch',
                Icons.playlist_add_rounded,
                AppRoutes.batches,
              ),
              _moduleTile(
                '+ Add Teacher',
                Icons.school_rounded,
                AppRoutes.teachers,
              ),
              _moduleTile(
                '+ Review Approvals',
                Icons.fact_check_rounded,
                AppRoutes.users,
              ),
              _moduleTile(
                '+ View Reports',
                Icons.bar_chart_rounded,
                AppRoutes.reports,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _entrance({required Widget child, int delayMs = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delayMs),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _moduleTile(String title, IconData icon, String route) {
    return _HoverLift(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(route),
        child: Container(
          width: 162,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: const Color(0xFFF8FAFF),
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverLift extends StatefulWidget {
  const _HoverLift({required this.child});

  final Widget child;

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _hovered ? -4.0 : 0.0),
        child: AnimatedScale(
          scale: _hovered ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
