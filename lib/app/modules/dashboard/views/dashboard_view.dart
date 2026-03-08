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
              _heroPanel(controller, syncedTime),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  _kpiCard(
                    title: 'Students',
                    value: controller.totalStudents.toString(),
                    subtitle: '${controller.activeStudents} active learners',
                    icon: Icons.groups_2_rounded,
                    accent: const Color(0xFF2F5DFF),
                  ),
                  _kpiCard(
                    title: 'Batches',
                    value: controller.totalBatches.toString(),
                    subtitle:
                        '${controller.activeBatches} active • ${controller.completedBatches} completed',
                    icon: Icons.class_rounded,
                    accent: const Color(0xFF148F52),
                  ),
                  _kpiCard(
                    title: 'Teachers',
                    value: controller.totalTeachers.toString(),
                    subtitle:
                        '${controller.approvedTeachers} approved profiles',
                    icon: Icons.cast_for_education_rounded,
                    accent: const Color(0xFFD17A00),
                  ),
                  _kpiCard(
                    title: 'Users Pending',
                    value: controller.pendingUsers.toString(),
                    subtitle: '${controller.totalUsers} users in platform',
                    icon: Icons.manage_accounts_rounded,
                    accent: const Color(0xFF6D28D9),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
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
            ],
          );
        }),
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
                  title: 'Student Assignment',
                  value:
                      '${(controller.studentAssignmentRate * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _heroMini(
                  title: 'Batch Utilization',
                  value:
                      '${controller.totalBatchSeatLoad} enrolled across ${controller.totalBatches}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _heroMini(
                  title: 'Active Batch Share',
                  value:
                      '${(controller.activeBatchRate * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMini({required String title, required String value}) {
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
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return SizedBox(
      width: 250,
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
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opsCard(DashboardController controller) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Operational Pulse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time distribution across students, batches, and approvals.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _progressLine(
            label: 'Students Active',
            value: controller.activeStudents,
            total: controller.totalStudents,
            color: const Color(0xFF148F52),
          ),
          const SizedBox(height: 10),
          _progressLine(
            label: 'Students Completed',
            value: controller.completedStudents,
            total: controller.totalStudents,
            color: const Color(0xFF1E4ED8),
          ),
          const SizedBox(height: 10),
          _progressLine(
            label: 'Students Drop',
            value: controller.dropStudents,
            total: controller.totalStudents,
            color: const Color(0xFFB42318),
          ),
          const SizedBox(height: 10),
          _progressLine(
            label: 'Batches Active',
            value: controller.activeBatches,
            total: controller.totalBatches,
            color: const Color(0xFFD17A00),
          ),
          const SizedBox(height: 10),
          _progressLine(
            label: 'Pending User Approvals',
            value: controller.pendingUsers,
            total: controller.totalUsers,
            color: const Color(0xFF6D28D9),
          ),
        ],
      ),
    );
  }

  Widget _progressLine({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final double ratio = total == 0
        ? 0
        : (value / total).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value / $total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: ratio,
            backgroundColor: const Color(0xFFE7ECF5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _workspaceCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Workspace',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quickly jump to high-frequency modules.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _moduleTile('Batches', Icons.class_rounded, AppRoutes.batches),
              _moduleTile('Students', Icons.groups_rounded, AppRoutes.students),
              _moduleTile(
                'Teachers',
                Icons.cast_for_education_rounded,
                AppRoutes.teachers,
              ),
              _moduleTile(
                'Users',
                Icons.manage_accounts_rounded,
                AppRoutes.users,
              ),
              _moduleTile(
                'Attendance',
                Icons.fact_check_rounded,
                AppRoutes.attendance,
              ),
              _moduleTile(
                'Reports',
                Icons.bar_chart_rounded,
                AppRoutes.reports,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moduleTile(String title, IconData icon, String route) {
    return InkWell(
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
    );
  }
}
