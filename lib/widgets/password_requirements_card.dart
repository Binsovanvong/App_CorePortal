import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Password Requirements Card matching the official design specification:
/// - Gold/Amber title "លក្ខខណ្ឌពាក្យសម្ងាត់" (Password Requirements)
/// - Clean rounded white container with subtle border
/// - 5 checklist items with circular status indicators:
///   1. យ៉ាងតិច ៨ តួអក្សរ (At least 8 characters)
///   2. មានអក្សរធំ (A–Z) (Contains uppercase (A–Z))
///   3. មានអក្សរតូច (a–z) (Contains lowercase (a–z))
///   4. មានលេខ (0–9) (Contains number (0–9))
///   5. ពាក្យសម្ងាត់ថ្មីដូចគ្នាទាំងពីរ (Both new passwords match)
class PasswordRequirementsCard extends StatelessWidget {
  /// The current new password string (evaluated dynamically if provided).
  final String? password;

  /// The current confirm password string (evaluated dynamically for match).
  final String? confirmPassword;

  /// Explicit override booleans (optional).
  final bool? hasMinLength;
  final bool? hasUppercase;
  final bool? hasLowercase;
  final bool? hasNumber;
  final bool? hasMatch;

  /// Custom styling overrides.
  final String? title;
  final Color? titleColor;
  final Color? cardColor;
  final Color? borderColor;
  final Color? metColor;
  final Color? unmetBorderColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const PasswordRequirementsCard({
    super.key,
    this.password,
    this.confirmPassword,
    this.hasMinLength,
    this.hasUppercase,
    this.hasLowercase,
    this.hasNumber,
    this.hasMatch,
    this.title,
    this.titleColor,
    this.cardColor,
    this.borderColor,
    this.metColor,
    this.unmetBorderColor,
    this.margin,
    this.padding,
  });

  bool get isMinLengthMet =>
      hasMinLength ?? ((password ?? '').length >= 8);

  bool get isUppercaseMet =>
      hasUppercase ?? RegExp(r'[A-Z]').hasMatch(password ?? '');

  bool get isLowercaseMet =>
      hasLowercase ?? RegExp(r'[a-z]').hasMatch(password ?? '');

  bool get isNumberMet =>
      hasNumber ?? RegExp(r'[0-9]').hasMatch(password ?? '');

  bool get isMatchMet {
    if (hasMatch != null) return hasMatch!;
    final p = password ?? '';
    final c = confirmPassword ?? '';
    return p.isNotEmpty && c.isNotEmpty && p == c;
  }

  /// Helper to check if all criteria are met
  bool get allRequirementsMet =>
      isMinLengthMet &&
      isUppercaseMet &&
      isLowercaseMet &&
      isNumberMet &&
      isMatchMet;

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = titleColor ?? const Color(0xFF9E7728);
    final effectiveMetColor = metColor ?? const Color(0xFF10B981);
    final effectiveUnmetBorder = unmetBorderColor ?? const Color(0xFFCBD5E1);

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Title: "លក្ខខណ្ឌពាក្យសម្ងាត់" in warm golden/amber
          Text(
            title ?? 'password_requirements_title'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: effectiveTitleColor,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),

          // White rounded card container with 5 requirement rows
          Container(
            width: double.infinity,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor ?? const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow(
                  label: 'req_min_8_chars_short'.tr,
                  isMet: isMinLengthMet,
                  metColor: effectiveMetColor,
                  unmetBorderColor: effectiveUnmetBorder,
                ),
                const SizedBox(height: 11),
                _buildRow(
                  label: 'req_uppercase'.tr,
                  isMet: isUppercaseMet,
                  metColor: effectiveMetColor,
                  unmetBorderColor: effectiveUnmetBorder,
                ),
                const SizedBox(height: 11),
                _buildRow(
                  label: 'req_lowercase'.tr,
                  isMet: isLowercaseMet,
                  metColor: effectiveMetColor,
                  unmetBorderColor: effectiveUnmetBorder,
                ),
                const SizedBox(height: 11),
                _buildRow(
                  label: 'req_number'.tr,
                  isMet: isNumberMet,
                  metColor: effectiveMetColor,
                  unmetBorderColor: effectiveUnmetBorder,
                ),
                const SizedBox(height: 11),
                _buildRow(
                  label: 'req_passwords_match'.tr,
                  isMet: isMatchMet,
                  metColor: effectiveMetColor,
                  unmetBorderColor: effectiveUnmetBorder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required bool isMet,
    required Color metColor,
    required Color unmetBorderColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular requirement indicator:
        // - When not met: empty circular grey ring (matching design spec)
        // - When met: smooth animated green badge with white checkmark
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? metColor : Colors.transparent,
            border: Border.all(
              color: isMet ? metColor : unmetBorderColor,
              width: 1.8,
            ),
          ),
          child: isMet
              ? const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13.5,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              height: 1.25,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
