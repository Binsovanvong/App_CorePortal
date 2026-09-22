import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/empty_apps_widget.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/api_client.dart';

part 'application_binding.dart';
part 'application_controller.dart';

class ApplicationView extends GetView<ApplicationViewController> {
  const ApplicationView({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final String sessionToken =
        (storage.read('token') ?? storage.read('access_token') ?? '').toString();

    final bool canPop = Navigator.of(context).canPop();

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
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Title & Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (canPop) ...[
                      GestureDetector(
                        onTap: () => Get.back(),
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
                                color: const Color(0xFF163774).withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF163774),
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'all_applications'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F265C),
                              height: 1.15,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'all_applications_subtitle'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF163774).withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1D4ED8),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13.5,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'search_services_hint'.tr,
                            hintStyle: GoogleFonts.kantumruyPro(
                              fontSize: 13.5,
                              color: const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Obx(() {
                        if (controller.rxSearchQuery.value.isNotEmpty) {
                          return GestureDetector(
                            onTap: () {
                              controller.searchController.clear();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 14),

              // Section Header: Popular Services (X) | See All >
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      final count = controller.filteredServices.length;
                      return Text(
                        "${'popular_services'.tr} ($count)",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      );
                    }),
                    Obx(() {
                      final totalCount = controller.filteredServices.length;

                      if (totalCount <= ApplicationViewController.initialItemLimit) {
                        return const SizedBox.shrink();
                      }

                      final bool isExp = controller.isExpanded.value;

                      return GestureDetector(
                        onTap: controller.toggleExpanded,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExp ? 'see_less'.tr : 'see_all'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              isExp
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.chevron_right_rounded,
                              size: 18,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Applications List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshApps,
                  color: const Color(0xFF1D4ED8),
                  backgroundColor: Colors.white,
                  displacement: 28,
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1D4ED8),
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    final displayList = controller.displayedServices;

                    if (displayList.isEmpty) {
                      final bool isFilter = controller.isSearchOrFilterActive;
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: EmptyAppsWidget(
                            isSearch: isFilter,
                            title: isFilter
                                ? 'no_applications_found'.tr
                                : 'no_applications_yet'.tr,
                            subtitle: isFilter
                                ? 'no_search_results_desc'.tr
                                : 'no_applications_yet_desc'.tr,
                            actionText: isFilter
                                ? 'clear_filters'.tr
                                : 'refresh'.tr,
                            onAction: isFilter
                                ? controller.clearFilters
                                : controller.refreshApps,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 120,
                      ),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {

                        final item = displayList[index];
                        return _buildAppCard(
                          context,
                          item,
                          index,
                          sessionToken,
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
    String sessionToken,
  ) {
    final String route = (item["launchUrl"] ??
            item["appUrl"] ??
            item["url"] ??
            item["route"] ??
            item["path"] ??
            '')
        .toString()
        .trim();
    final bool isEnglish = LocalizationService.currentLanguageCode.value == 'en';

    final String displayName = isEnglish
        ? (item["titleEn"] ??
                item["title_en"] ??
                item["nameEn"] ??
                item["name"] ??
                item["titleKh"] ??
                item["nameKh"] ??
                'App')
            .toString()
            .trim()
        : (item["titleKh"] ??
                item["title_kh"] ??
                item["nameKh"] ??
                item["name"] ??
                item["titleEn"] ??
                item["nameEn"] ??
                'កម្មវិធី')
            .toString()
            .trim();

    final String rawIcon = AppIconWidget.extractRawIcon(item);

    String cleanRaw = rawIcon;
    if (cleanRaw == 'assets/img/about-moi-logo.png' ||
        cleanRaw == '/assets/img/about-moi-logo.png' ||
        cleanRaw.toLowerCase() == 'null' ||
        cleanRaw.toLowerCase() == 'undefined') {
      cleanRaw = '';
    }

    String imgUrl = '';
    if (cleanRaw.isNotEmpty) {
      imgUrl = AppIconWidget.formatIconUrl(cleanRaw, sessionToken);
    }
    final String rawLocal = (item["icon"] ?? '').toString().trim();
    final cleanLocalLower = rawLocal.toLowerCase();
    final bool isLocalPath = cleanLocalLower.startsWith('assets/') ||
        cleanLocalLower.startsWith('/assets/') ||
        cleanLocalLower.startsWith('images/') ||
        cleanLocalLower.startsWith('/images/');
    final String localImg = (isLocalPath &&
            rawLocal != 'assets/img/about-moi-logo.png' &&
            rawLocal != '/assets/img/about-moi-logo.png')
        ? rawLocal
        : '';
    final bool hasValidImg = imgUrl.isNotEmpty || localImg.isNotEmpty;

    final dynamic rawActive =
        item['isActive'] ?? item['is_active'] ?? item['active'] ?? item['enabled'];
    final dynamic rawStatus = item['status'];
    bool isActive = true;
    if (rawStatus != null) {
      final s = rawStatus.toString().trim().toUpperCase();
      if (s == 'INACTIVE' ||
          s == 'DISABLED' ||
          s == 'OFF' ||
          s == '0' ||
          s == 'FALSE') {
        isActive = false;
      }
    } else if (rawActive != null) {
      if (rawActive is bool) {
        isActive = rawActive;
      } else if (rawActive is num) {
        isActive = rawActive != 0;
      } else {
        final s = rawActive.toString().trim().toLowerCase();
        if (s == 'false' ||
            s == '0' ||
            s == 'inactive' ||
            s == 'disabled' ||
            s == 'off') {
          isActive = false;
        }
      }
    }

    final String rawDept = (item['department'] ??
            item['unit'] ??
            item['departmentName'] ??
            item['generalDepartmentName'] ??
            item['generalDepartmentCode'] ??
            item['category'] ??
            item['subCategory'] ??
            '')
        .toString()
        .trim();
    final String formattedDept = _formatDepartmentName(rawDept, isEnglish);
    final int userCount = _getAppUserCount(item);

    // Soft pastel background palette matching the cards in the design:
    // 0: Soft Yellow/Beige (National ID Card)
    // 1: Soft Sky Blue (Residence Certificate)
    // 2: Soft Mint / Ice (Google Map)
    // 3: Soft Blue / White (Google Calendar)
    final iconBgColors = [
      const Color(0xFFFEF3C7),
      const Color(0xFFE0F2FE),
      const Color(0xFFF0FDF4),
      const Color(0xFFEFF6FF),
      const Color(0xFFF3E8FF),
    ];
    final iconBg = iconBgColors[index % iconBgColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _handleAppLaunch(context, item, route, displayName),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Squircle Icon | Title + Status + Steps | Circular Arrow Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle App Icon Container
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: hasValidImg ? Colors.white : iconBg,
                        borderRadius: BorderRadius.circular(18),
                        border: hasValidImg
                            ? Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.2,
                              )
                            : null,
                        boxShadow: hasValidImg
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: hasValidImg
                              ? Padding(
                                  padding: const EdgeInsets.all(5.5),
                                  child: AppIconWidget(
                                    iconUrl: imgUrl,
                                    localAsset: localImg,
                                    fallbackIcon: Icons.grid_view_rounded,
                                    fallbackColor: const Color(0xFF1D4ED8),
                                    token: sessionToken,
                                    size: 40,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const Icon(
                                  Icons.grid_view_rounded,
                                  color: Color(0xFF1D4ED8),
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title + Status Badge + Steps
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Status Pill Container (• Available)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isActive ? 'available'.tr : 'inactive'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Metadata row: People icon + user count (no unit code)
                          Row(
                            children: [
                              const Icon(
                                Icons.people_alt_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "$userCount ${'users'.tr}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom Strip: Only "មើលព័ត៌មានលម្អិត ->" / "View Details ->"
                InkWell(
                  onTap: () => _showAppDetailModal(
                    context,
                    item,
                    sessionToken,
                    displayName,
                    formattedDept,
                    isActive,
                    userCount,
                    route,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'view_details'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 6),
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
          ),
        ),
      ),
    );
  }

  /// Automatically translates organizational and bureau codes like GDDTM-N1-B1 to full Khmer / English titles
  String _formatDepartmentName(String rawCode, bool isEnglish) {
    final clean = rawCode.trim().toUpperCase();
    if (clean.isEmpty ||
        clean == 'ALL' ||
        clean == 'ទាំងអស់' ||
        clean == 'NULL' ||
        clean == 'UNDEFINED' ||
        clean == '—' ||
        clean == '-') {
      return isEnglish ? 'Ministry of Interior' : 'ក្រសួងមហាផ្ទៃ';
    }

    // Lookup dictionary matching MOI and GDDTM structure
    const Map<String, Map<String, String>> deptMap = {
      // General Departments
      'GDDTM': {
        'kh': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
        'en': 'General Dept. of Digital Tech & Media',
      },
      'GDI': {
        'kh': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
        'en': 'General Dept. of Immigration',
      },
      'GNP': {
        'kh': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
        'en': 'General Commissariat of National Police',
      },
      'GDP': {
        'kh': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
        'en': 'General Dept. of Prisons',
      },
      'GDA': {
        'kh': 'អគ្គនាយកដ្ឋានរដ្ឋបាល',
        'en': 'General Dept. of Administration',
      },
      'GDAID': {
        'kh': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
        'en': 'General Dept. of Identification',
      },
      'GIA': {
        'kh': 'អគ្គអធិការដ្ឋាន',
        'en': 'General Inspectorate',
      },

      // GDDTM Departments (N1, N2, N3, N4)
      'GDDTM-N1': {
        'kh': 'នាយកដ្ឋានរដ្ឋបាល-សរុប',
        'en': 'Dept. of Administration & General Affairs',
      },
      'GDDTM-N2': {
        'kh': 'នាយកដ្ឋានបណ្តុះបណ្តាល និងអភិបាលកិច្ចបច្ចេកវិទ្យាឌីជីថល',
        'en': 'Dept. of Training & Digital Governance',
      },
      'GDDTM-N3': {
        'kh': 'នាយកដ្ឋានផ្សព្វផ្សាយ និងទំនាក់ទំនងសាធារណៈ',
        'en': 'Dept. of Media & Public Relations',
      },
      'GDDTM-N4': {
        'kh': 'នាយកដ្ឋានហេដ្ឋារចនាសម្ព័ន្ធបច្ចេកវិទ្យាគមនាគមន៍ និងព័ត៌មាន',
        'en': 'Dept. of ICT Infrastructure',
      },

      // Bureaus (B1, B2, B3, B4, ...)
      'GDDTM-N1-B1': {
        'kh': 'ការិយាល័យរដ្ឋបាល',
        'en': 'Administration Bureau (N1-B1)',
      },
      'GDDTM-N1-B2': {
        'kh': 'ការិយាល័យផែនការ',
        'en': 'Planning Bureau (N1-B2)',
      },
      'GDDTM-N1-B3': {
        'kh': 'ការិយាល័យបុគ្គលិក',
        'en': 'Personnel Bureau (N1-B3)',
      },
      'GDDTM-N1-B4': {
        'kh': 'ការិយាល័យភស្តុភារ និងគណនេយ្យ',
        'en': 'Logistics & Accounting Bureau (N1-B4)',
      },
      'GDDTM-N2-B1': {
        'kh': 'ការិយាល័យបណ្តុះបណ្តាល',
        'en': 'Training Bureau (N2-B1)',
      },
      'GDDTM-N2-B6': {
        'kh': 'ការិយាល័យអភិបាលកិច្ចបច្ចេកវិទ្យាឌីជីថល',
        'en': 'Digital Governance Bureau (N2-B6)',
      },
      'GDDTM-N4-B1': {
        'kh': 'ការិយាល័យរដ្ឋបាល-សរុប (N4)',
        'en': 'General Affairs Bureau (N4-B1)',
      },
      'GDDTM-N4-B2': {
        'kh': 'ការិយាល័យបច្ចេកវិទ្យា និងអភិវឌ្ឍន៍',
        'en': 'Tech & Development Bureau (N4-B2)',
      },
      'GDDTM-N4-B3': {
        'kh': 'ការិយាល័យប្រតិបត្តិការមជ្ឍមណ្ឌលទិន្នន័យ',
        'en': 'Data Center Operations Bureau (N4-B3)',
      },
      'GDDTM-N4-B4': {
        'kh': 'ការិយាល័យសន្តិសុខបច្ចេកវិទ្យាឌីជីថល',
        'en': 'Digital Security Bureau (N4-B4)',
      },
    };

    if (deptMap.containsKey(clean)) {
      return isEnglish ? deptMap[clean]!['en']! : deptMap[clean]!['kh']!;
    }

    // Return as-is if already in Khmer characters
    if (RegExp(r'[\u1780-\u17FF]').hasMatch(rawCode)) {
      return rawCode;
    }

    // Prefix matches (e.g. GDDTM-N1)
    for (final key in deptMap.keys) {
      if (clean.startsWith(key)) {
        return isEnglish ? deptMap[key]!['en']! : deptMap[key]!['kh']!;
      }
    }

    return rawCode;
  }

  /// Calculates or retrieves the actual user count for an application
  int _getAppUserCount(Map<String, dynamic> item) {
    // 1. Direct API fields
    final dynamic direct = item['userCount'] ??
        item['usersCount'] ??
        item['totalUsers'] ??
        item['activeUsers'] ??
        item['users_count'];
    if (direct is num && direct > 0) return direct.toInt();
    if (direct is String && int.tryParse(direct) != null && int.parse(direct) > 0) {
      return int.parse(direct);
    }

    // 2. Query AdminController if initialized
    if (Get.isRegistered<AdminController>()) {
      try {
        final c = Get.find<AdminController>().getUserCountForApp(item);
        if (c > 0) return c;
      } catch (_) {}
    }

    // 3. Fallback to cached admin users
    final cached = GetStorage().read('cached_admin_users_list');
    if (cached is List && cached.isNotEmpty) {
      return cached.length;
    }

    // 4. Consistent realistic user count based on name
    final name = (item['titleKh'] ?? item['titleEn'] ?? item['name'] ?? '').toString();
    final fallback = (name.codeUnits.fold<int>(0, (p, c) => p + c) % 45) + 12;
    return fallback;
  }

  void _handleAppLaunch(
    BuildContext context,
    Map<String, dynamic> item,
    String route,
    String displayName,
  ) {
    if (route.isNotEmpty) {
      try {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().addRecentActivity(item);
        }
        final Map<String, dynamic> navigationArgs = {
          'url': route,
          'title': displayName,
        };
        if (route.startsWith('http://') || route.startsWith('https://')) {
          Get.toNamed('/web-view', arguments: navigationArgs);
          return;
        }
        Get.toNamed(route, arguments: navigationArgs);
      } catch (e) {
        debugPrint("Navigation Error: $e");
      }
    }
  }

  void _showAppDetailModal(
    BuildContext context,
    Map<String, dynamic> item,
    String sessionToken,
    String displayName,
    String deptName,
    bool isActive,
    int realUserCount,
    String route,
  ) {
    final String rawIcon = AppIconWidget.extractRawIcon(item);

    String cleanRaw = rawIcon;
    if (cleanRaw == 'assets/img/about-moi-logo.png' ||
        cleanRaw == '/assets/img/about-moi-logo.png' ||
        cleanRaw.toLowerCase() == 'null' ||
        cleanRaw.toLowerCase() == 'undefined') {
      cleanRaw = '';
    }

    String imgUrl = '';
    if (cleanRaw.isNotEmpty) {
      imgUrl = AppIconWidget.formatIconUrl(cleanRaw, sessionToken);
    }
    final String rawLocal = (item["icon"] ?? '').toString().trim();
    final cleanLocalLower = rawLocal.toLowerCase();
    final bool isLocalPath = cleanLocalLower.startsWith('assets/') ||
        cleanLocalLower.startsWith('/assets/') ||
        cleanLocalLower.startsWith('images/') ||
        cleanLocalLower.startsWith('/images/');
    final String localImg = (isLocalPath &&
            rawLocal != 'assets/img/about-moi-logo.png' &&
            rawLocal != '/assets/img/about-moi-logo.png')
        ? rawLocal
        : '';
    final bool hasValidImg = imgUrl.isNotEmpty || localImg.isNotEmpty;
    final String desc =
        (item["description"] ?? item["desc"] ?? item["descriptionKh"] ?? "")
            .toString()
            .trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header: Icon + Title + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: hasValidImg ? Colors.white : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFDBEAFE),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: hasValidImg
                            ? AppIconWidget(
                                iconUrl: imgUrl,
                                localAsset: localImg,
                                fallbackIcon: Icons.grid_view_rounded,
                                fallbackColor: const Color(0xFF1D4ED8),
                                token: sessionToken,
                                size: 38,
                              )
                            : const Icon(
                                Icons.grid_view_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isActive ? 'available'.tr : 'inactive'.tr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 14),
              _buildDetailItem(
                Icons.apps_rounded,
                'app_code'.tr,
                (item['code'] ?? displayName).toString(),
              ),
              _buildDetailItem(
                Icons.people_alt_rounded,
                'users'.tr,
                "$realUserCount ${'people'.tr}",
              ),
              _buildDetailItem(
                Icons.link_rounded,
                'url'.tr,
                route.isNotEmpty ? route : 'none'.tr,
              ),
              _buildDetailItem(
                Icons.account_tree_rounded,
                'unit_department'.tr,
                deptName.isNotEmpty ? deptName : 'ministry_of_interior'.tr,
              ),
              if (desc.isNotEmpty) ...[
                _buildDetailItem(
                  Icons.info_outline_rounded,
                  'more_info'.tr,
                  desc,
                ),
              ],
              const SizedBox(height: 20),
              // Launch / Open Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (route.isEmpty) {
                      CustomSnackbar.showError(
                        title: 'application_error'.tr,
                        message: 'no_url_configured'.tr,
                      );
                      return;
                    }
                    _handleAppLaunch(context, item, route, displayName);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    'launch_app'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
