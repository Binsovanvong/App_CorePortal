import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyle {
  // Standardized Font Sizes across Screens & Folders
  static const double fontSizeScreenTitle = 27.0;
  static const double fontSizeHeading = 20.0;
  static const double fontSizeSectionTitle = 17.0;
  static const double fontSizeCardTitle = 15.0;
  static const double fontSizeFieldLabel = 14.0;
  static const double fontSizeBody = 13.5;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeSmall = 11.0;

  // Screen Headers & Titles (using AppColors.primary / Navy)
  static TextStyle get screenTitle => GoogleFonts.kantumruyPro(
        fontSize: fontSizeScreenTitle,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get screenSubtitle => GoogleFonts.kantumruyPro(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  // Section & Card Titles
  static TextStyle get sectionTitle => GoogleFonts.kantumruyPro(
        fontSize: fontSizeSectionTitle,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get cardTitle => GoogleFonts.kantumruyPro(
        fontSize: fontSizeCardTitle,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  // Form Field Labels & Hints
  static TextStyle get fieldLabel => GoogleFonts.kantumruyPro(
        fontSize: fontSizeFieldLabel,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get fieldHint => GoogleFonts.kantumruyPro(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // Body & Caption
  static TextStyle get bodyText => GoogleFonts.kantumruyPro(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get caption => GoogleFonts.kantumruyPro(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // Button Text
  static TextStyle get buttonText => GoogleFonts.kantumruyPro(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  // Legacy fallback styles
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}