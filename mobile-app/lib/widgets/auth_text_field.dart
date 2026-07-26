import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Rounded, filled text field matching the style used across the app's
/// settings dialogs and the edit-profile sheet — shared by the sign-in and
/// sign-up screens.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isDark;
  final String? prefix;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.isDark,
    this.prefix,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      style: GoogleFonts.lato(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        errorText: errorText,
        errorMaxLines: 3,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }
}

/// Banner used for top-level form errors (e.g. an [AuthException] message)
/// and for the post-signup "check your email" success state.
class AuthMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final bool isDark;

  const AuthMessageBanner({
    super.key,
    required this.message,
    required this.isDark,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.like : AppColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.mark_email_read_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.lato(fontSize: 13, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
