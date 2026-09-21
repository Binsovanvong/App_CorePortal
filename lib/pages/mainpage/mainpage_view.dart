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
        return pages[index];
      }),
      bottomNavigationBar: Obx(
        () {
          final bool isAdmin = controller.isAdmin.value;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF163774).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: isAdmin
                  ? [
                      _buildNavItem(0, Icons.home_rounded, "home".tr),
                      _buildNavItem(1, Icons.grid_view_rounded, "application".tr),
                      _buildNavItem(
                        2,
                        Icons.people_alt_rounded,
                        "users".tr,
                      ),
                      _buildNavItem(
                        3,
                        Icons.campaign_rounded,
                        "announcement".tr,
                        badge: controller.unreadCount.value > 0
                            ? controller.unreadCount.value.toString()
                            : null,
                      ),
                      _buildNavItem(4, Icons.settings_rounded, "settings".tr),
                    ]
                  : [
                      _buildNavItem(0, Icons.home_rounded, "home".tr),
                      _buildNavItem(
                        1,
                        Icons.campaign_rounded,
                        "announcement".tr,
                        badge: controller.unreadCount.value > 0
                            ? controller.unreadCount.value.toString()
                            : null,
                      ),
                      _buildNavItem(2, Icons.settings_rounded, "settings".tr),
                    ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    String? badge,
  }) {
    final isSelected = controller.currentIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEBF3FE) : Colors.transparent,
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
                    icon,
                    color: isSelected
                        ? const Color(0xFF0F3C99)
                        : const Color(0xff94A3B8),
                    size: 22,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -8,
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
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.kantumruyPro(
                  color: isSelected
                      ? const Color(0xFF0F3C99)
                      : const Color(0xff94A3B8),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
