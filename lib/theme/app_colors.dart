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