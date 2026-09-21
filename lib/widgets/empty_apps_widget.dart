import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium empty state widget for applications matching the Ministry of Interior portal design.
/// Displays "អត់ទាន់មានកម្មវិធី" (No Applications Yet) or "រកមិនឃើញកម្មវិធីឡើយ" (No applications found).
class EmptyAppsWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool isSearch;
  final bool isCompact;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyAppsWidget({
    super.key,
    this.title,
    this.subtitle,
    this.isSearch = false,
    this.isCompact = false,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final String effectiveTitle = title ??
        (isSearch ? 'no_applications_found'.tr : 'no_applications_yet'.tr);

    final String effectiveSubtitle = subtitle ??
        (isSearch
            ? 'no_search_results_desc'.tr
            : 'no_applications_yet_desc'.tr);

    final String effectiveActionText = actionText ??
        (isSearch ? 'clear_filters'.tr : 'refresh'.tr);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 22 : 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Custom Canvas Vector Illustration
          _EmptyAppsIllustration(
            isSearch: isSearch,
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 14 : 20),

          // Title
          Text(
            effectiveTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.kantumruyPro(
              fontSize: isCompact ? 16 : 18.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F265C),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle / Description
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isCompact ? 280 : 340),
            child: Text(
              effectiveSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.kantumruyPro(
                fontSize: isCompact ? 12.5 : 13.5,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),

          // Interactive Action Button
          if (onAction != null) ...[
            SizedBox(height: isCompact ? 14 : 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 18 : 22,
                    vertical: isCompact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1D4ED8),
                        Color(0xFF163774),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSearch
                            ? Icons.filter_alt_off_rounded
                            : Icons.refresh_rounded,
                        color: Colors.white,
                        size: isCompact ? 15 : 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        effectiveActionText,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: isCompact ? 12.5 : 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom vector illustration with layered app tiles and golden accents
class _EmptyAppsIllustration extends StatelessWidget {
  final bool isSearch;
  final bool isCompact;

  const _EmptyAppsIllustration({
    required this.isSearch,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isCompact ? 84 : 110;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyAppsPainter(
          isSearch: isSearch,
        ),
      ),
    );
  }
}

class _EmptyAppsPainter extends CustomPainter {
  final bool isSearch;

  _EmptyAppsPainter({required this.isSearch});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    // 1. Soft Ambient Circular Halo
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFDBEAFE).withOpacity(0.65),
          const Color(0xFFEFF6FF).withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.48));
    canvas.drawCircle(center, w * 0.48, auraPaint);

    // 2. Sparkles (Gold stars)
    _drawSparkle(canvas, Offset(w * 0.86, h * 0.20), 4.5, const Color(0xFFD4AF37));
    _drawSparkle(canvas, Offset(w * 0.12, h * 0.70), 3.5, const Color(0xFFD4AF37));
    _drawSparkle(canvas, Offset(w * 0.18, h * 0.22), 3.0, const Color(0xFF60A5FA));

    // Small floating dots
    final dotPaint1 = Paint()..color = const Color(0xFF93C5FD).withOpacity(0.7);
    canvas.drawCircle(Offset(w * 0.82, h * 0.78), 2.5, dotPaint1);
    final dotPaint2 = Paint()..color = const Color(0xFFD4AF37).withOpacity(0.5);
    canvas.drawCircle(Offset(w * 0.24, h * 0.85), 2.0, dotPaint2);

    // 3. Central Rounded Dashboard Tablet / Base Slab
    final slabWidth = w * 0.68;
    final slabHeight = h * 0.68;
    final slabRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: slabWidth, height: slabHeight),
      Radius.circular(w * 0.18),
    );

    // Slab drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF163774).withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(slabRect.shift(const Offset(0, 4)), shadowPaint);

    // Slab body
    final slabPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF1F5F9)],
      ).createShader(slabRect.outerRect);
    canvas.drawRRect(slabRect, slabPaint);

    // Slab border
    final slabBorderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawRRect(slabRect, slabBorderPaint);

    // 4. 2x2 Grid of Mini App Tiles
    final double tileGap = w * 0.04;
    final double tileSize = (slabWidth - w * 0.16 - tileGap) / 2;
    final double startX = center.dx - slabWidth / 2 + w * 0.08;
    final double startY = center.dy - slabHeight / 2 + h * 0.08;
    final double tileRadius = tileSize * 0.32;

    // Tile (0,0): Royal Blue Document App
    final r00 = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, startY, tileSize, tileSize),
      Radius.circular(tileRadius),
    );
    final p00 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      ).createShader(r00.outerRect);
    canvas.drawRRect(r00, p00);
    // Mini glyph lines in Tile (0,0)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(startX + tileSize * 0.25, startY + tileSize * 0.35),
      Offset(startX + tileSize * 0.75, startY + tileSize * 0.35),
      linePaint,
    );
    canvas.drawLine(
      Offset(startX + tileSize * 0.25, startY + tileSize * 0.52),
      Offset(startX + tileSize * 0.70, startY + tileSize * 0.52),
      linePaint,
    );
    canvas.drawLine(
      Offset(startX + tileSize * 0.25, startY + tileSize * 0.69),
      Offset(startX + tileSize * 0.55, startY + tileSize * 0.69),
      linePaint,
    );

    // Tile (1,0): Emerald Green Shield/Check App
    final r10 = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX + tileSize + tileGap, startY, tileSize, tileSize),
      Radius.circular(tileRadius),
    );
    final p10 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(r10.outerRect);
    canvas.drawRRect(r10, p10);
    // Mini checkmark in Tile (1,0)
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path();
    final cX = startX + tileSize + tileGap;
    checkPath.moveTo(cX + tileSize * 0.30, startY + tileSize * 0.50);
    checkPath.lineTo(cX + tileSize * 0.45, startY + tileSize * 0.66);
    checkPath.lineTo(cX + tileSize * 0.72, startY + tileSize * 0.34);
    canvas.drawPath(checkPath, checkPaint);

    // Tile (0,1): Amber Golden Star App
    final r01 = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, startY + tileSize + tileGap, tileSize, tileSize),
      Radius.circular(tileRadius),
    );
    final p01 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(r01.outerRect);
    canvas.drawRRect(r01, p01);
    // Mini star glyph in Tile (0,1)
    _drawStarGlyph(
      canvas,
      Offset(startX + tileSize * 0.5, startY + tileSize + tileGap + tileSize * 0.5),
      tileSize * 0.28,
      Colors.white,
    );

    // Tile (1,1): Empty / Search slot
    final r11 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        startX + tileSize + tileGap,
        startY + tileSize + tileGap,
        tileSize,
        tileSize,
      ),
      Radius.circular(tileRadius),
    );

    if (isSearch) {
      // Search slot: Soft indigo background with magnifying glass
      final p11 = Paint()..color = const Color(0xFFEFF6FF);
      canvas.drawRRect(r11, p11);
      final border11 = Paint()
        ..color = const Color(0xFF93C5FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(r11, border11);

      // Mini magnifying glass inside
      final searchGlassPaint = Paint()
        ..color = const Color(0xFF1D4ED8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final glassCenter = Offset(
        startX + tileSize + tileGap + tileSize * 0.45,
        startY + tileSize + tileGap + tileSize * 0.45,
      );
      canvas.drawCircle(glassCenter, tileSize * 0.18, searchGlassPaint);
      canvas.drawLine(
        Offset(glassCenter.dx + tileSize * 0.12, glassCenter.dy + tileSize * 0.12),
        Offset(glassCenter.dx + tileSize * 0.26, glassCenter.dy + tileSize * 0.26),
        searchGlassPaint..strokeCap = StrokeCap.round,
      );
    } else {
      // Empty slot: Dashed border with subtle plus sign
      final p11 = Paint()..color = const Color(0xFFF8FAFC);
      canvas.drawRRect(r11, p11);

      _drawDashedRRect(
        canvas,
        r11,
        const Color(0xFF94A3B8),
        strokeWidth: 1.1,
      );

      // Soft plus sign
      final plusPaint = Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final pX = startX + tileSize + tileGap + tileSize * 0.5;
      final pY = startY + tileSize + tileGap + tileSize * 0.5;
      final pLen = tileSize * 0.20;
      canvas.drawLine(Offset(pX - pLen, pY), Offset(pX + pLen, pY), plusPaint);
      canvas.drawLine(Offset(pX, pY - pLen), Offset(pX, pY + pLen), plusPaint);
    }

    // 5. Floating Badge on the Bottom-Right
    final badgeRadius = w * 0.15;
    final badgeCenter = Offset(
      center.dx + slabWidth * 0.42,
      center.dy + slabHeight * 0.42,
    );

    // Badge shadow
    final badgeShadow = Paint()
      ..color = const Color(0xFF0F265C).withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(badgeCenter.translate(0, 2), badgeRadius, badgeShadow);

    // Badge background
    final badgePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF163774), Color(0xFF0F265C)],
      ).createShader(Rect.fromCircle(center: badgeCenter, radius: badgeRadius));
    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    // Badge gold rim
    final badgeRimPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeRimPaint);

    // Badge icon / symbol inside
    if (isSearch) {
      // Question mark / search symbol
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final qPath = Path();
      qPath.moveTo(badgeCenter.dx - badgeRadius * 0.35, badgeCenter.dy - badgeRadius * 0.30);
      qPath.cubicTo(
        badgeCenter.dx - badgeRadius * 0.35,
        badgeCenter.dy - badgeRadius * 0.65,
        badgeCenter.dx + badgeRadius * 0.35,
        badgeCenter.dy - badgeRadius * 0.65,
        badgeCenter.dx + badgeRadius * 0.35,
        badgeCenter.dy - badgeRadius * 0.25,
      );
      qPath.lineTo(badgeCenter.dx, badgeCenter.dy + badgeRadius * 0.05);
      canvas.drawPath(qPath, iconPaint);
      canvas.drawCircle(
        Offset(badgeCenter.dx, badgeCenter.dy + badgeRadius * 0.38),
        1.1,
        Paint()..color = Colors.white,
      );
    } else {
      // 4 tiny grid dots / app symbol in white & gold
      final dotP = Paint()..color = const Color(0xFFD4AF37);
      final r = badgeRadius * 0.18;
      final off = badgeRadius * 0.32;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(badgeCenter.dx - off, badgeCenter.dy - off), width: r * 2, height: r * 2),
          const Radius.circular(1.5),
        ),
        dotP,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(badgeCenter.dx + off, badgeCenter.dy - off), width: r * 2, height: r * 2),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(badgeCenter.dx - off, badgeCenter.dy + off), width: r * 2, height: r * 2),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(badgeCenter.dx + off, badgeCenter.dy + off), width: r * 2, height: r * 2),
          const Radius.circular(1.5),
        ),
        dotP,
      );
    }
  }

  void _drawSparkle(Canvas canvas, Offset pos, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(pos.dx, pos.dy - r);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + r, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + r);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - r, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - r);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStarGlyph(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const int points = 5;
    final double innerRadius = radius * 0.45;
    double step = math.pi / points;
    double angle = -math.pi / 2;

    for (int i = 0; i < 2 * points; i++) {
      double r = (i % 2 == 0) ? radius : innerRadius;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Color color, {
    double strokeWidth = 1.0,
    double dashWidth = 3.0,
    double dashSpace = 3.0,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyAppsPainter oldDelegate) =>
      oldDelegate.isSearch != isSearch;
}
