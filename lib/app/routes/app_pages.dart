import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/guards/role_guard.dart';
import 'package:academia/app/modules/attendance/views/attendance_view.dart';
import 'package:academia/app/modules/auth/views/login_view.dart';
import 'package:academia/app/modules/auth/views/register_view.dart';
import 'package:academia/app/modules/batches/views/batches_view.dart';
import 'package:academia/app/modules/dashboard/views/dashboard_view.dart';
import 'package:academia/app/modules/reports/views/reports_view.dart';
import 'package:academia/app/modules/settings/views/settings_view.dart';
import 'package:academia/app/modules/students/views/students_view.dart';
import 'package:academia/app/modules/teachers/views/teachers_view.dart';
import 'package:academia/app/modules/users/views/users_view.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:get/get.dart';

class AppPages {
  AppPages._();

  static const String initial = AppRoutes.login;

  // Temporary role until auth/session service is wired.
  static UserRole activeRole = UserRole.administrator;

  static void setActiveRole(UserRole role) {
    activeRole = role;
  }

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginView(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterView(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.dashboard,
      page: () => _guardedPage(
        view: const DashboardView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.batches,
      page: () => _guardedPage(
        view: const BatchesView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.students,
      page: () => _guardedPage(
        view: const StudentsView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.teachers,
      page: () => _guardedPage(
        view: const TeachersView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.attendance,
      page: () => _guardedPage(
        view: const AttendanceView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.users,
      page: () => _guardedPage(
        view: const UsersView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.reports,
      page: () => _guardedPage(
        view: const ReportsView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () => _guardedPage(
        view: const SettingsView(),
        allowedRoles: <UserRole>[
          UserRole.superAdmin,
          UserRole.administrator,
          UserRole.cah,
        ],
      ),
    ),
  ];

  static dynamic _guardedPage({
    required dynamic view,
    required List<UserRole> allowedRoles,
  }) {
    final bool allowed = RoleGuard.canAccess(
      activeRole: activeRole,
      allowedRoles: allowedRoles,
    );

    if (allowed) {
      return view;
    }

    return const LoginView();
  }
}
