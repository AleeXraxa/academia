import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:academia/app/theme/app_colors.dart';

class AppNotifier {
  static const Duration _defaultDuration = Duration(milliseconds: 2200);

  static void showSuccess(String title, {String? message}) {
    _showToast(
      title: title,
      message: message,
      accent: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(String title, {String? message}) {
    _showToast(
      title: title,
      message: message,
      accent: AppColors.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showRetry({
    required String title,
    String? message,
    required VoidCallback onRetry,
  }) {
    _showToast(
      title: title,
      message: message,
      accent: AppColors.warning,
      icon: Icons.wifi_off_rounded,
      actionLabel: 'Retry',
      onAction: onRetry,
      duration: const Duration(milliseconds: 4200),
    );
  }

  static bool isNetworkError(Object error) {
    if (error is FirebaseException) {
      final String code = error.code.toLowerCase().trim();
      return code == 'unavailable' ||
          code == 'network-request-failed' ||
          code == 'deadline-exceeded' ||
          code == 'cancelled' ||
          code == 'internal' ||
          code == 'unknown';
    }
    final String text = error.toString().toLowerCase();
    return text.contains('network') ||
        text.contains('unavailable') ||
        text.contains('timeout') ||
        text.contains('connection') ||
        text.contains('socket');
  }

  static String cleanMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '')
        .trim();
  }

  static void _showToast({
    required String title,
    String? message,
    required Color accent,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    if (!Get.isOverlaysOpen) {
      return;
    }
    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: 14,
      backgroundColor: Colors.white,
      boxShadows: const <BoxShadow>[
        BoxShadow(
          color: Color(0x240F172A),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
      duration: duration ?? _defaultDuration,
      messageText: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if ((message ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                onAction();
              },
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
