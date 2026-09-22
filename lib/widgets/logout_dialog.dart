import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void showLogoutConfirmDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
  String? title,
  String? message,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Close button at top right
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),

          // Dialog Body Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                // Top Illustration: Soft Pink/Red Blob with Logout Icon & Exclamation Badge + Floating Dots
                _buildLogoutIllustration(),

                const SizedBox(height: 18),

                // Title
                Text(
                  title ?? 'logout_dialog_title'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle / Description
                Text(
                  message ?? 'logout_dialog_message'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 18),

                // Red/Pink Notice Banner: Data is safe
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFE4E6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFFDC2626),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'logout_data_safe_notice'.tr,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Bottom Action Buttons: [Cancel] & [Log Out]
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'cancel'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Confirm Log Out Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              onConfirm();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'logout'.tr,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLogoutIllustration() {
  return SizedBox(
    width: 140,
    height: 115,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Floating decorative soft pink dots
        Positioned(
          left: 12,
          top: 32,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6).withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 32,
          bottom: 12,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 24,
          top: 18,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6).withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 14,
          bottom: 22,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6).withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Central soft pink/blush circle
        Container(
          width: 98,
          height: 98,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFFFFF1F2),
                Color(0xFFFEE2E2),
              ],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main Red Logout Icon
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 42,
                      ),
                    ),
                  ),

                  // Warning Exclamation Badge on bottom right of the icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF87171),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
