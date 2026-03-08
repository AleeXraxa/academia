import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Segoe UI';

  static TextTheme textTheme() {
    return const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    );
  }
}
