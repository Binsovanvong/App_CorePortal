import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/screens/home/home_view.dart';
import 'package:core_portal/screens/setting/setting_view.dart';
import 'package:core_portal/screens/announcement/announcement_view.dart';
import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/screens/admin/admin_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

part 'mainpage_controller.dart';

class MainpageView extends StatelessWidget {
  MainpageView({super.key});

  // Use Get.find to sync with the instance from MainpageBinding
  final NavController controller = Get.find<NavController>();

  List<Widget> get userPages => [
    HomeView(),
    const AnnouncementView(),
    const SettingView(),
  ];

  List<Widget> get adminPages => [
    HomeView(),
    const ApplicationView(),
    const AdminUsersTabView(),
    const AnnouncementView(),
    const SettingView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final pages = controller.isAdmin.value ? adminPages : userPages;
        final index = controller.currentIndex.value.clamp(0, pages.length - 1);
        return IndexedStack(
          index: index,
          children: pages,
        );
      }),
      bottomNavigationBar: Obx(
        () {
          final bool isAdmin = controller.isAdmin.value;
          // React to locale change so tab labels immediately re-translate
          final String _ = LocalizationService.currentLanguageCode.value;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFF1F5F9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF8C6615).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: isAdmin
                  ? [
                      _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, "home".tr),
                      _buildNavItem(1, Icons.grid_view_rounded, Icons.grid_view_rounded, "application".tr),
                      _buildNavItem(2, Icons.people_alt_outlined, Icons.people_alt_rounded, "users".tr),
                      _buildNavItem(
                        3,
                        Icons.notifications_none_rounded,
                        Icons.notifications_active_rounded,
                        "nav_announcement".tr,
                        badge: controller.unreadCount.value > 0
                            ? controller.unreadCount.value.toString()
                            : null,
                      ),
                      _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, "settings".tr),
                    ]
                  : [
                      _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, "home".tr),
                      _buildNavItem(
                        1,
                        Icons.notifications_none_rounded,
                        Icons.notifications_active_rounded,
                        "nav_announcement".tr,
                        badge: controller.unreadCount.value > 0
                            ? controller.unreadCount.value.toString()
                            : null,
                      ),
                      _buildNavItem(2, Icons.settings_outlined, Icons.settings_rounded, "settings".tr),
                    ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label, {
    String? badge,
  }) {
    final isSelected = controller.currentIndex.value == index;
    final bool isKh = LocalizationService.currentLanguageCode.value == 'km';

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF6EEDB) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: isSelected
                        ? const Color(0xFF8C6615)
                        : const Color(0xFF94A3B8),
                    size: 21,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -7,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        color: isSelected
                            ? const Color(0xFF8C6615)
                            : const Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        height: 1.3,
                      )
                    : GoogleFonts.poppins(
                        color: isSelected
                            ? const Color(0xFF8C6615)
                            : const Color(0xFF64748B),
                        fontSize: 10.0,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        height: 1.3,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
