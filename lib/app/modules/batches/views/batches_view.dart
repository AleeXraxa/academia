import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/modules/batches/controllers/batches_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BatchesView extends StatelessWidget {
  const BatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    final BatchesController controller = Get.put(BatchesController());

    return AppShell(
      currentRoute: AppRoutes.batches,
      child: AppPageScaffold(
        title: 'Batches',
        subtitle:
            'SaaS-style batch directory with assignment and schedule insights.',
        actions: <Widget>[
          FilledButton.icon(
            onPressed: () => _openAddBatchDialog(context, controller),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Batch'),
          ),
        ],
        child: Column(
          children: <Widget>[
            Obx(() {
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  _metricCard(
                    title: 'Total Batches',
                    value: controller.totalBatches.toString(),
                    icon: Icons.class_rounded,
                    accent: const Color(0xFF2F5DFF),
                    trend: 'In directory',
                  ),
                  _metricCard(
                    title: 'Active Batches',
                    value: controller.activeBatches.toString(),
                    icon: Icons.play_circle_outline_rounded,
                    accent: const Color(0xFF148F52),
                    trend: 'Current running',
                  ),
                  _metricCard(
                    title: 'Teacher Assigned',
                    value: controller.batchesWithTeacher.toString(),
                    icon: Icons.cast_for_education_rounded,
                    accent: const Color(0xFFD17A00),
                    trend: 'Linked to teacher',
                  ),
                  _metricCard(
                    title: 'Students Total',
                    value: controller.totalStudents.toString(),
                    icon: Icons.groups_2_rounded,
                    accent: const Color(0xFF6D28D9),
                    trend: 'Across batches',
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

                        if (controller.batches.isEmpty) {
                          return const Center(child: Text('No batches found.'));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: controller.batches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final BatchModel batch = controller.batches[index];
                            return _tableRow(
                              context,
                              controller,
                              batch,
                              controller.teacherLabel(batch),
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
          const Icon(Icons.class_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Batches Directory',
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
              'Matches teachers-page UI language',
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

  Widget _tableRow(
    BuildContext context,
    BatchesController controller,
    BatchModel batch,
    String teacherLabel,
  ) {
    final String scheduleLabel = _scheduleLabel(batch);
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
                    Icons.class_rounded,
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
                        batch.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        scheduleLabel,
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
              _valueOrDash(scheduleLabel),
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
              _valueOrDash(teacherLabel),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
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
                  '${batch.studentsCount ?? 0}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _actionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  bg: const Color(0xFFEFF3FA),
                  fg: const Color(0xFF334155),
                  onTap: () => _openViewDialog(context, batch, teacherLabel),
                ),
                _actionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  bg: const Color(0xFFE9EEFF),
                  fg: AppColors.accent,
                  onTap: () =>
                      _openEditDialog(context, controller, batch, teacherLabel),
                ),
                _actionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  bg: const Color(0xFFFDEBEC),
                  fg: const Color(0xFFB42318),
                  onTap: () => _openDeleteDialog(
                    context,
                    controller,
                    batch.name,
                    batch.id,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scheduleLabel(BatchModel batch) {
    final List<String> days = (batch.days ?? <String>[])
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
    final String timing = (batch.timing ?? '').trim();

    if (days.isEmpty) {
      final String baseSchedule = _valueOrDash(batch.schedule);
      if (timing.isEmpty) {
        return baseSchedule;
      }
      if (baseSchedule == '--') {
        return timing;
      }
      return '$baseSchedule | $timing';
    }

    final bool isRegular =
        days.length == 6 &&
        days[0] == 'Monday' &&
        days[1] == 'Tuesday' &&
        days[2] == 'Wednesday' &&
        days[3] == 'Thursday' &&
        days[4] == 'Friday' &&
        days[5] == 'Saturday';
    final String dayCode =
        isRegular
        ? 'REGULAR'
        :
        days.length == 3 &&
            days[0] == 'Monday' &&
            days[1] == 'Wednesday' &&
            days[2] == 'Friday'
        ? 'MWF'
        : days.length == 3 &&
              days[0] == 'Tuesday' &&
              days[1] == 'Thursday' &&
              days[2] == 'Saturday'
        ? 'TTS'
        : days.map((String day) => day.substring(0, 3).toUpperCase()).join('-');

    if (timing.isEmpty) {
      return dayCode;
    }
    return '$dayCode | $timing';
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bg.withValues(alpha: 0.88)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

  Future<void> _openViewDialog(
    BuildContext context,
    BatchModel batch,
    String teacherLabel,
  ) async {
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.visibility_rounded,
            title: 'Batch Details',
            subtitle: 'Read-only batch information and schedule summary.',
            accent: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: <Widget>[
                _detailTile('Batch Name', batch.name),
                _detailTile('Semester', _valueOrDash(batch.semester)),
                _detailTile('Curriculam', _valueOrDash(batch.curriculam)),
                _detailTile('Schedule', _scheduleLabel(batch)),
                _detailTile('Teacher', _valueOrDash(teacherLabel)),
                _detailTile('Students', '${batch.studentsCount ?? 0}'),
                _detailTile('Batch ID', batch.id),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    BatchesController controller,
    BatchModel batch,
    String teacherLabel,
  ) async {
    final TextEditingController nameController = TextEditingController(
      text: batch.name,
    );
    final TextEditingController otherCurriculamController =
        TextEditingController();
    final TextEditingController otherTimingController = TextEditingController();

    String? selectedSemester = (batch.semester ?? '').trim().isEmpty
        ? null
        : batch.semester;
    String? selectedCurriculam = (batch.curriculam ?? '').trim().isEmpty
        ? null
        : batch.curriculam;
    String? selectedTeacherId = (batch.teacherId ?? '').trim().isEmpty
        ? null
        : batch.teacherId;
    String? selectedTeacherName = (batch.teacherName ?? '').trim().isEmpty
        ? (teacherLabel == '--' ? null : teacherLabel)
        : batch.teacherName;
    String? selectedDaysPattern;
    String? selectedTiming = (batch.timing ?? '').trim().isEmpty
        ? null
        : batch.timing;
    String selectedStatus =
        ((batch.status ?? 'active').trim().toLowerCase() == 'completed')
        ? 'Completed'
        : 'Active';

    final List<String> batchDays = (batch.days ?? <String>[])
        .map((String value) => value.trim())
        .toList();
    if (batchDays.length == 3 &&
        batchDays[0] == 'Monday' &&
        batchDays[1] == 'Wednesday' &&
        batchDays[2] == 'Friday') {
      selectedDaysPattern = 'MWF';
    } else if (batchDays.length == 3 &&
        batchDays[0] == 'Tuesday' &&
        batchDays[1] == 'Thursday' &&
        batchDays[2] == 'Saturday') {
      selectedDaysPattern = 'TTS';
    } else if (batchDays.length == 6 &&
        batchDays[0] == 'Monday' &&
        batchDays[1] == 'Tuesday' &&
        batchDays[2] == 'Wednesday' &&
        batchDays[3] == 'Thursday' &&
        batchDays[4] == 'Friday' &&
        batchDays[5] == 'Saturday') {
      selectedDaysPattern = 'Regular (Daily)';
    }

    const List<String> semesterOptions = <String>[
      'Semester 1',
      'Semester 2',
      'Semester 3',
      'Semester 4',
      'Semester 5',
      'Semester 6',
    ];
    const List<String> curriculamOptions = <String>[
      'OV-7062',
      'OV-7144',
      'Other',
    ];
    const List<String> dayPatternOptions = <String>[
      'MWF',
      'TTS',
      'Regular (Daily)',
    ];
    const List<String> timingOptions = <String>['3-5', '5-7', '7-9', 'Other'];
    const List<String> statusOptions = <String>['Active', 'Completed'];

    final bool curriculamKnown =
        selectedCurriculam == 'OV-7062' || selectedCurriculam == 'OV-7144';
    if (!curriculamKnown && (selectedCurriculam ?? '').isNotEmpty) {
      otherCurriculamController.text = selectedCurriculam!;
      selectedCurriculam = 'Other';
    }

    final bool timingKnown =
        selectedTiming == '3-5' ||
        selectedTiming == '5-7' ||
        selectedTiming == '7-9';
    if (!timingKnown && (selectedTiming ?? '').isNotEmpty) {
      otherTimingController.text = selectedTiming!;
      selectedTiming = 'Other';
    }

    await _showSaasDialog(
      context: context,
      child: StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _dialogHeader(
                      icon: Icons.edit_note_rounded,
                      title: 'Update Batch',
                      subtitle:
                          'Modify batch profile, schedule, and assignment.',
                      accent: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Name',
                        prefixIcon: Icon(Icons.class_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      items: semesterOptions
                          .map(
                            (String semester) => DropdownMenuItem<String>(
                              value: semester,
                              child: Text(semester),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedSemester = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedCurriculam,
                      decoration: const InputDecoration(
                        labelText: 'Curriculam',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: curriculamOptions
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedCurriculam = value;
                          if (value != 'Other') {
                            otherCurriculamController.clear();
                          }
                        });
                      },
                    ),
                    if (selectedCurriculam == 'Other') ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: otherCurriculamController,
                        decoration: const InputDecoration(
                          labelText: 'Other Curriculam',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedDaysPattern,
                      decoration: const InputDecoration(
                        labelText: 'Days Pattern',
                        prefixIcon: Icon(Icons.event_repeat_rounded),
                      ),
                      items: dayPatternOptions
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedDaysPattern = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedTiming,
                      decoration: const InputDecoration(
                        labelText: 'Timing',
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                      items: timingOptions
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedTiming = value;
                          if (value != 'Other') {
                            otherTimingController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: statusOptions
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    if (selectedTiming == 'Other') ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: otherTimingController,
                        decoration: const InputDecoration(
                          labelText: 'Other Timing',
                          prefixIcon: Icon(Icons.edit_calendar_rounded),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Obx(() {
                      final teachers = controller.approvedTeachers;
                      return DropdownButtonFormField<String>(
                        value: selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Teacher',
                          prefixIcon: Icon(Icons.cast_for_education_rounded),
                        ),
                        items: teachers
                            .map(
                              (teacher) => DropdownMenuItem<String>(
                                value: teacher.id,
                                child: Text(teacher.name),
                              ),
                            )
                            .toList(),
                        onChanged: teachers.isEmpty
                            ? null
                            : (String? value) {
                                setState(() {
                                  selectedTeacherId = value;
                                  String? matchedName;
                                  for (final teacher in teachers) {
                                    if (teacher.id == value) {
                                      matchedName = teacher.name;
                                      break;
                                    }
                                  }
                                  selectedTeacherName = matchedName;
                                });
                              },
                      );
                    }),
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
                            final String name = nameController.text.trim();
                            final String semester = (selectedSemester ?? '')
                                .trim();
                            String curriculam = (selectedCurriculam ?? '')
                                .trim();
                            if (curriculam == 'Other') {
                              curriculam = otherCurriculamController.text
                                  .trim();
                            }
                            final String pattern = (selectedDaysPattern ?? '')
                                .trim();
                            String timing = (selectedTiming ?? '').trim();
                            if (timing == 'Other') {
                              timing = otherTimingController.text.trim();
                            }
                            final List<String> days = pattern == 'MWF'
                                ? <String>['Monday', 'Wednesday', 'Friday']
                                : pattern == 'TTS'
                                ? <String>['Tuesday', 'Thursday', 'Saturday']
                                : pattern == 'Regular (Daily)'
                                ? <String>[
                                    'Monday',
                                    'Tuesday',
                                    'Wednesday',
                                    'Thursday',
                                    'Friday',
                                    'Saturday',
                                  ]
                                : <String>[];

                            if (name.isEmpty ||
                                semester.isEmpty ||
                                curriculam.isEmpty ||
                                days.isEmpty ||
                                timing.isEmpty ||
                                selectedTeacherId == null ||
                                (selectedTeacherName ?? '').isEmpty) {
                              return;
                            }

                            await controller.updateBatch(
                              id: batch.id,
                              name: name,
                              semester: semester,
                              curriculam: curriculam,
                              days: days,
                              timing: timing,
                              status: selectedStatus,
                              teacherId: selectedTeacherId!,
                              teacherName: selectedTeacherName!,
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
      ),
    );

    nameController.dispose();
    otherCurriculamController.dispose();
    otherTimingController.dispose();
  }

  Future<void> _openDeleteDialog(
    BuildContext context,
    BatchesController controller,
    String batchName,
    String id,
  ) async {
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.delete_outline_rounded,
            title: 'Delete Batch',
            subtitle: 'This action is permanent and cannot be undone.',
            accent: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF5D0D0)),
            ),
            child: Text(
              'Delete $batchName from batches directory?',
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
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
                  await controller.deleteBatch(id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete Batch'),
              ),
            ],
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

  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddBatchDialog(
    BuildContext context,
    BatchesController controller,
  ) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController otherCurriculamController =
        TextEditingController();
    DateTime? selectedStartDate;
    String? selectedTeacherId;
    String? selectedTeacherName;
    String? selectedSemester;
    String? selectedCurriculam;
    String? selectedDaysPattern;
    String? selectedTiming;
    const List<String> semesterOptions = <String>[
      'Semester 1',
      'Semester 2',
      'Semester 3',
      'Semester 4',
      'Semester 5',
      'Semester 6',
    ];
    const List<String> curriculamOptions = <String>[
      'OV-7062',
      'OV-7144',
      'Other',
    ];
    const List<String> dayPatternOptions = <String>[
      'MWF',
      'TTS',
      'Regular (Daily)',
    ];
    const List<String> timingOptions = <String>['3-5', '5-7', '7-9', 'Other'];
    final TextEditingController otherTimingController = TextEditingController();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'add_batch',
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Add Batch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create a new batch and assign it to an approved teacher.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatefulBuilder(
                      builder:
                          (
                            BuildContext context,
                            void Function(void Function()) setState,
                          ) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Batch Name',
                                    prefixIcon: Icon(Icons.class_rounded),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DropdownButtonFormField<String>(
                                  value: selectedSemester,
                                  decoration: const InputDecoration(
                                    labelText: 'Semester',
                                    prefixIcon: Icon(Icons.layers_outlined),
                                  ),
                                  items: semesterOptions
                                      .map(
                                        (String semester) =>
                                            DropdownMenuItem<String>(
                                              value: semester,
                                              child: Text(semester),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedSemester = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DropdownButtonFormField<String>(
                                  value: selectedCurriculam,
                                  decoration: const InputDecoration(
                                    labelText: 'Curriculam',
                                    prefixIcon: Icon(Icons.menu_book_outlined),
                                  ),
                                  items: curriculamOptions
                                      .map(
                                        (String value) =>
                                            DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedCurriculam = value;
                                      if (value != 'Other') {
                                        otherCurriculamController.clear();
                                      }
                                    });
                                  },
                                ),
                                if (selectedCurriculam == 'Other') ...<Widget>[
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: otherCurriculamController,
                                    decoration: const InputDecoration(
                                      labelText: 'Other Curriculam',
                                      prefixIcon: Icon(Icons.edit_note_rounded),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                const Text(
                                  'Days Pattern',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                DropdownButtonFormField<String>(
                                  value: selectedDaysPattern,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Pattern',
                                    prefixIcon: Icon(
                                      Icons.event_repeat_rounded,
                                    ),
                                  ),
                                  items: dayPatternOptions
                                      .map(
                                        (String pattern) =>
                                            DropdownMenuItem<String>(
                                              value: pattern,
                                              child: Text(pattern),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedDaysPattern = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                DropdownButtonFormField<String>(
                                  value: selectedTiming,
                                  decoration: const InputDecoration(
                                    labelText: 'Timing',
                                    prefixIcon: Icon(Icons.access_time_rounded),
                                  ),
                                  items: timingOptions
                                      .map(
                                        (String timing) =>
                                            DropdownMenuItem<String>(
                                              value: timing,
                                              child: Text(timing),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedTiming = value;
                                      if (value != 'Other') {
                                        otherTimingController.clear();
                                      }
                                    });
                                  },
                                ),
                                if (selectedTiming == 'Other') ...<Widget>[
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: otherTimingController,
                                    decoration: const InputDecoration(
                                      labelText: 'Other Timing',
                                      prefixIcon: Icon(
                                        Icons.edit_calendar_rounded,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final DateTime now = DateTime.now();
                                    final DateTime? picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: selectedStartDate ?? now,
                                          firstDate: DateTime(now.year - 2),
                                          lastDate: DateTime(now.year + 10),
                                        );
                                    if (picked != null) {
                                      setState(() {
                                        selectedStartDate = picked;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  label: Text(
                                    selectedStartDate == null
                                        ? 'Start Date'
                                        : '${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Obx(() {
                                  final teachers = controller.approvedTeachers;
                                  return DropdownButtonFormField<String>(
                                    value: selectedTeacherId,
                                    decoration: const InputDecoration(
                                      labelText: 'Teacher',
                                      prefixIcon: Icon(
                                        Icons.cast_for_education_rounded,
                                      ),
                                    ),
                                    items: teachers
                                        .map(
                                          (teacher) => DropdownMenuItem<String>(
                                            value: teacher.id,
                                            child: Text(teacher.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: teachers.isEmpty
                                        ? null
                                        : (String? value) {
                                            setState(() {
                                              selectedTeacherId = value;
                                              String? matchedName;
                                              for (final teacher in teachers) {
                                                if (teacher.id == value) {
                                                  matchedName = teacher.name;
                                                  break;
                                                }
                                              }
                                              selectedTeacherName = matchedName;
                                            });
                                          },
                                  );
                                }),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: <Widget>[
                                    OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    const Spacer(),
                                    FilledButton.icon(
                                      onPressed: () async {
                                        final String name = nameController.text
                                            .trim();
                                        final String semester =
                                            (selectedSemester ?? '').trim();
                                        String curriculam =
                                            (selectedCurriculam ?? '').trim();
                                        if (curriculam == 'Other') {
                                          curriculam = otherCurriculamController
                                              .text
                                              .trim();
                                        }
                                        final String pattern =
                                            (selectedDaysPattern ?? '').trim();
                                        String timing = (selectedTiming ?? '')
                                            .trim();
                                        if (timing == 'Other') {
                                          timing = otherTimingController.text
                                              .trim();
                                        }
                                        final List<String> days =
                                            pattern == 'MWF'
                                            ? <String>[
                                                'Monday',
                                                'Wednesday',
                                                'Friday',
                                              ]
                                            : pattern == 'TTS'
                                            ? <String>[
                                                'Tuesday',
                                                'Thursday',
                                                'Saturday',
                                              ]
                                            : pattern == 'Regular (Daily)'
                                            ? <String>[
                                                'Monday',
                                                'Tuesday',
                                                'Wednesday',
                                                'Thursday',
                                                'Friday',
                                                'Saturday',
                                              ]
                                            : <String>[];

                                        if (name.isEmpty ||
                                            semester.isEmpty ||
                                            curriculam.isEmpty ||
                                            days.isEmpty ||
                                            timing.isEmpty ||
                                            selectedStartDate == null ||
                                            selectedTeacherId == null ||
                                            (selectedTeacherName ?? '')
                                                .isEmpty) {
                                          return;
                                        }

                                        await controller.createBatch(
                                          name: name,
                                          semester: semester,
                                          curriculam: curriculam,
                                          days: days,
                                          timing: timing,
                                          startDate: selectedStartDate!,
                                          teacherId: selectedTeacherId!,
                                          teacherName: selectedTeacherName!,
                                        );
                                        Navigator.of(context).pop();
                                      },
                                      icon: const Icon(Icons.check_rounded),
                                      label: const Text('Create Batch'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                    ),
                  ],
                ),
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

    nameController.dispose();
    otherCurriculamController.dispose();
    otherTimingController.dispose();
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
            child: Text('Batch', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Schedule',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Teacher',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Students',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
