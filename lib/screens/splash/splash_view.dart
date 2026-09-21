import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF163774),
      body: GestureDetector(
        onTap: controller.skip,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // ── 1. Clean Royal Navy Gradient Background ────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A3E82), // Top Royal Blue
                        Color(0xFF163774), // Primary Navy
                        Color(0xFF0F2550), // Deep Midnight Navy
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // ── 2. Subtle Radial Light Accent Behind Emblem ────────────
              Positioned(
                top: size.height * 0.13,
                left: (size.width - 320) / 2,
                width: 320,
                height: 320,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2E65BF).withOpacity(0.35),
                          const Color(0xFF224E97).withOpacity(0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Main Content (Logo, Typography, Progress, Footer) ───
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Animated Entry for Emblem & Ministry Title
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.92 + (0.08 * value),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Official MOI Circular Badge (Enlarged & Prominent)
                            Container(
                              width: 188,
                              height: 188,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 4.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withOpacity(0.32),
                                    blurRadius: 30,
                                    spreadRadius: 2.0,
                                    offset: const Offset(0, 5),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.28),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFEAB308).withOpacity(0.45),
                                    width: 1.4,
                                  ),
                                ),
                                padding: const EdgeInsets.all(5.0),
                                child: ClipOval(
                                  child: Image.asset(
                                    "assets/img/about-moi-logo.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Ministry Title (ក្រសួងមហាផ្ទៃ)
                            Text(
                              'ministry_title'.tr.isNotEmpty
                                  ? 'ministry_title'.tr
                                  : 'ក្រសួងមហាផ្ទៃ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),

                            // System Subtitle (ប្រព័ន្ធច្រកចេញចូលតែមួយ)
                            Text(
                              'app_title'.tr.isNotEmpty
                                  ? 'app_title'.tr
                                  : 'ប្រព័ន្ធច្រកចេញចូលតែមួយ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFE5C058),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Fine Gold Accent Line
                            Container(
                              width: 38,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.65),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Loading Progress Bar & Status Text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Modern Pill Progress Bar Track & Indicator
                          Container(
                            width: 160,
                            height: 4.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Obx(
                              () => Container(
                                width: 160 *
                                    controller.progress.value.clamp(0.0, 1.0),
                                height: 4.0,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE5C058),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Status Text (កំពុងដំណើរការ...)
                          Obx(
                            () => Text(
                              controller.statusText.value,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Footer Motto: ប្រទេសជាតិ • ប្រជាជន • សន្តិសុខ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'nation'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.90),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFD4AF37).withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'people_motto'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.90),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFD4AF37).withOpacity(0.6),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            'security_motto'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.90),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Subtle Golden Lotus Divider: ──── 🪷 ────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFD4AF37).withOpacity(0.0),
                                  const Color(0xFFD4AF37).withOpacity(0.55),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomPaint(
                            size: const Size(18, 12),
                            painter: _KhmerLotusIconPainter(
                              color: const Color(0xFFD4AF37).withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFD4AF37).withOpacity(0.55),
                                  const Color(0xFFD4AF37).withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: bottomPadding > 0 ? 12 : 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Traditional Khmer Lotus Icon Painter ───────────────────────────────────

class _KhmerLotusIconPainter extends CustomPainter {
  final Color color;

  _KhmerLotusIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Central Lotus Bud Petal
    final centerPath = Path();
    centerPath.moveTo(w * 0.50, h * 0.05);
    centerPath.quadraticBezierTo(w * 0.62, h * 0.45, w * 0.50, h * 0.95);
    centerPath.quadraticBezierTo(w * 0.38, h * 0.45, w * 0.50, h * 0.05);
    centerPath.close();
    canvas.drawPath(centerPath, paint);

    // Left Petal
    final leftPath = Path();
    leftPath.moveTo(w * 0.45, h * 0.90);
    leftPath.cubicTo(w * 0.15, h * 0.60, w * 0.10, h * 0.25, w * 0.20, h * 0.30);
    leftPath.quadraticBezierTo(w * 0.32, h * 0.50, w * 0.45, h * 0.90);
    leftPath.close();
    canvas.drawPath(leftPath, paint);

    // Right Petal
    final rightPath = Path();
    rightPath.moveTo(w * 0.55, h * 0.90);
    rightPath.cubicTo(w * 0.85, h * 0.60, w * 0.90, h * 0.25, w * 0.80, h * 0.30);
    rightPath.quadraticBezierTo(w * 0.68, h * 0.50, w * 0.55, h * 0.90);
    rightPath.close();
    canvas.drawPath(rightPath, paint);

    // Small Lotus Base Pod
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.92),
        width: w * 0.35,
        height: h * 0.14,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
