import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:dio/dio.dart' show DioException;
import 'package:core_portal/controllers/nav_controller.dart';

import '../../routes/page_route.dart';

part 'message_binding.dart';
part 'message_controller.dart';

class MessageView extends GetView<MessageViewController> {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(child: _buildHeader()),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xffD4AF37)),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (controller.announcements.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchAnnouncements(),
          color: const Color(0xffD4AF37),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.announcements.length,
            itemBuilder: (context, index) {
              final announcement = controller.announcements[index];
              if (index == 0) {
                return _buildFeaturedCard(announcement);
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
                padding: const EdgeInsets.only(bottom: 20),
                child: _newsCard(
                  category: category.toUpperCase(),
                  title: title,
                  time: _formatKhmerDate(time, short: true),
                  onTap: () => _showAnnouncementDialog(context, announcement),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () {
                if (Get.key.currentState?.canPop() ?? false) {
                  Get.back();
                } else {
                  Get.offAllNamed(AppRoutes.mainPage);
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),

          const SizedBox(width: 14),
          Text(
            "សេចក្តីប្រកាស",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xffD4AF37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsCard({
    required String category,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
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
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xffA88400), width: 5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffA88400).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xffA88400),
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      "អានបន្ថែម",
                      style: TextStyle(
                        color: Color(0xffA88400),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xffA88400),
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
    final String time =
        announcement['createdAt']?.toString() ??
        announcement['time']?.toString() ??
        '';
    final String title =
        announcement['title']?.toString() ??
        announcement['titleEn']?.toString() ??
        'គ្មានចំណងជើង';
    final String content =
        announcement['content']?.toString() ?? announcement['body'] ?? '';
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
                    child: const Text(
                      "សេចក្តីប្រកាស",
                      style: TextStyle(
                        color: Color(0xffA88400),
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
              if (time.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatKhmerDate(time),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1E293B),
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xff475569),
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
                  child: const Text(
                    "បិទ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> announcement) {
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Indicator / Top Accent Gradient
          Container(
            height: 6,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffA88400), Color(0xffF6EBC2)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            size: 14,
                            color: Color(0xffA88400),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "សេចក្តីប្រកាសថ្មីបំផុត",
                            style: TextStyle(
                              color: Color(0xffA88400),
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
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatKhmerDate(time),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1E293B),
                    height: 1.3,
                  ),
                ),
                if (titleKh.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    titleKh,
                    style: const TextStyle(
                      color: Color(0xffA88400),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Divider(
                  height: 32,
                  color: Color(0xffF1F5F9),
                  thickness: 1.5,
                ),
                Text(
                  cleanContent,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff475569),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              "ការចូលប្រើប្រាស់ត្រូវបានកំណត់",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.fetchAnnouncements(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("ព្យាយាមម្តងទៀត"),
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "គ្មានសេចក្តីប្រកាស",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "មិនទាន់មានសេចក្តីប្រកាសនៅឡើយទេ។",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.fetchAnnouncements(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("ផ្ទុកឡើងវិញ"),
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

      // Convert digits to Khmer
      String toKhmer(String input) {
        const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
        String res = input;
        for (int i = 0; i < english.length; i++) {
          res = res.replaceAll(english[i], khmer[i]);
        }
        return res;
      }

      if (short) {
        return '${toKhmer(day)} $month ${toKhmer(year)}, ${toKhmer(hour)}:${toKhmer(minute)}';
      }
      return 'ថ្ងៃទី ${toKhmer(day)} ខែ$month ឆ្នាំ${toKhmer(year)} ម៉ោង ${toKhmer(hour)}:${toKhmer(minute)}';
    } catch (_) {
      return dateStr;
    }
  }
}
