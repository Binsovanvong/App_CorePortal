import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSnackbar {
  /// Strips or sanitizes raw error messages so that no API endpoints,
  /// URLs, or technical Dio/Socket/HTTP traces are shown to users.
  static String sanitizeMessage(String message) {
    if (message.isEmpty) return message;

    final lower = message.toLowerCase().trim();

    // 1. Connection timeout / network timeout patterns
    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded') ||
        lower.contains('connectiontimeout') ||
        lower.contains('receivetimeout') ||
        lower.contains('sendtimeout') ||
        lower.contains('time out')) {
      if (_hasUserFacingPrefix(message)) {
        final prefix = _extractPrefix(message);
        return '$prefix (${'timeout_error'.tr})';
      }
      return 'timeout_error'.tr;
    }

    // 2. No internet / DNS failure / socket errors
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection abort') ||
        lower.contains('broken pipe') ||
        lower.contains('no internet') ||
        lower.contains('connection error') ||
        lower.contains('connectionerror') ||
        lower.contains('handshakeexception') ||
        lower.contains('networkerror') ||
        lower.contains('err_name_not_resolved') ||
        lower.contains('err_internet_disconnected') ||
        lower.contains('err_network_changed') ||
        lower.contains('os error: no address associated with hostname') ||
        lower.contains('failed to connect') ||
        lower.contains('clientexception')) {
      if (_hasUserFacingPrefix(message)) {
        final prefix = _extractPrefix(message);
        return '$prefix (${'no_internet_error'.tr})';
      }
      return 'no_internet_error'.tr;
    }

    // 3. Technical exception dumps, server crashes, and raw URL / endpoint leaks
    final bool containsUrlOrEndpoint = lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('/api/') ||
        lower.contains('api/mobile') ||
        lower.contains('url:') ||
        lower.contains('endpoint:');

    final bool containsTechDump = lower.contains('dioexception') ||
        lower.contains('formatexception') ||
        lower.contains('bad response') ||
        lower.contains('status code of') ||
        lower.contains('requestoptions') ||
        lower.contains('stack trace') ||
        lower.contains('syntaxerror') ||
        lower.contains('internal server error');

    if (containsUrlOrEndpoint || containsTechDump) {
      if (_hasUserFacingPrefix(message)) {
        final prefix = _extractPrefix(message);
        return '$prefix (${'server_error'.tr})';
      }
      return 'server_error'.tr;
    }

    // 4. Scrub any remaining URL tokens, endpoints, or method tags
    String sanitized = message
        .replaceAll(RegExp(r'https?://[^\s)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'url:\s*[^\s)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'(/api/|api/mobile/)[^\s)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[(get|post|put|delete|patch)\s+[^\]]+\]', caseSensitive: false), '')
        .trim();

    // Clean up trailing punctuation left by stripping (e.g. "Error: ")
    sanitized = sanitized.replaceAll(RegExp(r'[:\-\s]+$'), '').trim();

    if (sanitized.isEmpty) {
      return 'server_error'.tr;
    }

    return sanitized;
  }

  /// Sanitizes title strings to prevent technical traces or URLs in title
  static String? sanitizeTitle(String? title) {
    if (title == null || title.isEmpty) return title;
    final lower = title.toLowerCase();
    if (lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('/api/') ||
        lower.contains('dio') ||
        lower.contains('exception') ||
        lower.contains('status code')) {
      return 'error'.tr;
    }
    return title;
  }

  static bool _hasUserFacingPrefix(String msg) {
    if (!msg.contains(':')) return false;
    final prefix = msg.split(':').first.trim().toLowerCase();
    if (prefix.startsWith('http') ||
        prefix.startsWith('the connection') ||
        prefix.startsWith('the request') ||
        prefix.contains('dio') ||
        prefix.contains('exception') ||
        prefix.contains('status code') ||
        prefix.contains('socket') ||
        prefix.contains('error') ||
        prefix.length < 3) {
      return false;
    }
    return true;
  }

  static String _extractPrefix(String msg) {
    return msg.split(':').first.trim();
  }

  static void showSuccess({
    String? title,
    required String message,
  }) {
    _show(
      title: title ?? 'success'.tr,
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
      title: sanitizeTitle(title) ?? 'error'.tr,
      message: sanitizeMessage(message),
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
      title: sanitizeTitle(title) ?? 'info'.tr,
      message: sanitizeMessage(message),
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
      title: sanitizeTitle(title) ?? 'warning'.tr,
      message: sanitizeMessage(message),
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
    // Ultimate safeguard: sanitize all displayed texts
    final cleanTitle = sanitizeTitle(title) ?? title;
    final cleanMessage = sanitizeMessage(message);

    Get.snackbar(
      '',
      '',
      titleText: Text(
        cleanTitle,
        style: GoogleFonts.kantumruyPro(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xff0F172A),
        ),
      ),
      messageText: Text(
        cleanMessage,
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
