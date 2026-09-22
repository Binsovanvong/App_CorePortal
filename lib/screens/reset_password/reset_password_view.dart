import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/reset_password/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with circular back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // Header Section: Title + Subtitle on Left, 3D Lock on Right
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Soft decorative ambient blob behind lock illustration
                        Positioned(
                          right: -10,
                          top: -15,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFDBEAFE).withValues(alpha: 0.6),
                                  const Color(0xFFEFF6FF).withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 120,
                          top: 10,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE).withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 18,
                          top: 10,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBFDBFE).withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Header Content Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    'reset_password_title'.tr,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F1E36),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'reset_password_subtitle'.tr,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3D Padlock Illustration
                            Container(
                              width: 110,
                              height: 110,
                              margin: const EdgeInsets.only(left: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/img/reset_password_lock.jpg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Security Tip Notice Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'account_security_tip'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Field 1: New Password
                    Text(
                      'new_password_label'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller.newPasswordController,
                          obscureText: !controller.isNewPasswordVisible.value,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'enter_new_password_hint'.tr,
                            hintStyle: GoogleFonts.kantumruyPro(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isNewPasswordVisible.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: controller.toggleNewPasswordVisibility,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Password Strength Segmented Indicator
                    Obx(() {
                      final score = controller.passwordStrengthScore;
                      final color = controller.passwordStrengthColor;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(4, (index) {
                              final isActive = index < score;
                              return Expanded(
                                child: Container(
                                  height: 5,
                                  margin: EdgeInsets.only(
                                    right: index < 3 ? 6.0 : 0.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? color
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${'password_strength'.tr} ',
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                controller.passwordStrengthLabel,
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 18),

                    // Field 2: Confirm Password
                    Text(
                      'confirm_new_password_label'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller.confirmPasswordController,
                          obscureText: !controller.isConfirmPasswordVisible.value,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'enter_confirm_password_hint'.tr,
                            hintStyle: GoogleFonts.kantumruyPro(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isConfirmPasswordVisible.value
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: controller.toggleConfirmPasswordVisibility,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Password Requirements Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0EDFD),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1D6EEB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.verified_user_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'password_characteristics'.tr,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1D6EEB),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'password_characteristics_desc'.tr,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Checklist & Document Graphic
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Checklist on Left
                              Expanded(
                                flex: 6,
                                child: Obx(() {
                                  return Column(
                                    children: [
                                      _buildChecklistRow(
                                        'req_min_8_chars'.tr,
                                        controller.hasMinLength,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildChecklistRow(
                                        'req_both_cases'.tr,
                                        controller.hasBothCases,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildChecklistRow(
                                        'req_numbers'.tr,
                                        controller.hasNumber,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildChecklistRow(
                                        'req_special_chars'.tr,
                                        controller.hasSpecialChar,
                                      ),
                                    ],
                                  );
                                }),
                              ),

                              // Document Graphic & Floating Accent Dots on Right
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  height: 110,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Top right blue dot
                                      Positioned(
                                        top: 2,
                                        right: 10,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3B82F6),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // Left blue dot
                                      Positioned(
                                        left: 0,
                                        top: 55,
                                        child: Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF60A5FA),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // Bottom right amber dot
                                      Positioned(
                                        bottom: 6,
                                        right: 18,
                                        child: Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFBBF24),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // 3D Document Illustration
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.asset(
                                          'assets/img/security_card_doc.jpg',
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Submit Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Obx(() {
                final bool loading = controller.isLoading.value;
                return Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: loading ? null : controller.submitResetPassword,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'btn_reset_password'.tr,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String text, bool isMet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isMet ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.check_rounded,
              size: 13,
              color: isMet ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? const Color(0xFF0F172A) : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
