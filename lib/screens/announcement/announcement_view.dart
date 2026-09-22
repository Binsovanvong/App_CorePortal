import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/announcement/announcement_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/announcement_detail_dialog.dart';

class AnnouncementView extends GetView<AnnouncementController> {
  const AnnouncementView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = Get.arguments == 'admin';
    final TextEditingController searchController = TextEditingController(
      text: controller.searchQuery.value,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
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
            ),
          ),

          // Subtle soft bottom curve wave matching concept
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 240,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SubtleBackgroundWavePainter(),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isAdmin),
                Expanded(
                  child: isAdmin
                      ? _buildAdminBody(context, searchController)
                      : _buildUserBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAdmin) {
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () {
                controller.isCategoryDropdownOpen.value = false;
                Get.back();
              },
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
                  'announcement'.tr,
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
                const SizedBox(height: 5),
                Text(
                  'announcement_subtitle'.tr,
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
          if (isAdmin) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddEditAnnouncementDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'create_new'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 0),
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCategoryDropdown(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": 'all_categories'.tr,
        "icon": Icons.grid_view_rounded,
        "color": const Color(0xFF1D4ED8),
      },
      {
        "title": 'urgent'.tr,
        "icon": Icons.bolt_rounded,
        "color": const Color(0xffEF4444),
      },
      {
        "title": 'policy'.tr,
        "icon": Icons.gavel_rounded,
        "color": const Color(0xff9333EA),
      },
      {
        "title": 'event'.tr,
        "icon": Icons.event_rounded,
        "color": const Color(0xffD97706),
      },
      {
        "title": 'general'.tr,
        "icon": Icons.info_outline_rounded,
        "color": const Color(0xff475569),
      },
    ];

    return Obx(() {
      final currentSelection = controller.selectedCategory.value;
      final isOpen = controller.isCategoryDropdownOpen.value;

      IconData displayIcon = Icons.grid_view_rounded;
      Color accentColor = const Color(0xFF1D4ED8);

      if (currentSelection == 'urgent'.tr || currentSelection == "បន្ទាន់") {
        displayIcon = Icons.bolt_rounded;
        accentColor = const Color(0xffEF4444);
      } else if (currentSelection == 'policy'.tr || currentSelection == "គោលការណ៍") {
        displayIcon = Icons.gavel_rounded;
        accentColor = const Color(0xff9333EA);
      } else if (currentSelection == 'event'.tr || currentSelection == "ព្រឹត្តិការណ៍") {
        displayIcon = Icons.event_rounded;
        accentColor = const Color(0xffD97706);
      } else if (currentSelection == 'general'.tr || currentSelection == "ទូទៅ") {
        displayIcon = Icons.info_outline_rounded;
        accentColor = const Color(0xff475569);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => controller.isCategoryDropdownOpen.value = !isOpen,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOpen ? accentColor : const Color(0xffE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF163774).withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(displayIcon, color: accentColor, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      currentSelection,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F265C),
                      ),
                    ),
                  ),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff64748B),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            child: isOpen
                ? Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xffE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF163774).withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: menuItems.map((item) {
                        final String title = item["title"] as String;
                        final IconData icon = item["icon"] as IconData;
                        final Color itemAccentColor = item["color"] as Color;
                        final bool isSelected = currentSelection == title;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                controller.selectedCategory.value = title;
                                controller.isCategoryDropdownOpen.value = false;
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? itemAccentColor.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? itemAccentColor.withOpacity(0.12)
                                            : const Color(0xffF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        icon,
                                        size: 16,
                                        color: isSelected
                                            ? itemAccentColor
                                            : const Color(0xff64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? itemAccentColor
                                              : const Color(0xff1E293B),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: itemAccentColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }

  Widget _buildUserStatusChips() {
    final chips = [
      {
        'label': 'ទាំងអស់',
        'icon': Icons.notifications_rounded,
        'values': ['ស្ថានភាពទាំងអស់', 'ទាំងអស់'],
        'selectValue': 'ស្ថានភាពទាំងអស់',
      },
      {
        'label': 'ផ្សាយ',
        'icon': Icons.article_outlined,
        'values': ['ផ្សព្វផ្សាយ', 'ផ្សាយ'],
        'selectValue': 'ផ្សព្វផ្សាយ',
      },
      {
        'label': 'ព្រាង',
        'icon': Icons.bookmark_outline_rounded,
        'values': ['ព្រាង'],
        'selectValue': 'ព្រាង',
      },
    ];

    return Obx(() {
      final selectedStatus = controller.selectedStatus.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 2, 20, 16),
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _buildStatusChip(chips[i], selectedStatus),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildStatusChip(
    Map<String, dynamic> chip,
    String selectedStatus,
  ) {
    final List<String> matchValues = chip['values'] as List<String>;
    final bool isSelected = matchValues.contains(selectedStatus);
    final String label = chip['label'] as String;
    final IconData icon = chip['icon'] as IconData;
    final String selectValue = chip['selectValue'] as String;

    return GestureDetector(
      onTap: () => controller.selectedStatus.value = selectValue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.kantumruyPro(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchAnnouncements(),
      color: const Color(0xFF163774),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildUserCategoryDropdown(context),
            _buildUserStatusChips(),
            Obx(() {
              if (controller.isLoading.value) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF163774)),
                  ),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return _buildErrorState();
              }

              final paginatedList = controller.paginatedAnnouncements;
              if (paginatedList.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 20,
                    ),
                    itemCount: paginatedList.length,
                    itemBuilder: (context, index) {
                      final announcement = paginatedList[index];
                      if (index == 0 && controller.currentPage.value == 1) {
                        return _buildFeaturedCard(context, announcement);
                      }

                      final String category =
                          announcement['category']?.toString() ?? 'OFFICIAL';
                      final String title =
                          announcement['title']?.toString() ??
                          announcement['titleEn']?.toString() ??
                          'គ្មានចំណងជើង';
                      final String time =
                          announcement['createdAt']?.toString() ??
                          announcement['time']?.toString() ??
                          '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _newsCard(
                          category: category.toUpperCase(),
                          title: title,
                          time: _formatKhmerDate(time, short: true),
                          onTap: () =>
                              _showAnnouncementDialog(context, announcement),
                        ),
                      );
                    },
                  ),
                  _buildPaginationControls(),
                  const SizedBox(height: 100),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBody(
    BuildContext context,
    TextEditingController searchController,
  ) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchAdminAnnouncements(),
      color: const Color(0xFF163774),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildStatsCardsRow(),
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (val) => controller.searchQuery.value = val,
                    style: GoogleFonts.kantumruyPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'search_announcements'.tr,
                      hintStyle: GoogleFonts.kantumruyPro(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: const Color(0xffF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF163774)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _buildCustomDropdown(
                            label: 'category'.tr,
                            value: controller.selectedCategory.value,
                            items: [
                              'all_categories'.tr,
                              'urgent'.tr,
                              'policy'.tr,
                              'event'.tr,
                              'general'.tr,
                            ],
                            onChanged: (val) {
                              if (val != null)
                                controller.selectedCategory.value = val;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => _buildCustomDropdown(
                            label: 'status'.tr,
                            value: controller.selectedStatus.value,
                            items: [
                              'all_statuses'.tr,
                              'published'.tr,
                              'draft'.tr,
                            ],
                            onChanged: (val) {
                              if (val != null)
                                controller.selectedStatus.value = val;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _buildDatePickerField(
                            context,
                            label: 'start_date'.tr,
                            selectedDate: controller.startDate.value,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    controller.startDate.value ??
                                    DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                controller.startDate.value = picked;
                            },
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 8, right: 8, top: 22),
                        child: Text(
                          "→",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Obx(
                          () => _buildDatePickerField(
                            context,
                            label: 'end_date'.tr,
                            selectedDate: controller.endDate.value,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    controller.endDate.value ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                controller.endDate.value = picked;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    final hasFilter =
                        controller.searchQuery.value.isNotEmpty ||
                        (controller.selectedCategory.value != 'all_categories'.tr &&
                            controller.selectedCategory.value != "ប្រភេទទាំងអស់") ||
                        (controller.selectedStatus.value != 'all_statuses'.tr &&
                            controller.selectedStatus.value != "ស្ថានភាពទាំងអស់") ||
                        controller.startDate.value != null ||
                        controller.endDate.value != null;
                    if (!hasFilter) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            controller.clearFilters();
                            searchController.clear();
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                          label: Text(
                            'clear_filters'.tr,
                            style: GoogleFonts.kantumruyPro(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoading.value) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF163774)),
                  ),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return _buildErrorState();
              }

              final paginatedList = controller.paginatedAnnouncements;
              if (paginatedList.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: paginatedList.length,
                    itemBuilder: (context, index) {
                      final announcement = paginatedList[index];
                      final globalIndex =
                          (controller.currentPage.value - 1) *
                              controller.itemsPerPage +
                          index +
                          1;
                      return _buildAdminAnnouncementCard(
                        context,
                        globalIndex,
                        announcement,
                      );
                    },
                  ),
                  _buildPaginationControls(),
                  const SizedBox(height: 80),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAnnouncementCard(
    BuildContext context,
    int index,
    Map<String, dynamic> announcement,
  ) {
    final String title =
        announcement['title']?.toString() ??
        announcement['titleEn']?.toString() ??
        'គ្មានចំណងជើង';
    final String content =
        announcement['content']?.toString() ??
        announcement['body']?.toString() ??
        '';
    final String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .trim();
    final String category =
        (announcement['category'] ?? announcement['priority'] ?? 'GENERAL')
            .toString()
            .toUpperCase();
    final String status = (announcement['status'] ?? 'DRAFT')
        .toString()
        .toUpperCase();
    final String time = announcement['createdAt']?.toString() ?? '';

    Color categoryBgColor = const Color(0xffCCFBF1);
    Color categoryTextColor = const Color(0xff0D9488);
    String khmerCategory = "ទូទៅ";

    if (category == 'URGENT' || category == 'IMPORTANT') {
      categoryBgColor = const Color(0xffFEE2E2);
      categoryTextColor = const Color(0xffEF4444);
      khmerCategory = "បន្ទាន់";
    } else if (category == 'POLICY') {
      categoryBgColor = const Color(0xffF3E8FF);
      categoryTextColor = const Color(0xff9333EA);
      khmerCategory = "គោលការណ៍";
    } else if (category == 'EVENT') {
      categoryBgColor = const Color(0xffFEF3C7);
      categoryTextColor = const Color(0xffD97706);
      khmerCategory = "ព្រឹត្តិការណ៍";
    }

    Color statusBgColor = const Color(0xffF1F5F9);
    Color statusTextColor = const Color(0xff64748B);
    String khmerStatus = "ព្រាង";

    if (status == 'PUBLISHED' || status == 'ACTIVE') {
      statusBgColor = const Color(0xffDCFCE7);
      statusTextColor = const Color(0xff16A34A);
      khmerStatus = "ផ្សព្វផ្សាយ";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Text(
                  "ល.រ $index",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    khmerCategory,
                    style: GoogleFonts.kantumruyPro(
                      color: categoryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    khmerStatus,
                    style: GoogleFonts.kantumruyPro(
                      color: statusTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                if (cleanContent.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    cleanContent,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatKhmerDate(time, short: true),
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Row(
                  children: [
                    _buildAdminActionButton(
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF163774),
                      onTap: () =>
                          _showAnnouncementDialog(context, announcement),
                    ),
                    const SizedBox(width: 10),
                    _buildAdminActionButton(
                      icon: Icons.edit_rounded,
                      color: const Color(0xffD97706),
                      onTap: () => _showAddEditAnnouncementDialog(
                        context,
                        announcement: announcement,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildAdminActionButton(
                      icon: Icons.delete_rounded,
                      color: const Color(0xffEF4444),
                      onTap: () =>
                          _showConfirmDeleteDialog(context, announcement),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showAddEditAnnouncementDialog(
    BuildContext context, {
    Map<String, dynamic>? announcement,
  }) {
    final bool isEdit = announcement != null;
    final titleCtrl = TextEditingController(
      text: announcement != null
          ? (announcement['title'] ?? announcement['titleEn'] ?? '').toString()
          : '',
    );
    final contentCtrl = TextEditingController(
      text: announcement != null
          ? (announcement['content'] ?? announcement['body'] ?? '').toString()
          : '',
    );

    String selectedCat = "ទូទៅ";
    if (isEdit) {
      final cat = (announcement['category'] ?? announcement['priority'] ?? '')
          .toString()
          .toUpperCase();
      if (cat == 'URGENT' || cat == 'IMPORTANT')
        selectedCat = "បន្ទាន់";
      else if (cat == 'POLICY')
        selectedCat = "គោលការណ៍";
      else if (cat == 'EVENT')
        selectedCat = "ព្រឹត្តិការណ៍";
    }

    String selectedStat = "ផ្សព្វផ្សាយ";
    if (isEdit) {
      final stat = (announcement['status'] ?? '').toString().toUpperCase();
      if (stat == 'DRAFT' || stat == 'INACTIVE') selectedStat = "ព្រាង";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit
                        ? 'edit_announcement'.tr
                        : 'create_announcement'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'announcement_title'.tr + ' *',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.kantumruyPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'announcement_title'.tr + '...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF163774),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return DropdownButtonFormField<String>(
                              value: selectedCat,
                              items:
                                  const [
                                        "បន្ទាន់",
                                        "គោលការណ៍",
                                        "ព្រឹត្តិការណ៍",
                                        "ទូទៅ",
                                      ]
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => selectedCat = val);
                              },
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 13,
                                color: const Color(0xff0F172A),
                              ),
                              decoration: InputDecoration(
                                labelText: 'category'.tr + ' *',
                                labelStyle: GoogleFonts.kantumruyPro(
                                  fontSize: 12,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return DropdownButtonFormField<String>(
                              value: selectedStat,
                              items: const ["ផ្សព្វផ្សាយ", "ព្រាង"]
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => selectedStat = val);
                              },
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 13,
                                color: const Color(0xff0F172A),
                              ),
                              decoration: InputDecoration(
                                labelText: "ស្ថានភាព *",
                                labelStyle: GoogleFonts.kantumruyPro(
                                  fontSize: 12,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'announcement_content'.tr + ' *',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: GoogleFonts.kantumruyPro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'announcement_content'.tr + '...',
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF163774),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'cancel'.tr,
                          style: GoogleFonts.kantumruyPro(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty ||
                              contentCtrl.text.trim().isEmpty) {
                            CustomSnackbar.showWarning(
                              message: 'please_fill_required'.tr,
                            );
                            return;
                          }
                          if (isEdit) {
                            final id = announcement['id']?.toString() ?? '';
                            controller.updateAnnouncement(
                              id: id,
                              title: titleCtrl.text.trim(),
                              content: contentCtrl.text.trim(),
                              status: selectedStat == 'ផ្សព្វផ្សាយ'
                                  ? 'PUBLISHED'
                                  : 'DRAFT',
                              priority: selectedCat == 'បន្ទាន់'
                                  ? 'IMPORTANT'
                                  : 'NORMAL',
                            );
                          } else {
                            controller.createAnnouncement(
                              title: titleCtrl.text.trim(),
                              content: contentCtrl.text.trim(),
                              status: selectedStat == 'ផ្សព្វផ្សាយ'
                                  ? 'PUBLISHED'
                                  : 'DRAFT',
                              priority: selectedCat == 'បន្ទាន់'
                                  ? 'IMPORTANT'
                                  : 'NORMAL',
                            );
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 0),
                          backgroundColor: const Color(0xFF163774),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'save'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDeleteDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  'delete'.tr + ' ' + 'announcement'.tr + '?',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'delete_announcement_confirm'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: GoogleFonts.kantumruyPro(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final id = announcement['id']?.toString() ?? '';
                          if (id.isNotEmpty) controller.deleteAnnouncement(id);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 0),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'delete'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.kantumruyPro(
              color: const Color(0xFF163774),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: safeValue,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff1E293B),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF163774),
            size: 20,
          ),
          elevation: 2,
          dropdownColor: Colors.white,
          style: GoogleFonts.kantumruyPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1E293B),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            filled: true,
            fillColor: const Color(0xffF8FAFC),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF163774),
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    final String dateText = selectedDate != null
        ? "${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.year}"
        : "mm/dd/yyyy";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.kantumruyPro(
              color: const Color(0xFF163774),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selectedDate != null
                        ? const Color(0xff1E293B)
                        : Colors.grey.shade400,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: selectedDate != null
                      ? const Color(0xFF163774)
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _newsCard({
    required String category,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    String khmerCat = category;
    Color catColor = const Color(0xFF163774);
    Color catBg = const Color(0xFF163774).withOpacity(0.08);

    final upperCat = category.toUpperCase();
    if (upperCat == 'URGENT' || upperCat == 'បន្ទាន់') {
      khmerCat = "បន្ទាន់";
      catColor = const Color(0xffEF4444);
      catBg = const Color(0xffEF4444).withOpacity(0.08);
    } else if (upperCat == 'POLICY' || upperCat == 'គោលការណ៍') {
      khmerCat = "គោលការណ៍";
      catColor = const Color(0xff9333EA);
      catBg = const Color(0xff9333EA).withOpacity(0.08);
    } else if (upperCat == 'EVENT' || upperCat == 'ព្រឹត្តិការណ៍') {
      khmerCat = "ព្រឹត្តិការណ៍";
      catColor = const Color(0xffD97706);
      catBg = const Color(0xffD97706).withOpacity(0.08);
    } else {
      khmerCat = "ទូទៅ";
      catColor = const Color(0xFF163774);
      catBg = const Color(0xFF163774).withOpacity(0.08);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: catColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: catBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        khmerCat,
                        style: GoogleFonts.kantumruyPro(
                          color: catColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'read_more'.tr,
                      style: GoogleFonts.kantumruyPro(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: catColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDialog(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    showAnnouncementDetailDialog(context, announcement);
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) {
    final String time =
        announcement['createdAt']?.toString() ??
        announcement['time']?.toString() ??
        '';
    final String title =
        announcement['title']?.toString() ??
        announcement['titleEn']?.toString() ??
        'គ្មានចំណងជើង';
    final String titleKh = announcement['titleKh']?.toString() ?? '';
    final String content =
        announcement['content']?.toString() ?? announcement['body'] ?? '';
    final String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAnnouncementDialog(context, announcement),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF163774), Color(0xFF102652)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF163774).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.campaign_rounded,
                                size: 14,
                                color: Color(0xFF163774),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'latest_announcement'.tr,
                                style: GoogleFonts.kantumruyPro(
                                  color: const Color(0xFF163774),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (time.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatKhmerDate(time, short: true),
                                style: GoogleFonts.kantumruyPro(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff1E293B),
                        height: 1.3,
                      ),
                    ),
                    if (titleKh.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        titleKh,
                        style: GoogleFonts.kantumruyPro(
                          color: const Color(0xFF163774),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Divider(
                      height: 24,
                      color: Color(0xffF1F5F9),
                      thickness: 1.2,
                    ),
                    Text(
                      cleanContent,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14,
                        color: const Color(0xff475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'read_more'.tr,
                          style: GoogleFonts.kantumruyPro(
                            color: const Color(0xFF163774),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Color(0xFF163774),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'access_restricted'.tr,
              style: GoogleFonts.kantumruyPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.kantumruyPro(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.fetchAnnouncements(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'retry'.tr,
                style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffD4AF37),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNoAnnouncementIllustration(),
            const SizedBox(height: 28),
            Text(
              'គ្មានសេចក្តីជូនដំណឹងនៅឡើយទេ',
              textAlign: TextAlign.center,
              style: GoogleFonts.kantumruyPro(
                fontSize: 19.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F265C),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'មិនទាន់សេចក្តីជូនដំណឹងប្រកាស និងបង្ហោះនៅឡើយទេ',
              textAlign: TextAlign.center,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => controller.fetchAnnouncements(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ផ្ទុកឡើងវិញ',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAnnouncementIllustration() {
    return SizedBox(
      width: 170,
      height: 145,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating dot to the left
          Positioned(
            left: 12,
            top: 55,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Floating dot to the top right
          Positioned(
            right: 22,
            top: 16,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main circle backdrop
          Container(
            width: 126,
            height: 126,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
          ),
          // Custom painted bell, sound waves, and bold slash
          CustomPaint(
            size: const Size(90, 90),
            painter: _MutedBellPainter(),
          ),
        ],
      ),
    );
  }

  String _formatKhmerDate(String? dateStr, {bool short = false}) {
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
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      String toKhmer(String input) {
        const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
        String res = input;
        for (int i = 0; i < english.length; i++) {
          res = res.replaceAll(english[i], khmer[i]);
        }
        return res;
      }

      if (short)
        return '${toKhmer(day)} $month ${toKhmer(year)}, ${toKhmer(hour)}:${toKhmer(minute)}';
      return 'ថ្ងៃទី ${toKhmer(day)} ខែ$month ឆ្នាំ${toKhmer(year)} ម៉ោង ${toKhmer(hour)}:${toKhmer(minute)}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPaginationControls() {
    return Obx(() {
      final total = controller.totalPages;
      final current = controller.currentPage.value;

      // Determine dot indicator parameters (up to 5 dots with sliding window)
      final int dotCount = total < 5 ? total : 5;
      int startPage = 1;
      if (total > 5) {
        if (current <= 3) {
          startPage = 1;
        } else if (current >= total - 2) {
          startPage = total - 4;
        } else {
          startPage = current - 2;
        }
      }

      final bool canPrev = current > 1;
      final bool canNext = current < total;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous Button ("មុន")
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canPrev
                    ? () {
                        controller.currentPage.value--;
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: canPrev
                        ? const Color(0xFFEEF3FA)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: canPrev
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'prev_page'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: canPrev
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center Page Info & Dots
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${'page_of'.tr} ',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      TextSpan(
                        text: '$current',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0851D7),
                        ),
                      ),
                      TextSpan(
                        text: ' ${'of'.tr} $total',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Dots Indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(dotCount, (index) {
                    final pageNum = startPage + index;
                    final bool isActive = pageNum == current;
                    return GestureDetector(
                      onTap: () {
                        controller.currentPage.value = pageNum;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: isActive ? 7.5 : 6,
                        height: isActive ? 7.5 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF3885FE)
                              : const Color(0xFFDCE6F5),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Next Button ("បន្ទាប់")
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canNext
                    ? () {
                        controller.currentPage.value++;
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: canNext
                        ? const Color(0xFF3885FE)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canNext
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3885FE).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'next_page'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: canNext
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: canNext
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsCardsRow() {
    return Obx(() {
      final list = controller.announcements;
      final totalCount = list.length;
      final publishedCount = list.where((ann) {
        final status = (ann['status'] ?? '').toString().toUpperCase();
        return status == 'PUBLISHED' ||
            status == 'ACTIVE' ||
            status == 'ផ្សព្វផ្សាយ' ||
            status.isEmpty;
      }).length;
      final scheduledCount = 0;
      final draftCount = list.where((ann) {
        final status = (ann['status'] ?? '').toString().toUpperCase();
        return status == 'DRAFT' || status == 'INACTIVE' || status == 'ព្រាង';
      }).length;

      final double screenWidth = Get.width;
      final int crossAxisCount = screenWidth > 600 ? 4 : 2;
      final double childAspectRatio = screenWidth > 600
          ? 2.5
          : (screenWidth < 360 ? 1.6 : 1.9);

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildStatCardItem(
            title: 'total_announcements'.tr,
            value: totalCount.toString(),
            subtitle: 'all_announcements_in_system'.tr,
            icon: Icons.campaign_rounded,
            iconColor: const Color(0xff2563EB),
            bgIconColor: const Color(0xffEFF6FF),
          ),
          _buildStatCardItem(
            title: 'published'.tr,
            value: publishedCount.toString(),
            subtitle: 'visible_to_users'.tr,
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xff10B981),
            bgIconColor: const Color(0xffECFDF5),
          ),
          _buildStatCardItem(
            title: 'scheduled'.tr,
            value: scheduledCount.toString(),
            subtitle: 'waiting_to_publish'.tr,
            icon: Icons.date_range_rounded,
            iconColor: const Color(0xffD97706),
            bgIconColor: const Color(0xffFEF3C7),
          ),
          _buildStatCardItem(
            title: 'draft'.tr,
            value: draftCount.toString(),
            subtitle: 'saved_as_draft'.tr,
            icon: Icons.save_rounded,
            iconColor: const Color(0xff7C3AED),
            bgIconColor: const Color(0xffF3E8FF),
          ),
        ],
      );
    });
  }

  Widget _buildStatCardItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 9,
                    color: const Color(0xff94A3B8),
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

class _MutedBellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bellPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;

    // Top loop/knob
    canvas.drawCircle(const Offset(45, 23), 3.5, bellPaint);

    // Bell body
    final Path bellPath = Path();
    bellPath.moveTo(45, 26);
    bellPath.cubicTo(55, 27, 60, 36, 61, 48);
    bellPath.cubicTo(62, 53, 65, 58, 69, 61);
    bellPath.lineTo(21, 61);
    bellPath.cubicTo(25, 58, 28, 53, 29, 48);
    bellPath.cubicTo(30, 36, 35, 27, 45, 26);
    bellPath.close();
    canvas.drawPath(bellPath, bellPaint);

    // Lip of bell
    final RRect lip = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 59, 54, 5),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(lip, bellPaint);

    // Clapper
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(45, 62), width: 13, height: 11),
      0,
      3.14159,
      true,
      bellPaint,
    );

    // 3 Sound wave arcs on right
    final soundPaint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: const Offset(45, 45), radius: 32),
      -0.35,
      0.22,
      false,
      soundPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(45, 45), radius: 38),
      -0.18,
      0.26,
      false,
      soundPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(45, 45), radius: 32),
      0.15,
      0.22,
      false,
      soundPaint,
    );

    // Bold diagonal slash
    final slashPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(23, 22), const Offset(67, 68), slashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SubtleBackgroundWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFE2EDFB).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.65,
      size.height * 0.25,
      size.width,
      size.height * 0.45,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFE8F1FC).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.4,
      size.height * 0.45,
      size.width * 0.7,
      size.height * 0.75,
      size.width,
      size.height * 0.55,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
