import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeController extends GetxController {
  final bannerIndex = 0.obs;
  final currentIndex = 0.obs;
  final isLoading = false.obs;

  final AuthService _authService = AuthService();

  final services = <Map<String, dynamic>>[].obs;
  final recentActivities = <Map<String, dynamic>>[].obs;
  final announcements = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPortalApps();
    loadRecentActivities();
    fetchAnnouncements();
  }

  void loadRecentActivities() {
    final box = GetStorage();
    final List? saved = box.read('recent_activities');
    if (saved != null) {
      recentActivities.assignAll(
        saved.map((item) => Map<String, dynamic>.from(item)).toList(),
      );
    }
  }

  void addRecentActivity(Map<String, dynamic> app) {
    // Remove if already exists to move it to the top
    recentActivities.removeWhere((item) => item['route'] == app['route']);
    recentActivities.insert(0, app);
    // Keep only the last 3 items
    if (recentActivities.length > 3) {
      recentActivities.removeLast();
    }
    final box = GetStorage();
    box.write('recent_activities', recentActivities.toList());
  }

  void clearRecentActivities() {
    recentActivities.clear();
    final box = GetStorage();
    box.remove('recent_activities');
  }

  Future<void> fetchPortalApps() async {
    try {
      isLoading.value = true;
      final response = await _authService.fetchApps();
      if (response != null && response is List) {
        final parsedServices = response.map<Map<String, dynamic>>((app) {
          final String titleKh =
              app['title_kh'] ??
              app['name_kh'] ??
              app['titleKh'] ??
              app['name'] ??
              'កម្មវិធី';
          final String titleEn =
              app['title_en'] ??
              app['name_en'] ??
              app['titleEn'] ??
              app['name'] ??
              'App';
          final String icon = app['icon'] ?? app['logo'] ?? '';
          final String route = app['route'] ?? app['path'] ?? app['url'] ?? '/';

          String iconPath = 'assets/img/about-moi-logo.png';
          String iconUrl = '';

          if (icon.isNotEmpty) {
            if (icon.startsWith('assets/')) {
              iconPath = icon;
            } else if (icon.startsWith('http')) {
              iconUrl = icon;
            } else {
              final box = GetStorage();
              final String? token = box.read('token');

              String cleanedIcon = icon;
              if (cleanedIcon.startsWith('/uploads/')) {
                cleanedIcon = cleanedIcon.substring(9);
              } else if (cleanedIcon.startsWith('uploads/')) {
                cleanedIcon = cleanedIcon.substring(8);
              }

              final separator = cleanedIcon.startsWith('/') ? '' : '/';
              iconUrl =
                  '${ApiConfig.baseUrl}/api/mobile/portals/uploads$separator$cleanedIcon?token=$token';
            }
          }

          return {
            'icon': iconPath,
            'iconUrl': iconUrl,
            'titleKh': titleKh,
            'titleEn': titleEn,
            'route': route,
          };
        }).toList();

        if (parsedServices.isNotEmpty) {
          services.assignAll(parsedServices);
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch portal apps: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await _authService.fetchAnnouncements();
      if (response != null) {
        if (response is List) {
          announcements.assignAll(
            response.map<Map<String, dynamic>>((item) {
              return Map<String, dynamic>.from(item as Map);
            }).toList(),
          );
        } else if (response is Map) {
          final data = response['value'] ?? response['data'];
          if (data is List) {
            announcements.assignAll(
              data.map<Map<String, dynamic>>((item) {
                return Map<String, dynamic>.from(item as Map);
              }).toList(),
            );
          }
        }
        if (Get.isRegistered<NavController>()) {
          Get.find<NavController>().updateUnreadCount(announcements);
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch announcements on Home: $e");
    }
  }
}
