import 'package:academia/app/data/models/user_model.dart';
import 'package:academia/app/data/repositories/auth_repository.dart';
import 'package:academia/app/core/utils/auth_error_mapper.dart';
import 'package:academia/app/routes/app_routes.dart';
import 'package:academia/app/services/auth_service.dart';
import 'package:academia/app/widgets/common/app_message_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  RegisterController() : _authService = AuthService(repository: AuthRepository());

  final AuthService _authService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString selectedRole = 'Teacher'.obs;
  final RxBool isLoading = false.obs;

  Future<void> register() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      await AppMessageDialog.showError(
        title: 'Incomplete Form',
        message: 'Name, email, and password are required.',
      );
      return;
    }

    isLoading.value = true;

    try {
      final UserModel? user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: selectedRole.value,
      );

      if (user == null) {
        await AppMessageDialog.showError(
          title: 'Profile Creation Failed',
          message: 'Registration succeeded but profile creation failed.',
        );
        return;
      }

      await _authService.logout();
      await AppMessageDialog.showSuccess(
        title: 'Registration Submitted',
        message: 'Your account is pending CAH approval.',
      );
      Get.offAllNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      await AppMessageDialog.showError(
        title: 'Registration Failed',
        message: AuthErrorMapper.registerMessage(e),
      );
    } catch (_) {
      await AppMessageDialog.showError(
        title: 'Unexpected Error',
        message: 'Unexpected error during registration.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
