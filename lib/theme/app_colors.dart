import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF163774);
  static const Color primaryLight = Color(0xFF244F9C);
  static const Color primaryGold = Color(0xffD4AF37);
  static const Color secondary = Color(0xFFE8EEF8);
  static const Color background = Color(0xFFF4F7FB);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xff1E8E3E);
  static const Color warning = Color(0xffF9A825);
  static const Color danger = Color(0xffE53935);

  // Typography & Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textNavy = Color(0xFF163774);

  // Concept Design Royal Khmer Bronze Gold & Warm Ivory Palette
  static const Color royalGold = Color(0xFF8C6615);
  static const Color royalGoldLight = Color(0xFFF6EEDB);
  static const Color warmCream = Color(0xFFFBF8F2);
  static const Color warmCreamBorder = Color(0xFFF1E8DA);
  static const Color warmIvory = warmCream;
  static const Color warmIvoryBorder = warmCreamBorder;
  static const Color iconBeige = Color(0xFFF7EEDF);

  // Royal Navy Gradient (HomeView App Bar, Action Buttons, and Brand Badges)
  static const LinearGradient royalNavyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F3278),
      Color(0xFF163774),
      Color(0xFF194498),
    ],
  );

  static const LinearGradient warmBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
      Color(0xFFEFF4FB),
      Color(0xFFE8EEF8),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient appBackgroundGradient = warmBackgroundGradient;
}