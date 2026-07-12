import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final notifications = <AppNotification>[
    AppNotification(
      title: "New Feature Available",
      description:
          "Dark mode is now available in the latest version.",
      date: "Today",
      icon: Icons.auto_awesome,
    ),
    AppNotification(
      title: "System Maintenance",
      description:
          "The system will be unavailable on Sunday from 1:00 AM to 3:00 AM.",
      date: "Yesterday",
      icon: Icons.build_circle_outlined,
    ),
    AppNotification(
      title: "Version 2.0 Released",
      description:
          "Enjoy a faster experience and improved performance.",
      date: "May 30",
      icon: Icons.system_update,
    ),
  ].obs;

  void markAsRead(int index) {
    notifications[index].isRead = true;
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
  final IconData icon;
  bool isRead;

  AppNotification({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    this.isRead = false,
  });
}