import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/theme/app_colors.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/screens/announcement/announcement_detail_controller.dart';

/// Announcement Detail View:
/// - Clean, elegant, view-only reading experience for announcement details
/// - Fetches live data from API via [AnnouncementDetailController]
/// - Pull-to-refresh support
/// - Top Bar: Back navigation chevron in Royal Gold + Title
/// - Announcement View Card:
///   * Squircle golden bell badge + Category/Priority pill
///   * Bold Khmer/English announcement title
///   * Metadata row: Calendar date/time · Department / Publisher
///   * Subtle gold divider
///   * Clean formatted announcement content paragraphs (view only, no upload file)
class AnnouncementDetailView extends StatefulWidget {
  final Map<String, dynamic>? announcement;
  final String? announcementId;

  const AnnouncementDetailView({
    super.key,
    this.announcement,
    this.announcementId,
  });

  @override
  State<AnnouncementDetailView> createState() => _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView> {
  late final AnnouncementDetailController controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag =
        widget.announcementId ??
        widget.announcement?['id']?.toString() ??
        widget.announcement?['uuid']?.toString() ??
        UniqueKey().toString();

    controller = Get.put(AnnouncementDetailController(), tag: _tag);
    controller.initData(widget.announcement, id: widget.announcementId);
  }

  @override
  void dispose() {
    if (Get.isRegistered<AnnouncementDetailController>(tag: _tag)) {
      Get.delete<AnnouncementDetailController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar: < សេចក្តីជូនដំណឹង
            _buildTopAppBar(context),

            // In-flight API loading indicator
            Obx(() {
              if (controller.isLoading.value &&
                  controller.announcement.isNotEmpty) {
                return const LinearProgressIndicator(
                  minHeight: 2.5,
                  color: AppColors.royalGold,
                  backgroundColor: AppColors.royalGoldLight,
                );
              }
              return const SizedBox.shrink();
            }),

            // Scrollable View-Only Content
            Expanded(
              child: Obx(() {
                // If loading with no cached data, display centered loading spinner
                if (controller.isLoading.value &&
                    controller.announcement.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.royalGold,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final data = controller.announcement;
                final bool isKh =
                    LocalizationService.currentLanguageCode.value == 'km';

                // 1. Title
                final String title = _resolveTitle(data, isKh);

                // 2. Content & Paragraphs
                final String rawContent = _resolveContent(data, isKh);
                final List<String> paragraphs = _extractParagraphs(rawContent);

                // 3. Formatted Date
                final String formattedDate = _formatDate(data, isKh);

                // 4. Department / Organization
                final String department =
                    (data['department'] ??
                            data['source'] ??
                            data['author'] ??
                            data['organization'] ??
                            data['publisher'] ??
                            (isKh ? 'ក្រសួងមហាផ្ទៃ' : 'Ministry of Interior'))
                        .toString();

                // 5. Category / Priority
                final String? category =
                    data['category']?.toString() ??
                    data['priority']?.toString();

                return RefreshIndicator(
                  onRefresh: () =>
                      controller.fetchDetailFromApi(isRefresh: true),
                  color: AppColors.royalGold,
                  backgroundColor: Colors.white,
                  displacement: 20,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: _buildDetailCard(
                      title: title,
                      paragraphs: paragraphs,
                      formattedDate: formattedDate,
                      department: department,
                      category: category,
                      isKh: isKh,
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

  /// Top Bar with left chevron in Royal Gold and title
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1E8DA), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Get.back();
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 19,
                  color: AppColors.royalGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'announcement'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean View-Only Announcement Detail Card
  Widget _buildDetailCard({
    required String title,
    required List<String> paragraphs,
    required String formattedDate,
    required String department,
    String? category,
    required bool isKh,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.warmCreamBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Squircle Bell Icon + Category Badge (if any)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.iconBeige,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmCreamBorder, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.royalGold,
                    size: 24,
                  ),
                ),
              ),
              if (category != null && category.trim().isNotEmpty)
                _buildCategoryPill(category.trim(), isKh),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2: Title
          Text(
            title,
            style: GoogleFonts.kantumruyPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 12),

          // Row 3: Metadata Row (Calendar + Date + · + Department)
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14.5,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (department.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text(
                  '·',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    department,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // Row 4: Subtle Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(
              color: AppColors.warmCreamBorder,
              height: 1,
              thickness: 1,
            ),
          ),

          // Row 5: View-Only Content Paragraphs
          if (paragraphs.isEmpty)
            Text(
              'no_announcements_yet_desc'.tr,
              style: GoogleFonts.kantumruyPro(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            )
          else
            ...paragraphs.map((para) {
              final isLast = para == paragraphs.last;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: SelectableText(
                  para,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14.5,
                    height: 1.75,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF334155),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Category / Priority Pill Badge
  Widget _buildCategoryPill(String cat, bool isKh) {
    final upper = cat.toUpperCase();

    Color bg;
    Color border;
    Color text;
    String label;

    if (upper == 'URGENT' || upper == 'IMPORTANT' || upper == 'បន្ទាន់') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
      label = isKh ? 'បន្ទាន់' : 'Urgent';
    } else if (upper == 'POLICY' || upper == 'គោលការណ៍') {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      text = const Color(0xFF2563EB);
      label = isKh ? 'គោលការណ៍' : 'Policy';
    } else if (upper == 'EVENT' || upper == 'ព្រឹត្តិការណ៍') {
      bg = const Color(0xFFFAF5FF);
      border = const Color(0xFFE9D5FF);
      text = const Color(0xFF7E22CE);
      label = isKh ? 'ព្រឹត្តិការណ៍' : 'Event';
    } else {
      bg = const Color(0xFFF6EEDB);
      border = const Color(0xFFEDE3CE);
      text = AppColors.royalGold;
      label = isKh ? 'ទូទៅ' : 'General';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.9),
      ),
      child: Text(
        label,
        style: GoogleFonts.kantumruyPro(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Methods for Formatting
  // ---------------------------------------------------------------------------

  String _resolveTitle(Map<String, dynamic> data, bool isKh) {
    if (isKh) {
      final kh = data['titleKh'] ?? data['title'] ?? data['subject'];
      if (kh != null && kh.toString().trim().isNotEmpty) {
        return kh.toString().trim();
      }
      return (data['titleEn'] ?? 'announcement'.tr).toString().trim();
    } else {
      final en = data['titleEn'];
      if (en != null && en.toString().trim().isNotEmpty) {
        return en.toString().trim();
      }
      return (data['title'] ?? data['titleKh'] ?? 'Announcement')
          .toString()
          .trim();
    }
  }

  String _resolveContent(Map<String, dynamic> data, bool isKh) {
    if (isKh) {
      final kh = data['contentKh'] ??
          data['content'] ??
          data['description'] ??
          data['body'];
      if (kh != null && kh.toString().trim().isNotEmpty) {
        return kh.toString().trim();
      }
      return (data['contentEn'] ?? '').toString().trim();
    } else {
      final en = data['contentEn'];
      if (en != null && en.toString().trim().isNotEmpty) {
        return en.toString().trim();
      }
      return (data['content'] ??
              data['contentKh'] ??
              data['description'] ??
              data['body'] ??
              '')
          .toString()
          .trim();
    }
  }

  List<String> _extractParagraphs(String raw) {
    if (raw.isEmpty) return [];

    // Replace HTML paragraph and break tags with newlines
    String clean = raw
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ');

    final split = clean
        .split(RegExp(r'\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (split.isEmpty) {
      return [clean.trim()];
    }
    return split;
  }

  String _formatDate(Map<String, dynamic> data, bool isKh) {
    if (isKh && data['displayDateKh'] != null) {
      return data['displayDateKh'].toString().trim();
    }
    if (!isKh && data['displayDateEn'] != null) {
      return data['displayDateEn'].toString().trim();
    }

    final raw = (data['date'] ??
            data['createdAt'] ??
            data['created_at'] ??
            data['publishStartAt'] ??
            data['time'] ??
            '')
        .toString();

    if (raw.isEmpty) {
      return isKh ? '២៧ តុលា ២០២៦' : '27 Oct 2026';
    }

    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;

      if (isKh) {
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

        String toKh(dynamic val) {
          const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
          const khm = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
          String s = val.toString();
          for (int i = 0; i < 10; i++) {
            s = s.replaceAll(eng[i], khm[i]);
          }
          return s;
        }

        final String khDay = toKh(dt.day);
        final String khMonth = khmerMonths[dt.month - 1];
        final String khYear = toKh(dt.year);

        return '$khDay $khMonth $khYear';
      } else {
        const englishMonths = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${dt.day} ${englishMonths[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {
      return raw;
    }
  }
}
