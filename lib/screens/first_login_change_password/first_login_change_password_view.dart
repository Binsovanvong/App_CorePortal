import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'first_login_change_password_controller.dart';

class FirstLoginChangePasswordView
    extends GetView<FirstLoginChangePasswordController> {
  const FirstLoginChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF163774),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF163774), Color(0xFF102652)],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _WaveBackgroundPainter(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Navy Section (Ministry Emblem & Golden Titles)
                        Container(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight * 0.38,
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 12),
                                  // Ministry Emblem
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37),
                                        width: 3.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.20),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: ClipOval(
                                      child: Image.asset(
                                        "assets/img/about-moi-logo.png",
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Ministry Title (Golden Khmer Text)
                                  Text(
                                    'ministry_title'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF1B722),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Subtitle (Soft Gold Text)
                                  Text(
                                    'portal_subtitle'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFDFBC66),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // White Rounded Bottom Card Container
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 20,
                                  offset: Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(
                              24,
                              28,
                              24,
                              bottomInset > 0 ? bottomInset + 20 : 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Page Title and Subtitle
                                Text(
                                  'change_password'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'for_first_login'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Guidelines Box (Soft Navy Tint)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        color: Color(0xFF163774),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'password_guideline'.tr,
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF163774),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // New Password Label & Field
                                Text(
                                  'new_password'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => TextField(
                                    controller: controller.newPasswordController,
                                    obscureText: controller.obscureNewPassword.value,
                                    textInputAction: TextInputAction.next,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 14.5,
                                      color: const Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'enter_new_password'.tr,
                                      hintStyle: GoogleFonts.kantumruyPro(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 21,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.obscureNewPassword.value
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF94A3B8),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          controller.obscureNewPassword.toggle();
                                        },
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF163774),
                                          width: 2.0,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Confirm Password Label & Field
                                Text(
                                  'confirm_new_password'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => TextField(
                                    controller: controller.confirmPasswordController,
                                    obscureText:
                                        controller.obscureConfirmPassword.value,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!controller.isLoading.value) {
                                        controller.submitPasswordChange();
                                      }
                                    },
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 14.5,
                                      color: const Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'enter_confirm_password'.tr,
                                      hintStyle: GoogleFonts.kantumruyPro(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 21,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          controller.obscureConfirmPassword.value
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF94A3B8),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          controller.obscureConfirmPassword.toggle();
                                        },
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF163774),
                                          width: 2.0,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Submit Button (Ministry Navy)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: Obx(
                                    () => ElevatedButton(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : controller.submitPasswordChange,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF163774),
                                        disabledBackgroundColor: const Color(
                                          0xFF163774,
                                        ).withOpacity(0.65),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                        shadowColor: const Color(
                                          0xFF163774,
                                        ).withOpacity(0.4),
                                      ),
                                      child: controller.isLoading.value
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.4,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '${'save'.tr} ${'password'.tr}',
                                                  style: GoogleFonts.kantumruyPro(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 19,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Footer Copyright Text
                                Center(
                                  child: Text(
                                    'copyright'.tr,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Subtle Curved Light Blue Wave Lines in Navy Background (matching login)
class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paint2 = Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paint3 = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Wave 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.22);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.16,
      size.width * 0.65,
      size.height * 0.30,
      size.width,
      size.height * 0.20,
    );
    canvas.drawPath(path1, paint1);

    // Wave 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.27);
    path2.cubicTo(
      size.width * 0.28,
      size.height * 0.21,
      size.width * 0.72,
      size.height * 0.35,
      size.width,
      size.height * 0.25,
    );
    canvas.drawPath(path2, paint2);

    // Wave 3
    final path3 = Path();
    path3.moveTo(0, size.height * 0.32);
    path3.cubicTo(
      size.width * 0.40,
      size.height * 0.25,
      size.width * 0.60,
      size.height * 0.38,
      size.width,
      size.height * 0.30,
    );
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
