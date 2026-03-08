import 'package:academia/app/data/repositories/auth_repository.dart';
import 'package:academia/app/core/enums/user_role.dart';
import 'package:academia/app/core/utils/auth_error_mapper.dart';
import 'package:academia/app/data/models/user_model.dart';
import 'package:academia/app/routes/app_pages.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/services/auth_service.dart';
import 'package:academia/app/widgets/common/app_message_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  LoginController()
    : _authService = AuthService(repository: AuthRepository());

  final AuthService _authService;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      await AppMessageDialog.showError(
        title: 'Missing Credentials',
        message: 'Email and password are required.',
      );
      return;
    }

    isLoading.value = true;

    try {
      final UserModel? user = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user == null) {
        await AppMessageDialog.showError(
          title: 'Profile Not Found',
          message:
              'Login succeeded but no profile was found in Firestore users collection.',
        );
        return;
      }

      final String normalizedStatus = user.status.trim().toLowerCase();
      if (normalizedStatus == 'pending') {
        await _authService.logout();
        await AppMessageDialog.showError(
          title: 'Approval Pending',
          message: 'Your account is pending approval from CAH.',
        );
        return;
      }
      if (normalizedStatus == 'rejected') {
        await _authService.logout();
        await AppMessageDialog.showError(
          title: 'Access Rejected',
          message: 'Your account request was rejected. Contact CAH.',
        );
        return;
      }

      AppPages.setActiveRole(_toRole(user.role));
      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      debugPrint('LOGIN FirebaseAuthException code=${e.code} message=${e.message}');
      await AppMessageDialog.showError(
        title: 'Authentication Failed',
        message: AuthErrorMapper.loginMessage(e),
      );
    } catch (_) {
      await AppMessageDialog.showError(
        title: 'Unexpected Error',
        message: 'Unexpected error during login.',
      );
    } finally {
      isLoading.value = false;
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
      case 'STUDENT':
        return UserRole.staff;
      default:
        return UserRole.staff;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
