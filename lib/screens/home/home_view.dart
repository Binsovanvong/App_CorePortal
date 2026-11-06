import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/widgets/empty_apps_widget.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/widgets/announcement_detail_dialog.dart';
import 'package:core_portal/widgets/portal_top_app_bar.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/theme/app_colors.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFAF9F6),
        ),
        child: Stack(
          children: [
            // Background Subtle Khmer Kbach Watermarks
            Positioned(
              right: -30,
              top: 320,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _KhmerLotusKbachPainter(
                      color: AppColors.royalGold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 80,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(
                    size: const Size(240, 240),
                    painter: _KhmerLotusKbachPainter(
                      color: AppColors.royalGold,
                    ),
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
                    _buildTopAppBar(context),
                    const SizedBox(height: 12),
                    _buildUserGreeting(),
                    const SizedBox(height: 16),
                    _buildGeneralApplicationsSection(context),
                    _buildDepartmentApplicationsSection(context),
                    const SizedBox(height: 20),
                    _buildLatestAnnouncementsSection(context),
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

  // =========================================================================
  // 1. TOP APP BAR
  // =========================================================================
  Widget _buildTopAppBar(BuildContext context) {
    return const PortalTopAppBar();
  }

  // =========================================================================
  // 2. USER GREETING SECTION
  // =========================================================================
  Widget _buildUserGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vertical Gold Bar
          Container(
            width: 3.5,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.royalGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Greeting Text
          Expanded(
            child: Obx(() {
              final isKh = LocalizationService.currentLanguageCode.value == 'km';
              final rawName = controller.userDisplayName.value.trim();
              final hasName = rawName.isNotEmpty && rawName != 'guest'.tr && rawName != 'officer'.tr;

              final String greetingText;
              final String fallbackUsername =
                  GetStorage().read('username')?.toString() ?? '';
              if (isKh) {
                final displayKhName = hasName
                    ? rawName
                    : (fallbackUsername.isNotEmpty ? fallbackUsername : 'មន្ត្រី');
                greetingText = "អរុណសួស្ដី លោក $displayKhName";
              } else {
                final displayEnName = hasName
                    ? rawName
                    : (fallbackUsername.isNotEmpty ? fallbackUsername : 'Officer');
                greetingText = "Good morning, Mr. $displayEnName";
              }

              return Text(
                greetingText,
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      )
                    : GoogleFonts.poppins(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. GENERAL APPLICATIONS SECTION (Horizontal Scroll in Warm Cream Card)
  // =========================================================================
  Widget _buildGeneralApplicationsSection(BuildContext context) {
    return Obx(() {
      final liveGeneralApps = controller.generalServices;
      if (liveGeneralApps.isEmpty) {
        return const SizedBox.shrink();
      }

      final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
      final List<Map<String, dynamic>> generalItems = liveGeneralApps;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warmCream,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.warmCreamBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header inside the cream card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: AppColors.royalGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'general_applications'.tr,
                      style: isKh
                          ? GoogleFonts.kantumruyPro(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.3,
                            )
                          : GoogleFonts.poppins(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (Get.isRegistered<ApplicationViewController>()) {
                      Get.find<ApplicationViewController>().setFilterTab('general');
                    }
                    _navigateToAllApps();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Text(
                      'view_all'.tr,
                      style: isKh
                          ? GoogleFonts.kantumruyPro(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalGold,
                              height: 1.3,
                            )
                          : GoogleFonts.poppins(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalGold,
                              height: 1.3,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Scrollable Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(generalItems.length, (index) {
                  final item = generalItems[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < generalItems.length - 1 ? 10.0 : 0.0,
                    ),
                    child: _buildGeneralAppCard(item),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGeneralAppCard(Map<String, dynamic> item) {
    final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
    final String title = ApplicationView.resolveAppTitle(item, isKh);

    final resolvedTheme = ApplicationView.resolveAppTheme(item);
    final Color iconBg = item['iconBg'] is Color
        ? (item['iconBg'] as Color)
        : (resolvedTheme['bg'] as Color);
    final IconData fallbackIcon = item['fallbackIcon'] is IconData
        ? (item['fallbackIcon'] as IconData)
        : (resolvedTheme['icon'] as IconData);

    final storage = GetStorage();
    final String sessionToken = (ApiClient.currentToken ??
            storage.read('token') ??
            storage.read('access_token') ??
            '')
        .toString();

    String? iconUrl;
    final String rawImg = AppIconWidget.extractRawIcon(item);
    if (rawImg.isNotEmpty &&
        rawImg != 'assets/img/about-moi-logo.png' &&
        rawImg != '/assets/img/about-moi-logo.png' &&
        rawImg.toLowerCase() != 'null' &&
        rawImg.toLowerCase() != 'undefined') {
      iconUrl = AppIconWidget.formatIconUrl(rawImg, sessionToken);
    }

    final String rawIconStr = (item["icon"] ?? '').toString().trim();
    final bool isLocalPath = rawIconStr.toLowerCase().startsWith('assets/') ||
        rawIconStr.toLowerCase().startsWith('/assets/') ||
        rawIconStr.toLowerCase().startsWith('images/') ||
        rawIconStr.toLowerCase().startsWith('/images/');
    final String itemLocal = (isLocalPath &&
            rawIconStr != 'assets/img/about-moi-logo.png' &&
            rawIconStr != '/assets/img/about-moi-logo.png')
        ? rawIconStr
        : '';

    final bool hasImage = (iconUrl != null && iconUrl.trim().isNotEmpty) || itemLocal.isNotEmpty;

    return GestureDetector(
      onTap: () => _handleAppLaunch(item, title),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 236,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Squircle Icon Container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasImage ? Colors.transparent : iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: hasImage
                      ? AppIconWidget(
                          iconUrl: iconUrl ?? '',
                          localAsset: itemLocal,
                          fallbackIcon: fallbackIcon,
                          fallbackColor: iconBg,
                          token: sessionToken,
                          size: 46,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          fallbackIcon,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Middle App Title
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      )
                    : GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      ),
              ),
            ),
            const SizedBox(width: 6),

            // Right Circular Chevron Button
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.iconBeige,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.royalGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. DEPARTMENT APPLICATIONS SECTION (2-Column Grid of Concept Cards)
  // =========================================================================
  Widget _buildDepartmentApplicationsSection(BuildContext context) {
    return Obx(() {
      final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
      final liveApps = controller.departmentServices;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'department_applications'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isKh
                        ? GoogleFonts.kantumruyPro(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          )
                        : GoogleFonts.poppins(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                  ),
                ),
                if (liveApps.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _navigateToAllApps(),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'view_all'.tr,
                          style: isKh
                              ? GoogleFonts.kantumruyPro(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.royalGold,
                                  height: 1.3,
                                )
                              : GoogleFonts.poppins(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.royalGold,
                                  height: 1.3,
                                ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.royalGold,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // If user has no department applications, show the standard empty apps widget
            if (liveApps.isEmpty)
              EmptyAppsWidget(
                isCompact: true,
                onAction: () => controller.fetchPortalApps(),
              )
            else
              // 2-Column Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final double cardWidth = (constraints.maxWidth - 12) / 2;

                  // Chunk into rows of 2
                  final List<List<Map<String, dynamic>>> rows = [];
                  for (var i = 0; i < liveApps.length; i += 2) {
                    rows.add(
                      liveApps.sublist(
                        i,
                        i + 2 > liveApps.length ? liveApps.length : i + 2,
                      ),
                    );
                  }

                  return Column(
                    children: List.generate(rows.length, (rowIndex) {
                      final rowItems = rows[rowIndex];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: rowIndex < rows.length - 1 ? 12.0 : 0.0,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _buildDepartmentCard(
                                rowItems[0],
                                ApplicationView.resolveAppTheme(rowItems[0]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (rowItems.length > 1)
                              SizedBox(
                                width: cardWidth,
                                child: _buildDepartmentCard(
                                  rowItems[1],
                                  ApplicationView.resolveAppTheme(rowItems[1]),
                                ),
                              )
                            else
                              SizedBox(width: cardWidth),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _buildDepartmentCard(
    Map<String, dynamic> item,
    Map<String, dynamic> theme,
  ) {
    final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
    final String title = ApplicationView.resolveAppTitle(item, isKh);

    final resolvedTheme = ApplicationView.resolveAppTheme(item);
    final Color iconBg = item['iconBg'] is Color
        ? (item['iconBg'] as Color)
        : (resolvedTheme['bg'] as Color);
    final IconData fallbackIcon = item['fallbackIcon'] is IconData
        ? (item['fallbackIcon'] as IconData)
        : (resolvedTheme['icon'] as IconData);

    final storage = GetStorage();
    final String sessionToken = (ApiClient.currentToken ??
            storage.read('token') ??
            storage.read('access_token') ??
            '')
        .toString();

    String? iconUrl;
    final String rawImg = AppIconWidget.extractRawIcon(item);
    if (rawImg.isNotEmpty &&
        rawImg != 'assets/img/about-moi-logo.png' &&
        rawImg != '/assets/img/about-moi-logo.png' &&
        rawImg.toLowerCase() != 'null' &&
        rawImg.toLowerCase() != 'undefined') {
      iconUrl = AppIconWidget.formatIconUrl(rawImg, sessionToken);
    }

    final String rawIconStr = (item["icon"] ?? '').toString().trim();
    final bool isLocalPath = rawIconStr.toLowerCase().startsWith('assets/') ||
        rawIconStr.toLowerCase().startsWith('/assets/') ||
        rawIconStr.toLowerCase().startsWith('images/') ||
        rawIconStr.toLowerCase().startsWith('/images/');
    final String itemLocal = (isLocalPath &&
            rawIconStr != 'assets/img/about-moi-logo.png' &&
            rawIconStr != '/assets/img/about-moi-logo.png')
        ? rawIconStr
        : '';

    final bool hasImage = (iconUrl != null && iconUrl.trim().isNotEmpty) || itemLocal.isNotEmpty;

    return GestureDetector(
      onTap: () => _handleAppLaunch(item, title),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Squircle Icon & Chevron Circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Squircle Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.transparent : iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Center(
                      child: hasImage
                          ? AppIconWidget(
                              iconUrl: iconUrl ?? '',
                              localAsset: itemLocal,
                              fallbackIcon: fallbackIcon,
                              fallbackColor: iconBg,
                              token: sessionToken,
                              size: 44,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              fallbackIcon,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ),

                // Chevron Circle
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.iconBeige,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.royalGold,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Title (2 lines)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      )
                    : GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 5. LATEST ANNOUNCEMENTS SECTION
  // =========================================================================
  Widget _buildLatestAnnouncementsSection(BuildContext context) {
    return Obx(() {
      final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
      final announcementsList = controller.announcements;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'recent_announcements'.tr,
                  style: isKh
                      ? GoogleFonts.kantumruyPro(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        )
                      : GoogleFonts.poppins(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    if (Get.isRegistered<NavController>()) {
                      final bool isAdmin = Get.find<NavController>().isAdmin.value;
                      Get.find<NavController>().changeTab(isAdmin ? 3 : 1);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'view_all'.tr,
                        style: isKh
                            ? GoogleFonts.kantumruyPro(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalGold,
                                height: 1.3,
                              )
                            : GoogleFonts.poppins(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.royalGold,
                                height: 1.3,
                              ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.royalGold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Announcements Card Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: announcementsList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Notification bell icon shown ONLY when there are no announcements
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.iconBeige,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  size: 22,
                                  color: AppColors.royalGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'no_announcements'.tr,
                              style: isKh
                                  ? GoogleFonts.kantumruyPro(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                      height: 1.35,
                                    )
                                  : GoogleFonts.poppins(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                      height: 1.3,
                                    ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'no_announcements_yet_desc'.tr,
                              style: isKh
                                  ? GoogleFonts.kantumruyPro(
                                      fontSize: 12.5,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w400,
                                      height: 1.35,
                                    )
                                  : GoogleFonts.poppins(
                                      fontSize: 12.0,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w400,
                                      height: 1.3,
                                    ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            children: List.generate(
                              announcementsList.length > 3 ? 3 : announcementsList.length,
                              (index) {
                                final a = announcementsList[index];
                                final String title =
                                    a['title']?.toString() ?? 'announcement'.tr;
                                final String content =
                                    a['content']?.toString() ?? '';
                                final String cleanContent = content
                                    .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
                                    .replaceAll(RegExp(r'\s+'), ' ')
                                    .trim();
                                final String formattedDate =
                                    _formatAnnouncementDate(a, isKh);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _showAnnouncementDialog(context, a),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            children: [
                                              // Title & snippet (no notification icon when announcements exist)
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: isKh
                                                          ? GoogleFonts
                                                              .kantumruyPro(
                                                            fontSize: 13.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                                0xFF1E293B),
                                                            height: 1.3,
                                                          )
                                                          : GoogleFonts.poppins(
                                                            fontSize: 13.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                                0xFF1E293B),
                                                            height: 1.3,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      cleanContent.isNotEmpty
                                                          ? cleanContent
                                                          : (formattedDate
                                                                  .isNotEmpty
                                                              ? formattedDate
                                                              : '...'),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: isKh
                                                          ? GoogleFonts
                                                              .kantumruyPro(
                                                            fontSize: 12.0,
                                                            color: const Color(
                                                                0xFF64748B),
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            height: 1.35,
                                                          )
                                                          : GoogleFonts.poppins(
                                                            fontSize: 11.5,
                                                            color: const Color(
                                                                0xFF64748B),
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            height: 1.3,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              // Date snippet
                                              if (formattedDate.isNotEmpty) ...[
                                                Text(
                                                  formattedDate,
                                                  style: isKh
                                                      ? GoogleFonts
                                                          .kantumruyPro(
                                                        fontSize: 11.5,
                                                        color: const Color(
                                                            0xFF64748B),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      )
                                                      : GoogleFonts.poppins(
                                                        fontSize: 11.0,
                                                        color: const Color(
                                                            0xFF64748B),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],

                                              // Chevron
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                color: AppColors.royalGold,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (index <
                                            (announcementsList.length > 3
                                                    ? 3
                                                    : announcementsList.length) -
                                                1)
                                          const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Color(0xFFF8FAFC),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // =========================================================================
  // NAVIGATION & CLICK HANDLERS
  // =========================================================================
  void _navigateToAllApps() {
    if (Get.isRegistered<NavController>()) {
      final bool isAdmin = Get.find<NavController>().isAdmin.value;
      if (isAdmin) {
        Get.find<NavController>().changeTab(1);
      } else {
        Get.toNamed(AppRoutes.application);
      }
    } else {
      Get.toNamed(AppRoutes.application);
    }
  }

  void _handleAppLaunch(Map<String, dynamic> item, String title) {
    final String route = (item["appUrl"] ??
            item["launchUrl"] ??
            item["url"] ??
            item["route"] ??
            item["path"] ??
            '')
        .toString()
        .trim();

    if (route.isNotEmpty) {
      try {
        controller.addRecentActivity(item);
        final Map<String, dynamic> navigationArgs = {
          'url': route,
          'title': title,
        };
        if (route.startsWith('http://') || route.startsWith('https://')) {
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
      _navigateToAllApps();
    }
  }

  void _showAnnouncementDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    showAnnouncementDetailDialog(context, announcement);
  }

  String _formatAnnouncementDate(Map<String, dynamic> a, bool isKh) {
    if (isKh && a['displayDateKh'] != null && a['displayDateKh'].toString().trim().isNotEmpty) {
      final s = a['displayDateKh'].toString().trim();
      return s.contains('·') ? s.split('·')[0].trim() : s;
    }
    if (!isKh && a['displayDateEn'] != null && a['displayDateEn'].toString().trim().isNotEmpty) {
      final s = a['displayDateEn'].toString().trim();
      return s.contains('·') ? s.split('·')[0].trim() : s;
    }

    final String rawDate = (a['createdAt'] ??
            a['created_at'] ??
            a['date'] ??
            a['time'] ??
            '')
        .toString();
    if (rawDate.isEmpty) return '';
    try {
      final dateTime = DateTime.tryParse(rawDate);
      if (dateTime == null) return rawDate;

      final day = dateTime.day.toString();
      final year = dateTime.year.toString();

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

        String toKhmer(String input) {
          const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
          const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
          String res = input;
          for (int i = 0; i < english.length; i++) {
            res = res.replaceAll(english[i], khmer[i]);
          }
          return res;
        }

        final khDay = toKhmer(day);
        final khMonth = khmerMonths[dateTime.month - 1];
        final khYear = toKhmer(year);
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
        final enMonth = englishMonths[dateTime.month - 1];
        return '$day $enMonth $year';
      }
    } catch (_) {
      return rawDate;
    }
  }
}

/// Traditional Khmer Lotus / Kbach Watermark Line Art Painter
class _KhmerLotusKbachPainter extends CustomPainter {
  final Color color;

  const _KhmerLotusKbachPainter({
    this.color = AppColors.royalGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.0;
    const opacity = 0.08;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.25)
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
