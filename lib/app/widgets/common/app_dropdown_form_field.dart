import 'package:academia/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppDropdownFormField<T> extends StatelessWidget {
  const AppDropdownFormField({
    super.key,
    required this.labelText,
    required this.items,
    this.onChanged,
    this.value,
    this.prefixIcon,
    this.hintText,
    this.isExpanded = true,
    this.menuMaxHeight = 320,
    this.enabled = true,
  });

  final String labelText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final IconData? prefixIcon;
  final String? hintText;
  final bool isExpanded;
  final double menuMaxHeight;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      menuMaxHeight: menuMaxHeight,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      dropdownColor: AppColors.surface,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.8),
          ),
        ),
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }
}
