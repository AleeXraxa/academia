import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.settings,
      child: AppPageScaffold(
        title: 'Settings',
        subtitle: 'Manage platform preferences, policies, and account defaults.',
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            constraints: const BoxConstraints(maxWidth: 620),
            child: const Text(
              'Settings module is ready for configuration controls.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
