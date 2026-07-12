import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'first_login_change_password_controller.dart';

class FirstLoginChangePasswordView
    extends GetView<FirstLoginChangePasswordController> {
  const FirstLoginChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  /// Centered Logo & Ministry Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              "assets/img/about-moi-logo.png",
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ក្រសួងមហាផ្ទៃ",
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff8A6514),
                            ),
                          ),
                          Text(
                            "MINISTRY OF INTERIOR",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff8A6514),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  /// Page Title and Subtitle
                  Text(
                    "ផ្លាស់ប្តូរពាក្យសម្ងាត់",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "សម្រាប់គណនីចូលប្រើប្រាស់លើកដំបូង",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      color: const Color(0xff64748B),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Warning / Guidelines Alert Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFDF0), // Light yellow background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF6EBC2), // Gold border
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xffD4AF37),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "លោកអ្នកត្រូវផ្លាស់ប្តូរពាក្យសម្ងាត់ ដើម្បីដំណើរការគណនីរបស់អ្នក",
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8A6514),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBulletPoint(
                                "ពាក្យសម្ងាត់ថ្មីត្រូវមានយ៉ាងហោចណាស់ ៨ តួអក្សរ",
                              ),
                              _buildBulletPoint(
                                "ត្រូវមានអក្សរធំ អក្សរតូច លេខ និងសញ្ញាពិសេស",
                              ),
                              _buildBulletPoint(
                                "ជៀសវាងការប្រើឈ្មោះគណនី ថ្ងៃខែឆ្នាំកំណើត ឬពាក្យសម្ងាត់ចាស់។",
                              ),
                              _buildBulletPoint("ឧទាហរណ៍: m4ze*Q9!"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// Input Form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// New Password Label
                      Text(
                        "ពាក្យសម្ងាត់ថ្មី",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// New Password Input
                      Obx(
                        () => TextField(
                          controller: controller.newPasswordController,
                          obscureText: controller.obscureNewPassword.value,
                          style: GoogleFonts.kantumruyPro(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "បញ្ចូលពាក្យសម្ងាត់ថ្មី",
                            hintStyle: GoogleFonts.kantumruyPro(
                              color: const Color(0xff94A3B8),
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xff94A3B8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscureNewPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xff94A3B8),
                              ),
                              onPressed: () {
                                controller.obscureNewPassword.toggle();
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xffE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xff8A6514),
                                width: 1.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Confirm Password Label
                      Text(
                        "បញ្ជាក់ពាក្យសម្ងាត់ថ្មី",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// Confirm Password Input
                      Obx(
                        () => TextField(
                          controller: controller.confirmPasswordController,
                          obscureText: controller.obscureConfirmPassword.value,
                          style: GoogleFonts.kantumruyPro(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "បញ្ចូលពាក្យសម្ងាត់ថ្មីម្តងទៀត",
                            hintStyle: GoogleFonts.kantumruyPro(
                              color: const Color(0xff94A3B8),
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xff94A3B8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscureConfirmPassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xff94A3B8),
                              ),
                              onPressed: () {
                                controller.obscureConfirmPassword.toggle();
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xffE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xff8A6514),
                                width: 1.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.submitPasswordChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xff6B5005,
                          ), // Olive gold background
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "រក្សាទុកពាក្យសម្ងាត់",
                                style: GoogleFonts.kantumruyPro(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  /// Footer Copyright Text
                  Text(
                    "© 2026 ក្រសួងមហាផ្ទៃ - ព្រះរាជាណាចក្រកម្ពុជា",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 11,
                      color: const Color(0xff94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "- ",
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              color: const Color(0xFF8A6514),
              height: 1.4,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                color: const Color(0xFF8A6514),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
