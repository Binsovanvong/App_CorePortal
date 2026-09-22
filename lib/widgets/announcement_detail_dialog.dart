import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows the Announcement Detail Dialog matching the design mockup:
/// - Rounded white card (28px border radius)
/// - Top-right circular close button (X)
/// - Centered custom illustration: document sheet + megaphone + sound rays + floating dots
/// - Centered soft blue pill badge: "សេចក្តីជូនដំណឹង"
/// - Centered clock icon + formatted Khmer datetime: "ថ្ងៃទី ១៧ ខែកញ្ញា ឆ្នាំ ២០២៦ ម៉ោង ០៥:០៥"
/// - Centered bold announcement title
/// - Subtle horizontal divider
/// - Left-aligned clean announcement content
/// - Full-width vibrant blue "បិទ" (Close) button
void showAnnouncementDetailDialog(
  BuildContext context,
  Map<String, dynamic> announcement,
) {
  final String title = (announcement['title'] ??
          announcement['titleEn'] ??
          announcement['subject'] ??
          'announcement'.tr)
      .toString();

  final String rawContent = (announcement['content'] ??
          announcement['contentKh'] ??
          announcement['description'] ??
          announcement['body'] ??
          '')
      .toString();

  final String cleanContent = rawContent
      .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final String rawTime = (announcement['createdAt'] ??
          announcement['created_at'] ??
          announcement['publishStartAt'] ??
          announcement['date'] ??
          announcement['time'] ??
          '')
      .toString();

  final String formattedDateTime = formatDetailKhmerDateTime(rawTime);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              // Top-right Close (X) Button
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Main Dialog Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    // Centered Illustration (Document + Megaphone + Floating dots)
                    const _AnnouncementDetailIllustration(),
                    const SizedBox(height: 14),

                    // Soft Blue Pill Badge: "សេចក្តីជូនដំណឹង"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'announcement'.tr,
                        style: GoogleFonts.kantumruyPro(
                          color: const Color(0xFF2563EB),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date & Time Row with clock icon
                    if (formattedDateTime.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDateTime,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Announcement Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtle Divider
                    const Divider(
                      height: 1,
                      color: Color(0xFFF1F5F9),
                      thickness: 1.2,
                    ),
                    const SizedBox(height: 14),

                    // Clean Content
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            cleanContent.isNotEmpty ? cleanContent : '...',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 14.5,
                              color: const Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full-width Vibrant Blue Close Button: "បិទ"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          'close'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
  );
}

/// Formats datetime to Khmer string: "ថ្ងៃទី ១៧ ខែកញ្ញា ឆ្នាំ ២០២៦ ម៉ោង ០៥:០៥"
String formatDetailKhmerDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final dateTime = DateTime.tryParse(dateStr)?.toLocal();
    if (dateTime == null) return dateStr;

    const khmerMonths = [
      'មករា',
      'កុម្ភៈ',
      'មីនា',
      'មេសា',
      'ឧសភា',
      'មិថុនា',
      'កក្កដា',
      'សីហា',
      'កញ្ញា',
      'តុលា',
      'វិច្ឆិកា',
      'ធ្នូ',
    ];

    String toKhmer(String input) {
      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
      String res = input;
      for (int i = 0; i < english.length; i++) {
        res = res.replaceAll(english[i], khmer[i]);
      }
      return res;
    }

    final day = toKhmer(dateTime.day.toString());
    final month = khmerMonths[dateTime.month - 1];
    final year = toKhmer(dateTime.year.toString());
    final hour = toKhmer(dateTime.hour.toString().padLeft(2, '0'));
    final minute = toKhmer(dateTime.minute.toString().padLeft(2, '0'));

    return 'ថ្ងៃទី $day ខែ$month ឆ្នាំ $year ម៉ោង $hour:$minute';
  } catch (_) {
    return dateStr;
  }
}

/// Custom illustration matching the dialog mockup:
/// Circle background with paper document sheet + angled 3D megaphone + sound rays + floating dots
class _AnnouncementDetailIllustration extends StatelessWidget {
  const _AnnouncementDetailIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background soft pastel circle
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F6FF),
              shape: BoxShape.circle,
            ),
          ),

          // Decorative floating dots
          Positioned(
            top: 6,
            right: 18,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFBFDBFE),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 6,
            child: Container(
              width: 13,
              height: 13,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 18,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFED7AA),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            right: 12,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Custom Painted Document Sheet & Megaphone with sound rays
          CustomPaint(
            size: const Size(90, 84),
            painter: _AnnouncementIllustrationPainter(),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Document sheet dimensions
    const double docW = 42;
    const double docH = 54;
    final double docX = cx - docW / 2 - 8;
    final double docY = cy - docH / 2 - 2;
    const double fold = 10;

    // Document path with folded top-right corner
    final docPath = Path()
      ..moveTo(docX + 6, docY)
      ..lineTo(docX + docW - fold, docY)
      ..lineTo(docX + docW, docY + fold)
      ..lineTo(docX + docW, docY + docH - 6)
      ..arcToPoint(Offset(docX + docW - 6, docY + docH),
          radius: const Radius.circular(6))
      ..lineTo(docX + 6, docY + docH)
      ..arcToPoint(Offset(docX, docY + docH - 6),
          radius: const Radius.circular(6))
      ..lineTo(docX, docY + 6)
      ..arcToPoint(Offset(docX + 6, docY), radius: const Radius.circular(6))
      ..close();

    final docFill = Paint()..color = Colors.white;
    final docStroke = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawPath(docPath, docFill);
    canvas.drawPath(docPath, docStroke);

    // Dog ear fold line
    final foldPath = Path()
      ..moveTo(docX + docW - fold, docY)
      ..lineTo(docX + docW - fold, docY + fold)
      ..lineTo(docX + docW, docY + fold);
    canvas.drawPath(foldPath, docStroke);

    // 3 blue content lines
    final linePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(docX + 9, docY + 18), Offset(docX + 26, docY + 18), linePaint);
    canvas.drawLine(
        Offset(docX + 9, docY + 26), Offset(docX + 32, docY + 26), linePaint);
    canvas.drawLine(
        Offset(docX + 9, docY + 34), Offset(docX + 21, docY + 34), linePaint);

    // Megaphone in foreground
    canvas.save();
    canvas.translate(cx + 8, cy + 8);
    canvas.rotate(-16 * 3.14159265 / 180);

    // Megaphone Cone
    final hornPath = Path()
      ..moveTo(-15, -6)
      ..lineTo(14, -17)
      ..lineTo(14, 17)
      ..lineTo(-15, 6)
      ..close();

    final hornPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
      ).createShader(const Rect.fromLTWH(-15, -17, 29, 34));
    canvas.drawPath(hornPath, hornPaint);

    // Megaphone Base cap
    final basePaint = Paint()..color = const Color(0xFF1E40AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-19, -7, 5.5, 14), const Radius.circular(2)),
      basePaint,
    );

    // Megaphone Handle
    final handlePath = Path()
      ..moveTo(-8, 7)
      ..lineTo(-5, 19)
      ..lineTo(-1, 18)
      ..lineTo(-3, 7)
      ..close();
    canvas.drawPath(handlePath, basePaint);

    // Front rim
    final rimPaint = Paint()..color = const Color(0xFF93C5FD);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(14, 0), width: 6, height: 34),
      rimPaint,
    );

    // Inner rim
    final innerRim = Paint()..color = const Color(0xFF60A5FA);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(14, 0), width: 3, height: 24),
      innerRim,
    );

    canvas.restore();

    // 3 Sound ray bursts in bright orange
    final rayPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    final rayCenter = Offset(cx + 28, cy + 4);
    // Top ray
    canvas.drawLine(Offset(rayCenter.dx + 4, rayCenter.dy - 12),
        Offset(rayCenter.dx + 12, rayCenter.dy - 16), rayPaint);
    // Middle ray
    canvas.drawLine(Offset(rayCenter.dx + 8, rayCenter.dy),
        Offset(rayCenter.dx + 17, rayCenter.dy), rayPaint);
    // Bottom ray
    canvas.drawLine(Offset(rayCenter.dx + 4, rayCenter.dy + 12),
        Offset(rayCenter.dx + 12, rayCenter.dy + 16), rayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
