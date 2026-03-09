import 'dart:convert';
import 'dart:io';

import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/modules/students/controllers/students_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentsView extends StatelessWidget {
  const StudentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final StudentsController controller = Get.put(StudentsController());

    return AppShell(
      currentRoute: AppRoutes.students,
      child: AppPageScaffold(
        title: 'Students',
        subtitle: 'SaaS-style student directory with lifecycle management.',
        actions: <Widget>[
          OutlinedButton.icon(
            onPressed: () => _downloadImportTemplate(context, controller),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Template'),
          ),
          OutlinedButton.icon(
            onPressed: () => _openBulkImportDialog(context, controller),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Bulk Import'),
          ),
          FilledButton.icon(
            onPressed: () => _openCreateDialog(context, controller),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add Student'),
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
                    title: 'Total Students',
                    value: controller.totalStudents.toString(),
                    icon: Icons.groups_2_rounded,
                    accent: const Color(0xFF2F5DFF),
                    trend: 'Directory size',
                  ),
                  _metricCard(
                    title: 'Active',
                    value: controller.activeStudents.toString(),
                    icon: Icons.play_circle_outline_rounded,
                    accent: const Color(0xFF148F52),
                    trend: 'Currently active',
                  ),
                  _metricCard(
                    title: 'Completed',
                    value: controller.completedStudents.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    accent: const Color(0xFFD17A00),
                    trend: 'Finished batches',
                  ),
                  _metricCard(
                    title: 'Batch Assigned',
                    value: controller.assignedStudents.toString(),
                    icon: Icons.class_rounded,
                    accent: const Color(0xFF6D28D9),
                    trend: 'Linked students',
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

                        if (controller.students.isEmpty) {
                          return const Center(
                            child: Text('No students found.'),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: controller.students.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final StudentModel student =
                                controller.students[index];
                            return _tableRow(context, controller, student);
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
          const Icon(Icons.school_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Students Directory',
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
              'Aligned with batches UI language',
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
    StudentsController controller,
    StudentModel student,
  ) {
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
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        student.email,
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
              _valueOrDash(student.studentId),
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
              _valueOrDash(student.contactNo),
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
              _valueOrDash(student.batchName),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _actionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  bg: const Color(0xFFEFF3FA),
                  fg: const Color(0xFF334155),
                  onTap: () => _openViewDialog(context, student),
                ),
                _actionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  bg: const Color(0xFFE9EEFF),
                  fg: AppColors.accent,
                  onTap: () => _openEditDialog(context, controller, student),
                ),
                _actionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  bg: const Color(0xFFFDEBEC),
                  fg: const Color(0xFFB42318),
                  onTap: () => _openDeleteDialog(context, controller, student),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final String normalized = status.trim().toLowerCase();
    if (normalized == 'active') {
      return _pill(
        label: 'Active',
        background: const Color(0xFFDEF7E8),
        foreground: const Color(0xFF15803D),
      );
    }
    if (normalized == 'completed') {
      return _pill(
        label: 'Completed',
        background: const Color(0xFFE8EEFF),
        foreground: const Color(0xFF1E4ED8),
      );
    }
    if (normalized == 'drop') {
      return _pill(
        label: 'Drop',
        background: const Color(0xFFFDE7E7),
        foreground: const Color(0xFFB42318),
      );
    }
    return _pill(
      label: _capitalize(normalized),
      background: const Color(0xFFF3F4F6),
      foreground: const Color(0xFF4B5563),
    );
  }

  Widget _pill({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: foreground.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
          border: Border.all(color: fg.withValues(alpha: 0.2)),
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

  Future<void> _openCreateDialog(
    BuildContext context,
    StudentsController controller,
  ) async {
    await _openStudentFormDialog(
      controller: controller,
      context: context,
      title: 'Add Student',
      actionLabel: 'Create',
      onSubmit:
          ({
            required String name,
            required String studentId,
            required String email,
            required String contactNo,
            required String parentContact,
            required String gender,
            required String status,
            required String batchId,
            required String batchName,
          }) async {
            await controller.createStudent(
              name: name,
              studentId: studentId,
              email: email,
              contactNo: contactNo,
              parentContact: parentContact,
              gender: gender,
              status: status,
              batchId: batchId,
              batchName: batchName,
            );
          },
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    StudentsController controller,
    StudentModel student,
  ) async {
    await _openStudentFormDialog(
      controller: controller,
      context: context,
      title: 'Update Student',
      actionLabel: 'Save',
      initialName: student.name,
      initialStudentId: student.studentId ?? '',
      initialEmail: student.email,
      initialContactNo: student.contactNo,
      initialParentContact: student.parentContact,
      initialGender: student.gender.trim().isEmpty ? 'Male' : student.gender,
      initialStatus: controller.statusLabel(student),
      initialBatchId: (student.batchId ?? '').trim(),
      onSubmit:
          ({
            required String name,
            required String studentId,
            required String email,
            required String contactNo,
            required String parentContact,
            required String gender,
            required String status,
            required String batchId,
            required String batchName,
          }) async {
            await controller.updateStudent(
              id: student.id,
              name: name,
              studentId: studentId,
              email: email,
              contactNo: contactNo,
              parentContact: parentContact,
              gender: gender,
              status: status,
              batchId: batchId,
              batchName: batchName,
            );
          },
    );
  }

  Future<void> _openStudentFormDialog({
    required StudentsController controller,
    required BuildContext context,
    required String title,
    required String actionLabel,
    required Future<void> Function({
      required String name,
      required String studentId,
      required String email,
      required String contactNo,
      required String parentContact,
      required String gender,
      required String status,
      required String batchId,
      required String batchName,
    })
    onSubmit,
    String initialName = '',
    String initialStudentId = '',
    String initialEmail = '',
    String initialContactNo = '',
    String initialParentContact = '',
    String initialGender = 'Male',
    String initialStatus = 'Active',
    String initialBatchId = '',
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: initialName,
    );
    final TextEditingController studentIdController = TextEditingController(
      text: initialStudentId,
    );
    final TextEditingController emailController = TextEditingController(
      text: initialEmail,
    );
    final TextEditingController contactNoController = TextEditingController(
      text: initialContactNo,
    );
    final TextEditingController parentContactController = TextEditingController(
      text: initialParentContact,
    );
    String selectedGender = initialGender;
    String selectedStatus = initialStatus;
    String? selectedBatchId = initialBatchId.trim().isEmpty
        ? null
        : initialBatchId;

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
                    icon: Icons.edit_note_rounded,
                    title: title,
                    subtitle: 'Manage student identity and lifecycle status.',
                    accent: AppColors.accent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'StudentID (Optional)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: contactNoController,
                    decoration: const InputDecoration(
                      labelText: 'Contact No (Optional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: parentContactController,
                    decoration: const InputDecoration(
                      labelText: 'Parent Contact (Optional)',
                      prefixIcon: Icon(Icons.call_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedGender = value;
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
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(value: 'Drop', child: Text('Drop')),
                    ],
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(() {
                    final batches = controller.batches;
                    final bool hasSelectedBatch =
                        selectedBatchId != null &&
                        batches.any((batch) => batch.id == selectedBatchId);
                    final String? dropdownValue = hasSelectedBatch
                        ? selectedBatchId
                        : null;
                    return DropdownButtonFormField<String>(
                      value: dropdownValue,
                      decoration: const InputDecoration(
                        labelText: 'Batch',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      items: batches
                          .map(
                            (batch) => DropdownMenuItem<String>(
                              value: batch.id,
                              child: Text(batch.name),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedBatchId = value;
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
                          final String studentId = studentIdController.text
                              .trim();
                          final String email = emailController.text.trim();
                          final String contactNo = contactNoController.text
                              .trim();
                          final String parentContact = parentContactController
                              .text
                              .trim();
                          final String gender = selectedGender.trim();
                          final String status = selectedStatus.trim();
                          final String batchId = (selectedBatchId ?? '').trim();
                          String batchName = '';
                          for (final batch in controller.batches) {
                            if (batch.id == batchId) {
                              batchName = batch.name;
                              break;
                            }
                          }

                          if (name.isEmpty ||
                              gender.isEmpty ||
                              status.isEmpty ||
                              batchId.isEmpty ||
                              batchName.isEmpty) {
                            return;
                          }

                          await onSubmit(
                            name: name,
                            studentId: studentId,
                            email: email,
                            contactNo: contactNo,
                            parentContact: parentContact,
                            gender: gender,
                            status: status,
                            batchId: batchId,
                            batchName: batchName,
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: Text(actionLabel),
                      ),
                    ],
                  ),
                ],
              );
            },
      ),
    );

    nameController.dispose();
    studentIdController.dispose();
    emailController.dispose();
    contactNoController.dispose();
    parentContactController.dispose();
  }

  Future<void> _openViewDialog(
    BuildContext context,
    StudentModel student,
  ) async {
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.visibility_rounded,
            title: 'Student Details',
            subtitle: 'Read-only identity and status summary.',
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
                _detailTile('Full Name', student.name),
                _detailTile('StudentID', _valueOrDash(student.studentId)),
                _detailTile('Email', student.email),
                _detailTile('Contact No', _valueOrDash(student.contactNo)),
                _detailTile(
                  'Parent Contact',
                  _valueOrDash(student.parentContact),
                ),
                _detailTile('Gender', _valueOrDash(student.gender)),
                _detailTile('Status', _capitalize(student.status)),
                _detailTile('Batch', _valueOrDash(student.batchName)),
                _detailTile('Student ID', student.id),
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

  Future<void> _openDeleteDialog(
    BuildContext context,
    StudentsController controller,
    StudentModel student,
  ) async {
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.delete_outline_rounded,
            title: 'Delete Student',
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
              'Delete ${student.name} (${student.email}) from students directory?',
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
                  await controller.deleteStudent(student.id);
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete Student'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImportTemplate(
    BuildContext context,
    StudentsController controller,
  ) async {
    try {
      final String? directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Folder for Student CSV Template',
      );
      if (directory == null || directory.trim().isEmpty) {
        return;
      }
      final String path =
          '$directory${Platform.pathSeparator}students_import_template.csv';
      final File file = File(path);
      await file.writeAsString(controller.bulkImportTemplateCsv);
      if (context.mounted) {
        await _showSaasDialog(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _dialogHeader(
                icon: Icons.check_circle_outline_rounded,
                title: 'Template Downloaded',
                subtitle: 'CSV template saved successfully at:\n$path',
                accent: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      await _showSaasDialog(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _dialogHeader(
              icon: Icons.error_outline_rounded,
              title: 'Template Download Failed',
              subtitle: '$e',
              accent: AppColors.error,
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
  }

  Future<void> _openBulkImportDialog(
    BuildContext context,
    StudentsController controller,
  ) async {
    BulkStudentImportPreview? preview;
    String selectedFileName = '';
    String feedbackText = '';
    bool isParsing = false;
    bool isImporting = false;

    await _showSaasDialog(
      context: context,
      child: StatefulBuilder(
        builder:
            (BuildContext dialogContext, void Function(void Function()) setState) {
              Future<void> pickAndPreview() async {
                setState(() {
                  isParsing = true;
                  feedbackText = '';
                });
                try {
                  final FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const <String>['csv'],
                        withData: true,
                      );
                  if (result == null || result.files.isEmpty) {
                    setState(() {
                      isParsing = false;
                    });
                    return;
                  }

                  final PlatformFile file = result.files.first;
                  selectedFileName = file.name;
                  String content = '';
                  if (file.bytes != null) {
                    content = utf8.decode(file.bytes!);
                  } else if ((file.path ?? '').trim().isNotEmpty) {
                    content = await File(file.path!).readAsString();
                  }
                  if (content.trim().isEmpty) {
                    throw Exception('Selected file is empty.');
                  }

                  final BulkStudentImportPreview parsed = controller
                      .previewBulkImport(content);
                  setState(() {
                    preview = parsed;
                    isParsing = false;
                    feedbackText =
                        'Parsed ${parsed.totalRows} rows. Valid: ${parsed.validRows}, Invalid: ${parsed.invalidRows}.';
                  });
                } catch (e) {
                  setState(() {
                    isParsing = false;
                    preview = null;
                    feedbackText = '$e';
                  });
                }
              }

              Future<void> runImport() async {
                final BulkStudentImportPreview? currentPreview = preview;
                if (currentPreview == null || currentPreview.validRows == 0) {
                  return;
                }
                setState(() {
                  isImporting = true;
                  feedbackText = '';
                });
                try {
                  final BulkStudentImportResult result = await controller
                      .importBulkStudents(
                        preview: currentPreview,
                        skipInvalid: true,
                      );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  await _showSaasDialog(
                    context: context,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _dialogHeader(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Bulk Import Completed',
                          subtitle:
                              'Imported: ${result.imported} | Skipped: ${result.skipped} | Failed chunks: ${result.failed.length}',
                          accent: AppColors.success,
                        ),
                        if (result.failed.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF5D0D0)),
                            ),
                            child: Text(
                              result.failed.join('\n'),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) {
                    return;
                  }
                  setState(() {
                    isImporting = false;
                    feedbackText = '$e';
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _dialogHeader(
                      icon: Icons.upload_file_rounded,
                      title: 'Bulk Import Students',
                      subtitle:
                          'Upload CSV, review validation, and import valid rows.',
                      accent: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: isParsing || isImporting ? null : pickAndPreview,
                          icon: isParsing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.attach_file_rounded),
                          label: const Text('Choose CSV'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: isImporting || isParsing
                              ? null
                              : () => _downloadImportTemplate(context, controller),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Template'),
                        ),
                      ],
                    ),
                    if (selectedFileName.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'File: $selectedFileName',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (feedbackText.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          feedbackText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    if (preview != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _pill(
                            label: 'Total: ${preview!.totalRows}',
                            background: const Color(0xFFE8EEFF),
                            foreground: AppColors.accent,
                          ),
                          _pill(
                            label: 'Valid: ${preview!.validRows}',
                            background: const Color(0xFFDEF7E8),
                            foreground: const Color(0xFF15803D),
                          ),
                          _pill(
                            label: 'Invalid: ${preview!.invalidRows}',
                            background: const Color(0xFFFDE7E7),
                            foreground: const Color(0xFFB42318),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: preview!.rows.length > 20
                              ? 20
                              : preview!.rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (BuildContext context, int index) {
                            final BulkStudentImportRow row = preview!.rows[index];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: row.isValid
                                    ? const Color(0xFFFAFCFF)
                                    : const Color(0xFFFFF7F7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: row.isValid
                                      ? const Color(0xFFE5EAF5)
                                      : const Color(0xFFF3D1D1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'Row ${row.rowNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _pill(
                                        label: row.isValid ? 'Valid' : 'Invalid',
                                        background: row.isValid
                                            ? const Color(0xFFDEF7E8)
                                            : const Color(0xFFFDE7E7),
                                        foreground: row.isValid
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB42318),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${row.fullName}  |  ${row.batchName.isEmpty ? '--' : row.batchName}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (!row.isValid) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      row.errors.join(' '),
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (preview!.rows.length > 20)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Showing first 20 rows only.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: isImporting
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed:
                              (preview == null ||
                                  preview!.validRows == 0 ||
                                  isImporting ||
                                  isParsing)
                              ? null
                              : runImport,
                          icon: isImporting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_rounded),
                          label: Text(
                            isImporting
                                ? 'Importing...'
                                : 'Import Valid Rows',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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
              'Student',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'StudentID',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Contact No',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Batch', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 4,
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
