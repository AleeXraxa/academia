import 'package:academia/app/data/models/user_model.dart';
import 'package:academia/app/modules/users/controllers/users_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final UsersController controller = Get.put(UsersController());

    return AppShell(
      currentRoute: AppRoutes.users,
      child: AppPageScaffold(
        title: 'Users Management',
        subtitle:
            'SaaS-style access center for approvals, status, and role governance.',
        actions: <Widget>[
          FilledButton.icon(
            onPressed: () => _openCreateDialog(context, controller),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Create User'),
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
                    title: 'Total Users',
                    value: controller.totalUsers.toString(),
                    icon: Icons.groups_2_rounded,
                    accent: const Color(0xFF2F5DFF),
                    trend: 'Directory health',
                  ),
                  _metricCard(
                    title: 'Pending Approvals',
                    value: controller.pendingUsers.toString(),
                    icon: Icons.hourglass_top_rounded,
                    accent: const Color(0xFFD17A00),
                    trend: 'Needs CAH review',
                  ),
                  _metricCard(
                    title: 'Approved',
                    value: controller.approvedUsers.toString(),
                    icon: Icons.verified_rounded,
                    accent: const Color(0xFF148F52),
                    trend: 'Can sign in',
                  ),
                  _metricCard(
                    title: 'Rejected',
                    value: controller.rejectedUsers.toString(),
                    icon: Icons.block_rounded,
                    accent: const Color(0xFFBE2D2D),
                    trend: 'Blocked accounts',
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

                        if (controller.users.isEmpty) {
                          return const Center(child: Text('No users found.'));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: controller.users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final UserModel user = controller.users[index];
                            return _tableRow(context, controller, user);
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
            Icons.admin_panel_settings_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Access Queue',
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
              'Pending users require CAH action',
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
    UsersController controller,
    UserModel user,
  ) {
    final DateTime? createdAt = user.createdAt;
    final String createdText = createdAt == null
        ? 'Unknown'
        : '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

    final String normalizedStatus = user.status.trim().toLowerCase();
    final bool canEdit = _canEditUser(controller, user);
    final bool canDelete = _canDeleteUser(controller, user);

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
                    color: const Color(0xFFE6EEFF),
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
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
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
          Expanded(flex: 2, child: _roleBadge(user.role)),
          Expanded(flex: 2, child: _statusBadge(normalizedStatus)),
          Expanded(
            flex: 2,
            child: Text(
              createdText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (normalizedStatus == 'pending')
                  _actionButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    bg: const Color(0xFFDEF7E8),
                    fg: const Color(0xFF15803D),
                    onTap: () => controller.approveUser(user.id),
                  ),
                if (normalizedStatus == 'pending')
                  _actionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    bg: const Color(0xFFFDE3E3),
                    fg: const Color(0xFFB42318),
                    onTap: () => controller.rejectUser(user.id),
                  ),
                _actionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  bg: const Color(0xFFEFF3FA),
                  fg: const Color(0xFF334155),
                  onTap: () => _openViewDialog(context, user),
                ),
                _actionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  bg: canEdit
                      ? const Color(0xFFE9EEFF)
                      : const Color(0xFFF3F4F6),
                  fg: canEdit
                      ? AppColors.accent
                      : const Color(0xFF9CA3AF),
                  onTap: canEdit
                      ? () => _openEditDialog(context, controller, user)
                      : () {},
                ),
                _actionButton(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  bg: canDelete
                      ? const Color(0xFFFCE7E7)
                      : const Color(0xFFF3F4F6),
                  fg: canDelete
                      ? const Color(0xFFB42318)
                      : const Color(0xFF9CA3AF),
                  onTap: canDelete
                      ? () => _openDeleteDialog(context, controller, user)
                      : () {},
                ),
              ],
            ),
          ),
        ],
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final String upper = role.trim().toUpperCase();
    Color bg;
    Color fg;

    switch (upper) {
      case 'CAH':
        bg = const Color(0xFFE8EEFF);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'TEACHER':
        bg = const Color(0xFFE6F7EE);
        fg = const Color(0xFF157347);
        break;
      case 'STUDENT':
        bg = const Color(0xFFF1F3F5);
        fg = const Color(0xFF495057);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
    }

    return _pill(label: role, background: bg, foreground: fg);
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'approved':
        return _pill(
          label: 'Approved',
          background: const Color(0xFFDEF7E8),
          foreground: const Color(0xFF15803D),
        );
      case 'pending':
        return _pill(
          label: 'Pending',
          background: const Color(0xFFFFF3DC),
          foreground: const Color(0xFFB45309),
        );
      case 'rejected':
        return _pill(
          label: 'Rejected',
          background: const Color(0xFFFDE7E7),
          foreground: const Color(0xFFB42318),
        );
      case 'blocked':
      case 'block':
        return _pill(
          label: 'Blocked',
          background: const Color(0xFFFDE7E7),
          foreground: const Color(0xFFB42318),
        );
      default:
        return _pill(
          label: _capitalize(status),
          background: const Color(0xFFF3F4F6),
          foreground: const Color(0xFF4B5563),
        );
    }
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
          border: Border.all(color: foreground.withValues(alpha: 0.18)),
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

  Future<void> _openCreateDialog(
    BuildContext context,
    UsersController controller,
  ) async {
    await _openUserFormDialog(
      context: context,
      title: 'Create User',
      actionLabel: 'Create',
      initialRole: 'Teacher',
      includePassword: true,
      onSubmit:
          ({
            required String name,
            required String email,
            required String role,
            required String status,
            String? password,
          }) async {
            await controller.createUser(
              name: name,
              email: email,
              role: role,
              password: password ?? '',
            );
          },
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    UsersController controller,
    UserModel user,
  ) async {
    final bool isAdministratorActor =
        controller.assignableRoles.length == 1 &&
        controller.assignableRoles.first.trim().toUpperCase() == 'TEACHER';
    final bool canBlockTarget =
        !isAdministratorActor || user.role.trim().toUpperCase() == 'TEACHER';
    await _openUserFormDialog(
      context: context,
      title: 'Edit User',
      actionLabel: 'Save',
      initialName: user.name,
      initialEmail: user.email,
      initialRole: user.role,
      initialStatus: _toEditStatus(user.status),
      statusOptionsOverride: canBlockTarget
          ? const <String>['Active', 'Block']
          : const <String>['Active'],
      includePassword: false,
      onSubmit:
          ({
            required String name,
            required String email,
            required String role,
            required String status,
            String? password,
          }) async {
            await controller.updateUser(
              id: user.id,
              name: name,
              email: email,
              role: role,
              status: status,
            );
          },
    );
  }

  Future<void> _openUserFormDialog({
    required BuildContext context,
    required String title,
    required String actionLabel,
    required Future<void> Function({
      required String name,
      required String email,
      required String role,
      required String status,
      String? password,
    })
    onSubmit,
    required bool includePassword,
    String initialName = '',
    String initialEmail = '',
    String initialRole = 'Teacher',
    String initialStatus = 'Active',
    List<String>? statusOptionsOverride,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: initialName,
    );
    final TextEditingController emailController = TextEditingController(
      text: initialEmail,
    );
    final TextEditingController passwordController = TextEditingController();
    final UsersController usersController = Get.find<UsersController>();
    final List<String> roleOptions = <String>[...usersController.assignableRoles];
    if (roleOptions.isEmpty) {
      return;
    }
    final bool initialRoleAssignable = roleOptions
        .map((String role) => role.trim().toUpperCase())
        .contains(initialRole.trim().toUpperCase());
    if (initialRole.trim().isNotEmpty && !initialRoleAssignable) {
      roleOptions.insert(0, initialRole);
    }
    final bool roleLocked = !includePassword && !initialRoleAssignable;
    final List<String> statusOptions =
        statusOptionsOverride == null || statusOptionsOverride.isEmpty
        ? <String>['Active', 'Block']
        : <String>[...statusOptionsOverride];
    if (!statusOptions.contains(initialStatus)) {
      statusOptions.insert(0, initialStatus);
    }
    String selectedRole = roleOptions.contains(initialRole)
        ? initialRole
        : roleOptions.first;
    String selectedStatus = statusOptions.contains(initialStatus)
        ? initialStatus
        : 'Active';

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
                    subtitle: 'Update profile identity and role assignment.',
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
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (includePassword) ...<Widget>[
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: roleOptions
                        .map(
                          (String role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          ),
                        )
                        .toList(),
                    onChanged: roleLocked
                        ? null
                        : (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              selectedRole = value;
                            });
                          },
                  ),
                  if (!includePassword) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      items: statusOptions
                          .map(
                            (String status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
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
                  ],
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
                          final String email = emailController.text.trim();

                          if (name.isEmpty || email.isEmpty) {
                            return;
                          }
                          final String password = passwordController.text;
                          if (includePassword && password.length < 6) {
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
                                    title: 'Invalid Password',
                                    subtitle: 'Minimum 6 characters required.',
                                    accent: AppColors.error,
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
                            return;
                          }

                          try {
                            await onSubmit(
                              name: name,
                              email: email,
                              role: selectedRole,
                              status: includePassword ? 'Active' : selectedStatus,
                              password: includePassword ? password : null,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
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
                                    title: 'Action Not Allowed',
                                    subtitle: 'Permission check failed.',
                                    accent: AppColors.error,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF5F5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFF5D0D0),
                                      ),
                                    ),
                                    child: Text(
                                      '$e'.replaceFirst('Exception: ', ''),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
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
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _openViewDialog(BuildContext context, UserModel user) async {
    await _showSaasDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _dialogHeader(
            icon: Icons.visibility_rounded,
            title: 'User Details',
            subtitle: 'Read-only identity and access summary.',
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
                _detailTile('Full Name', user.name),
                _detailTile('Email', user.email),
                _detailTile('Role', user.role),
                _detailTile('Status', _capitalize(user.status)),
                _detailTile('User ID', user.id),
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
    UsersController controller,
    UserModel user,
  ) async {
    final TextEditingController passwordController = TextEditingController();
    String? errorText;
    bool isDeleting = false;
    await _showSaasDialog(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext dialogContext, void Function(void Function()) setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _dialogHeader(
                icon: Icons.delete_outline_rounded,
                title: 'Delete User',
                subtitle:
                    'This will delete both Firebase Auth and Firestore records.',
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
                  'Delete ${user.name} (${user.email}) from access directory?',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'User Password',
                  hintText: 'Enter this user\'s password',
                  errorText: errorText,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  OutlinedButton(
                    onPressed: isDeleting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            final String password = passwordController.text
                                .trim();
                            if (password.isEmpty) {
                              setState(() {
                                errorText = 'Password is required.';
                              });
                              return;
                            }
                            setState(() {
                              isDeleting = true;
                              errorText = null;
                            });
                            try {
                              await controller.deleteUser(
                                id: user.id,
                                password: password,
                              );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (e) {
                              if (!dialogContext.mounted) {
                                return;
                              }
                              setState(() {
                                isDeleting = false;
                                errorText = '$e'.replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    icon: isDeleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_rounded),
                    label: Text(isDeleting ? 'Deleting...' : 'Delete User'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    passwordController.dispose();
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

  String _toEditStatus(String status) {
    final String normalized = status.trim().toLowerCase();
    if (normalized == 'blocked' || normalized == 'block') {
      return 'Block';
    }
    return 'Active';
  }

  bool _canEditUser(UsersController controller, UserModel user) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (controller.assignableRoles.length == 1 &&
        controller.assignableRoles.first.trim().toUpperCase() == 'TEACHER' &&
        currentUid.trim().isNotEmpty &&
        currentUid.trim() == user.id.trim()) {
      return true;
    }
    final List<String> roles = controller.assignableRoles
        .map((String role) => role.trim().toUpperCase())
        .toList();
    return roles.contains(user.role.trim().toUpperCase());
  }

  bool _canDeleteUser(UsersController controller, UserModel user) {
    final List<String> roles = controller.assignableRoles
        .map((String role) => role.trim().toUpperCase())
        .toList();
    return roles.contains(user.role.trim().toUpperCase());
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
            child: Text('User', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text('Role', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Created',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
