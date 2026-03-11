import 'package:academia/app/modules/reports/controllers/reports_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ReportType { student, batch, teacher, day }

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  ReportType _selectedReport = ReportType.student;
  String _selectedStudentId = '';
  String _selectedBatchId = '';
  String _selectedTeacherId = '';
  String _selectedEntityLabel = '';
  int _selectedRangeDays = 30;
  String _inlineError = '';
  late DateTime _selectedMonth;
  late final List<DateTime> _monthOptions;

  final GlobalKey _entitySearchKey = GlobalKey();
  OverlayEntry? _entityDropdownOverlay;
  bool _isGeneratingReport = false;
  List<ReportSession> _reportSessions = <ReportSession>[];
  String _reportTitle = '';
  String _reportSubtitle = '';

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _monthOptions = List<DateTime>.generate(12, (int index) {
      final DateTime date = DateTime(now.year, now.month - index);
      return DateTime(date.year, date.month);
    });
  }

  @override
  void dispose() {
    _removeEntityDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReportsController controller = Get.put(ReportsController());

    return AppShell(
      currentRoute: AppRoutes.reports,
      child: AppPageScaffold(
        contextHint: 'Administration / Analytics / Reports',
        title: 'Reports',
        subtitle: 'Premium attendance intelligence with drill-down insights.',
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

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _heroBanner(controller),
                const SizedBox(height: AppSpacing.md),
                _kpiRow(controller),
                const SizedBox(height: AppSpacing.md),
                _reportBuilderCard(controller),
                const SizedBox(height: AppSpacing.md),
                _trendSnapshotSection(controller),
                const SizedBox(height: AppSpacing.md),
                _comparativeInsightsSection(controller),
                const SizedBox(height: AppSpacing.md),
                _exceptionsPanel(controller),
                const SizedBox(height: AppSpacing.md),
                _reportHealthPanel(controller),
                const SizedBox(height: AppSpacing.md),
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
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Compare performance, spot risks, and export summaries with confidence.',
                  style: TextStyle(
                    color: Color(0xFFE6ECFF),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _heroStat('${controller.totalSessions}', 'Sessions'),
              const SizedBox(height: 8),
              _heroStat(
                '${controller.averageAttendance.toStringAsFixed(1)}%',
                'Avg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE6ECFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiRow(ReportsController controller) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth > 1200
            ? 4
            : (constraints.maxWidth > 800 ? 3 : 2);
        final List<_KpiData> items = <_KpiData>[
          _KpiData(
            'Total Sessions',
            '${controller.totalSessions}',
            Icons.event_note_rounded,
            AppColors.accent,
          ),
          _KpiData(
            'Avg Attendance',
            '${controller.averageAttendance.toStringAsFixed(1)}%',
            Icons.insights_rounded,
            AppColors.success,
          ),
          _KpiData(
            'Present',
            '${controller.totalPresent}',
            Icons.check_circle_rounded,
            AppColors.success,
          ),
          _KpiData(
            'Absent',
            '${controller.totalAbsent}',
            Icons.cancel_rounded,
            AppColors.error,
          ),
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
            return _kpiCard(item);
          },
        );
      },
    );
  }

  Widget _kpiCard(_KpiData data) {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: data.accent.withValues(alpha: 0.2)),
            ),
            child: Icon(data.icon, color: data.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  data.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportBuilderCard(ReportsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A1E293B),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Report Builder',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a report type and configure the filters below.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool narrow = constraints.maxWidth < 900;
              final List<Widget> fields = <Widget>[
                _reportTypeField(),
                _entitySearchField(controller),
                _secondarySelector(controller),
              ];
              if (narrow) {
                return Column(
                  children: <Widget>[
                    fields[0],
                    const SizedBox(height: 10),
                    fields[1],
                    const SizedBox(height: 10),
                    fields[2],
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: fields[0]),
                  const SizedBox(width: 10),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 10),
                  Expanded(child: fields[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isGeneratingReport
                  ? null
                  : () => _generateReport(controller),
              icon: _isGeneratingReport
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics_rounded),
              label: Text(
                _isGeneratingReport ? 'Generating...' : 'Generate Report',
              ),
            ),
          ),
          if (_inlineError.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _inlineErrorCard(_inlineError),
          ],
          if (_reportSessions.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _reportResultsCard(controller),
          ],
        ],
      ),
    );
  }

  Widget _reportTypeField() {
    return _dropdownField<ReportType>(
      value: _selectedReport,
      label: 'Report Type',
      icon: Icons.auto_graph_rounded,
      items: <DropdownMenuItem<ReportType>>[
        DropdownMenuItem(
          value: ReportType.student,
          child: _dropdownItem(
            icon: Icons.person_rounded,
            label: 'Student-wise Attendance Report',
          ),
        ),
        DropdownMenuItem(
          value: ReportType.batch,
          child: _dropdownItem(
            icon: Icons.class_rounded,
            label: 'Batch-wise Attendance Report',
          ),
        ),
        DropdownMenuItem(
          value: ReportType.teacher,
          child: _dropdownItem(
            icon: Icons.school_rounded,
            label: 'Teacher-wise Attendance Report',
          ),
        ),
        DropdownMenuItem(
          value: ReportType.day,
          child: _dropdownItem(
            icon: Icons.calendar_month_rounded,
            label: 'Day-wise Attendance Report',
          ),
        ),
      ],
      onChanged: (ReportType? value) {
        if (value == null) {
          return;
        }
        setState(() {
          _selectedReport = value;
          _selectedEntityLabel = '';
          _selectedStudentId = '';
          _selectedBatchId = '';
          _selectedTeacherId = '';
          _inlineError = '';
        });
      },
    );
  }

  Widget _entitySearchField(ReportsController controller) {
    final bool disabled = _selectedReport == ReportType.day;
    final String label = _selectedReport == ReportType.teacher
        ? 'Teacher'
        : (_selectedReport == ReportType.batch ? 'Batch' : 'Student');
    final IconData icon = _selectedReport == ReportType.teacher
        ? Icons.school_rounded
        : (_selectedReport == ReportType.batch
              ? Icons.class_rounded
              : Icons.person_rounded);

    final List<_SelectOption<String>> options = _buildSearchOptions(controller);
    final String displayLabel = _selectedEntityLabel.isEmpty
        ? 'Select $label'
        : _selectedEntityLabel;

    return InkWell(
      key: _entitySearchKey,
      borderRadius: BorderRadius.circular(12),
      onTap: disabled
          ? null
          : () =>
                _showEntityDropdown(label: label, icon: icon, options: options),
      child: InputDecorator(
        decoration: _dropdownDecoration(label: label, icon: icon).copyWith(
          hintText: disabled ? 'Not required for day-wise' : 'Select $label',
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: disabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondarySelector(ReportsController controller) {
    if (_selectedReport == ReportType.day) {
      return _monthSummary();
    }
    return _dropdownField<int>(
      value: _selectedRangeDays,
      label: 'Date Range',
      icon: Icons.date_range_rounded,
      items: const <DropdownMenuItem<int>>[
        DropdownMenuItem<int>(value: 1, child: Text('Today')),
        DropdownMenuItem<int>(value: 7, child: Text('Last 7 days')),
        DropdownMenuItem<int>(value: 30, child: Text('Last 30 days')),
        DropdownMenuItem<int>(value: 90, child: Text('Last 90 days')),
        DropdownMenuItem<int>(value: 0, child: Text('All time')),
      ],
      onChanged: (int? value) {
        setState(() {
          _selectedRangeDays = value ?? 30;
        });
      },
    );
  }

  Widget _monthSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF7)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.event_note_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selected month: ${_formatMonth(_selectedMonth)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _dropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      decoration: _dropdownDecoration(label: label, icon: icon),
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      dropdownColor: AppColors.surface,
      menuMaxHeight: 320,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE4EAF7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE4EAF7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.8)),
      ),
    );
  }

  Widget _dropdownItem({required IconData icon, required String label}) {
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  List<_SelectOption<String>> _buildSearchOptions(
    ReportsController controller,
  ) {
    switch (_selectedReport) {
      case ReportType.batch:
        return controller.batchOptions
            .map(
              (BatchOption batch) =>
                  _SelectOption<String>(value: batch.id, label: batch.name),
            )
            .toList();
      case ReportType.teacher:
        final List<MapEntry<String, String>> teachers =
            controller.teacherNameById.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value));
        return teachers
            .map(
              (MapEntry<String, String> entry) =>
                  _SelectOption<String>(value: entry.key, label: entry.value),
            )
            .toList();
      case ReportType.day:
        return <_SelectOption<String>>[];
      case ReportType.student:
      default:
        final List<StudentMeta> options = controller.students.toList()
          ..sort(
            (StudentMeta a, StudentMeta b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        return options
            .map(
              (StudentMeta student) => _SelectOption<String>(
                value: student.id,
                label: '${student.name} (${student.studentId})',
              ),
            )
            .toList();
    }
  }

  void _applySearchSelection(_SelectOption<String> option) {
    setState(() {
      if (_selectedReport == ReportType.student) {
        _selectedStudentId = option.value;
      } else if (_selectedReport == ReportType.batch) {
        _selectedBatchId = option.value;
      } else if (_selectedReport == ReportType.teacher) {
        _selectedTeacherId = option.value;
      }
    });
  }

  Future<void> _generateReport(ReportsController controller) async {
    final String? error = _validateReportInputs();
    if (error != null) {
      setState(() {
        _inlineError = error;
      });
      return;
    }

    setState(() {
      _isGeneratingReport = true;
      _inlineError = '';
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final DateTime now = DateTime.now();
    final DateTime start = _selectedRangeDays <= 0
        ? DateTime(2000, 1, 1)
        : DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: _selectedRangeDays - 1));

    final DateTime monthStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final DateTime monthEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
    );

    final Map<String, String> batchTeacher = <String, String>{};
    for (final BatchOption batch in controller.batchOptions) {
      batchTeacher[batch.id] = batch.teacherId;
    }

    List<ReportSession> filtered = controller.sessions.where((ReportSession s) {
      if (_selectedReport == ReportType.day) {
        return !s.date.isBefore(monthStart) && s.date.isBefore(monthEnd);
      }
      return !s.date.isBefore(start);
    }).toList();

    if (_selectedReport == ReportType.student) {
      filtered = filtered.where((ReportSession s) {
        return s.presentStudentIds.contains(_selectedStudentId) ||
            s.leaveStudentIds.contains(_selectedStudentId) ||
            s.absentStudentIds.contains(_selectedStudentId);
      }).toList();
    } else if (_selectedReport == ReportType.batch) {
      filtered = filtered
          .where((ReportSession s) => s.batchId == _selectedBatchId)
          .toList();
    } else if (_selectedReport == ReportType.teacher) {
      filtered = filtered
          .where(
            (ReportSession s) => batchTeacher[s.batchId] == _selectedTeacherId,
          )
          .toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _reportSessions = filtered;
      _reportTitle = _reportTitleForSelection(controller);
      _reportSubtitle = _reportSubtitleForSelection();
      _isGeneratingReport = false;
    });
  }

  String? _validateReportInputs() {
    if (_selectedReport == ReportType.student && _selectedStudentId.isEmpty) {
      return 'Select a student to generate the report.';
    }
    if (_selectedReport == ReportType.batch && _selectedBatchId.isEmpty) {
      return 'Select a batch to generate the report.';
    }
    if (_selectedReport == ReportType.teacher && _selectedTeacherId.isEmpty) {
      return 'Select a teacher to generate the report.';
    }
    return null;
  }

  String _reportTitleForSelection(ReportsController controller) {
    switch (_selectedReport) {
      case ReportType.student:
        return 'Student Report: $_selectedEntityLabel';
      case ReportType.batch:
        return 'Batch Report: $_selectedEntityLabel';
      case ReportType.teacher:
        return 'Teacher Report: $_selectedEntityLabel';
      case ReportType.day:
        return 'Day-wise Report: ${_formatMonth(_selectedMonth)}';
    }
  }

  String _reportSubtitleForSelection() {
    if (_selectedReport == ReportType.day) {
      return 'Attendance summary for selected month';
    }
    if (_selectedRangeDays == 0) {
      return 'All time attendance summary';
    }
    if (_selectedRangeDays == 1) {
      return 'Attendance summary for today';
    }
    return 'Last $_selectedRangeDays days attendance summary';
  }

  Widget _reportResultsCard(ReportsController controller) {
    final int totalPresent = _reportSessions.fold<int>(
      0,
      (int sum, ReportSession s) => sum + s.presentCount,
    );
    final int totalLeave = _reportSessions.fold<int>(
      0,
      (int sum, ReportSession s) => sum + s.leaveCount,
    );
    final int totalAbsent = _reportSessions.fold<int>(
      0,
      (int sum, ReportSession s) => sum + s.absentCount,
    );
    final int totalStudents = _reportSessions.fold<int>(
      0,
      (int sum, ReportSession s) => sum + s.totalStudents,
    );
    final double attendance = totalStudents == 0
        ? 0
        : ((totalPresent + totalLeave) / totalStudents) * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _reportTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _reportSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _kpiChip('Sessions', '${_reportSessions.length}'),
              _kpiChip('Present', '$totalPresent'),
              _kpiChip('Leave', '$totalLeave'),
              _kpiChip('Absent', '$totalAbsent'),
              _kpiChip('Attendance', '${attendance.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 12),
          if (_reportSessions.isEmpty)
            const Text(
              'No sessions match this report.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reportSessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final ReportSession s = _reportSessions[index];
                final String d =
                    '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFDFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EAF5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _kpiChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4EAF7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendSnapshotSection(ReportsController controller) {
    final DateTime now = DateTime.now();
    final List<_DayTrend> days = List<_DayTrend>.generate(7, (int index) {
      final DateTime date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final List<ReportSession> sessions = controller.sessions.where((s) {
        return s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day;
      }).toList();
      final int totalStudents = sessions.fold<int>(
        0,
        (int sum, ReportSession s) => sum + s.totalStudents,
      );
      final int attended = sessions.fold<int>(
        0,
        (int sum, ReportSession s) => sum + s.presentCount + s.leaveCount,
      );
      final double percent = totalStudents == 0
          ? 0
          : (attended / totalStudents) * 100;
      return _DayTrend(date: date, percent: percent);
    });

    return _sectionCard(
      title: 'Weekly Attendance Trend',
      subtitle: 'Last 7 days attendance percentages.',
      child: Row(
        children: days.map((d) => Expanded(child: _trendChip(d))).toList(),
      ),
    );
  }

  Widget _comparativeInsightsSection(ReportsController controller) {
    final List<BatchAttendanceRow> batches = controller.batchRows.toList(
      growable: false,
    )..sort((a, b) => b.attendancePercent.compareTo(a.attendancePercent));
    final List<BatchAttendanceRow> topBatches = batches.take(3).toList();
    final List<BatchAttendanceRow> worstBatches = batches.reversed
        .take(3)
        .toList()
        .reversed
        .toList();

    final List<TeacherAttendanceRow> teachers = controller.teacherRows.toList(
      growable: false,
    )..sort((a, b) => b.submissionRate.compareTo(a.submissionRate));
    final List<TeacherAttendanceRow> topTeachers = teachers.take(3).toList();

    return _sectionCard(
      title: 'Comparative Insights',
      subtitle: 'Best vs worst batches and top teacher compliance.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool twoColumn = constraints.maxWidth > 900;
          final List<Widget> cards = <Widget>[
            _miniListCard(
              title: 'Top Batches',
              rows: topBatches
                  .map(
                    (b) => _miniRow(
                      leading: b.batchName,
                      trailing: '${b.attendancePercent.toStringAsFixed(1)}%',
                      caption: '${b.sessions} sessions',
                    ),
                  )
                  .toList(),
            ),
            _miniListCard(
              title: 'Lowest Batches',
              rows: worstBatches
                  .map(
                    (b) => _miniRow(
                      leading: b.batchName,
                      trailing: '${b.attendancePercent.toStringAsFixed(1)}%',
                      caption: '${b.sessions} sessions',
                    ),
                  )
                  .toList(),
            ),
            _miniListCard(
              title: 'Top Teacher Compliance',
              rows: topTeachers
                  .map(
                    (t) => _miniRow(
                      leading: t.teacherName,
                      trailing: '${t.submissionRate.toStringAsFixed(1)}%',
                      caption: '${t.submitted}/${t.sessions} submitted',
                    ),
                  )
                  .toList(),
            ),
          ];
          if (twoColumn) {
            return Row(
              children: <Widget>[
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[1]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[2]),
              ],
            );
          }
          return Column(
            children: <Widget>[
              ...cards.expand(
                (Widget card) => <Widget>[
                  card,
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ]..removeLast(),
          );
        },
      ),
    );
  }

  Widget _exceptionsPanel(ReportsController controller) {
    final List<ReportSession> highAbsence = controller.highAbsenceSessions;
    final List<ReportSession> notConducted = controller.notConductedSessions;
    return _sectionCard(
      title: 'Exceptions',
      subtitle: 'High absence or not-conducted sessions.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool twoColumn = constraints.maxWidth > 900;
          final Widget highAbsenceCard = _miniListCard(
            title: 'High Absence Sessions',
            rows: highAbsence.take(4).map((s) {
              final String date =
                  '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
              final double pct = s.totalStudents == 0
                  ? 0
                  : (s.absentCount / s.totalStudents) * 100;
              return _miniRow(
                leading: s.batchName,
                trailing: '${pct.toStringAsFixed(1)}%',
                caption: date,
              );
            }).toList(),
          );
          final Widget notConductedCard = _miniListCard(
            title: 'Not Conducted',
            rows: notConducted.take(4).map((s) {
              final String date =
                  '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
              return _miniRow(
                leading: s.batchName,
                trailing: date,
                caption: s.notConductedReason.isEmpty
                    ? 'No reason'
                    : s.notConductedReason,
              );
            }).toList(),
          );
          if (twoColumn) {
            return Row(
              children: <Widget>[
                Expanded(child: highAbsenceCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: notConductedCard),
              ],
            );
          }
          return Column(
            children: <Widget>[
              highAbsenceCard,
              const SizedBox(height: AppSpacing.md),
              notConductedCard,
            ],
          );
        },
      ),
    );
  }

  Widget _reportHealthPanel(ReportsController controller) {
    final int missingSubmissions = controller.sessions
        .where((s) => !s.teacherSubmitted)
        .length;
    DateTime? latest;
    for (final ReportSession s in controller.sessions) {
      if (latest == null || s.date.isAfter(latest)) {
        latest = s.date;
      }
    }
    final String lastSync = latest == null
        ? 'No data'
        : '${latest.year}-${latest.month.toString().padLeft(2, '0')}-${latest.day.toString().padLeft(2, '0')}';

    return _sectionCard(
      title: 'Report Health',
      subtitle: 'Data freshness and submission coverage.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _kpiChip('Last sync', lastSync),
          _kpiChip('Missing submissions', '$missingSubmissions'),
          _kpiChip('Total sessions', '${controller.sessions.length}'),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _miniRow({
    required String leading,
    required String trailing,
    required String caption,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5EAF5)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    leading,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniListCard({required String title, required List<Widget> rows}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text(
              'No data',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            Column(children: rows),
        ],
      ),
    );
  }

  Widget _trendChip(_DayTrend trend) {
    final String label = _weekdayLabel(trend.date.weekday);
    final String value = '${trend.percent.toStringAsFixed(0)}%';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF7)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const List<String> labels = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  Widget _inlineErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEntityDropdown({
    required String label,
    required IconData icon,
    required List<_SelectOption<String>> options,
  }) {
    _removeEntityDropdown();
    final BuildContext? targetContext = _entitySearchKey.currentContext;
    final RenderBox? box = targetContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    String query = '';
    _entityDropdownOverlay = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeEntityDropdown,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: position.dx,
              top: position.dy + size.height + 8,
              width: size.width,
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder:
                      (
                        BuildContext context,
                        void Function(void Function()) setState,
                      ) {
                        final List<_SelectOption<String>> filtered =
                            query.isEmpty
                            ? options
                            : options
                                  .where(
                                    (_SelectOption<String> option) => option
                                        .label
                                        .toLowerCase()
                                        .contains(query.toLowerCase()),
                                  )
                                  .toList();
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 320),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4EAF7)),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x161E293B),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TextField(
                                onChanged: (String value) {
                                  setState(() {
                                    query = value.trim();
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Search $label',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: filtered.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No matches found.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filtered.length.clamp(0, 12),
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 12,
                                              color: Color(0xFFE6ECF7),
                                            ),
                                        itemBuilder: (BuildContext context, int index) {
                                          final _SelectOption<String> option =
                                              filtered[index];
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _selectedEntityLabel =
                                                    option.label;
                                                _applySearchSelection(option);
                                              });
                                              _removeEntityDropdown();
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              child: Row(
                                                children: <Widget>[
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEFF4FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      icon,
                                                      size: 16,
                                                      color: AppColors.accent,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      option.label,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_entityDropdownOverlay!);
  }

  void _removeEntityDropdown() {
    _entityDropdownOverlay?.remove();
    _entityDropdownOverlay = null;
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.accent);

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

class _SelectOption<T> {
  const _SelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _DayTrend {
  const _DayTrend({required this.date, required this.percent});

  final DateTime date;
  final double percent;
}
