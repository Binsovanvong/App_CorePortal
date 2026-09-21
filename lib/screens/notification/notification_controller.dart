import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum NotificationTimeGroup { today, yesterday, earlier }

enum NotificationType {
  feature,
  security,
  maintenance,
  announcement,
  release,
  general,
}

class NotificationController extends GetxController {
  final notifications = <AppNotification>[
    // Today
    AppNotification(
      title: "New Feature Available",
      description:
          "Dark mode and enhanced analytics are now available in the latest version.",
      date: "09:30 AM • Apr 22, 2025",
      type: NotificationType.feature,
      group: NotificationTimeGroup.today,
      isRead: false,
    ),
    AppNotification(
      title: "Security Update",
      description:
          "Two-factor authentication has been enabled for your administrator account.",
      date: "07:15 AM • Apr 22, 2025",
      type: NotificationType.security,
      group: NotificationTimeGroup.today,
      isRead: false,
    ),
    // Yesterday
    AppNotification(
      title: "System Maintenance",
      description:
          "The system will be undergoing scheduled maintenance on Sunday from 1:00 AM to 3:00 AM.",
      date: "Yesterday, 04:20 PM",
      type: NotificationType.maintenance,
      group: NotificationTimeGroup.yesterday,
      isRead: true,
    ),
    AppNotification(
      title: "New Policy Announcement",
      description:
          "General Department of Digital Government has published a new guideline.",
      date: "Yesterday, 11:00 AM",
      type: NotificationType.announcement,
      group: NotificationTimeGroup.yesterday,
      isRead: true,
    ),
    // Earlier
    AppNotification(
      title: "Version 2.0 Released",
      description:
          "Enjoy a faster experience, improved portal performance, and modern interface.",
      date: "May 30, 2026",
      type: NotificationType.release,
      group: NotificationTimeGroup.earlier,
      isRead: true,
    ),
  ].obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<AppNotification> get todayNotifications => notifications
      .where((n) =>
          (n.group ?? NotificationTimeGroup.today) ==
          NotificationTimeGroup.today)
      .toList();

  List<AppNotification> get yesterdayNotifications => notifications
      .where((n) => n.group == NotificationTimeGroup.yesterday)
      .toList();

  List<AppNotification> get earlierNotifications => notifications
      .where((n) => n.group == NotificationTimeGroup.earlier)
      .toList();

  void markAsRead(int index) {
    if (index >= 0 && index < notifications.length) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  void markItemAsRead(AppNotification item) {
    item.isRead = true;
    notifications.refresh();
  }

  void markAllAsRead() {
    for (var item in notifications) {
      item.isRead = true;
    }
    notifications.refresh();
  }
}

class AppNotification {
  final String title;
  final String description;
  final String date;
  final NotificationType? type;
  final NotificationTimeGroup? group;
  bool isRead;

  AppNotification({
    required this.title,
    required this.description,
    required this.date,
    this.type = NotificationType.general,
    this.group = NotificationTimeGroup.today,
    this.isRead = false,
  });

  NotificationTimeGroup get effectiveGroup =>
      group ?? NotificationTimeGroup.today;

  NotificationType get effectiveType {
    if (type != null) return type!;
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('feature')) return NotificationType.feature;
    if (lowerTitle.contains('security')) return NotificationType.security;
    if (lowerTitle.contains('maintenance')) return NotificationType.maintenance;
    if (lowerTitle.contains('policy') || lowerTitle.contains('announcement')) {
      return NotificationType.announcement;
    }
    if (lowerTitle.contains('version') || lowerTitle.contains('release')) {
      return NotificationType.release;
    }
    return NotificationType.general;
  }

  IconData get icon {
    switch (effectiveType) {
      case NotificationType.feature:
        return Icons.auto_awesome;
      case NotificationType.security:
        return Icons.shield_rounded;
      case NotificationType.maintenance:
        return Icons.build_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.release:
        return Icons.article_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color get iconBgColor {
    switch (effectiveType) {
      case NotificationType.feature:
        return const Color(0xFFEFF6FF); // soft blue
      case NotificationType.security:
        return const Color(0xFFE0F2FE); // soft sky blue
      case NotificationType.maintenance:
        return const Color(0xFFDCFCE7); // soft mint green
      case NotificationType.announcement:
        return const Color(0xFFFEF3C7); // soft warm amber
      case NotificationType.release:
        return const Color(0xFFF3E8FF); // soft lavender purple
      case NotificationType.general:
        return const Color(0xFFEFF6FF);
    }
  }

  Color get iconColor {
    switch (effectiveType) {
      case NotificationType.feature:
        return const Color(0xFF2563EB); // vibrant blue
      case NotificationType.security:
        return const Color(0xFF0284C7); // sky blue
      case NotificationType.maintenance:
        return const Color(0xFF16A34A); // emerald green
      case NotificationType.announcement:
        return const Color(0xFFD97706); // amber
      case NotificationType.release:
        return const Color(0xFF9333EA); // purple
      case NotificationType.general:
        return const Color(0xFF2563EB);
    }
  }
}