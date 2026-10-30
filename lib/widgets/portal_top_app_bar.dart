import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/theme/app_colors.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/screens/home/home_controller.dart';

/// The official top app bar for Government Portal screens.
/// Standardized across all 5 bottom navigator tabs:
/// 1. Home (`HomeView`)
/// 2. Applications (`ApplicationView`)
/// 3. Users (`AdminUsersTabView`)
/// 4. Announcements (`AnnouncementView`)
/// 5. Settings (`SettingView`)
class PortalTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool canPop;

  const PortalTopAppBar({
    super.key,
    this.canPop = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              // Optional Back Button (when screen is pushed from route)
              if (canPop) ...[
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.back();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],

              // Ministry Emblem Logo with Golden Ring
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.royalGold,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalGold.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Image.asset(
                    "assets/img/about-moi-logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle in Royal Gold Bronze
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ក្រសួងមហាផ្ទៃ",
                      style: GoogleFonts.kantumruyPro(
                        color: AppColors.royalGold,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "MINISTRY OF INTERIOR",
                      style: GoogleFonts.poppins(
                        color: AppColors.royalGold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Language Selector Pill
              _buildLanguageSelector(),
              const SizedBox(width: 8),

              // User Profile Avatar Circle with Initial
              _buildAvatarButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Obx(() {
      final currentLang = LocalizationService.currentLanguageCode.value;
      final isKh = currentLang == 'km';

      return Theme(
        data: Theme.of(Get.context!).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: PopupMenuButton<String>(
          onSelected: (String langCode) {
            LocalizationService.changeLanguage(langCode);
          },
          offset: const Offset(0, 36),
          padding: EdgeInsets.zero,
          tooltip: 'select_language'.tr,
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'km',
              height: 40,
              child: Row(
                children: [
                  const Text('🇰🇭', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ភាសាខ្មែរ (KH)',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12.5,
                        fontWeight: isKh ? FontWeight.bold : FontWeight.w500,
                        color:
                            isKh ? AppColors.royalGold : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (isKh)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.royalGold,
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'en',
              height: 40,
              child: Row(
                children: [
                  const Text('🇬🇧', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'English (EN)',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: !isKh ? FontWeight.bold : FontWeight.w500,
                        color:
                            !isKh ? AppColors.royalGold : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (!isKh)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.royalGold,
                    ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warmCream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.warmCreamBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isKh ? '🇰🇭' : '🇬🇧',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  isKh ? 'KH' : 'EN',
                  style: GoogleFonts.poppins(
                    color: AppColors.royalGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: AppColors.royalGold,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAvatarButton() {
    return Obx(() {
      String name = '';
      if (Get.isRegistered<HomeController>()) {
        name = Get.find<HomeController>().userDisplayName.value.trim();
      }
      if (name.isEmpty) {
        final box = GetStorage();
        name = (box.read('displayName') ??
                box.read('name') ??
                box.read('username') ??
                '')
            .toString()
            .trim();
      }

      final String initial = name.isNotEmpty
          ? (name.startsWith('លោក ')
              ? (name.length > 5 ? name.substring(4, 5).toUpperCase() : 'B')
              : name.substring(0, 1).toUpperCase())
          : 'B';

      return GestureDetector(
        onTap: () {
          if (Get.isRegistered<NavController>()) {
            final bool isAdmin = Get.find<NavController>().isAdmin.value;
            Get.find<NavController>().changeTab(isAdmin ? 4 : 2);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.royalGold,
            boxShadow: [
              BoxShadow(
                color: AppColors.royalGold.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    });
  }
}

