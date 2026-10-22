import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/core/services/app_lock_service.dart';

/// Full-screen security lock view presented when the application resumes
/// from background or when explicitly locked by the user.
class BiometricLockScreenView extends StatelessWidget {
  const BiometricLockScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final lockService = AppLockService.to;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bool isIOS = Platform.isIOS;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A3E82),
              Color(0xFF163774),
              Color(0xFF102652),
            ],
          ),
        ),
        child: Column(
          children: [
            // Top Government Branding Section
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circular Logo with Royal Gold Border
                          Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 3.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4.5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEAB308).withValues(alpha: 0.45),
                                  width: 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(3.5),
                              child: ClipOval(
                                child: Image.asset(
                                  "assets/img/about-moi-logo.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ministry Title (Royal Gold Khmer)
                          Text(
                            'ក្រសួងមហាផ្ទៃ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD4AF37),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Ministry Subtitle (English Champagne Gold)
                          Text(
                            'MINISTRY OF INTERIOR',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDFBC66),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Elevated Security Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                28,
                24,
                bottomInset > 0 ? bottomInset + 16 : 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Lock Title
                  Text(
                    'app_locked'.tr.isNotEmpty
                        ? 'app_locked'.tr
                        : 'កម្មវិធីត្រូវបានចាក់សោ',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Reason / Hint text
                  Text(
                    'biometric_reason'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Biometric Icon Container
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF4FB),
                      border: Border.all(
                        color: const Color(0xFFC7D7EC),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF163774).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isIOS ? Icons.face_rounded : Icons.fingerprint_rounded,
                      size: 44,
                      color: const Color(0xFF163774),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button 1: Verify Biometrics Again
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(
                      () {
                        final bool loading = lockService.isAuthenticating.value;
                        return ElevatedButton.icon(
                          onPressed: loading
                              ? null
                              : () => lockService.triggerBiometricUnlock(),
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Icon(
                                  isIOS
                                      ? Icons.face_rounded
                                      : Icons.fingerprint_rounded,
                                ),
                          label: Text(
                            loading
                                ? 'biometric_verifying'.tr
                                : 'verify_again'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF163774),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Button 2: Exit App
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: lockService.exitApp,
                      icon: const Icon(
                        Icons.exit_to_app_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      label: Text(
                        'exit_app'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Action Button 3: Switch to Username & Password (Full Logout)
                  TextButton(
                    onPressed: () => lockService.unlockWithFullLogout(),
                    child: Text(
                      'switch_to_password_login'.tr.isNotEmpty
                          ? 'switch_to_password_login'.tr
                          : 'ចូលដោយប្រើឈ្មោះគណនី និងពាក្យសម្ងាត់',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF163774),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
