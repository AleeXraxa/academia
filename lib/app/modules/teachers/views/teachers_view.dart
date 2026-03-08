import 'package:academia/app/data/models/user_model.dart';
import 'package:academia/app/modules/teachers/controllers/teachers_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeachersView extends StatelessWidget {
  const TeachersView({super.key});

  @override
  Widget build(BuildContext context) {
    final TeachersController controller = Get.put(TeachersController());

    return AppShell(
      currentRoute: AppRoutes.teachers,
      child: AppPageScaffold(
        title: 'Teachers',
        subtitle: 'SaaS-style teacher directory with profile depth insights.',
        child: Column(
          children: <Widget>[
            Obx(() {
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  _metricCard(
                    title: 'Approved Teachers',
                    value: controller.approvedTeachers.toString(),
                    icon: Icons.verified_rounded,
                    accent: const Color(0xFF148F52),
                    trend: 'Visible in table',
                  ),
                  _metricCard(
                    title: 'With Expertise',
                    value: controller.withExpertise.toString(),
                    icon: Icons.psychology_alt_rounded,
                    accent: const Color(0xFFD17A00),
                    trend: 'Profile quality',
                  ),
                  _metricCard(
                    title: 'With Education',
                    value: controller.withEducation.toString(),
                    icon: Icons.school_rounded,
                    accent: const Color(0xFF6D28D9),
                    trend: 'Profile quality',
                  ),
                  _metricCard(
                    title: 'Assigned Batches',
                    value: controller.totalAssignedBatches.toString(),
                    icon: Icons.class_rounded,
                    accent: const Color(0xFF1E4ED8),
                    trend: 'Across teachers',
                  ),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    _tableTopBar(),
                    const _TableHeader(),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (controller.errorText.value.isNotEmpty) {
                          return Center(
                            child: Text(
                              controller.errorText.value,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          );
                        }

                        if (controller.teachers.isEmpty) {
                          return const Center(
                            child: Text('No approved teachers found.'),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: controller.teachers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final UserModel teacher =
                                controller.teachers[index];
                            return _tableRow(
                              teacher,
                              controller.batchCountForTeacher(teacher.id),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.cast_for_education_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Teachers Directory',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Only approved teachers are shown',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required String trend,
  }) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Colors.white, accent.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tableRow(UserModel teacher, int batchCount) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        teacher.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        teacher.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _valueOrDash(teacher.expertise),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _valueOrDash(teacher.education),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _valueOrDash(teacher.experience),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD6E1FF)),
                ),
                child: Text(
                  '$batchCount',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _valueOrDash(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return '--';
    }
    return normalized;
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

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
            child: Text(
              'Teacher',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Expertise',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Education',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Experience',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Batches',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
