import 'package:academia/app/modules/reports/controllers/reports_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportsController controller = Get.put(ReportsController());

    return AppShell(
      currentRoute: AppRoutes.reports,
      child: AppPageScaffold(
        title: 'Reports',
        subtitle: 'Premium attendance analytics for Admin and CAH.',
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

          final List<ReportSession> sessions = controller.filteredSessions;
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _heroBanner(controller),
                const SizedBox(height: AppSpacing.md),
                _filtersCard(controller),
                const SizedBox(height: AppSpacing.md),
                _kpiGrid(controller),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 560,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: _sessionsPanel(context, sessions),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: _batchPerformancePanel(controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _heroBanner(ReportsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F3AA9), Color(0xFF1E4ED8), Color(0xFF2F5DFF)],
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
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Attendance Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Analyze trends, compare performance, and export ready summaries.',
                  style: TextStyle(
                    color: Color(0xFFE6ECFF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Text(
              '${controller.totalSessions} sessions',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard(ReportsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow = constraints.maxWidth < 980;
          if (narrow) {
            return Column(
              children: <Widget>[
                _rangeField(controller, double.infinity),
                const SizedBox(height: 10),
                _batchField(controller, double.infinity),
                const SizedBox(height: 10),
                _statusField(controller, double.infinity),
              ],
            );
          }
          return Row(
            children: <Widget>[
              _rangeField(controller, 220),
              const SizedBox(width: 10),
              _batchField(controller, 320),
              const SizedBox(width: 10),
              _statusField(controller, 260),
              const Spacer(),
              Text(
                'Live reporting',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rangeField(ReportsController controller, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<int>(
        value: controller.rangeDays.value,
        decoration: const InputDecoration(
          labelText: 'Date Range',
          prefixIcon: Icon(Icons.date_range_rounded),
        ),
        items: const <DropdownMenuItem<int>>[
          DropdownMenuItem<int>(value: 7, child: Text('Last 7 days')),
          DropdownMenuItem<int>(value: 30, child: Text('Last 30 days')),
          DropdownMenuItem<int>(value: 90, child: Text('Last 90 days')),
          DropdownMenuItem<int>(value: 0, child: Text('All time')),
        ],
        onChanged: (int? value) => controller.updateRangeDays(value ?? 30),
      ),
    );
  }

  Widget _batchField(ReportsController controller, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: controller.selectedBatchId.value.isEmpty
            ? ''
            : controller.selectedBatchId.value,
        decoration: const InputDecoration(
          labelText: 'Batch',
          prefixIcon: Icon(Icons.class_rounded),
        ),
        items: <DropdownMenuItem<String>>[
          const DropdownMenuItem<String>(
            value: '',
            child: Text('All batches'),
          ),
          ...controller.batchOptions.map(
            (BatchOption item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.name),
            ),
          ),
        ],
        onChanged: (String? value) => controller.updateBatchId(value ?? ''),
      ),
    );
  }

  Widget _statusField(ReportsController controller, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: controller.selectedStatus.value.isEmpty
            ? ''
            : controller.selectedStatus.value,
        decoration: const InputDecoration(
          labelText: 'Status',
          prefixIcon: Icon(Icons.flag_rounded),
        ),
        items: const <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(value: '', child: Text('All status')),
          DropdownMenuItem<String>(value: 'open', child: Text('Open')),
          DropdownMenuItem<String>(
            value: 'submitted_by_teacher',
            child: Text('Submitted'),
          ),
          DropdownMenuItem<String>(
            value: 'completed',
            child: Text('Completed'),
          ),
        ],
        onChanged: (String? value) => controller.updateStatus(value ?? ''),
      ),
    );
  }

  Widget _kpiGrid(ReportsController controller) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth > 1300 ? 6 : 3;
        final List<_KpiData> items = <_KpiData>[
          _KpiData('Sessions', '${controller.totalSessions}', Icons.event_note_rounded),
          _KpiData(
            'Avg Attendance',
            '${controller.averageAttendance.toStringAsFixed(1)}%',
            Icons.insights_rounded,
          ),
          _KpiData('Present', '${controller.totalPresent}', Icons.check_circle_rounded),
          _KpiData('Leave', '${controller.totalLeave}', Icons.time_to_leave_rounded),
          _KpiData('Absent', '${controller.totalAbsent}', Icons.cancel_rounded),
          _KpiData('Top Batch', controller.topBatch, Icons.emoji_events_rounded),
        ];
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (BuildContext context, int index) {
            final _KpiData item = items[index];
            return _kpiTile(item);
          },
        );
      },
    );
  }

  Widget _kpiTile(_KpiData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF6F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF7)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x142F5DFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionsPanel(BuildContext context, List<ReportSession> sessions) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'Session Records',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${sessions.length} rows',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4EAF7)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 2, child: Text('Date')),
                Expanded(flex: 3, child: Text('Batch')),
                Expanded(child: Text('P')),
                Expanded(child: Text('L')),
                Expanded(child: Text('A')),
                Expanded(child: Text('Total')),
                Expanded(flex: 2, child: Text('Attendance %')),
                Expanded(flex: 2, child: Text('Status')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Text(
                      'No sessions match selected filters.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final ReportSession s = sessions[index];
                      final String d =
                          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFDFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5EAF5)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Text(
                                d,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                s.batchName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${s.presentCount}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${s.leaveCount}',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${s.absentCount}',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(child: Text('${s.totalStudents}')),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${s.attendancePercent.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: <Widget>[
                                  Expanded(child: _statusChip(s.status)),
                                  const SizedBox(width: 6),
                                  _exportIcon(context, s, d),
                                ],
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
    );
  }

  Widget _batchPerformancePanel(ReportsController controller) {
    final Map<String, List<double>> perf = <String, List<double>>{};
    for (final ReportSession s in controller.filteredSessions) {
      perf.putIfAbsent(s.batchName, () => <double>[]).add(s.attendancePercent);
    }
    final List<MapEntry<String, double>> rows = perf.entries.map((entry) {
      final double avg =
          entry.value.reduce((double a, double b) => a + b) / entry.value.length;
      return MapEntry<String, double>(entry.key, avg);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Batch Performance',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Average attendance percentage by batch',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final row = rows[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFDFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5EAF5)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                row.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${row.value.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
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
    );
  }

  Widget _exportIcon(BuildContext context, ReportSession s, String dateLabel) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final String summary =
            'Session: ${s.id}\n'
            'Date: $dateLabel\n'
            'Batch: ${s.batchName}\n'
            'Present: ${s.presentCount}\n'
            'Leave: ${s.leaveCount}\n'
            'Absent: ${s.absentCount}\n'
            'Total: ${s.totalStudents}\n'
            'Attendance: ${s.attendancePercent.toStringAsFixed(1)}%';
        await Clipboard.setData(ClipboardData(text: summary));
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Export Ready'),
                content: const Text('Session summary copied to clipboard.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0x141E4ED8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x334B71F5)),
        ),
        child: const Icon(
          Icons.download_rounded,
          size: 16,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final String normalized = status.trim().toLowerCase();
    final bool submitted = normalized.contains('submitted');
    final bool open = normalized == 'open';
    final Color bg = submitted
        ? const Color(0xFFDCFCE7)
        : open
        ? const Color(0xFFE8EEFF)
        : const Color(0xFFFEE2E2);
    final Color fg = submitted
        ? const Color(0xFF166534)
        : open
        ? const Color(0xFF1E4ED8)
        : const Color(0xFF991B1B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        normalized.isEmpty
            ? '--'
            : normalized[0].toUpperCase() + normalized.substring(1),
        textAlign: TextAlign.center,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
