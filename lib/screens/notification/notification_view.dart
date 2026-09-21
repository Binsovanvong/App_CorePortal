import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_portal/screens/notification/notification_controller.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Royal Blue Gradient Header with Curved Bottom
          _buildHeaderBanner(context),

          // 2. Notification List
          Expanded(
            child: Obx(() {
              if (controller.notifications.isEmpty) {
                return _buildEmptyState();
              }

              final todayItems = controller.todayNotifications;
              final yesterdayItems = controller.yesterdayNotifications;
              final earlierItems = controller.earlierNotifications;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today Section ("ថ្មីៗ")
                    if (todayItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'today'.tr,
                        pillColor: const Color(0xFFD97706), // Amber
                      ),
                      ...todayItems.map(_buildNotificationCard),
                      const SizedBox(height: 8),
                    ],

                    // Yesterday Section ("ម្សិលមិញ")
                    if (yesterdayItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'yesterday'.tr,
                        pillColor: const Color(0xFF16A34A), // Green
                      ),
                      ...yesterdayItems.map(_buildNotificationCard),
                      const SizedBox(height: 8),
                    ],

                    // Earlier Section ("មុនៗ")
                    if (earlierItems.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'earlier'.tr,
                        pillColor: const Color(0xFF64748B), // Slate Grey
                      ),
                      ...earlierItems.map(_buildNotificationCard),
                    ],
                    const SizedBox(height: 36),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Top Royal Blue Gradient Header matching concept
  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A3E82), // Corporate Navy
            Color(0xFF163774), // Official Navy
            Color(0xFF102652), // Deep Navy
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular White Back Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF163774),
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'notification'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'notifications_subtitle'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // Notification Bell Quick Action
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.markAllAsRead,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 22,
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

  /// Section Header with colored vertical pill and trailing line
  Widget _buildSectionHeader({
    required String title,
    required Color pillColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.kantumruyPro(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Notification Item Card matching concept
  Widget _buildNotificationCard(AppNotification item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => controller.markItemAsRead(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Squircle Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Content Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.description,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4.5),
                          Text(
                            item.date,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing: Unread Blue Dot + Chevron
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!item.isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state when no notifications exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFBFDBFE).withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 34,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_notifications'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'no_notifications_desc'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
