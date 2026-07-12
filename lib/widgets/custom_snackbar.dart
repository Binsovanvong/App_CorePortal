import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSnackbar {
  static void showSuccess({
    String? title,
    required String message,
  }) {
    _show(
      title: title ?? 'ជោគជ័យ',
      message: message,
      icon: const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        size: 28,
      ),
      accentColor: const Color(0xFF10B981),
    );
  }

  static void showError({
    String? title,
    required String message,
  }) {
    _show(
      title: title ?? 'មានបញ្ហា',
      message: message,
      icon: const Icon(
        Icons.error_rounded,
        color: Color(0xFFEF4444),
        size: 28,
      ),
      accentColor: const Color(0xFFEF4444),
    );
  }

  static void showInfo({
    String? title,
    required String message,
  }) {
    _show(
      title: title ?? 'ព័ត៌មាន',
      message: message,
      icon: const Icon(
        Icons.info_rounded,
        color: Color(0xFF3B82F6),
        size: 28,
      ),
      accentColor: const Color(0xFF3B82F6),
    );
  }

  static void showWarning({
    String? title,
    required String message,
  }) {
    _show(
      title: title ?? 'ប្រុងប្រយ័ត្ន',
      message: message,
      icon: const Icon(
        Icons.warning_rounded,
        color: Color(0xFFF59E0B),
        size: 28,
      ),
      accentColor: const Color(0xFFF59E0B),
    );
  }

  static void _show({
    required String title,
    required String message,
    required Widget icon,
    required Color accentColor,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: GoogleFonts.kantumruyPro(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xff0F172A),
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.kantumruyPro(
          fontSize: 14,
          color: const Color(0xff475569),
          fontWeight: FontWeight.w400,
        ),
      ),
      icon: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: icon,
      ),
      shouldIconPulse: false,
      backgroundColor: Colors.white.withOpacity(0.95),
      leftBarIndicatorColor: accentColor,
      borderRadius: 20,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      borderColor: const Color(0xffE2E8F0),
      borderWidth: 1,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accentColor.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
