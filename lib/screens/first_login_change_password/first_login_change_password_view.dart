import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'first_login_change_password_controller.dart';

class FirstLoginChangePasswordView
    extends GetView<FirstLoginChangePasswordController> {
  const FirstLoginChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF163774),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: isKeyboardOpen
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
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
                          Expanded(
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 6,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Ministry Emblem
                                      Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFD4AF37),
                                            width: 2.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.20,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(3.5),
                                        child: ClipOval(
                                          child: Image.asset(
                                            "assets/img/about-moi-logo.png",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Ministry Title (Royal Gold Khmer)
                                      Text(
                                        'ក្រសួងមហាផ្ទៃ',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFD4AF37),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Ministry Subtitle (English - Royal Gold / Champagne)
                                      Text(
                                        'MINISTRY OF INTERIOR',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFDFBC66),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // White Rounded Bottom Card Container
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
                                  color: Color(0x14000000),
                                  blurRadius: 20,
                                  offset: Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              16,
                              20,
                              bottomSafeArea > 0 ? bottomSafeArea + 6 : 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Page Title and Subtitle (Centered)
                                Center(
                                  child: Text(
                                    'change_password'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Center(
                                  child: Text(
                                    'for_first_login'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Guidelines Box (Warm Amber Card with Exclamation Badge)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF9EE),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Circular Warning Icon Badge with Exclamation Mark
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDE047)
                                              .withValues(alpha: 0.75),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.45),
                                            width: 1.0,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          '!',
                                          style: TextStyle(
                                            color: Color(0xFF92400E),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Guideline Text Rules
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'must_change_password'.tr,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF92400E),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'password_guideline_rule1'.tr,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF92400E),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 1.5),
                                            Text(
                                              'password_guideline_rule2'.tr,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF92400E),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 1.5),
                                            Text(
                                              'password_guideline_rule3'.tr,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF92400E),
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'password_guideline_example'.tr,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF92400E),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Current Password Label & Field (when not passed in route arguments and not in ticket flow)
                                if (controller.ticket == null && controller.tempPassword.isEmpty) ...[
                                  Text(
                                    'current_password'.tr,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Obx(
                                    () => TextField(
                                      controller:
                                          controller.currentPasswordController,
                                      obscureText: controller
                                          .obscureCurrentPassword.value,
                                      textInputAction: TextInputAction.next,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 14.5,
                                        color: const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'enter_current_password_hint'.tr,
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
                                            controller.obscureCurrentPassword
                                                    .value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF94A3B8),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            controller.obscureCurrentPassword
                                                .toggle();
                                          },
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF163774),
                                            width: 2.0,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                ],

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
                                        ).withValues(alpha: 0.65),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                        shadowColor: const Color(
                                          0xFF163774,
                                        ).withValues(alpha: 0.4),
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

                                const SizedBox(height: 12),

                                // Cancel / Return to Login Button
                                Center(
                                  child: TextButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.cancelAndReturnToLogin,
                                    child: Text(
                                      'cancel'.tr,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Subtle Curved Light Blue Wave Lines in Navy Background (matching login)
class _WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paint2 = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paint3 = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.14)
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
