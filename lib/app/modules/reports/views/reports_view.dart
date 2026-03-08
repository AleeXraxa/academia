import 'package:academia/app/modules/reports/controllers/reports_controller.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReportsController());

    return AppShell(
      currentRoute: AppRoutes.reports,
      child: const AppPageScaffold(
        title: 'Reports',
        subtitle: 'Generate attendance reports by date, batch, and status.',
        child: Center(child: Text('Reports module scaffolded.')),
      ),
    );
  }
}
