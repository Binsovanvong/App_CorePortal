import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core_portal/screens/announcement/announcement_detail_view.dart';

/// Shows the Announcement Detail Screen matching the official concept mockup.
void showAnnouncementDetailDialog(
  BuildContext context,
  Map<String, dynamic> announcement,
) {
  Get.to(() => AnnouncementDetailView(announcement: announcement));
}

/// Formats datetime to Khmer string: "ថ្ងៃទី ១៧ ខែកញ្ញា ឆ្នាំ ២០២៦ ម៉ោង ០៥:០៥"
String formatDetailKhmerDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final dateTime = DateTime.tryParse(dateStr)?.toLocal();
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

    String toKhmer(String input) {
      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
      String res = input;
      for (int i = 0; i < english.length; i++) {
        res = res.replaceAll(english[i], khmer[i]);
      }
      return res;
    }

    final day = toKhmer(dateTime.day.toString());
    final month = khmerMonths[dateTime.month - 1];
    final year = toKhmer(dateTime.year.toString());
    final hour = toKhmer(dateTime.hour.toString().padLeft(2, '0'));
    final minute = toKhmer(dateTime.minute.toString().padLeft(2, '0'));

    return 'ថ្ងៃទី $day ខែ$month ឆ្នាំ $year ម៉ោង $hour:$minute';
  } catch (_) {
    return dateStr;
  }
}
