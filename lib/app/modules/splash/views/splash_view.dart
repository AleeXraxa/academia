import 'dart:async';

import 'package:academia/app/core/constants/app_constants.dart';
import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/session/app_session.dart';
import 'package:academia/app/data/repositories/auth_repository.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentSlide;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(repository: AuthRepository());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _contentSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    );

    _bootstrapNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrapNavigation() async {
    final String route = await _resolveInitialRoute();
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) {
      return;
    }
    Get.offAllNamed(route);
  }

  Future<String> _resolveInitialRoute() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (user == null) {
        return AppRoutes.login;
      }

      final String status = user.status.trim().toLowerCase();
      if (status == 'pending' ||
          status == 'rejected' ||
          status == 'blocked' ||
          status == 'block') {
        await _authService.logout();
        Get.find<AppSession>().clear();
        return AppRoutes.login;
      }

      final UserRole role = _toRole(user.role);
      if (role == UserRole.teacher && !_isMobilePlatform()) {
        await _authService.logout();
        Get.find<AppSession>().clear();
        return AppRoutes.login;
      }
      Get.find<AppSession>().setRole(role);
      if (role == UserRole.teacher) {
        return AppRoutes.attendance;
      }
      if (role == UserRole.cah ||
          role == UserRole.administrator ||
          role == UserRole.superAdmin) {
        return AppRoutes.dashboard;
      }
      return AppRoutes.login;
    } catch (_) {
      return AppRoutes.login;
    }
  }

  UserRole _toRole(String role) {
    switch (role.trim().toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'ADMINISTRATOR':
      case 'ADMIN':
        return UserRole.administrator;
      case 'CAH':
        return UserRole.cah;
      case 'TEACHER':
        return UserRole.teacher;
      default:
        return UserRole.staff;
    }
  }

  bool _isMobilePlatform() {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFF8FAFF),
              Color(0xFFEFF4FF),
              Color(0xFFE7EEFF),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -80,
              right: -60,
              child: _ambientBlob(
                size: 220,
                colors: const <Color>[Color(0x442F5DFF), Color(0x112F5DFF)],
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _ambientBlob(
                size: 260,
                colors: const <Color>[Color(0x331E4ED8), Color(0x101E4ED8)],
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Transform.scale(
                        scale: Tween<double>(
                          begin: 0.72,
                          end: 1.0,
                        ).evaluate(_logoScale),
                        child: Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[Color(0xFF1641C7), Color(0xFF2F5DFF)],
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x332F5DFF),
                                blurRadius: 26,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: _contentSlide.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _contentSlide.value) * 16),
                          child: Column(
                            children: <Widget>[
                              Text(
                                AppConstants.appTitle,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Attendance Intelligence',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 5,
                            backgroundColor: Color(0xFFDCE5FF),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2F5DFF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Developed by Sir Alee',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'TryUnity Solutions',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientBlob({
    required double size,
    required List<Color> colors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}
