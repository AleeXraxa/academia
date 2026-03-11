import 'package:academia/app/data/models/audit_log_model.dart';
import 'package:academia/app/modules/audit_logs/controllers/audit_logs_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuditLogsView extends StatelessWidget {
  const AuditLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuditLogsController controller = Get.put(AuditLogsController());

    return AppShell(
      currentRoute: AppRoutes.auditLogs,
      child: AppPageScaffold(
        contextHint: 'Administration / Compliance / Audit Logs',
        title: 'Audit Logs',
        subtitle: 'System-wide activity trail for accountability and review.',
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

          return Column(
            children: <Widget>[
              _heroBanner(controller),
              const SizedBox(height: AppSpacing.md),
              _filtersCard(controller),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _logsPanel(controller)),
            ],
          );
        }),
      ),
    );
  }

  Widget _heroBanner(AuditLogsController controller) {
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Icon(
              Icons.policy_rounded,
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
                  'System Audit Trail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track account, batch, student, and attendance changes in one view.',
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
              _heroStat('${controller.totalLogs}', 'Total Logs'),
              const SizedBox(height: 8),
              _heroStat('${controller.todayLogs}', 'Today'),
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

  Widget _filtersCard(AuditLogsController controller) {
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
          final Widget range = _rangeField(controller);
          final Widget type = _typeField(controller);
          final Widget action = _actionField(controller);
          final Widget role = _roleField(controller);
          final Widget search = _searchField(controller);

          if (narrow) {
            return Column(
              children: <Widget>[
                range,
                const SizedBox(height: 10),
                type,
                const SizedBox(height: 10),
                action,
                const SizedBox(height: 10),
                role,
                const SizedBox(height: 10),
                search,
              ],
            );
          }
          return Row(
            children: <Widget>[
              SizedBox(width: 200, child: range),
              const SizedBox(width: 10),
              SizedBox(width: 200, child: type),
              const SizedBox(width: 10),
              SizedBox(width: 200, child: action),
              const SizedBox(width: 10),
              SizedBox(width: 180, child: role),
              const SizedBox(width: 10),
              Expanded(child: search),
            ],
          );
        },
      ),
    );
  }

  Widget _rangeField(AuditLogsController controller) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      value: controller.rangeDays.value,
      decoration: const InputDecoration(
        labelText: 'Date Range',
        prefixIcon: Icon(Icons.date_range_rounded),
      ),
      items: const <DropdownMenuItem<int>>[
        DropdownMenuItem<int>(value: 1, child: Text('Today')),
        DropdownMenuItem<int>(value: 7, child: Text('Last 7 days')),
        DropdownMenuItem<int>(value: 30, child: Text('Last 30 days')),
        DropdownMenuItem<int>(value: 90, child: Text('Last 90 days')),
        DropdownMenuItem<int>(value: 0, child: Text('All time')),
      ],
      onChanged: (int? value) => controller.updateRangeDays(value ?? 7),
    );
  }

  Widget _typeField(AuditLogsController controller) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: controller.entityType.value.isEmpty
          ? ''
          : controller.entityType.value,
      decoration: const InputDecoration(
        labelText: 'Entity',
        prefixIcon: Icon(Icons.layers_rounded),
      ),
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(value: '', child: Text('All entities')),
        DropdownMenuItem<String>(value: 'user', child: Text('Users')),
        DropdownMenuItem<String>(value: 'batch', child: Text('Batches')),
        DropdownMenuItem<String>(value: 'student', child: Text('Students')),
        DropdownMenuItem<String>(value: 'session', child: Text('Sessions')),
        DropdownMenuItem<String>(value: 'attendance', child: Text('Attendance')),
        DropdownMenuItem<String>(value: 'settings', child: Text('Settings')),
      ],
      onChanged: (String? value) => controller.updateEntityType(value ?? ''),
    );
  }

  Widget _actionField(AuditLogsController controller) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: controller.action.value.isEmpty ? '' : controller.action.value,
      decoration: const InputDecoration(
        labelText: 'Action',
        prefixIcon: Icon(Icons.flash_on_rounded),
      ),
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(value: '', child: Text('All actions')),
        DropdownMenuItem<String>(value: 'create', child: Text('Create')),
        DropdownMenuItem<String>(value: 'update', child: Text('Update')),
        DropdownMenuItem<String>(value: 'delete', child: Text('Delete')),
        DropdownMenuItem<String>(value: 'generate', child: Text('Generate')),
        DropdownMenuItem<String>(value: 'submit', child: Text('Submit')),
        DropdownMenuItem<String>(value: 'correct', child: Text('Correct')),
        DropdownMenuItem<String>(value: 'approve', child: Text('Approve')),
        DropdownMenuItem<String>(value: 'reject', child: Text('Reject')),
        DropdownMenuItem<String>(value: 'block', child: Text('Block')),
        DropdownMenuItem<String>(value: 'unblock', child: Text('Unblock')),
      ],
      onChanged: (String? value) => controller.updateAction(value ?? ''),
    );
  }

  Widget _roleField(AuditLogsController controller) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: controller.actorRole.value.isEmpty
          ? ''
          : controller.actorRole.value,
      decoration: const InputDecoration(
        labelText: 'Actor Role',
        prefixIcon: Icon(Icons.person_rounded),
      ),
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(value: '', child: Text('All roles')),
        DropdownMenuItem<String>(value: 'cah', child: Text('CAH')),
        DropdownMenuItem<String>(value: 'administrator', child: Text('Admin')),
        DropdownMenuItem<String>(value: 'superadmin', child: Text('Super Admin')),
        DropdownMenuItem<String>(value: 'teacher', child: Text('Teacher')),
        DropdownMenuItem<String>(value: 'staff', child: Text('Staff')),
      ],
      onChanged: (String? value) => controller.updateActorRole(value ?? ''),
    );
  }

  Widget _searchField(AuditLogsController controller) {
    return TextField(
      onChanged: controller.updateSearch,
      decoration: const InputDecoration(
        labelText: 'Search entity, id, actor',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }

  Widget _logsPanel(AuditLogsController controller) {
    final logs = controller.pagedLogs;

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
                'Activity Stream',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${logs.length} of ${controller.filteredLogs.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs match current filters.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: logs.length + (controller.hasMoreLogs ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= logs.length) {
                        return Align(
                          alignment: Alignment.center,
                          child: OutlinedButton.icon(
                            onPressed: controller.loadMore,
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('Load more'),
                          ),
                        );
                      }
                      final AuditLogModel log = logs[index];
                      return _logTile(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _logTile(AuditLogModel log) {
    final String title = _actionTitle(log.action, log.entityType);
    final String dateLabel = _formatDate(log.at);
    final Color accent = _actionColor(log.action);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF5)),
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
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _actionIcon(log.action),
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log.entityType.toUpperCase()} · ${log.entityName.isEmpty ? log.entityId : log.entityName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD4E0FF)),
                ),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${log.actorEmail.isEmpty ? 'Unknown' : log.actorEmail} · ${log.actorRole.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (log.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              log.note,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (log.meta.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: log.meta.entries
                  .take(4)
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FE),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2EAF8)),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    final DateTime d = date ?? DateTime(2000, 1, 1);
    final String yyyy = d.year.toString().padLeft(4, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    final String hh = d.hour.toString().padLeft(2, '0');
    final String min = d.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  String _actionTitle(String action, String entityType) {
    final String a = action.trim().toLowerCase();
    final String e = entityType.trim().toLowerCase();
    final String entity = e.isEmpty ? 'Item' : _capitalize(e);

    switch (a) {
      case 'create':
        return '$entity Created';
      case 'update':
        return '$entity Updated';
      case 'delete':
        return '$entity Deleted';
      case 'generate':
        return '$entity Generated';
      case 'submit':
        return '$entity Submitted';
      case 'correct':
        return '$entity Corrected';
      case 'approve':
        return '$entity Approved';
      case 'reject':
        return '$entity Rejected';
      case 'block':
        return '$entity Blocked';
      case 'unblock':
        return '$entity Unblocked';
      default:
        return '${_capitalize(a)} $entity';
    }
  }

  IconData _actionIcon(String action) {
    switch (action.trim().toLowerCase()) {
      case 'create':
        return Icons.add_circle_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_rounded;
      case 'generate':
        return Icons.event_available_rounded;
      case 'submit':
        return Icons.check_circle_rounded;
      case 'correct':
        return Icons.fact_check_rounded;
      case 'approve':
        return Icons.verified_rounded;
      case 'reject':
        return Icons.block_rounded;
      case 'block':
        return Icons.lock_rounded;
      case 'unblock':
        return Icons.lock_open_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  Color _actionColor(String action) {
    switch (action.trim().toLowerCase()) {
      case 'create':
      case 'approve':
      case 'submit':
        return AppColors.success;
      case 'update':
      case 'generate':
        return AppColors.accent;
      case 'delete':
      case 'reject':
      case 'block':
        return AppColors.error;
      case 'correct':
      case 'unblock':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _capitalize(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }
}
