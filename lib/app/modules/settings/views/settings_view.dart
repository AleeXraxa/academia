import 'package:academia/app/modules/settings/controllers/settings_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_dropdown_form_field.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsController _controller;
  late final TextEditingController _instituteController;
  late final TextEditingController _supportController;
  bool _hasChanges = false;
  String? _instituteError;
  String? _supportError;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SettingsController());
    _instituteController = TextEditingController();
    _supportController = TextEditingController();
  }

  @override
  void dispose() {
    _instituteController.dispose();
    _supportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.settings,
      child: AppPageScaffold(
        contextHint: 'Administration / Configuration / Settings',
        title: 'Settings',
        subtitle: 'Configure platform defaults, attendance policy and system controls.',
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.errorText.value.isNotEmpty) {
            return Center(
              child: Text(
                _controller.errorText.value,
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          if (_instituteController.text.trim().isEmpty) {
            _instituteController.text = _controller.instituteName.value;
          }
          if (_supportController.text.trim().isEmpty) {
            _supportController.text = _controller.supportEmail.value;
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: LayoutBuilder(
            key: ValueKey<String>(
              '${_controller.lockSubmittedSessions.value}-${_controller.requireCorrectionNote.value}-${_controller.includeLeaveInAttendance.value}-${_controller.defaultHistoryDays.value}',
            ),
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 1200;
              if (compact) {
                return ListView(
                  children: <Widget>[
                    _heroCard(),
                    const SizedBox(height: AppSpacing.md),
                    _organizationCard(),
                    const SizedBox(height: AppSpacing.md),
                    _policyCard(),
                    const SizedBox(height: AppSpacing.md),
                    _saveRow(context),
                    const SizedBox(height: AppSpacing.md),
                    _snapshotCard(),
                    const SizedBox(height: AppSpacing.md),
                    _appCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: ListView(
                      children: <Widget>[
                        _heroCard(),
                        const SizedBox(height: AppSpacing.md),
                        _organizationCard(),
                        const SizedBox(height: AppSpacing.md),
                        _policyCard(),
                        const SizedBox(height: AppSpacing.md),
                        _saveRow(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ListView(
                      children: <Widget>[
                        _snapshotCard(),
                        const SizedBox(height: AppSpacing.md),
                        _appCard(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          );
        }),
      ),
    );
  }

  Widget _heroCard() {
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
              Icons.settings_suggest_rounded,
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
                  'Platform Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Secure, policy-driven defaults for CAH and administrators.',
                  style: TextStyle(color: Color(0xFFE6ECFF), fontSize: 12),
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
              _controller.appVersion.value,
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

  Widget _organizationCard() {
    return _sectionShell(
      title: 'Organization',
      subtitle: 'Identity, support and default reporting preferences.',
      icon: Icons.business_rounded,
      child: Column(
        children: <Widget>[
          TextField(
            controller: _instituteController,
            onChanged: (_) {
              if (_instituteError != null) {
                setState(() {
                  _instituteError = null;
                });
              }
              _markDirty();
            },
            decoration: const InputDecoration(
              labelText: 'Institute Name',
              prefixIcon: Icon(Icons.school_rounded),
            ).copyWith(errorText: _instituteError),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _supportController,
            onChanged: (_) {
              if (_supportError != null) {
                setState(() {
                  _supportError = null;
                });
              }
              _markDirty();
            },
            decoration: const InputDecoration(
              labelText: 'Support Email',
              prefixIcon: Icon(Icons.support_agent_rounded),
            ).copyWith(errorText: _supportError),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownFormField<int>(
            value: _controller.defaultHistoryDays.value,
            labelText: 'Default History Range',
            prefixIcon: Icons.history_rounded,
            items: const <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 7, child: Text('Last 7 days')),
              DropdownMenuItem<int>(value: 30, child: Text('Last 30 days')),
              DropdownMenuItem<int>(value: 90, child: Text('Last 90 days')),
            ],
            onChanged: (int? value) {
              if (value != null) {
                _controller.defaultHistoryDays.value = value;
                _markDirty();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _policyCard() {
    return _sectionShell(
      title: 'Attendance Policy',
      subtitle: 'Control correction flow and attendance calculation behavior.',
      icon: Icons.policy_rounded,
      child: Column(
        children: <Widget>[
          _policyTile(
            title: 'Lock submitted sessions',
            subtitle: 'Prevent edits once teacher submits attendance.',
            value: _controller.lockSubmittedSessions.value,
            onChanged: (bool value) {
              _controller.toggleLockSubmittedSessions(value);
              _markDirty();
            },
            icon: Icons.lock_clock_rounded,
          ),
          const SizedBox(height: 10),
          _policyTile(
            title: 'Require correction note',
            subtitle: 'Admin/CAH must mention reason for correction.',
            value: _controller.requireCorrectionNote.value,
            onChanged: (bool value) {
              _controller.toggleRequireCorrectionNote(value);
              _markDirty();
            },
            icon: Icons.note_alt_rounded,
          ),
          const SizedBox(height: 10),
          _policyTile(
            title: 'Include leave in attendance %',
            subtitle: 'Leave students are counted in attendance percentage.',
            value: _controller.includeLeaveInAttendance.value,
            onChanged: (bool value) {
              _controller.toggleIncludeLeaveInAttendance(value);
              _markDirty();
            },
            icon: Icons.percent_rounded,
          ),
        ],
      ),
    );
  }

  Widget _saveRow(BuildContext context) {
    return Row(
      children: <Widget>[
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE4EAF7)),
            ),
            child: const Text(
              'Unsaved changes',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: (_controller.isSaving.value || !_hasChanges)
              ? null
              : () async {
                  final String instituteName =
                      _instituteController.text.trim();
                  final String supportEmail = _supportController.text.trim();
                  String? instituteError;
                  String? supportError;
                  if (instituteName.isEmpty) {
                    instituteError = 'Institute name is required.';
                  }
                  if (supportEmail.isNotEmpty &&
                      !RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$')
                          .hasMatch(supportEmail)) {
                    supportError = 'Enter a valid email address.';
                  }
                  if (instituteError != null || supportError != null) {
                    setState(() {
                      _instituteError = instituteError;
                      _supportError = supportError;
                    });
                    return;
                  }
                  await _controller.saveSettings(
                    instituteNameValue: instituteName,
                    supportEmailValue: supportEmail,
                    historyDays: _controller.defaultHistoryDays.value,
                  );
                  setState(() {
                    _hasChanges = false;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully.'),
                      ),
                    );
                  }
                },
          icon: _controller.isSaving.value
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _controller.isSaving.value ? 'Saving...' : 'Save Settings',
          ),
        ),
      ],
    );
  }

  void _markDirty() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Widget _snapshotCard() {
    return _sectionShell(
      title: 'System Snapshot',
      subtitle: 'Current module record counts across your workspace.',
      icon: Icons.pie_chart_rounded,
      child: Column(
        children: <Widget>[
          _metricTile(
            'Users',
            '${_controller.totalUsers.value}',
            Icons.manage_accounts_rounded,
          ),
          const SizedBox(height: 8),
          _metricTile(
            'Teachers',
            '${_controller.totalTeachers.value}',
            Icons.cast_for_education_rounded,
          ),
          const SizedBox(height: 8),
          _metricTile(
            'Students',
            '${_controller.totalStudents.value}',
            Icons.groups_rounded,
          ),
          const SizedBox(height: 8),
          _metricTile(
            'Batches',
            '${_controller.totalBatches.value}',
            Icons.class_rounded,
          ),
        ],
      ),
    );
  }

  Widget _appCard() {
    return _sectionShell(
      title: 'Application',
      subtitle: 'Build and release status.',
      icon: Icons.verified_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF5F8FF)],
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
                color: const Color(0x142F5DFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.desktop_windows_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Desktop Build',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Production profile',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              _controller.appVersion.value,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionShell({
    required String title,
    required String subtitle,
    required IconData icon,
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
            color: Color(0x090F172A),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x142F5DFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.accent, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _policyTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0x142F5DFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5EAF5)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x142F5DFF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.accent, size: 17),
          ),
          const SizedBox(width: 8),
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
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
