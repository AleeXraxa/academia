import 'package:academia/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppMessageDialog {
  static Future<void> showSuccess({required String title, required String message}) {
    return _show(
      title: title,
      message: message,
      accent: AppColors.success,
      icon: Icons.check_circle_rounded,
      actionLabel: 'Great',
    );
  }

  static Future<void> showError({required String title, required String message}) {
    return _show(
      title: title,
      message: message,
      accent: AppColors.error,
      icon: Icons.error_rounded,
      actionLabel: 'Close',
    );
  }

  static Future<void> _show({
    required String title,
    required String message,
    required Color accent,
    required IconData icon,
    required String actionLabel,
  }) async {
    final BuildContext? context = Get.overlayContext ?? Get.context;
    if (context == null) {
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'message_dialog',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x2B0F172A),
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, Animation<double> animation, __, Widget child) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
