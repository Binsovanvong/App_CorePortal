import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/reset_password/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 17,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Lock Icon in circular light blue container
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF2563EB),
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Screen Title
                    Text(
                      'កំណត់ពាក្យសម្ងាត់ថ្មី',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'សូមបញ្ចូលពាក្យសម្ងាត់ថ្មី និងបញ្ជាក់ពាក្យសម្ងាត់\nដើម្បីកំណត់ឡើងវិញ',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Field 1: New Password
                    Text(
                      'ពាក្យសម្ងាត់ថ្មី',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
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
                        ),
                        child: TextField(
                          controller: controller.newPasswordController,
                          obscureText: !controller.isNewPasswordVisible.value,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'បញ្ចូលពាក្យសម្ងាត់ថ្មី',
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
                    const SizedBox(height: 20),

                    // Field 2: Confirm Password
                    Text(
                      'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
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
                        ),
                        child: TextField(
                          controller: controller.confirmPasswordController,
                          obscureText: !controller.isConfirmPasswordVisible.value,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'បញ្ចូលពាក្យសម្ងាត់ម្ដងទៀត',
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
                    const SizedBox(height: 24),

                    // Requirements Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'តម្រូវការពាក្យសម្ងាត់',
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildRequirementBullet('• យ៉ាងហោចណាស់ 8 តួអក្សរ'),
                          _buildRequirementBullet(
                            '• មានអក្សរទាំងពីរប្រភេទ (អក្សរតូច និងអក្សរធំ)',
                          ),
                          _buildRequirementBullet('• មានលេខ (0-9)'),
                          _buildRequirementBullet(
                            '• មានតួអក្សរពិសេស (ឧ. !@#...)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            // Bottom Submit Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Obx(() {
                final bool loading = controller.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : controller.submitResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
                                'កំណត់ពាក្យសម្ងាត់ថ្មី',
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 15,
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
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.kantumruyPro(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF475569),
          height: 1.5,
        ),
      ),
    );
  }
}
