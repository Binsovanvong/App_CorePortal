import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:core_portal/screens/admin/admin_controller.dart';

import 'package:core_portal/screens/super_admin/super_admin_role_list_view.dart';

import 'package:core_portal/widgets/custom_snackbar.dart';

import 'package:core_portal/routes/page_route.dart';

import 'package:core_portal/screens/admin/admin_edit_user_groups_view.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/widgets/empty_apps_widget.dart';
import 'package:get_storage/get_storage.dart';

class AdminView extends GetView<AdminController> {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardHome(context),

      const AdminAppsListView(),

      buildUsersTab(context),

      _buildAdminSettingsTab(context),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      body: Obx(() => pages[controller.currentIndex.value]),

      bottomNavigationBar: Obx(
        () => Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),

          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),

            borderRadius: BorderRadius.circular(35),

            border: Border.all(
              color: const Color(0xffD4AF37).withOpacity(0.2),

              width: 1.5,
            ),

            boxShadow: [
              BoxShadow(
                color: const Color(0xffD4AF37).withOpacity(0.08),

                blurRadius: 25,

                offset: const Offset(0, 12),
              ),

              BoxShadow(
                color: Colors.black.withOpacity(0.03),

                blurRadius: 10,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'dashboard'.tr),

              _buildNavItem(1, Icons.grid_view_rounded, 'application'.tr),

              _buildNavItem(2, Icons.people_alt_rounded, 'users'.tr),

              _buildNavItem(3, Icons.settings_rounded, 'settings'.tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),

      behavior: HitTestBehavior.opaque,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),

        curve: Curves.easeInOut,

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF4FB) : Colors.transparent,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: isSelected
                ? const Color(0xFF163774).withOpacity(0.3)
                : Colors.transparent,

            width: 1,
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              icon,

              color: isSelected
                  ? const Color(0xFF163774)
                  : Colors.grey.shade500,

              size: 20,
            ),

            const SizedBox(width: 6),

            AnimatedCrossFade(
              firstChild: Text(
                label,

                style: GoogleFonts.kantumruyPro(
                  color: const Color(0xFF163774),

                  fontSize: 12,

                  fontWeight: FontWeight.bold,

                  letterSpacing: 0.1,
                ),
              ),

              secondChild: const SizedBox.shrink(),

              crossFadeState: isSelected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,

              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  /// ==========================================

  /// 1. DASHBOARD TAB VIEW

  /// ==========================================

  Widget _buildDashboardHome(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        centerTitle: true,

        title: Text(
          'admin_dashboard'.tr,

          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,

            fontSize: 16,

            color: const Color(0xff0F172A),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,

              color: Color(0xff64748B),

              size: 22,
            ),

            onPressed: () => _confirmLogout(context),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: controller.fetchDashboardData,

        color: const Color(0xFF163774),

        child: Obx(() {
          if (controller.isLoading.value && controller.appsList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF163774)),
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildWelcomeCard(),

                    const SizedBox(height: 20),

                    _buildStatsGrid(),

                    const SizedBox(height: 20),

                    _buildAppsSection(),

                    const SizedBox(height: 20),

                    _buildRecentAnnouncementsSection(),

                    const SizedBox(height: 20),

                    _buildAuditLogsSection(),

                    const SizedBox(height: 20),

                    _buildQuickAccessSection(context),

                    const SizedBox(height: 30),
                  ],
                ),
              ),

              if (controller.isBackingUp.value) _buildBackupOverlay(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163774), Color(0xFF102652)],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.15),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'welcome_admin'.tr,

                style: GoogleFonts.kantumruyPro(
                  color: Colors.white,

                  fontWeight: FontWeight.bold,

                  fontSize: 18,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,

                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),

                  borderRadius: BorderRadius.circular(30),
                ),

                child: Text(
                  "Online",

                  style: GoogleFonts.poppins(
                    color: Colors.white,

                    fontWeight: FontWeight.bold,

                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'welcome_admin_subtitle'.tr,

            style: GoogleFonts.kantumruyPro(
              color: Colors.white.withOpacity(0.85),

              fontSize: 13,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 12,

      mainAxisSpacing: 12,

      childAspectRatio: 1.3,

      children: [
        _buildStatCard(
          'total_apps'.tr,

          controller.totalApps.value.toString(),

          Icons.grid_view_rounded,

          const Color(0xffEFF6FF),

          const Color(0xff2563EB),
        ),

        _buildStatCard(
          'total_users'.tr,

          controller.totalUsers.value.toString(),

          Icons.people_alt_rounded,

          const Color(0xffECFDF5),

          const Color(0xff10B981),
        ),

        _buildStatCard(
          'running_apps'.tr,

          controller.runningApps.value.toString(),

          Icons.toggle_on_rounded,

          const Color(0xffFEF3C7),

          const Color(0xffD97706),
        ),

        _buildStatCard(
          'announcement'.tr,

          controller.announcementsCount.value.toString(),

          Icons.notifications_active_rounded,

          const Color(0xffFEE2E2),

          const Color(0xffEF4444),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,

    String value,

    IconData icon,

    Color bgIconColor,

    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xffF1F5F9)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),

            blurRadius: 4,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: bgIconColor,

                  shape: BoxShape.circle,
                ),

                child: Icon(icon, color: accentColor, size: 18),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,

                color: Colors.grey[300],

                size: 10,
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.kantumruyPro(
                  fontSize: 11,

                  color: const Color(0xff64748B),

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,

                style: GoogleFonts.poppins(
                  fontSize: 20,

                  fontWeight: FontWeight.bold,

                  color: const Color(0xff0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              'recent_announcements'.tr,

              style: GoogleFonts.kantumruyPro(
                fontSize: 14,

                fontWeight: FontWeight.bold,

                color: const Color(0xff0F172A),
              ),
            ),

            TextButton(
              onPressed: () =>
                  Get.toNamed(AppRoutes.announcement, arguments: 'admin'),

              child: Text(
                '${'view_all'.tr} >',

                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,

                  fontWeight: FontWeight.bold,

                  color: const Color(0xFF163774),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (controller.announcementsList.isEmpty)
          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(vertical: 24),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: const Color(0xffE2E8F0)),
            ),

            child: Center(
              child: Text(
                'no_announcements'.tr,

                style: GoogleFonts.kantumruyPro(
                  color: Colors.grey,

                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            itemCount: controller.announcementsList.length > 2
                ? 2
                : controller.announcementsList.length,

            separatorBuilder: (context, index) => const SizedBox(height: 8),

            itemBuilder: (context, index) {
              final announcement = controller.announcementsList[index];

              return _buildAnnouncementItemCard(announcement);
            },
          ),
      ],
    );
  }

  Widget _buildAnnouncementItemCard(Map<String, dynamic> ann) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xffF1F5F9)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: const EdgeInsets.all(8),

            decoration: const BoxDecoration(
              color: Color(0xffFEF3C7),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.campaign_outlined,

              color: Color(0xffD97706),

              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  ann['title'] ?? '',

                  style: GoogleFonts.kantumruyPro(
                    fontWeight: FontWeight.bold,

                    fontSize: 13,

                    color: const Color(0xff1E293B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  ann['date'] ?? '',

                  style: GoogleFonts.poppins(
                    fontSize: 10,

                    color: const Color(0xff94A3B8),

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'recent_activities'.tr,

          style: GoogleFonts.kantumruyPro(
            fontSize: 14,

            fontWeight: FontWeight.bold,

            color: const Color(0xff0F172A),
          ),
        ),

        const SizedBox(height: 12),

        if (controller.auditLogs.isEmpty)
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: const Color(0xffE2E8F0)),
            ),

            child: Center(
              child: Text(
                'no_recent_activities'.tr,

                style: GoogleFonts.kantumruyPro(
                  color: Colors.grey,

                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: const Color(0xffF1F5F9)),
            ),

            child: ListView.separated(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: controller.auditLogs.length > 3
                  ? 3
                  : controller.auditLogs.length,

              separatorBuilder: (context, index) =>
                  const Divider(height: 24, color: Color(0xffF1F5F9)),

              itemBuilder: (context, index) {
                final log = controller.auditLogs[index];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),

                      decoration: const BoxDecoration(
                        color: Color(0xffDCFCE7),

                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.campaign_rounded,

                        color: Color(0xff16A34A),

                        size: 14,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            log['title'] ?? '',

                            style: GoogleFonts.kantumruyPro(
                              fontWeight: FontWeight.bold,

                              fontSize: 12,

                              color: const Color(0xff0F172A),
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            log['desc'] ?? '',

                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11,

                              color: const Color(0xff475569),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            log['time'] ?? '',

                            style: GoogleFonts.poppins(
                              fontSize: 9,

                              color: const Color(0xff94A3B8),

                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAppsSection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xffE2E8F0)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  const Icon(
                    Icons.grid_view_rounded,

                    color: Color(0xFF163774),

                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'application'.tr,

                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,

                      fontWeight: FontWeight.bold,

                      color: const Color(0xff0F172A),
                    ),
                  ),
                ],
              ),

              TextButton(
                onPressed: () => Get.to(() => const AdminAppsListView()),

                child: Text(
                  '${'view_all'.tr} >',

                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12,

                    fontWeight: FontWeight.bold,

                    color: const Color(0xFF163774),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildAppTableHeader(),

          const Divider(height: 1, color: Color(0xffE2E8F0)),

          if (controller.appsList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: EmptyAppsWidget(
                isCompact: true,
                title: 'no_applications_yet'.tr,
                subtitle: 'no_applications_yet_desc'.tr,
                actionText: 'refresh'.tr,
                onAction: controller.fetchDashboardData,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: controller.appsList.length,

              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xffF1F5F9)),

              itemBuilder: (context, index) {
                final app = controller.appsList[index];

                return _buildAppTableRow(index + 1, app);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),

      child: Row(
        children: [
          SizedBox(
            width: 30,

            child: Text(
              "#",

              style: GoogleFonts.kantumruyPro(
                fontSize: 11,

                fontWeight: FontWeight.bold,

                color: const Color(0xff64748B),
              ),
            ),
          ),

          Expanded(
            child: Text(
              'app_name'.tr,

              style: GoogleFonts.kantumruyPro(
                fontSize: 11,

                fontWeight: FontWeight.bold,

                color: const Color(0xff64748B),
              ),
            ),
          ),

          Text(
            'status'.tr,

            style: GoogleFonts.kantumruyPro(
              fontSize: 11,

              fontWeight: FontWeight.bold,

              color: const Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTableRow(int number, Map<String, dynamic> app) {
    final titleKh = app['titleKh'] ?? 'កម្មវិធី';

    final titleEn = app['titleEn'] ?? 'App';

    final bool isActive = app['isActive'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),

      child: Row(
        children: [
          SizedBox(
            width: 30,

            child: Text(
              number.toString(),

              style: GoogleFonts.poppins(
                fontSize: 13,

                fontWeight: FontWeight.w600,

                color: const Color(0xff475569),
              ),
            ),
          ),

          Expanded(
            child: Row(
              children: [
                _buildAppIconAvatar(app),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        titleKh,

                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13,

                          fontWeight: FontWeight.bold,

                          color: const Color(0xff0F172A),
                        ),
                      ),

                      Text(
                        titleEn,

                        style: GoogleFonts.poppins(
                          fontSize: 10,

                          fontWeight: FontWeight.bold,

                          color: const Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xffECFDF5)
                  : const Color(0xffFEE2E2),

              borderRadius: BorderRadius.circular(20),

              border: Border.all(
                color: isActive
                    ? const Color(0xffA7F3D0)
                    : const Color(0xffFECACA),
              ),
            ),

            child: Text(
              isActive ? 'active'.tr : 'inactive'.tr,

              style: GoogleFonts.kantumruyPro(
                fontSize: 10,

                fontWeight: FontWeight.bold,

                color: isActive
                    ? const Color(0xff065F46)
                    : const Color(0xff991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIconAvatar(Map<String, dynamic> app) {
    final String iconPath = app['icon'] ?? 'assets/img/about-moi-logo.png';

    final String iconUrl = app['iconUrl'] ?? '';

    return Container(
      width: 32,

      height: 32,

      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: const Color(0xffE2E8F0)),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),

        child: AppIconWidget(
          iconUrl: iconUrl,
          localAsset: iconPath,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Icon(Icons.bolt_outlined, color: Color(0xFF163774), size: 18),

            const SizedBox(width: 8),

            Text(
              'quick_access'.tr,

              style: GoogleFonts.kantumruyPro(
                fontSize: 14,

                fontWeight: FontWeight.bold,

                color: const Color(0xff0F172A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 10,

          mainAxisSpacing: 10,

          childAspectRatio: 1.5,

          children: [
            _buildQuickAccessBtn(
              'add_app'.tr,

              Icons.add_to_photos_rounded,

              const Color(0xff2563EB),

              () => Get.to(
                () => const AdminAppsListView(),
              ), // Navigates to Apps List
            ),

            _buildQuickAccessBtn(
              'users'.tr,

              Icons.person_search_rounded,

              const Color(0xff10B981),

              () => controller.changeTab(2), // Navigates to Users Tab
            ),

            _buildQuickAccessBtn(
              'roles_permissions'.tr,

              Icons.verified_user_rounded,

              const Color(0xff7C3AED),

              () => Get.to(() => const SuperAdminRoleListView()),
            ),

            _buildQuickAccessBtn(
              'create_announcement'.tr,

              Icons.add_comment_rounded,

              const Color(0xffD97706),

              () => Get.toNamed(AppRoutes.announcement, arguments: 'admin'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessBtn(
    String label,

    IconData icon,

    Color iconColor,

    VoidCallback onTap,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,

        foregroundColor: iconColor,

        elevation: 0,

        side: const BorderSide(color: Color(0xffE2E8F0)),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      onPressed: onTap,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(height: 8),

          Text(
            label,

            textAlign: TextAlign.center,

            style: GoogleFonts.kantumruyPro(
              fontSize: 11,

              fontWeight: FontWeight.bold,

              color: const Color(0xff1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================

  /// 2. APPS LIST TAB VIEW

  /// ==========================================

  /// ==========================================

  /// 3. USERS LIST TAB VIEW

  /// ==========================================

  Widget buildUsersTab(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildUsersHeader(context),
            Expanded(
              child: Obx(() {
                final list = controller.filteredUsers;
                final bool isLoading = controller.isLoading.value;

                return RefreshIndicator(
                  onRefresh: controller.fetchDashboardData,
                  color: const Color(0xFF1D4ED8),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        /// Search Bar Section matching reference mockup
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF163774).withOpacity(0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    onChanged: (val) =>
                                        controller.userSearchQuery.value = val,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 14,
                                      color: const Color(0xff0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'ស្វែងរកអ្នកប្រើប្រាស់...',
                                      hintStyle: GoogleFonts.kantumruyPro(
                                        fontSize: 14,
                                        color: const Color(0xff94A3B8),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                Obx(() {
                                  if (controller.userSearchQuery.value.isNotEmpty) {
                                    return GestureDetector(
                                      onTap: () {
                                        controller.userSearchQuery.value = '';
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 14),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: Color(0xff94A3B8),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Direct user list or loading / empty state
                        if (isLoading && list.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1D4ED8),
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else if (list.isEmpty)
                          if (controller.userSearchQuery.value.trim().isEmpty &&
                              controller.usersList.isEmpty)
                            _buildSearchUsersGuide(context)
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_off_rounded,
                                      size: 48,
                                      color: const Color(
                                        0xFF163774,
                                      ).withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'no_data_user'.tr,
                                      style: GoogleFonts.kantumruyPro(
                                        color: const Color(0xff94A3B8),
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              top: 2,
                              bottom: 120,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              return _buildUserItemCard(
                                context,
                                list[index],
                                index,
                              );
                            },
                          ),
                      ],
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

  Widget _buildSearchUsersGuide(BuildContext context) {
    return Obx(() {
      final isKm = LocalizationService.currentLanguageCode.value == 'km';

      final title = isKm
          ? 'របៀបស្វែងរកអ្នកប្រើប្រាស់'
          : 'How to search users';
      final subtitle = isKm
          ? 'ប្រើប្រអប់ស្វែងរកដើម្បីស្វែងរកអ្នកប្រើប្រាស់ក្នុងប្រព័ន្ធយ៉ាងឆាប់រហ័ស។'
          : 'Use the search box to quickly find users\nin the system.';
      final whatTitle = isKm ? 'អ្វីដែលអ្នកអាចស្វែងរកបាន' : 'What you can search';
      final whatDesc = isKm
          ? 'ឈ្មោះពេញ ឈ្មោះគណនី ឬអាសយដ្ឋានអ៊ីមែល។'
          : 'Full name, username, or email address.';
      final tipsTitle = isKm ? 'គន្លឹះស្វែងរក' : 'Search tips';
      final tipsDesc = isKm
          ? 'បញ្ចូលយ៉ាងតិច ២-៣ តួអក្សរដើម្បីទទួលបានលទ្ធផលល្អប្រសើរ។\nការស្វែងរកមិនប្រកាន់តួអក្សរតូចធំឡើយ។'
          : 'Type at least 2–3 characters for better results.\nSearch is not case-sensitive.';
      final exTitle = isKm ? 'ឧទាហរណ៍' : 'Examples';
      final exDesc = isKm
          ? 'ស្វែងរក "admin" ឬ "@moi.com" ដើម្បីស្វែងរកអ្នកប្រើប្រាស់។'
          : 'Search "admin" or "@moi.com" to find users.';
      final noteTitle = isKm ? 'សម្គាល់' : 'Note';
      final noteDesc = isKm
          ? 'ប្រសិនបើអ្នករកមិនឃើញអ្នកប្រើប្រាស់ដែលអ្នកកំពុងស្វែងរក សូមសាកល្បងប្រើពាក្យគន្លឹះផ្សេង ឬទាក់ទងអ្នកគ្រប់គ្រងប្រព័ន្ធរបស់អ្នក។'
          : "If you can't find the user you're looking for,\ntry using different keywords or check with your administrator.";

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Top Icon
            const Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Color(0xff8E9BAE),
            ),
            const SizedBox(height: 18),
            // Title
            Text(
              title,
              style: GoogleFonts.kantumruyPro(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              subtitle,
              style: GoogleFonts.kantumruyPro(
                fontSize: 14,
                color: const Color(0xff8E9BAE),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 0.8),
            const SizedBox(height: 16),

            // Item 1: What you can search
            _buildSearchGuideItem(
              icon: Icons.search_rounded,
              title: whatTitle,
              subtitle: whatDesc,
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xffF1ECE1), height: 1, thickness: 0.8),
            const SizedBox(height: 14),

            // Item 2: Search tips
            _buildSearchGuideItem(
              icon: Icons.lightbulb_outline_rounded,
              title: tipsTitle,
              subtitle: tipsDesc,
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xffF1ECE1), height: 1, thickness: 0.8),
            const SizedBox(height: 14),

            // Item 3: Examples
            _buildSearchGuideItem(
              icon: Icons.description_outlined,
              title: exTitle,
              subtitle: exDesc,
            ),
            const SizedBox(height: 22),

            // Bottom Note Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xff8E9BAE),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        noteTitle,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    noteDesc,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      color: const Color(0xff8E9BAE),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    });
  }

  Widget _buildSearchGuideItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xffFAF3E5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF163774),
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12.5,
                  color: const Color(0xff8E9BAE),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          if (canPop) ...[
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(23),
                  onTap: () => Get.back(),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Center: Title + Subtitle matching mockup
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ប្រើប្រាស់ប្រព័ន្ធ',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F265C),
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'គ្រប់គ្រង និងគ្រប់គ្រងអ្នកប្រើប្រាស់',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatKhmerUnit(dynamic unit) {
    return AdminController.formatDepartmentToKhmer(unit);
  }

  Widget _buildUserItemCard(
    BuildContext context,
    Map<String, dynamic> user,
    int index,
  ) {
    final email = (user['email'] ?? '').toString().trim();
    final String status = (user['status'] ?? 'ACTIVE').toString();
    final bool isSelf = controller.isSelfUser(user);
    final bool canEdit = controller.canEditUser(user);

    // Resolve displayName and username
    final String rawUsername = (user['username'] ?? user['userName'] ?? user['accountName'] ?? '').toString().trim();
    final String rawId = (user['id'] ?? user['keycloakUserId'] ?? '').toString().trim();
    final String cleanUsername = (rawUsername.isNotEmpty && rawUsername != rawId)
        ? rawUsername
        : '';

    String rawDisplayName = (user['displayName'] ??
            user['display_name'] ??
            user['fullName'] ??
            user['full_name'] ??
            user['name_kh'] ??
            user['nameKh'] ??
            '')
        .toString()
        .trim();

    // Check Keycloak attributes map
    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) && user['attributes'] is Map) {
      final attrDisp = user['attributes']['displayName'] ?? user['attributes']['display_name'];
      if (attrDisp is List && attrDisp.isNotEmpty) {
        rawDisplayName = attrDisp.first.toString().trim();
      } else if (attrDisp is String) {
        rawDisplayName = attrDisp.trim();
      }
    }

    // Check firstName and lastName
    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final first = (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
      final last = (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
      if (first.isNotEmpty || last.isNotEmpty) {
        rawDisplayName = '$first $last'.trim();
      }
    }

    // Check if logged-in user (self) has cached display name
    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) && isSelf) {
      final box = GetStorage();
      final selfName = (box.read('user_display_name') ?? box.read('displayName') ?? '').toString().trim();
      if (selfName.isNotEmpty) {
        rawDisplayName = selfName;
      }
    }

    // Check user['name'] only if it's different from username
    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final rawName = (user['name'] ?? '').toString().trim();
      if (rawName.isNotEmpty && rawName.toLowerCase() != cleanUsername.toLowerCase()) {
        rawDisplayName = rawName;
      }
    }

    // Smart fallback for dot-formatted usernames (e.g. bin.sovanvong -> Sovanvong Bin)
    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      if (cleanUsername.contains('.')) {
        final parts = cleanUsername.split('.');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          final p0 = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
          final p1 = '${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
          rawDisplayName = '$p1 $p0';
        } else {
          rawDisplayName = parts
              .where((p) => p.isNotEmpty)
              .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
              .join(' ');
        }
      }
    }

    final String displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : (cleanUsername.isNotEmpty ? cleanUsername : 'User');

    final String username = cleanUsername.isNotEmpty
        ? cleanUsername
        : (email.isNotEmpty ? email : displayName);

    // Khmer unit name resolution
    String displayUnit = (user['unit'] ?? user['department'] ?? '').toString().trim();
    if (displayUnit.isEmpty || displayUnit == '—' || displayUnit == '-') {
      final rawGroups = user['groups'];
      if (rawGroups is List && rawGroups.isNotEmpty) {
        final g = rawGroups.first.toString().trim();
        displayUnit = g.startsWith('/') ? g.substring(1).split('/').first : g;
      }
    }
    displayUnit = _formatKhmerUnit(displayUnit);

    // Extract 2 initials (e.g. Sovanvong Bin -> SB, bin.sovanvong -> BS, huy.sambath -> HS)
    String initial = 'U';
    final nameForInitial = displayName.isNotEmpty ? displayName : cleanUsername;
    if (nameForInitial.isNotEmpty) {
      final parts = nameForInitial.trim().split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        final clean = nameForInitial.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (clean.length >= 2) {
          initial = clean.substring(0, 2).toUpperCase();
        } else if (clean.isNotEmpty) {
          initial = clean.toUpperCase();
        }
      }
    }

    final bool isActive = status.toUpperCase() == 'ACTIVE';

    // Pastel Avatar Themes from mockup
    final avatarThemes = [
      {'bg': const Color(0xFFDBEAFE), 'text': const Color(0xFF1D4ED8)}, // Blue (BI)
      {'bg': const Color(0xFFF3E8FF), 'text': const Color(0xFF7E22CE)}, // Purple (HU)
      {'bg': const Color(0xFFFFEDD5), 'text': const Color(0xFFC2410C)}, // Peach (ME)
      {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF15803D)}, // Mint
      {'bg': const Color(0xFFFEE2E2), 'text': const Color(0xFFB91C1C)}, // Rose
    ];
    final theme = avatarThemes[index % avatarThemes.length];

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar + Name info + 3 Circle Action Buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Pastel Avatar with 2 initials
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme['bg'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: theme['text'],
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // DisplayName (Up) + Username (Down)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // 3 Circular Action Buttons (Eye, Edit, Three-dots)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserCircleBtn(
                    icon: Icons.visibility_outlined,
                    onTap: () => _showUserDetailDialog(context, user),
                  ),
                  const SizedBox(width: 6),
                  _buildUserCircleBtn(
                    icon: Icons.edit_outlined,
                    iconColor: canEdit
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFCBD5E1),
                    onTap: canEdit
                        ? () => Get.to(() => AdminEditUserGroupsView(user: user))
                        : () {
                            CustomSnackbar.showWarning(
                              message:
                                  'មិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
                            );
                          },
                  ),
                  const SizedBox(width: 6),
                  _buildUserCircleBtn(
                    icon: Icons.more_vert_rounded,
                    iconColor: const Color(0xFF64748B),
                    onTap: () => _showUserActionsMenu(context, user, index),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          ),

          // Row 2: Unit (Group) + Status Badge
          Row(
            children: [
              // Unit (Group)
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'unit_group'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            displayUnit,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Self Badge (គណនីផ្ទាល់ខ្លួន)
              if (isSelf) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'គណនីផ្ទាល់ខ្លួន',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Status Badge (• ដំណើរការ)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
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
                      isActive ? 'active'.tr : 'inactive'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildUserCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 33,
          height: 33,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16.5,
              color: iconColor ?? const Color(0xFF1D4ED8),
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetailDialog(BuildContext context, Map<String, dynamic> user) {
    final String rawUsername = (user['username'] ?? user['userName'] ?? user['accountName'] ?? '').toString().trim();
    final String rawId = (user['id'] ?? user['keycloakUserId'] ?? '').toString().trim();
    final String cleanUsername = (rawUsername.isNotEmpty && rawUsername != rawId)
        ? rawUsername
        : '';

    String rawDisplayName = (user['displayName'] ??
            user['display_name'] ??
            user['fullName'] ??
            user['full_name'] ??
            user['name_kh'] ??
            user['nameKh'] ??
            '')
        .toString()
        .trim();

    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) && user['attributes'] is Map) {
      final attrDisp = user['attributes']['displayName'] ?? user['attributes']['display_name'];
      if (attrDisp is List && attrDisp.isNotEmpty) {
        rawDisplayName = attrDisp.first.toString().trim();
      } else if (attrDisp is String) {
        rawDisplayName = attrDisp.trim();
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final first = (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
      final last = (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
      if (first.isNotEmpty || last.isNotEmpty) {
        rawDisplayName = '$first $last'.trim();
      }
    }

    final box = GetStorage();
    final currentUname = (box.read('username') ?? '').toString().trim().toLowerCase();
    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) &&
        cleanUsername.toLowerCase() == currentUname) {
      final selfName = (box.read('user_display_name') ?? box.read('displayName') ?? '').toString().trim();
      if (selfName.isNotEmpty) {
        rawDisplayName = selfName;
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final rawName = (user['name'] ?? '').toString().trim();
      if (rawName.isNotEmpty && rawName.toLowerCase() != cleanUsername.toLowerCase()) {
        rawDisplayName = rawName;
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      if (cleanUsername.contains('.')) {
        final parts = cleanUsername.split('.');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          final p0 = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
          final p1 = '${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
          rawDisplayName = '$p1 $p0';
        }
      }
    }

    final String displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : (cleanUsername.isNotEmpty ? cleanUsername : 'User');

    final String username = cleanUsername.isNotEmpty
        ? cleanUsername
        : (displayName != 'User' ? displayName : 'admin');

    final role = (user['role'] ?? user['roleName'] ?? 'User').toString();
    final status = (user['status'] ?? 'ACTIVE').toString();
    final unit = _formatKhmerUnit(user['unit'] ?? user['department']);
    final bool isActive = status.toUpperCase() == 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF2563EB),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'user_info_title'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'user_detail_subtitle'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xFFF1F5F9),
                  height: 1,
                  thickness: 1,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tile 0: Display Name / Full Name
                      _buildModernUserDetailTile(
                        icon: Icons.badge_outlined,
                        iconBgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        label: 'full_name'.tr,
                        value: displayName,
                      ),

                      // Tile 1: Account Name / Username
                      _buildModernUserDetailTile(
                        icon: Icons.mail_outline_rounded,
                        iconBgColor: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF475569),
                        label: 'account_number_or_name'.tr,
                        value: username,
                      ),

                      // Tile 2: Role
                      _buildModernUserDetailTile(
                        icon: Icons.people_alt_rounded,
                        iconBgColor: const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFF9333EA),
                        label: 'role'.tr,
                        value: role,
                      ),

                      // Tile 3: Unit (Ministry)
                      _buildModernUserDetailTile(
                        icon: Icons.apartment_rounded,
                        iconBgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        label: 'unit_ministry'.tr,
                        value: unit,
                      ),

                      // Tile 4: Status
                      _buildModernUserStatusTile(isActive: isActive),

                      const SizedBox(height: 18),

                      // Bottom Reset Password Action Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Get.toNamed(
                              AppRoutes.resetPassword,
                              arguments: {
                                'username': username,
                                'displayName': displayName,
                                'user': user,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0EDFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sync_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'កំណត់ពាក្យសម្ងាត់ឡើងវិញ (Reset Password)',
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }

  Widget _buildModernUserDetailTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 12,
          thickness: 1,
          color: Color(0xFFF8FAFC),
        ),
      ],
    );
  }

  Widget _buildModernUserStatusTile({required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF16A34A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'status'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFA7F3D0).withOpacity(0.6)
                          : const Color(0xFFFECACA),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isActive
                            ? 'កំពុងដំណើរការ (ACTIVE)'
                            : 'ផ្អាកដំណើរការ (INACTIVE)',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserActionsMenu(
    BuildContext context,
    Map<String, dynamic> user,
    int index,
  ) {
    final bool canEdit = controller.canEditUser(user);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blue,
                ),
                title: Text(
                  'view_details'.tr,
                  style: GoogleFonts.kantumruyPro(fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showUserDetailDialog(context, user);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: canEdit ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  'កែសម្រួលក្រុម',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: canEdit ? const Color(0xFF0F172A) : Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (canEdit) {
                    Get.to(() => AdminEditUserGroupsView(user: user));
                  } else {
                    CustomSnackbar.showWarning(
                      message:
                          'មិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: canEdit ? Colors.red : Colors.grey,
                ),
                title: Text(
                  '${'delete'.tr} ${'users'.tr}',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: canEdit ? Colors.red : Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (canEdit) {
                    _confirmDeleteUser(context, index);
                  } else {
                    CustomSnackbar.showWarning(
                      message:
                          'មិនអាចលុបគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot delete your own account)',
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${'delete'.tr} ${'users'.tr}',
            style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'delete_user_confirm'.tr,
            style: GoogleFonts.kantumruyPro(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr,
                style: GoogleFonts.kantumruyPro(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.deleteUser(index);
                Navigator.of(context).pop();
              },
              child: Text(
                'delete'.tr,
                style: GoogleFonts.kantumruyPro(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminSettingsTab(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        centerTitle: true,

        title: Text(
          'admin_settings'.tr,

          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,

            fontSize: 16,

            color: const Color(0xff0F172A),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// Admin Profile Welcomer Header
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                border: Border.all(color: const Color(0xffF1F5F9)),
              ),

              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,

                    backgroundColor: Color(0xffF6EBC2),

                    child: Icon(
                      Icons.admin_panel_settings_rounded,

                      color: Color(0xFF163774),

                      size: 36,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "admin admin",

                          style: GoogleFonts.kantumruyPro(
                            fontSize: 16,

                            fontWeight: FontWeight.bold,

                            color: const Color(0xff0F172A),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,

                            vertical: 2,
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xffFEF3C7),

                            borderRadius: BorderRadius.circular(6),
                          ),

                          child: Text(
                            "ADMIN",

                            style: GoogleFonts.poppins(
                              fontSize: 9,

                              fontWeight: FontWeight.bold,

                              color: const Color(0xffD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Category 1: System Management
            Text(
              'management_system'.tr,

              style: GoogleFonts.kantumruyPro(
                fontSize: 12,

                fontWeight: FontWeight.bold,

                color: const Color(0xff64748B),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: const Color(0xffF1F5F9)),
              ),

              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.home_rounded,

                    title: 'go_to_client'.tr,

                    iconColor: const Color(0xFF163774),

                    onTap: () {
                      Get.offAllNamed(AppRoutes.mainPage);
                    },
                  ),

                  const Divider(height: 1, color: Color(0xffF1F5F9)),

                  _buildSettingTile(
                    icon: Icons.backup_rounded,

                    title: 'backup'.tr,

                    iconColor: const Color(0xff2563EB),

                    onTap: () => controller.backupDatabase(),
                  ),

                  const Divider(height: 1, color: Color(0xffF1F5F9)),

                  _buildSettingTile(
                    icon: Icons.cleaning_services_rounded,

                    title: 'clear_cache'.tr,

                    iconColor: const Color(0xff10B981),

                    onTap: () => controller.clearSystemCache(),
                  ),

                  const Divider(height: 1, color: Color(0xffF1F5F9)),

                  _buildSettingTile(
                    icon: Icons.api_rounded,

                    title: 'api_docs'.tr,

                    iconColor: const Color(0xff7C3AED),

                    onTap: () => controller.openApiDocs(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Category 2: Security & Account
            Text(
              'security_account'.tr,

              style: GoogleFonts.kantumruyPro(
                fontSize: 12,

                fontWeight: FontWeight.bold,

                color: const Color(0xff64748B),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: const Color(0xffF1F5F9)),
              ),

              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.lock_rounded,

                    title: 'change_password'.tr,

                    iconColor: const Color(0xffD97706),

                    onTap: () {
                      // Navigate to change password helper
                    },
                  ),

                  const Divider(height: 1, color: Color(0xffF1F5F9)),

                  _buildSettingTile(
                    icon: Icons.logout_rounded,

                    title: 'logout'.tr,

                    iconColor: const Color(0xffEF4444),

                    textColor: const Color(0xffEF4444),

                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,

    required String title,

    required Color iconColor,

    required VoidCallback onTap,

    Color textColor = const Color(0xff1E293B),
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(20),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),

                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: iconColor, size: 20),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,

                style: GoogleFonts.kantumruyPro(
                  fontSize: 13,

                  fontWeight: FontWeight.w600,

                  color: textColor,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,

              color: Colors.grey[400],

              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),

      width: double.infinity,

      height: double.infinity,

      child: Center(
        child: Container(
          width: 280,

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(24),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF163774)),
              ),

              const SizedBox(height: 24),

              Text(
                'backing_up_data'.tr,

                style: GoogleFonts.kantumruyPro(
                  fontWeight: FontWeight.bold,

                  fontSize: 15,

                  color: const Color(0xff1E293B),
                ),
              ),

              const SizedBox(height: 12),

              LinearProgressIndicator(
                value: controller.backupProgress.value,

                backgroundColor: const Color(0xffE2E8F0),

                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF163774),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "${(controller.backupProgress.value * 100).toInt()}%",

                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,

                  color: const Color(0xFF163774),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        title: Text(
          'ចាកចេញពីគណនី',

          style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
        ),

        content: Text(
          'តើអ្នកពិតជាចង់ចាកចេញពីគណនី Admin នេះមែនទេ?',

          style: GoogleFonts.kantumruyPro(),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),

            child: Text(
              'បោះបង់',

              style: GoogleFonts.kantumruyPro(color: Colors.grey),
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF163774),

              foregroundColor: Colors.white,
            ),

            onPressed: () {
              Navigator.of(context).pop();

              controller.logout();
            },

            child: Text('ចាកចេញ', style: GoogleFonts.kantumruyPro()),
          ),
        ],
      ),
    );
  }
}

class AdminAppsListView extends GetView<AdminController> {
  const AdminAppsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,

                  color: Color(0xFF163774),
                ),

                onPressed: () => Navigator.of(context).pop(),
              )
            : null,

        title: Text(
          'application'.tr,

          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,

            fontSize: 16,

            color: const Color(0xff0F172A),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,

              color: Color(0xFF163774),

              size: 24,
            ),

            onPressed: () => Get.to(() => const AdminAppCreateView()),
          ),
        ],
      ),

      body: Obx(() {
        final list = controller.filteredApps;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildAppsStatsRow(controller),

              /// Search Bar and Filters Row
              Container(
                color: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 16,

                  vertical: 12,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        // Search Input
                        Expanded(
                          child: TextField(
                            onChanged: (val) =>
                                controller.appSearchQuery.value = val,

                            decoration: InputDecoration(
                              hintText: 'search_apps'.tr,

                              hintStyle: GoogleFonts.kantumruyPro(
                                fontSize: 13,

                                color: Colors.grey,
                              ),

                              prefixIcon: const Icon(
                                Icons.search_rounded,

                                color: Colors.grey,

                                size: 20,
                              ),

                              filled: true,

                              fillColor: Colors.white,

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,

                                vertical: 8,
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),

                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Status Filter Dropdown
                        Obx(() {
                          final currentStatus =
                              controller.appStatusFilter.value;

                          String statusLabel = 'all_statuses'.tr;

                          if (currentStatus == 'active') {
                            statusLabel = 'active'.tr;
                          } else if (currentStatus == 'inactive') {
                            statusLabel = 'inactive'.tr;
                          }

                          return Theme(
                            data: Theme.of(context).copyWith(
                              hoverColor: Colors.transparent,

                              splashColor: Colors.transparent,

                              highlightColor: Colors.transparent,
                            ),

                            child: PopupMenuButton<String>(
                              onSelected: (value) =>
                                  controller.appStatusFilter.value = value,

                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'all',

                                  child: Text(
                                    'all_statuses'.tr,

                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                PopupMenuItem(
                                  value: 'active',

                                  child: Text(
                                    'active'.tr,

                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                PopupMenuItem(
                                  value: 'inactive',

                                  child: Text(
                                    'inactive'.tr,

                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],

                              child: Container(
                                height: 38,

                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xffEFF6FF),

                                  borderRadius: BorderRadius.circular(10),

                                  border: Border.all(
                                    color: const Color(0xff3B82F6),

                                    width: 1,
                                  ),
                                ),

                                child: Row(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    const Icon(
                                      Icons.filter_alt_outlined,

                                      size: 16,

                                      color: Color(0xff2563EB),
                                    ),

                                    const SizedBox(width: 6),

                                    Text(
                                      statusLabel,

                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 12,

                                        fontWeight: FontWeight.bold,

                                        color: const Color(0xff2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // List Title & Sorting Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Text(
                          'all_applications_list'.tr,

                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14,

                            fontWeight: FontWeight.bold,

                            color: const Color(0xff1E293B),
                          ),
                        ),

                        Obx(() {
                          final currentSort = controller.appSortFilter.value;

                          String sortLabel = 'newest'.tr;

                          if (currentSort == 'name_az') {
                            sortLabel = 'name_az'.tr;
                          } else if (currentSort == 'name_za') {
                            sortLabel = 'name_za'.tr;
                          } else if (currentSort == 'oldest') {
                            sortLabel = 'oldest'.tr;
                          }

                          return PopupMenuButton<String>(
                            onSelected: (value) =>
                                controller.appSortFilter.value = value,

                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'name_az',

                                child: Text(
                                  'name_az'.tr,

                                  style: GoogleFonts.kantumruyPro(fontSize: 13),
                                ),
                              ),

                              PopupMenuItem(
                                value: 'name_za',

                                child: Text(
                                  'name_za'.tr,

                                  style: GoogleFonts.kantumruyPro(fontSize: 13),
                                ),
                              ),

                              PopupMenuItem(
                                value: 'newest',

                                child: Text(
                                  'newest'.tr,

                                  style: GoogleFonts.kantumruyPro(fontSize: 13),
                                ),
                              ),

                              PopupMenuItem(
                                value: 'oldest',

                                child: Text(
                                  'oldest'.tr,

                                  style: GoogleFonts.kantumruyPro(fontSize: 13),
                                ),
                              ),
                            ],

                            child: Container(
                              height: 32,

                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),

                              decoration: BoxDecoration(
                                color: const Color(0xffF8FAFC),

                                borderRadius: BorderRadius.circular(8),

                                border: Border.all(
                                  color: const Color(0xffE2E8F0),
                                ),
                              ),

                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  Text(
                                    sortLabel,

                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 11,

                                      color: const Color(0xff475569),
                                    ),
                                  ),

                                  const SizedBox(width: 4),

                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,

                                    size: 14,

                                    color: Color(0xff475569),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              /// Card list
              list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: EmptyAppsWidget(
                        isCompact: true,
                        title: 'no_applications_yet'.tr,
                        subtitle: 'no_applications_yet_desc'.tr,
                        actionText: 'refresh'.tr,
                        onAction: controller.fetchDashboardData,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,

                      physics: const NeverScrollableScrollPhysics(),

                      padding: const EdgeInsets.symmetric(vertical: 10),

                      itemCount: list.length,

                      itemBuilder: (context, index) {
                        final app = list[index];

                        final originalIndex = controller.appsList.indexOf(app);

                        return _buildAppMobileCard(context, originalIndex, app);
                      },
                    ),
            ],
          ),
        );
      }),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff2563EB),

        elevation: 4,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        onPressed: () => Get.to(() => const AdminAppCreateView()),

        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildAppsStatsRow(AdminController controller) {
    final list = controller.appsList;

    final total = list.length;

    final active = list.where((app) => app['isActive'] == true).length;

    final inactive = list.where((app) => app['isActive'] != true).length;

    final users = controller.totalUsers.value;

    final activePct = total > 0 ? (active / total * 100) : 0.0;

    final inactivePct = total > 0 ? (inactive / total * 100) : 0.0;

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
          title: 'total_apps'.tr,

          value: total.toString(),

          subtitle: 'all_applications'.tr,

          icon: Icons.apps_rounded,

          iconColor: const Color(0xff2563EB),

          bgIconColor: const Color(0xffEFF6FF),
        ),

        _buildStatCardItem(
          title: 'running_apps'.tr,

          value: active.toString(),

          subtitle: "${activePct.toStringAsFixed(1)}% នៃចំនួនសរុប",

          icon: Icons.check_circle_rounded,

          iconColor: const Color(0xff10B981),

          bgIconColor: const Color(0xffECFDF5),
        ),

        _buildStatCardItem(
          title: '${'inactive'.tr} ${'application'.tr}',

          value: inactive.toString(),

          subtitle: "${inactivePct.toStringAsFixed(1)}% នៃចំនួនសរុប",

          icon: Icons.watch_later_outlined,

          iconColor: const Color(0xffD97706),

          bgIconColor: const Color(0xffFEF3C7),
        ),

        _buildStatCardItem(
          title: 'total_users'.tr,

          value: users.toString(),

          subtitle: 'app_access_permission'.tr,

          icon: Icons.people_alt_rounded,

          iconColor: const Color(0xff7C3AED),

          bgIconColor: const Color(0xffF3E8FF),
        ),
      ],
    );
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

  Widget _buildAppMobileCard(
    BuildContext context,

    int originalIndex,

    Map<String, dynamic> app,
  ) {
    final titleKh = app['titleKh'] ?? 'កម្មវិធី';

    final titleEn = app['titleEn'] ?? 'App';

    final route = app['route'] ?? '';

    final bool isActive = app['isActive'] ?? true;

    final ruleType = app['ruleType'] ?? 'អគ្គនាយកដ្ឋាន';

    final ruleValue = app['ruleValue'] ?? 'GDDTM';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

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

      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),

        child: Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: () => _showAppDetailDialog(context, app),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _buildAppIconAvatar(app),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              titleKh,

                              style: GoogleFonts.kantumruyPro(
                                fontSize: 14,

                                fontWeight: FontWeight.bold,

                                color: const Color(0xff0F172A),
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              titleEn,

                              style: GoogleFonts.poppins(
                                fontSize: 10,

                                fontWeight: FontWeight.bold,

                                color: const Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _buildStatusBadge(isActive),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Divider(height: 1, color: Color(0xffF1F5F9)),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,

                        size: 16,

                        color: Color(0xff2563EB),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          route,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: GoogleFonts.poppins(
                            fontSize: 11,

                            color: const Color(0xff2563EB),

                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,

                        size: 16,

                        color: Color(0xff64748B),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "ច្បាប់: $ruleType ($ruleValue)",

                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,

                          color: const Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      _buildMobileActionBtn(
                        icon: Icons.visibility_outlined,

                        label: 'view'.tr,

                        color: const Color(0xff2563EB),

                        onTap: () => _showAppDetailDialog(context, app),
                      ),

                      const SizedBox(width: 8),

                      _buildMobileActionBtn(
                        icon: Icons.edit_outlined,

                        label: 'edit'.tr,

                        color: const Color(0xff475569),

                        onTap: () => Get.to(
                          () => AdminAppCreateView(
                            isEdit: true,

                            appIndex: originalIndex,

                            appData: app,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      _buildMobileActionBtn(
                        icon: Icons.delete_outline_rounded,

                        label: 'delete'.tr,

                        color: const Color(0xffEF4444),

                        onTap: () =>
                            _confirmDeleteApp(context, originalIndex, titleKh),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: isActive ? const Color(0xffECFDF5) : const Color(0xffFEE2E2),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: isActive ? const Color(0xffA7F3D0) : const Color(0xffFECACA),
        ),
      ),

      child: Text(
        isActive ? 'active'.tr : 'inactive'.tr,

        style: GoogleFonts.kantumruyPro(
          fontSize: 9,

          fontWeight: FontWeight.bold,

          color: isActive ? const Color(0xff065F46) : const Color(0xff991B1B),
        ),
      ),
    );
  }

  Widget _buildMobileActionBtn({
    required IconData icon,

    required String label,

    required Color color,

    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(8),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

        decoration: BoxDecoration(
          color: color.withOpacity(0.06),

          borderRadius: BorderRadius.circular(8),

          border: Border.all(color: color.withOpacity(0.12)),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icon, color: color, size: 14),

            const SizedBox(width: 4),

            Text(
              label,

              style: GoogleFonts.kantumruyPro(
                fontSize: 10,

                fontWeight: FontWeight.bold,

                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIconAvatar(Map<String, dynamic> app) {
    final String iconPath = app['icon'] ?? 'assets/img/about-moi-logo.png';

    final String iconUrl = app['iconUrl'] ?? '';

    return Container(
      width: 38,

      height: 38,

      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: const Color(0xffE2E8F0)),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),

        child: AppIconWidget(
          iconUrl: iconUrl,
          localAsset: iconPath,
          size: 38,
        ),
      ),
    );
  }

  void _showAppDetailDialog(BuildContext context, Map<String, dynamic> app) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text(
          app['titleKh'] ?? 'ព័ត៌មានកម្មវិធី',

          style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildDetailRow('app_name_en'.tr, app['titleEn'] ?? ''),

            _buildDetailRow('app_url_link'.tr, app['route'] ?? ''),

            _buildDetailRow('rule_type'.tr, app['ruleType'] ?? 'អគ្គនាយកដ្ឋាន'),

            _buildDetailRow('rule_value'.tr, app['ruleValue'] ?? 'GDDTM'),

            _buildDetailRow(
              'status'.tr,

              (app['isActive'] ?? true) ? 'active'.tr : 'inactive'.tr,
            ),
          ],
        ),

        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF163774),

              minimumSize: const Size(80, 36),
            ),

            onPressed: () => Navigator.of(context).pop(),

            child: Text(
              'close'.tr,

              style: GoogleFonts.kantumruyPro(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: RichText(
        text: TextSpan(
          style: GoogleFonts.kantumruyPro(color: Colors.black, fontSize: 13),

          children: [
            TextSpan(
              text: "$label: ",

              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            TextSpan(text: val),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteApp(BuildContext context, int originalIndex, String name) {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        title: Text(
          'delete_app'.tr,

          style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
        ),

        content: Text(
          'តើអ្នកពិតជាចង់លុបកម្មវិធី "$name" នេះចេញពីប្រព័ន្ធមែនទេ?',

          style: GoogleFonts.kantumruyPro(),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),

            child: Text(
              'cancel'.tr,

              style: GoogleFonts.kantumruyPro(color: Colors.grey),
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,

              minimumSize: const Size(80, 36),
            ),

            onPressed: () {
              Navigator.of(context).pop();

              controller.deleteApp(originalIndex);
            },

            child: Text(
              'delete'.tr,

              style: GoogleFonts.kantumruyPro(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAppCreateView extends StatefulWidget {
  final bool isEdit;

  final int? appIndex;

  final Map<String, dynamic>? appData;

  const AdminAppCreateView({
    super.key,

    this.isEdit = false,

    this.appIndex,

    this.appData,
  });

  @override
  State<AdminAppCreateView> createState() => _AdminAppCreateViewState();
}

class _AdminAppCreateViewState extends State<AdminAppCreateView> {
  final _controller = Get.find<AdminController>();

  late final TextEditingController nameKhCtrl;

  late final TextEditingController nameEnCtrl;

  late final TextEditingController urlCtrl;

  late final TextEditingController ruleTypeCtrl;

  late final TextEditingController ruleValueCtrl;

  late bool isActive;

  @override
  void initState() {
    super.initState();

    String nameKh = '';

    String nameEn = '';

    String url = '';

    String ruleType = 'អគ្គនាយកដ្ឋាន';

    String ruleValue = 'GDDTM';

    if (widget.isEdit && widget.appData != null) {
      nameKh = widget.appData!['titleKh'] ?? '';

      nameEn = widget.appData!['titleEn'] ?? '';

      url = widget.appData!['route'] ?? '';

      ruleType = widget.appData!['ruleType'] ?? 'អគ្គនាយកដ្ឋាន';

      ruleValue = widget.appData!['ruleValue'] ?? 'GDDTM';
    }

    nameKhCtrl = TextEditingController(text: nameKh);

    nameEnCtrl = TextEditingController(text: nameEn);

    urlCtrl = TextEditingController(text: url);

    ruleTypeCtrl = TextEditingController(text: ruleType);

    ruleValueCtrl = TextEditingController(text: ruleValue);

    isActive = widget.isEdit ? (widget.appData?['isActive'] ?? true) : true;
  }

  @override
  void dispose() {
    nameKhCtrl.dispose();

    nameEnCtrl.dispose();

    urlCtrl.dispose();

    ruleTypeCtrl.dispose();

    ruleValueCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,

            color: Color(0xFF163774),
          ),

          onPressed: () => Navigator.of(context).pop(),
        ),

        title: Text(
          widget.isEdit
              ? 'edit_app'.tr
              : 'add_app'.tr,

          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,

            fontSize: 16,

            color: const Color(0xff0F172A),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// Sub Header
            Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

              decoration: const BoxDecoration(
                color: Colors.white,

                border: Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    widget.isEdit
                        ? 'edit_app'.tr
                        : 'add_app'.tr,

                    style: GoogleFonts.kantumruyPro(
                      fontSize: 22,

                      fontWeight: FontWeight.bold,

                      color: const Color(0xff0F172A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'enter_app_info_desc'.tr,

                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,

                      color: const Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),

            /// Input Fields form card
            Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            _buildInputLabel('${'app_name_kh'.tr} *'),

                            TextField(
                              controller: nameKhCtrl,

                              decoration: _buildInputDecoration(
                                'enter_app_name_kh_hint'.tr,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            _buildInputLabel('${'app_name_en'.tr} *'),

                            TextField(
                              controller: nameEnCtrl,

                              decoration: _buildInputDecoration(
                                'enter_app_name_en_hint'.tr,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildInputLabel("URL *"),

                  TextField(
                    controller: urlCtrl,

                    decoration: _buildInputDecoration(
                      'enter_app_url_hint'.tr,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Access Rules
                  _buildInputLabel('${'access_rule'.tr} *'),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            _buildSubInputLabel('rule_type'.tr),

                            TextField(
                              controller: ruleTypeCtrl,

                              decoration: _buildInputDecoration(
                                "អគ្គនាយកដ្ឋាន",
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            _buildSubInputLabel('rule_value'.tr),

                            TextField(
                              controller: ruleValueCtrl,

                              decoration: _buildInputDecoration('hint_gddtm'.tr),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// Status Select Radio box style
                  _buildInputLabel('status_required'.tr),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusRadioCard('active'.tr, true),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: _buildStatusRadioCard('inactive'.tr, false),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// Action Buttons Save and Cancel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,

                          foregroundColor: const Color(0xff475569),

                          elevation: 0,

                          side: const BorderSide(color: Color(0xffCBD5E1)),

                          minimumSize: const Size(100, 40),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,

                            vertical: 14,
                          ),
                        ),

                        onPressed: () => Navigator.of(context).pop(),

                        child: Text(
                          'cancel'.tr,

                          style: GoogleFonts.kantumruyPro(
                            fontWeight: FontWeight.bold,

                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563EB),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          minimumSize: const Size(100, 40),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,

                            vertical: 14,
                          ),
                        ),

                        onPressed: _saveForm,

                        icon: const Icon(Icons.save_rounded, size: 18),

                        label: Text(
                          'save'.tr,

                          style: GoogleFonts.kantumruyPro(
                            fontWeight: FontWeight.bold,

                            fontSize: 13,
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
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),

      child: Text(
        text,

        style: GoogleFonts.kantumruyPro(
          fontSize: 12,

          fontWeight: FontWeight.bold,

          color: const Color(0xff334155),
        ),
      ),
    );
  }

  Widget _buildSubInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),

      child: Text(
        text,

        style: GoogleFonts.kantumruyPro(
          fontSize: 11,

          color: const Color(0xff64748B),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,

      hintStyle: GoogleFonts.kantumruyPro(
        fontSize: 13,

        color: Colors.grey[400],
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xffE2E8F0)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xffE2E8F0)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.5),
      ),
    );
  }

  Widget _buildStatusRadioCard(String label, bool value) {
    final isSelected = isActive == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          isActive = value;
        });
      },

      child: Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffFEF3C7).withOpacity(0.3)
              : Colors.white,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(
            color: isSelected
                ? const Color(0xffD97706)
                : const Color(0xffE2E8F0),

            width: isSelected ? 1.5 : 1,
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 16,

              height: 16,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: isSelected ? const Color(0xffD97706) : Colors.grey,

                  width: 2,
                ),
              ),

              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(3),

                      decoration: const BoxDecoration(
                        color: Color(0xffD97706),

                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 8),

            Text(
              label,

              style: GoogleFonts.kantumruyPro(
                fontSize: 12,

                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,

                color: isSelected
                    ? const Color(0xff92400E)
                    : const Color(0xff1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm() {
    final nameKh = nameKhCtrl.text.trim();

    final nameEn = nameEnCtrl.text.trim();

    final url = urlCtrl.text.trim();

    final ruleType = ruleTypeCtrl.text.trim();

    final ruleValue = ruleValueCtrl.text.trim();

    if (nameKh.isEmpty ||
        nameEn.isEmpty ||
        url.isEmpty ||
        ruleType.isEmpty ||
        ruleValue.isEmpty) {
      CustomSnackbar.showError(message: 'សូមបំពេញព័ត៌មានអោយបានគ្រប់គ្រាន់');

      return;
    }

    if (widget.isEdit) {
      _controller.updateApp(
        index: widget.appIndex!,

        nameKh: nameKh,

        nameEn: nameEn,

        url: url,

        ruleType: ruleType,

        ruleValue: ruleValue,

        isActive: isActive,
      );
    } else {
      _controller.addNewApp(
        nameKh: nameKh,

        nameEn: nameEn,

        url: url,

        ruleType: ruleType,

        ruleValue: ruleValue,

        isActive: isActive,
      );
    }

    Navigator.of(context).pop();
  }
}

class AdminUsersTabView extends StatelessWidget {
  const AdminUsersTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminView().buildUsersTab(context);
  }
}
