import 'package:core_portal/screens/notification/notification_controller.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/widgets/empty_apps_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
              Color(0xFFEFF4FB),
              Color(0xFFE8EEF8),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background Traditional Khmer Floral / Kbach Watermarks
            Positioned(
              right: -30,
              top: 320,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.13,
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _KhmerLotusKbachPainter(),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 60,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    size: const Size(240, 240),
                    painter: _KhmerLotusKbachPainter(),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: 110,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.14,
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: _KhmerLotusKbachPainter(),
                  ),
                ),
              ),
            ),

            // Main Scrollable Content
            SafeArea(
              top: false,
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopAppBarCard(),
                    const SizedBox(height: 14),
                    _buildUserGreetingCard(),
                    const SizedBox(height: 18),
                    _buildPopularServicesSection(context),
                    _buildSectionHeader(
                      icon: Icons.campaign_rounded,
                      title: 'recent_announcements'.tr,
                      onTapSeeAll: () {
                        if (Get.isRegistered<NavController>()) {
                          final bool isAdmin =
                              Get.find<NavController>().isAdmin.value;
                          Get.find<NavController>().changeTab(isAdmin ? 3 : 1);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildNoticeSectionList(context),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBarCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3278), Color(0xFF163774), Color(0xFF194498)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom-right Khmer Lotus Kbach watermark in app bar
          Positioned(
            right: -20,
            bottom: -30,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: const _KhmerLotusKbachPainter(
                    color: Colors.white,
                    strokeWidth: 1.2,
                    opacity: 0.24,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Ministry Emblem Logo
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 8,
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
                      const SizedBox(width: 10),

                      // Titles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "ក្រសួងមហាផ្ទៃ",
                              style: GoogleFonts.kantumruyPro(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Ministry of Interior",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Language Dropdown
                      _buildLanguageDropdown(),
                      const SizedBox(width: 8),

                      // Notification Button
                      _buildNotificationButton(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Line 3: Full-width Motto text
                  Padding(
                    padding: const EdgeInsets.only(left: 62),
                    child: Text(
                      "moi_motto".tr,
                      style: GoogleFonts.kantumruyPro(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.15,
                        height: 1.2,
                      ),
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    final notifCtrl = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return Obx(() {
      final unreadCount = notifCtrl.notifications
          .where((n) => !n.isRead)
          .length;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.notification),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: Color(0xFF163774),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xffEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLanguageDropdown() {
    return Obx(() {
      final currentLang = LocalizationService.currentLanguageCode.value;
      final isKh = currentLang == 'km';

      return Theme(
        data: Theme.of(Get.context!).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xffF1F5F9), width: 1),
            ),
            elevation: 8,
            shadowColor: const Color(0xff0F172A).withOpacity(0.12),
          ),
        ),
        child: PopupMenuButton<String>(
          onSelected: (String langCode) {
            LocalizationService.changeLanguage(langCode);
          },
          offset: const Offset(0, 38),
          padding: EdgeInsets.zero,
          tooltip: 'select_language'.tr,
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'km',
              height: 42,
              child: Row(
                children: [
                  const Text('🇰🇭', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ភាសាខ្មែរ (KH)',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        fontWeight: isKh ? FontWeight.bold : FontWeight.w500,
                        color: isKh
                            ? const Color(0xFF163774)
                            : const Color(0xff334155),
                      ),
                    ),
                  ),
                  if (isKh)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xffD4AF37),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'en',
              height: 42,
              child: Row(
                children: [
                  const Text('🇬🇧', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'English (EN)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: !isKh ? FontWeight.bold : FontWeight.w500,
                        color: !isKh
                            ? const Color(0xFF163774)
                            : const Color(0xff334155),
                      ),
                    ),
                  ),
                  if (!isKh)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xffD4AF37),
                    ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isKh ? '🇰🇭' : '🇬🇧',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 5),
                Text(
                  isKh ? 'KH' : 'EN',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF163774),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF163774),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUserGreetingCard() {
    return GestureDetector(
      onTap: () {
        if (Get.isRegistered<NavController>()) {
          final bool isAdmin = Get.find<NavController>().isAdmin.value;
          Get.find<NavController>().changeTab(isAdmin ? 4 : 2);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF163774).withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Blue Avatar Circle with solid person icon
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Greeting + Name Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'hello'.tr,
                        style: GoogleFonts.kantumruyPro(
                          color: const Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('👋', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final name = controller.userDisplayName.value;
                    return Text(
                      name.isNotEmpty ? name : 'bin sovanvong',
                      style: GoogleFonts.kantumruyPro(
                        color: const Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Far-Right Chevron ">"
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1D4ED8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    IconData? icon,
    bool isPillAccent = false,
    required String title,
    VoidCallback? onTapSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPillAccent)
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: const Color(0xFF1D4ED8), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (onTapSeeAll != null)
            GestureDetector(
              onTap: onTapSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'view_all'.tr,
                      style: GoogleFonts.kantumruyPro(
                        color: const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF1D4ED8),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesSection(BuildContext context) {
    return Obx(() {
      final activeServices = controller.homeServices;

      if (activeServices.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionHeader(
              isPillAccent: true,
              title: 'all_applications'.tr,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EmptyAppsWidget(
                isCompact: true,
                title: 'no_applications_yet'.tr,
                subtitle: 'no_applications_yet_desc'.tr,
                actionText: 'refresh'.tr,
                onAction: controller.fetchPortalApps,
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(isPillAccent: true, title: 'all_applications'.tr),
          const SizedBox(height: 12),
          _buildPopularServicesRow(context, activeServices),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildPopularServicesRow(
    BuildContext context,
    List<Map<String, dynamic>> services,
  ) {
    final storage = GetStorage();
    final String sessionToken =
        (storage.read('token') ?? storage.read('access_token') ?? '')
            .toString();
    final bool isEnglish =
        LocalizationService.currentLanguageCode.value == 'en';

    final themes = [
      {
        'bgColor': const Color(0xFFF0F7FF),
        'borderColor': const Color(0xFFDBEAFE),
        'iconBg': const Color(0xFFDBEAFE),
        'tintColor': const Color(0xFF1D4ED8),
        'fallbackIcon': Icons.description_rounded,
      },
      {
        'bgColor': const Color(0xFFF0FDF4),
        'borderColor': const Color(0xFFDCFCE7),
        'iconBg': const Color(0xFFDCFCE7),
        'tintColor': const Color(0xFF16A34A),
        'fallbackIcon': Icons.badge_rounded,
      },
      {
        'bgColor': const Color(0xFFFFF7ED),
        'borderColor': const Color(0xFFFFEDD5),
        'iconBg': const Color(0xFFFFEDD5),
        'tintColor': const Color(0xFFEA580C),
        'fallbackIcon': Icons.security_rounded,
      },
    ];

    // Chunk all user services into rows of 3
    final List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < services.length; i += 3) {
      chunks.add(
        services.sublist(i, i + 3 > services.length ? services.length : i + 3),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double standardCardWidth = (constraints.maxWidth - 20) / 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(chunks.length, (rowIndex) {
              final rowItems = chunks[rowIndex];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex < chunks.length - 1 ? 10.0 : 0.0,
                ),
                child: Row(
                  children: List.generate(rowItems.length, (colIndex) {
                    final itemIndex = rowIndex * 3 + colIndex;
                    final theme = themes[itemIndex % themes.length];
                    final item = rowItems[colIndex];

                    final String displayName = isEnglish
                        ? (item["titleEn"] ??
                                  item["nameEn"] ??
                                  item["name"] ??
                                  item["titleKh"] ??
                                  item["nameKh"] ??
                                  'application'.tr)
                              .toString()
                        : (item["titleKh"] ??
                                  item["nameKh"] ??
                                  item["name"] ??
                                  item["titleEn"] ??
                                  item["nameEn"] ??
                                  'application'.tr)
                              .toString();

                    final String title = displayName.trim().isNotEmpty
                        ? displayName.trim()
                        : 'application'.tr;

                    String? iconUrl;
                    final String rawImg = AppIconWidget.extractRawIcon(item);
                    if (rawImg.isNotEmpty &&
                        rawImg != 'assets/img/about-moi-logo.png' &&
                        rawImg != '/assets/img/about-moi-logo.png' &&
                        rawImg.toLowerCase() != 'null' &&
                        rawImg.toLowerCase() != 'undefined') {
                      iconUrl = AppIconWidget.formatIconUrl(rawImg, sessionToken);
                    }

                    final String route =
                        (item["appUrl"] ??
                                item["launchUrl"] ??
                                item["url"] ??
                                item["route"] ??
                                item["path"] ??
                                '')
                            .toString()
                            .trim();

                    final String rawIconStr = (item["icon"] ?? '').toString().trim();
                    final String itemLocal = (rawIconStr.isNotEmpty &&
                            !rawIconStr.startsWith('http://') &&
                            !rawIconStr.startsWith('https://') &&
                            rawIconStr != 'assets/img/about-moi-logo.png' &&
                            rawIconStr != '/assets/img/about-moi-logo.png')
                        ? rawIconStr
                        : '';

                    final Widget card = _buildServiceCard(
                      bgColor: theme['bgColor'] as Color,
                      borderColor: theme['borderColor'] as Color,
                      iconBg: theme['iconBg'] as Color,
                      tintColor: theme['tintColor'] as Color,
                      fallbackIcon: theme['fallbackIcon'] as IconData,
                      title: title,
                      iconUrl: iconUrl,
                      localAsset: itemLocal,
                      sessionToken: sessionToken,
                      onTap: () {
                        if (route.isNotEmpty) {
                          try {
                            controller.addRecentActivity(item);
                            final Map<String, dynamic> navigationArgs = {
                              'url': route,
                              'title': title,
                            };
                            if (route.startsWith('http://') ||
                                route.startsWith('https://')) {
                              Get.toNamed(
                                AppRoutes.webView,
                                arguments: navigationArgs,
                              );
                              return;
                            }
                            Get.toNamed(route, arguments: navigationArgs);
                          } catch (e) {
                            debugPrint("Navigation error: $e");
                          }
                        } else {
                          if (Get.isRegistered<NavController>()) {
                            final bool isAdmin =
                                Get.find<NavController>().isAdmin.value;
                            if (isAdmin) {
                              Get.find<NavController>().changeTab(1);
                            } else {
                              Get.toNamed(AppRoutes.application);
                            }
                          }
                        }
                      },
                    );

                    if (rowItems.length == 3) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: colIndex < 2 ? 10.0 : 0.0,
                          ),
                          child: card,
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                        right: colIndex < rowItems.length - 1 ? 10.0 : 0.0,
                      ),
                      child: SizedBox(width: standardCardWidth, child: card),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard({
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required Color tintColor,
    required IconData fallbackIcon,
    required String title,
    String? iconUrl,
    String? localAsset,
    String? sessionToken,
    required VoidCallback onTap,
  }) {
    final cleanLocal = (localAsset != null &&
            localAsset.trim().isNotEmpty &&
            localAsset != 'assets/img/about-moi-logo.png' &&
            localAsset != '/assets/img/about-moi-logo.png')
        ? localAsset.trim()
        : '';
    final bool hasImage =
        (iconUrl != null && iconUrl.trim().isNotEmpty) ||
        cleanLocal.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: tintColor.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Squircle Icon Container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasImage ? Colors.white : iconBg,
                borderRadius: BorderRadius.circular(13),
                border: hasImage
                    ? Border.all(
                        color: borderColor.withOpacity(0.9),
                        width: 1.0,
                      )
                    : null,
                boxShadow: hasImage
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: hasImage
                      ? Padding(
                          padding: const EdgeInsets.all(4.5),
                          child: AppIconWidget(
                            iconUrl: iconUrl ?? '',
                            localAsset: cleanLocal,
                            fallbackIcon: fallbackIcon,
                            fallbackColor: tintColor,
                            token: sessionToken ?? '',
                            size: 32,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(fallbackIcon, color: tintColor, size: 24),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 2-Line Title
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Circular Arrow Button
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: tintColor,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeSectionList(BuildContext context) {
    return Obx(() {
      final list = controller.announcements;
      if (list.isEmpty) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF163774).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: _MegaphoneIllustration()),
              const SizedBox(height: 14),
              Text(
                'no_announcements'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F2B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                'no_announcements_yet_desc'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length > 3 ? 3 : list.length,
            itemBuilder: (context, index) {
              final a = list[index];
              final String title = a['title']?.toString() ?? 'announcement'.tr;
              final String content = a['content']?.toString() ?? '';
              final String rawDate = a['date']?.toString() ?? '';
              final String cleanContent = content
                  .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF163774).withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAnnouncementDialog(context, a),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xffFAF3E3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xffD4AF37).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: Color(0xFF163774),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xff1E293B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatKhmerDate(rawDate),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xff64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cleanContent,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 12,
                                    color: const Color(0xff64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Golden Khmer Prasat / Angkor Spire Decorative Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: CustomPaint(
              size: const Size(double.infinity, 24),
              painter: _KhmerPrasatDividerPainter(),
            ),
          ),
        ],
      );
    });
  }

  void _showAnnouncementDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    final String title = announcement['title']?.toString() ?? 'announcement'.tr;
    final String content = announcement['content']?.toString() ?? '';
    final String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .trim();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffA88400).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'announcement'.tr,
                      style: GoogleFonts.kantumruyPro(
                        color: const Color(0xffA88400),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
              const Divider(
                height: 24,
                color: Color(0xffF1F5F9),
                thickness: 1.5,
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    cleanContent,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 15,
                      color: const Color(0xff475569),
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffA88400),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }

  String _formatKhmerDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dateTime = DateTime.tryParse(dateStr);
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

      final day = dateTime.day.toString();
      final month = khmerMonths[dateTime.month - 1];
      final year = dateTime.year.toString();

      String toKhmer(String input) {
        const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
        String res = input;
        for (int i = 0; i < english.length; i++) {
          res = res.replaceAll(english[i], khmer[i]);
        }
        return res;
      }

      return '${toKhmer(day)} $month ${toKhmer(year)}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// Traditional Khmer Prasat / Angkor Spire Decorative Divider Painter
class _KhmerPrasatDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xffD4AF37).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final goldFill = Paint()
      ..color = const Color(0xffC59E3F)
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..color = const Color(0xFF163774)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    const double gap = 16.0;

    // Draw left and right dividing lines
    canvas.drawLine(Offset(0, cy), Offset(cx - gap, cy), linePaint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(size.width, cy), linePaint);

    // Draw Khmer Prasat (Angkor Spire) silhouette in center
    final path = Path();
    path.moveTo(cx, cy - 10);
    path.lineTo(cx + 1.5, cy - 7);
    path.lineTo(cx + 3, cy - 6);
    path.lineTo(cx + 2, cy - 4.5);
    path.lineTo(cx + 4.5, cy - 3.5);
    path.lineTo(cx + 3.5, cy - 1.5);
    path.lineTo(cx + 6, cy - 0.5);
    path.lineTo(cx + 5, cy + 2);
    path.lineTo(cx + 7.5, cy + 4);
    path.lineTo(cx + 7.5, cy + 6.5);
    path.lineTo(cx - 7.5, cy + 6.5);
    path.lineTo(cx - 7.5, cy + 4);
    path.lineTo(cx - 5, cy + 2);
    path.lineTo(cx - 6, cy - 0.5);
    path.lineTo(cx - 3.5, cy - 1.5);
    path.lineTo(cx - 4.5, cy - 3.5);
    path.lineTo(cx - 2, cy - 4.5);
    path.lineTo(cx - 3, cy - 6);
    path.lineTo(cx - 1.5, cy - 7);
    path.close();

    canvas.drawPath(path, goldFill);
    canvas.drawPath(path, goldStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Traditional Khmer Lotus / Kbach Watermark Line Art Painter
class _KhmerLotusKbachPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double opacity;

  const _KhmerLotusKbachPainter({
    this.color = const Color(0xFF163774),
    this.strokeWidth = 1.0,
    this.opacity = 0.08,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = color.withOpacity(opacity * 0.25)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate((i * 90) * 3.14159265 / 180);

      // Central pointed petal
      final p1 = Path();
      p1.moveTo(0, 0);
      p1.quadraticBezierTo(
        size.width * 0.15,
        -size.height * 0.25,
        0,
        -size.height * 0.48,
      );
      p1.quadraticBezierTo(-size.width * 0.15, -size.height * 0.25, 0, 0);
      p1.close();
      canvas.drawPath(p1, fillPaint);
      canvas.drawPath(p1, paint);

      // Inner flame detail
      final p2 = Path();
      p2.moveTo(0, -size.height * 0.08);
      p2.quadraticBezierTo(
        size.width * 0.08,
        -size.height * 0.22,
        0,
        -size.height * 0.38,
      );
      p2.quadraticBezierTo(
        -size.width * 0.08,
        -size.height * 0.22,
        0,
        -size.height * 0.08,
      );
      canvas.drawPath(p2, paint);

      // Side curved tendrils
      final p3 = Path();
      p3.moveTo(size.width * 0.05, -size.height * 0.1);
      p3.quadraticBezierTo(
        size.width * 0.25,
        -size.height * 0.15,
        size.width * 0.22,
        -size.height * 0.32,
      );
      p3.quadraticBezierTo(
        size.width * 0.12,
        -size.height * 0.26,
        size.width * 0.08,
        -size.height * 0.22,
      );
      canvas.drawPath(p3, paint);

      final p4 = Path();
      p4.moveTo(-size.width * 0.05, -size.height * 0.1);
      p4.quadraticBezierTo(
        -size.width * 0.25,
        -size.height * 0.15,
        -size.width * 0.22,
        -size.height * 0.32,
      );
      p4.quadraticBezierTo(
        -size.width * 0.12,
        -size.height * 0.26,
        -size.width * 0.08,
        -size.height * 0.22,
      );
      canvas.drawPath(p4, paint);

      canvas.restore();
    }

    // Center circular ornament
    canvas.drawCircle(Offset(cx, cy), size.width * 0.06, paint);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.03, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Megaphone vector illustration matching Screenshot 1 empty announcements state
class _MegaphoneIllustration extends StatelessWidget {
  const _MegaphoneIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 72,
      child: CustomPaint(painter: _MegaphonePainter()),
    );
  }
}

class _MegaphonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Megaphone horn
    canvas.save();
    canvas.translate(w * 0.42, h * 0.52);
    canvas.rotate(-22 * 3.14159265 / 180);

    // Body (trapezoid cone)
    final hornPath = Path();
    hornPath.moveTo(-w * 0.24, -h * 0.12);
    hornPath.lineTo(w * 0.16, -h * 0.28);
    hornPath.lineTo(w * 0.16, h * 0.28);
    hornPath.lineTo(-w * 0.24, h * 0.12);
    hornPath.close();

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      ).createShader(Rect.fromLTWH(-w * 0.24, -h * 0.28, w * 0.4, h * 0.56));
    canvas.drawPath(hornPath, bodyPaint);

    // Base cup / handle connector
    final basePaint = Paint()..color = const Color(0xFF1E40AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.30, -h * 0.13, w * 0.08, h * 0.26),
        const Radius.circular(3),
      ),
      basePaint,
    );

    // Handle
    final handlePath = Path();
    handlePath.moveTo(-w * 0.13, h * 0.14);
    handlePath.lineTo(-w * 0.09, h * 0.36);
    handlePath.lineTo(-w * 0.03, h * 0.36);
    handlePath.lineTo(-w * 0.07, h * 0.16);
    handlePath.close();
    canvas.drawPath(handlePath, basePaint);

    // Horn rim (light cyan/blue opening)
    final rimPaint = Paint()..color = const Color(0xFF93C5FD);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.16, 0),
        width: w * 0.10,
        height: h * 0.56,
      ),
      rimPaint,
    );

    // Inner rim
    final innerRimPaint = Paint()..color = const Color(0xFF60A5FA);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.16, 0),
        width: w * 0.05,
        height: h * 0.40,
      ),
      innerRimPaint,
    );

    canvas.restore();

    // Sound waves emitting from the horn
    final wavePaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final cx = w * 0.65;
    final cy = h * 0.32;

    // Small wave
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: 13),
      -0.65,
      1.3,
      false,
      wavePaint,
    );

    // Large wave
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: 23),
      -0.65,
      1.3,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
