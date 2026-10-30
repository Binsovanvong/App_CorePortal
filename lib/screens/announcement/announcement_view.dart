import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/announcement/announcement_controller.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/widgets/announcement_detail_dialog.dart';
import 'package:core_portal/widgets/portal_top_app_bar.dart';
import 'package:core_portal/theme/app_colors.dart';

class AnnouncementView extends GetView<AnnouncementController> {
  const AnnouncementView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    final bool isAdmin = Get.arguments == 'admin' ||
        (Get.isRegistered<NavController>() &&
            Get.find<NavController>().isAdmin.value);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFAF9F6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Government Portal Header
            PortalTopAppBar(canPop: canPop),

              // Scrollable Body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (isAdmin) {
                      await controller.fetchAdminAnnouncements();
                    } else {
                      await controller.fetchAnnouncements();
                    }
                  },
                  color: AppColors.royalGold,
                  backgroundColor: Colors.white,
                  displacement: 24,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() {
                        final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
                        final String selectedTab = controller.selectedFilterTab.value;
                        final int unreadCount = controller.unreadCount;
                        final list = controller.conceptFilteredAnnouncements;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),

                            // 2. Screen Title: | សេចក្តីជូនដំណឹង
                            _buildScreenTitle(isKh),
                            const SizedBox(height: 14),

                            // 3. Filter Pills: ទាំងអស់ | មិនទាន់អាន (X)
                            _buildFilterPills(
                              isKh: isKh,
                              selectedTab: selectedTab,
                              unreadCount: unreadCount,
                            ),
                            const SizedBox(height: 14),

                            // 4. Rounded Announcements Container Card
                            _buildAnnouncementsCard(
                              context,
                              isKh: isKh,
                              list: list,
                            ),

                            // Bottom padding to clear floating nav bar
                            const SizedBox(height: 120),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Screen Title: | សេចក្តីជូនដំណឹង
  // ---------------------------------------------------------------------------
  Widget _buildScreenTitle(bool isKh) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3.5,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.royalGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isKh ? 'សេចក្តីជូនដំណឹង' : 'Announcements',
          style: isKh
              ? GoogleFonts.kantumruyPro(
                  color: const Color(0xFF1E293B),
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                )
              : GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Filter Pills: ទាំងអស់ | មិនទាន់អាន (X)
  // ---------------------------------------------------------------------------
  Widget _buildFilterPills({
    required bool isKh,
    required String selectedTab,
    required int unreadCount,
  }) {
    final bool isAllSelected = selectedTab == 'all';
    final bool isUnreadSelected = selectedTab == 'unread';

    return Row(
      children: [
        // All pill ("ទាំងអស់")
        GestureDetector(
          onTap: () {
            controller.selectedFilterTab.value = 'all';
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8.5),
            decoration: BoxDecoration(
              color:
                  isAllSelected ? AppColors.royalGold : const Color(0xFFF6EEDB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'all'.tr,
              style: isKh
                  ? GoogleFonts.kantumruyPro(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: isAllSelected ? Colors.white : AppColors.royalGold,
                      height: 1.3,
                    )
                  : GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isAllSelected ? Colors.white : AppColors.royalGold,
                      height: 1.3,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Unread pill ("មិនទាន់អាន (2)")
        GestureDetector(
          onTap: () {
            controller.selectedFilterTab.value = 'unread';
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8.5),
            decoration: BoxDecoration(
              color: isUnreadSelected
                  ? AppColors.royalGold
                  : const Color(0xFFF6EEDB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              isKh ? 'មិនទាន់អាន ($unreadCount)' : 'Unread ($unreadCount)',
              style: GoogleFonts.kantumruyPro(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isUnreadSelected ? Colors.white : AppColors.royalGold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Main Rounded Announcements Container Card
  // ---------------------------------------------------------------------------
  Widget _buildAnnouncementsCard(
    BuildContext context, {
    required bool isKh,
    required List<Map<String, dynamic>> list,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: list.isEmpty
            ? _buildEmptyState(isKh)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final String title = _resolveTitle(item, isKh);
                  final String formattedDate =
                      _formatConceptDateTime(item, isKh);
                  final bool isUnread = controller.isAnnouncementUnread(item);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        controller.markAsRead(item);
                        showAnnouncementDetailDialog(context, item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left squircle cream container with golden bell
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6EEDB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFEDE3CE),
                                  width: 0.8,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.royalGold,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Center Column: Title & Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: isKh
                                        ? GoogleFonts.kantumruyPro(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                            height: 1.35,
                                          )
                                        : GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                            height: 1.3,
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedDate,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: isKh
                                        ? GoogleFonts.kantumruyPro(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                            height: 1.3,
                                          )
                                        : GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                            height: 1.3,
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            // Right unread dot indicator
                            if (isUnread) ...[
                              const SizedBox(width: 12),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB45309),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isKh) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF6EEDB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.royalGold,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              controller.selectedFilterTab.value == 'unread'
                  ? 'no_unread_announcements'.tr
                  : 'no_announcements'.tr,
              style: isKh
                  ? GoogleFonts.kantumruyPro(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      height: 1.35,
                    )
                  : GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      height: 1.3,
                    ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date & Time Formatter Matching Concept Mockup
  // Example: "២៧ តុលា ២០២៦ · ម៉ោង ០៩:៣០"
  // ---------------------------------------------------------------------------
  String _formatConceptDateTime(Map<String, dynamic> announcement, bool isKh) {
    if (isKh && announcement['displayDateKh'] != null) {
      return announcement['displayDateKh'].toString();
    }
    if (!isKh && announcement['displayDateEn'] != null) {
      return announcement['displayDateEn'].toString();
    }

    final String rawDate = (announcement['createdAt'] ??
            announcement['created_at'] ??
            announcement['date'] ??
            announcement['time'] ??
            '')
        .toString();

    if (rawDate.isEmpty) return '';

    try {
      final dt = DateTime.tryParse(rawDate);
      if (dt == null) return rawDate;

      final int day = dt.day;
      final int month = dt.month;
      final int year = dt.year;
      final String hour = dt.hour.toString().padLeft(2, '0');
      final String minute = dt.minute.toString().padLeft(2, '0');

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

        final String khDay = toKh(day);
        final String khMonth = khmerMonths[month - 1];
        final String khYear = toKh(year);
        final String khHour = toKh(hour);
        final String khMin = toKh(minute);
        return '$khDay $khMonth $khYear · ម៉ោង $khHour:$khMin';
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
        final String enMonth = englishMonths[month - 1];
        final int hourInt = dt.hour;
        final String period = hourInt >= 12 ? 'PM' : 'AM';
        final int displayHour = hourInt % 12 == 0 ? 12 : hourInt % 12;
        final String hourStr = displayHour.toString().padLeft(2, '0');
        return '$day $enMonth $year · $hourStr:$minute $period';
      }
    } catch (_) {
      return rawDate;
    }
  }

  // ---------------------------------------------------------------------------
  // Bilingual Title Resolver
  // ---------------------------------------------------------------------------
  String _resolveTitle(Map<String, dynamic> announcement, bool isKh) {
    if (isKh) {
      final kh = announcement['titleKh'] ?? announcement['title'];
      if (kh != null && kh.toString().trim().isNotEmpty) {
        return kh.toString().trim();
      }
      return (announcement['titleEn'] ?? 'គ្មានចំណងជើង').toString().trim();
    } else {
      final en = announcement['titleEn'];
      if (en != null && en.toString().trim().isNotEmpty) {
        return en.toString().trim();
      }
      return (announcement['title'] ?? 'No Title').toString().trim();
    }
  }
}

