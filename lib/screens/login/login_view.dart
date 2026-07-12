import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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

                  /// Centered Logo & Ministry text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              "assets/img/about-moi-logo.png",
                              width: 100,
                              height: 100,
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff8A6514),
                            ),
                          ),
                          Text(
                            "MINISTRY OF INTERIOR",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
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

                  /// Grey Login Container Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F5F9), // Light Grey Card
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: const Color(0xffE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Welcome Title & Subtitle
                        Text(
                          "ចូលប្រើប្រាស់ប្រព័ន្ធ",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "សូមបញ្ចូលគណនីរបស់អ្នកដើម្បីបន្តប្រើប្រាស់សេវាកម្ម",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14,
                            color: const Color(0xff64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// Form Fields
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Username Label
                            Text(
                              "ឈ្មោះអ្នកប្រើប្រាស់",
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Username Input
                            TextField(
                              controller: controller.usernameController,
                              style: GoogleFonts.kantumruyPro(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: "បញ្ចូលឈ្មោះអ្នកប្រើប្រាស់",
                                hintStyle: GoogleFonts.kantumruyPro(
                                  color: const Color(0xff94A3B8),
                                  fontSize: 15,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xff94A3B8),
                                ),
                                filled: true,
                                fillColor: Colors
                                    .white, // White inputs inside Grey Card
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
                                    color: Color(
                                      0xff8A6514,
                                    ), // Gold focused border
                                    width: 1.5,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// Password Label
                            Text(
                              "លេខសម្ងាត់",
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Password Input
                            Obx(
                              () => TextField(
                                controller: controller.passwordController,
                                obscureText: controller.obscurePassword.value,
                                style: GoogleFonts.kantumruyPro(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: "បញ្ចូលលេខសម្ងាត់",
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
                                      controller.obscurePassword.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xff94A3B8),
                                    ),
                                    onPressed: () {
                                      controller.obscurePassword.toggle();
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors
                                      .white, // White inputs inside Grey Card
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
                                      color: Color(
                                        0xff8A6514,
                                      ), // Gold focused border
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

                        /// Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.loginWithCredentials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xff6B5005,
                                ), // Olive gold color
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    30,
                                  ), // Rounded 30
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
                                      "ចូលប្រើប្រាស់",
                                      style: GoogleFonts.kantumruyPro(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  /// Footer Copyright
                  Text(
                    "© 2026 ក្រសួងមហាផ្ទៃ - ព្រះរាជាណាចក្រកម្ពុជា",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      color: const Color(0xff94A3B8),
                      fontWeight: FontWeight.w500,
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
}
