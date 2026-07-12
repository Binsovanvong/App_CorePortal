import 'package:carousel_slider/carousel_slider.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.fromBorderSide(BorderSide(color: Color(0xffD4AF37))),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 40),
            child: Row(
              children: [
                Image.asset("assets/img/about-moi-logo.png", height: 70),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ក្រសួងមហាផ្ទៃ",
                        style: TextStyle(
                          color: Color(0xffD4AF37),
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        "Ministry of Interior",
                        style: TextStyle(
                          color: Color(0xffD4AF37),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search for ID cards, passports...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onChanged: (value) {
                    // Search logic
                  },
                ),
              ),
              const SizedBox(height: 20),

              /// SERVICE TITLE
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "កម្មវិធី",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// GRID MENU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: Color(0xffD4AF37),
                        ),
                      ),
                    );
                  }

                  if (controller.services.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xffD4AF37).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xffFCFAF3),
                              border: Border.all(
                                color: const Color(0xffE9D8A6),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.grid_off_rounded,
                                size: 40,
                                color: Color(0xffD4AF37),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "អត់ទាន់មានកម្មវិធី",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1E293B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "No applications available yet",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.services.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.67,
                        ),
                    itemBuilder: (context, index) {
                      final item = controller.services[index];
                      final String route = item["route"] ?? AppRoutes.mainView;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            controller.addRecentActivity(item);
                            if (route.startsWith('http://') ||
                                route.startsWith('https://')) {
                              Get.toNamed(
                                AppRoutes.webView,
                                arguments: {
                                  'url': route,
                                  'title': item["titleEn"] ?? "Portal App",
                                },
                              );
                            } else {
                              Get.toNamed(route);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xffD4AF37),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /// Icon Circle
                                Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xffFCFAF3),
                                    border: Border.all(
                                      color: const Color(0xffE9D8A6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child:
                                        item["iconUrl"] != null &&
                                            item["iconUrl"]
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            item["iconUrl"]!,
                                            width: 34,
                                            height: 34,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                                      item["icon"]!,
                                                      width: 34,
                                                      height: 34,
                                                      color: const Color(
                                                        0xff8A6514,
                                                      ),
                                                    ),
                                          )
                                        : Image.asset(
                                            item["icon"]!,
                                            width: 34,
                                            height: 34,
                                            color: const Color(0xff8A6514),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item["titleKh"]!,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  item["titleEn"]!,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    controller.addRecentActivity(item);
                                    if (route.startsWith('http://') ||
                                        route.startsWith('https://')) {
                                      Get.toNamed(
                                        AppRoutes.webView,
                                        arguments: {
                                          'url': route,
                                          'title':
                                              item["titleEn"] ?? "Portal App",
                                        },
                                      );
                                    } else {
                                      Get.toNamed(route);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffD4AF37),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "បើកកម្មវិធី",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.login_rounded,
                                          size: 25,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 30),

              Obx(() {
                final list = controller.announcements;
                final int itemCount = list.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NEWS TITLE
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "សេចក្តីប្រកាស",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (list.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: [
                          CarouselSlider(
                            items: list
                                .map(
                                  (announcement) =>
                                      _announcementBanner(announcement),
                                )
                                .toList(),
                            options: CarouselOptions(
                              height: 190,
                              viewportFraction: 1,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 5),
                              autoPlayAnimationDuration: const Duration(
                                milliseconds: 800,
                              ),
                              enlargeCenterPage: false,
                              onPageChanged: (index, reason) {
                                controller.currentIndex.value = index;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(itemCount, (index) {
                              bool isActive =
                                  controller.currentIndex.value == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: isActive ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isActive
                                      ? const Color(0xffD4AF37)
                                      : Colors.grey.shade400,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                  ],
                );
              }),
              Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "សកម្មភាពថ្មីៗ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (controller.recentActivities.isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  controller.clearRecentActivities(),
                              child: const Text(
                                "សម្អាត",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (controller.recentActivities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 20,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "អត់មានសកម្មភាព",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xff94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              int i = 0;
                              i < controller.recentActivities.length;
                              i++
                            ) ...[
                              if (i > 0) const SizedBox(width: 16),
                              Expanded(
                                child: _recentActivityItem(
                                  controller.recentActivities[i],
                                  i,
                                ),
                              ),
                            ],
                            if (controller.recentActivities.length < 3)
                              for (
                                int j = 0;
                                j < 3 - controller.recentActivities.length;
                                j++
                              ) ...[
                                const SizedBox(width: 16),
                                const Expanded(child: SizedBox.shrink()),
                              ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? customIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA88400).withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffF1F5F9), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                /// Icon Box
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xffF1F5F9),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child:
                        customIcon ??
                        Icon(icon, size: 28, color: const Color(0xffA88400)),
                  ),
                ),

                const SizedBox(width: 16),

                /// Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Action Target Chevron
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xffF1F5F9),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xffA88400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentActivityItem(Map<String, dynamic> app, int index) {
    final titleKh = app['titleKh'] ?? app['titleEn'] ?? 'App';
    final titleEn = app['titleEn'] ?? 'App';
    final route = app['route'] ?? '';

    final colors = _getAppColors(index);
    final bgColor = colors['bg']!;
    final fgColor = colors['fg']!;

    return GestureDetector(
      onTap: () {
        controller.addRecentActivity(app);
        if (route.startsWith('http://') || route.startsWith('https://')) {
          Get.toNamed(
            AppRoutes.webView,
            arguments: {'url': route, 'title': titleEn},
          );
        } else {
          Get.toNamed(route);
        }
      },
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: _buildAppIcon(app, fgColor)),
          ),
          const SizedBox(height: 10),
          Text(
            titleKh,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xff1E293B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '($titleEn)',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getAppColors(int index) {
    final colors = [
      {'bg': const Color(0xffEEF2FF), 'fg': const Color(0xff4F46E5)},
      {'bg': const Color(0xffECFDF5), 'fg': const Color(0xff059669)},
      {'bg': const Color(0xffFFF7ED), 'fg': const Color(0xffEA580C)},
      {'bg': const Color(0xffF5F3FF), 'fg': const Color(0xff7C3AED)},
      {'bg': const Color(0xffF0FDFA), 'fg': const Color(0xff0D9488)},
      {'bg': const Color(0xffFEF2F2), 'fg': const Color(0xffEF4444)},
      {'bg': const Color(0xffF0F9FF), 'fg': const Color(0xff0284C7)},
    ];
    return colors[index % colors.length];
  }

  Widget _buildAppIcon(Map<String, dynamic> app, Color fgColor) {
    final String iconUrl = app['iconUrl'] ?? '';
    final String iconPath = app['icon'] ?? '';

    if (iconUrl.isNotEmpty) {
      return Image.network(
        iconUrl,
        width: 36,
        height: 36,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          iconPath.isNotEmpty ? iconPath : 'assets/img/about-moi-logo.png',
          width: 36,
          height: 36,
          color: fgColor,
        ),
      );
    } else if (iconPath.isNotEmpty) {
      return Image.asset(iconPath, width: 36, height: 36, color: fgColor);
    }

    return Icon(Icons.apps_rounded, size: 36, color: fgColor);
  }

  Widget _announcementBanner(Map<String, dynamic> announcement) {
    final String title =
        announcement['title']?.toString() ??
        announcement['titleEn']?.toString() ??
        'សេចក្តីប្រកាស';
    final String content = announcement['content']?.toString() ?? '';
    // Strip HTML tags for simple display
    final String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Dark blue
              Color(0xFF3B51C5), // Theme blue
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background pattern/logo
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  "assets/img/about-moi-logo.png",
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'សេចក្តីប្រកាស',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cleanContent,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xffD4AF37).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xffFCFAF3),
              border: Border.all(color: const Color(0xffE9D8A6), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_off_outlined,
                size: 32,
                color: Color(0xffD4AF37),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "គ្មានសេចក្តីប្រកាស",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff1E293B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "មិនទាន់មានសេចក្តីប្រកាសនៅឡើយទេ។",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
