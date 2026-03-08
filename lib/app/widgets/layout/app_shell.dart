import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/theme/app_colors.dart';
import 'package:academia/app/theme/app_spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.currentRoute, required this.child, super.key});

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          _Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users, students, batches...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              color: AppColors.surfaceAlt,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
                const SizedBox(width: 8),
                Text(_activeRoleLabel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _activeRoleLabel() {
    final AppSession session = Get.find<AppSession>();
    switch (session.roleOrStaff) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.cah:
        return 'CAH';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.staff:
        return 'Staff';
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final List<_SidebarItemData> items = <_SidebarItemData>[
      _SidebarItemData(
        icon: Icons.grid_view_rounded,
        label: 'Dashboard',
        route: AppRoutes.dashboard,
      ),
      _SidebarItemData(
        icon: Icons.fact_check_rounded,
        label: 'Attendance',
        route: AppRoutes.attendance,
      ),
      _SidebarItemData(
        icon: Icons.class_rounded,
        label: 'Batches',
        route: AppRoutes.batches,
      ),
      _SidebarItemData(
        icon: Icons.cast_for_education_rounded,
        label: 'Teachers',
        route: AppRoutes.teachers,
      ),
      _SidebarItemData(
        icon: Icons.groups_rounded,
        label: 'Students',
        route: AppRoutes.students,
      ),
      _SidebarItemData(
        icon: Icons.bar_chart_rounded,
        label: 'Reports',
        route: AppRoutes.reports,
      ),
      _SidebarItemData(
        icon: Icons.manage_accounts_rounded,
        label: 'Users',
        route: AppRoutes.users,
      ),
      _SidebarItemData(
        icon: Icons.settings_rounded,
        label: 'Settings',
        route: AppRoutes.settings,
      ),
    ];

    return Container(
      width: 246,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF5F8FF), Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD7E2F6)),
              color: AppColors.surface,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0A1E3A8A),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF1E4ED8), Color(0xFF2F5DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ACADEMIA',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFE8EEFF),
                    border: Border.all(color: const Color(0xFFD4E0FF)),
                  ),
                  child: const Text(
                    'Desk',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            margin: const EdgeInsets.only(bottom: 4),
            child: const Text(
              'MAIN MENU',
              style: TextStyle(
                letterSpacing: 0.9,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...items.map(
            (_SidebarItemData item) => _NavItem(
              icon: item.icon,
              label: item.label,
              route: item.route,
              active: currentRoute == item.route,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8FAFF),
              border: Border.all(color: AppColors.border),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.find<AppSession>().clear();
                  Get.offAllNamed(AppRoutes.login);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  const _SidebarItemData({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!active) {
            Get.offNamed(route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: active
                ? const LinearGradient(
                    colors: <Color>[Color(0xFFEAF0FF), Color(0xFFE3ECFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.transparent,
            border: Border.all(
              color: active ? const Color(0xFFCBD9FF) : Colors.transparent,
            ),
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 11),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: active ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
