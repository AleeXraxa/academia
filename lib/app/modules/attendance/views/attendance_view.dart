import 'package:academia/app/modules/attendance/controllers/attendance_controller.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:academia/app/widgets/common/app_dropdown_form_field.dart';
import 'package:academia/app/widgets/common/app_notifier.dart';
import 'package:academia/app/widgets/common/app_page_scaffold.dart';
import 'package:academia/app/widgets/layout/app_shell.dart';
import 'package:academia/app/services/network_guard.dart';
import 'package:academia/app/services/audit_log_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
part 'attendance_view_dialogs_part.dart';
part 'attendance_view_teacher_part.dart';
part 'attendance_view_admin_part.dart';

const Duration _kFastMotion = Duration(milliseconds: 160);
const Duration _kBaseMotion = Duration(milliseconds: 220);
const Duration _kEnterMotion = Duration(milliseconds: 280);
const double _kMobileRadius = 14;
const double _kMobileButtonHeight = 42;
const double _kMobileGap = 10;

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.put(AttendanceController());
    final bool isTeacher = Get.find<AppSession>().isTeacher;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile && isTeacher) {
      return _teacherMobileShell(context, controller);
    }

    if (isMobile) {
      return _adminMobileShell(context, controller);
    }

    return AppShell(
      currentRoute: AppRoutes.attendance,
      child: AppPageScaffold(
        title: 'Attendance',
        subtitle:
            'Admin attendance session setup for today with batch-level present count.',
        child: _attendanceBody(
          context,
          controller,
          isMobile: false,
          isTeacher: isTeacher,
        ),
      ),
    );
  }
}

class _AttendanceSessionHeader extends StatelessWidget {
  const _AttendanceSessionHeader();

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
              'Present',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Absent',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Leave', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Attendance %',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

