import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final services = <Map<String, dynamic>>[].obs;
  final recentActivities = <Map<String, dynamic>>[].obs;
  final announcements = <Map<String, dynamic>>[].obs;
  final userDisplayName = 'guest'.tr.obs;
  final AuthService _authService = AuthService();
  final _storage = GetStorage();

  String get _recentKey {
    final username = (_storage.read('username') ?? 'guest').toString();
    return 'recent_apps_$username';
  }

  @override
  void onInit() {
    super.onInit();
    final cachedServices = _storage.read('cached_portal_services');
    if (cachedServices is List && cachedServices.isNotEmpty) {
      try {
        final nonGen = cachedServices
            .map((e) => Map<String, dynamic>.from(e))
            .where((s) => !isGeneralApp(s))
            .toList();
        services.assignAll(nonGen);
      } catch (_) {}
    }
    loadRecentActivities();
    _initData();
  }

  Future<void> _initData() async {
    // Wait until login or session restoration finishes before fetching data
    await AuthService.waitForAuth();

    final token = await ApiClient.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint("HomeController: No token exists. Showing login instead of calling endpoints.");
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }

    fetchUserProfile();
    fetchPortalApps();
    fetchAnnouncements();
  }

  void loadRecentActivities() {
    try {
      recentActivities.clear();
      final stored = _storage.read<List<dynamic>>(_recentKey);
      if (stored == null) return;
      recentActivities.assignAll(
        stored.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void addRecentActivity(Map<String, dynamic> app) {
    try {
      String route = (app['url'] ?? app['route'] ?? app['path'] ?? '')
          .toString()
          .trim();

      final Map<String, dynamic> appToSave = {
        'id': (app['id'] ?? app['_id'] ?? '').toString(),
        'icon': (app['icon'] ?? 'assets/img/about-moi-logo.png').toString(),
        'iconUrl': (app['iconUrl'] ?? app['icon_url'] ?? '').toString(),
        'titleKh':
            (app['titleKh'] ??
                    app['title_kh'] ??
                    app['name'] ??
                    app['name_kh'] ??
                    '')
                .toString(),
        'titleEn': (app['titleEn'] ?? app['title_en'] ?? '').toString(),
        'route': route,
        'url': route,
      };

      recentActivities.removeWhere(
        (item) =>
            (item['id'].toString() == appToSave['id'].toString() &&
                item['id'].toString().isNotEmpty) ||
            (item['route'].toString() == appToSave['route'].toString()) ||
            (item['titleKh'].toString() == appToSave['titleKh'].toString()),
      );

      recentActivities.insert(0, appToSave);

      if (recentActivities.length > 6) {
        recentActivities.removeRange(6, recentActivities.length);
      }

      _storage.write(_recentKey, recentActivities.toList());
    } catch (e) {
      debugPrint("Error adding recent activity: $e");
    }
  }

  void clearRecentActivities() {
    recentActivities.clear();
    _storage.remove(_recentKey);
  }

  Future<void> fetchPortalApps() async {
    // 1. Wait until login or session restoration finishes before fetching apps
    await AuthService.waitForAuth();

    // 2. If no token exists, show login instead of calling these endpoints
    final accessToken = await ApiClient.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint("HomeController: No token exists. Showing login instead of calling apps endpoints.");
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }

    try {
      if (services.isEmpty) {
        isLoading.value = true;
      }
      bool is401 = false;
      final List<dynamic> rawApps = [];
      final Set<String> seenAppKeys = {};

      void addAppIfNew(dynamic app, {bool isGeneral = false}) {
        if (app is Map) {
          final id = (app['id'] ?? app['_id'] ?? '').toString().trim();
          final code = (app['code'] ?? '').toString().trim();
          final name = (app['name'] ?? app['nameKh'] ?? app['title_kh'] ?? '').toString().trim();
          final key = id.isNotEmpty
              ? 'id:$id'
              : (code.isNotEmpty ? 'code:$code' : 'name:$name');
          if (key.isNotEmpty && !seenAppKeys.contains(key)) {
            seenAppKeys.add(key);
            final copy = Map<String, dynamic>.from(app);
            if (isGeneral) {
              copy['isGeneral'] = true;
            }
            rawApps.add(copy);
          }
        }
      }

      // 1. Fetch portal apps (/portals/apps) - returns user assigned applications including ANPR
      try {
        final portalAppsRes = await _authService.fetchPortalApps();
        if (portalAppsRes != null) {
          List list = [];
          if (portalAppsRes is List) {
            list = portalAppsRes;
          } else if (portalAppsRes is Map) {
            final data = portalAppsRes['data'] ??
                portalAppsRes['value'] ??
                portalAppsRes['items'] ??
                portalAppsRes['content'] ??
                portalAppsRes['apps'] ??
                [];
            if (data is List) list = data;
          }
          for (var item in list) {
            addAppIfNew(item, isGeneral: false);
          }
        }
      } on DioException catch (e) {
        debugPrint("fetchPortalApps endpoint error: $e");
        if (e.response?.statusCode == 401) {
          is401 = true;
        }
      } catch (e) {
        debugPrint("fetchPortalApps endpoint error: $e");
      }

      // If 401 occurred, do NOT retry other endpoints. Redirect to login instead.
      if (is401) {
        debugPrint("401 Unauthorized encountered. Redirecting to login.");
        if (Get.currentRoute != AppRoutes.login) {
          await ApiClient.logout();
          Get.offAllNamed(AppRoutes.login);
        }
        return;
      }

      // 2. Fetch user tiles (/portals/tiles) to merge user's pinned tiles
      try {
        final tilesRes = await _authService.fetchApps();
        if (tilesRes != null) {
          List list = [];
          if (tilesRes is List) {
            list = tilesRes;
          } else if (tilesRes is Map) {
            final data = tilesRes['data'] ??
                tilesRes['value'] ??
                tilesRes['items'] ??
                tilesRes['content'] ??
                tilesRes['tiles'] ??
                tilesRes['apps'] ??
                [];
            if (data is List) list = data;
          }
          for (var item in list) {
            addAppIfNew(item, isGeneral: false);
          }
        }
      } on DioException catch (e) {
        debugPrint("fetchApps (tiles) error: $e");
        if (e.response?.statusCode == 401) {
          is401 = true;
        }
      } catch (e) {
        debugPrint("fetchApps (tiles) error: $e");
      }

      // User portal apps and tiles are the exclusive sources for Home services.
      // Admin/general catalog apps are not merged here.

      if (rawApps.isNotEmpty) {
        final List<Map<String, dynamic>> tempServices = [];

        for (var app in rawApps) {
          final String id = (app['id'] ?? app['_id'] ?? '').toString();
          final String titleKh =
              (app['nameKh'] ?? app['title_kh'] ?? app['titleKh'] ?? app['name'] ?? 'កម្មវិធី')
                  .toString();
          final String titleEn =
              (app['nameEn'] ?? app['title_en'] ?? app['titleEn'] ?? app['name'] ?? 'App')
                  .toString();
          final String rawIcon = AppIconWidget.extractRawIcon(app);
          String route =
              (app['launchUrl'] ?? app['appUrl'] ?? app['url'] ?? app['route'] ?? '')
                  .toString()
                  .trim();

          if (route.isNotEmpty &&
              !route.startsWith('http://') &&
              !route.startsWith('https://')) {
            if (route.contains('.com') ||
                route.contains('.gov.kh') ||
                route.contains('.org') ||
                route.contains('www.')) {
              route = 'https://$route';
            }
          }

          String iconPath = '';
          String iconUrl = '';

          if (rawIcon.isNotEmpty &&
              rawIcon.toLowerCase() != 'null' &&
              rawIcon.toLowerCase() != 'undefined') {
            final cleanLower = rawIcon.toLowerCase();
            final bool isLocal = cleanLower.startsWith('assets/') ||
                cleanLower.startsWith('asset/') ||
                cleanLower.startsWith('/assets/') ||
                cleanLower.startsWith('/asset/') ||
                cleanLower.startsWith('images/') ||
                cleanLower.startsWith('/images/');

            if (isLocal) {
              iconPath = rawIcon.startsWith('/') ? rawIcon.substring(1) : rawIcon;
              if (!iconPath.startsWith('assets/')) {
                iconPath = 'assets/$iconPath';
              }
            } else {
              iconUrl = AppIconWidget.formatIconUrl(rawIcon, accessToken);
            }
          }

          final dynamic rawActive =
              app['isActive'] ?? app['is_active'] ?? app['active'] ?? app['enabled'];
          final dynamic rawStatus = app['status'];
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

          final bool isGen = isGeneralApp(app);

          tempServices.add({
            'id': id,
            'icon': iconPath,
            'iconUrl': iconUrl,
            'titleKh': titleKh,
            'titleEn': titleEn,
            'url': route,
            'route': route,
            'isActive': isActive,
            'isGeneral': isGen,
            'status': rawStatus?.toString() ?? (isActive ? 'ACTIVE' : 'INACTIVE'),
            'code': (app['code'] ?? '').toString(),
            'category': (app['category'] ?? app['subCategory'] ?? '').toString(),
            'subCategory': (app['subCategory'] ?? '').toString(),
            'department': (app['department'] ?? app['unit'] ?? app['departmentName'] ?? app['generalDepartmentCode'] ?? '').toString(),
            'departmentName': (app['departmentName'] ?? app['department'] ?? app['unit'] ?? app['generalDepartmentName'] ?? '').toString(),
            'unit': (app['unit'] ?? '').toString(),
            'description': (app['description'] ?? app['desc'] ?? app['descriptionKh'] ?? '').toString(),
            'accessRules': app['accessRules'] ?? app['access_rules'] ?? app['rules'] ?? [],
          });
        }

        // Assign filtered internal apps to state management array
        services.assignAll(tempServices);
        _storage.write(
          'cached_portal_services',
          tempServices.where((s) => !isGeneralApp(s)).toList(),
        );
      } else {
        services.clear();
        _storage.remove('cached_portal_services');
      }
    } catch (e) {
      debugPrint("Failed to fetch portal apps: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Identifies general utility, admin, or third-party apps
  /// (such as Google Map, Google Calendar, and general department utilities)
  /// that must never appear on the user's primary Home screen.
  static bool isGeneralApp(Map<String, dynamic> app) {
    if (app['isGeneral'] == true || app['is_general'] == true) return true;

    final cat = (app['category'] ?? '').toString().toLowerCase().trim();
    final subCat = (app['subCategory'] ?? '').toString().toLowerCase().trim();
    final dept = (app['department'] ?? '').toString().toLowerCase().trim();
    final unit = (app['unit'] ?? '').toString().toLowerCase().trim();
    final deptName = (app['departmentName'] ?? '').toString().toLowerCase().trim();
    final code = (app['code'] ?? '').toString().toUpperCase().trim();
    final titleEn = (app['titleEn'] ?? app['nameEn'] ?? app['name'] ?? '').toString().toLowerCase().trim();
    final titleKh = (app['titleKh'] ?? app['nameKh'] ?? '').toString().toLowerCase().trim();
    final route = (app['route'] ?? app['url'] ?? app['launchUrl'] ?? app['appUrl'] ?? '').toString().toLowerCase().trim();

    // 1. General category or department names
    if (cat == 'general' ||
        cat == 'ទូទៅ' ||
        cat.contains('general') ||
        cat.contains('ទូទៅ') ||
        cat == 'public' ||
        cat == 'tools' ||
        cat == 'utility' ||
        cat == 'utilities' ||
        cat == 'external') {
      return true;
    }

    if (subCat == 'general' ||
        subCat == 'ទូទៅ' ||
        subCat.contains('general') ||
        subCat.contains('ទូទៅ')) {
      return true;
    }

    if (dept == 'general' ||
        dept == 'ទូទៅ' ||
        dept.contains('general') ||
        dept.contains('ទូទៅ')) {
      return true;
    }

    if (unit == 'general' ||
        unit == 'ទូទៅ' ||
        unit.contains('general') ||
        unit.contains('ទូទៅ')) {
      return true;
    }

    if (deptName == 'general' ||
        deptName == 'ទូទៅ' ||
        deptName.contains('general') ||
        deptName.contains('ទូទៅ')) {
      return true;
    }

    // 2. Google and external utility apps (Google Map, Google Calendar, etc.)
    if (code.contains('GOOGLE') ||
        code.contains('MAP') ||
        code.contains('CALENDAR') ||
        titleEn.contains('google map') ||
        titleEn.contains('google calendar') ||
        titleEn.contains('google') ||
        titleKh.contains('google') ||
        titleKh.contains('ផែនទី') ||
        titleKh.contains('ប្រតិទិន') ||
        route.contains('google.com') ||
        route.contains('calendar.google') ||
        route.contains('maps.google')) {
      return true;
    }

    return false;
  }

  /// Services to be displayed on Home (strictly user portal apps, excludes general apps)
  List<Map<String, dynamic>> get homeServices {
    return services.where((s) {
      if (s['isActive'] == false) return false;
      if (isGeneralApp(s)) return false;
      return true;
    }).toList();
  }

  Future<void> fetchUserProfile() async {
    await AuthService.waitForAuth();
    final token = await ApiClient.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final String? cachedName = _storage.read('user_display_name');
      if (cachedName != null && cachedName.isNotEmpty) {
        userDisplayName.value = cachedName;
      } else {
        userDisplayName.value = 'officer'.tr;
      }

      final response = await _authService.fetchProfile();
      debugPrint("👉 API User Profile Response: $response");

      if (response != null) {
        Map<String, dynamic> userData = {};
        if (response is Map) {
          if (response['data'] is Map) {
            userData = Map<String, dynamic>.from(response['data']);
          } else if (response['user'] is Map) {
            userData = Map<String, dynamic>.from(response['user']);
          } else {
            userData = Map<String, dynamic>.from(response);
          }
        }

        final String liveName =
            (userData['name'] ??
                    userData['display_name'] ??
                    userData['displayName'] ??
                    userData['name_kh'] ??
                    userData['username'] ??
                    '')
                .toString()
                .trim();

        if (liveName.isNotEmpty) {
          userDisplayName.value = liveName;
          await _storage.write('user_display_name', liveName);
        }

        if (userData['roles'] is List && (userData['roles'] as List).isNotEmpty) {
          await _storage.write('roles', userData['roles']);
        }
        if (userData['groups'] is List && (userData['groups'] as List).isNotEmpty) {
          await _storage.write('groups', userData['groups']);
        }
        if (userData['userGroups'] is List && (userData['userGroups'] as List).isNotEmpty) {
          await _storage.write('userGroups', userData['userGroups']);
        }
        if (userData['permissions'] is List && (userData['permissions'] as List).isNotEmpty) {
          await _storage.write('permissions', userData['permissions']);
        }
        if (Get.isRegistered<NavController>()) {
          Get.find<NavController>().checkAdminRole();
        }

        loadRecentActivities();
      }
    } catch (e) {
      debugPrint("Failed to fetch live user profile: $e");
      if (userDisplayName.value == 'guest'.tr || userDisplayName.value == 'ភ្ញៀវ') {
        userDisplayName.value = 'officer'.tr;
      }
    }
  }

  Future<void> fetchAnnouncements() async {
    await AuthService.waitForAuth();
    final token = await ApiClient.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _authService.fetchAnnouncements();
      if (response != null && response is List) {
        // 1. Map data and keep a temporary raw DateTime object for sorting
        final List<Map<String, dynamic>>
        rawList = response.map<Map<String, dynamic>>((ann) {
          final String title =
              (ann['title'] ??
                      ann['titleKh'] ??
                      ann['subject'] ??
                      'announcement'.tr)
                  .toString();
          final String content =
              (ann['content'] ?? ann['contentKh'] ?? ann['description'] ?? '')
                  .toString();

          // 🟢 Crucial: Get the raw, ISO format timestamp from the backend (e.g. "2026-07-14T09:48:00Z")
          // If your API payload uses a different timestamp key, update it here!
          final String rawTimeStr =
              (ann['created_at'] ?? ann['createdAt'] ?? ann['timestamp'] ?? '')
                  .toString();

          // Parse string into a valid Dart DateTime object for strict chronological sorting
          DateTime parsedDateTime =
              DateTime.tryParse(rawTimeStr) ??
              DateTime.fromMillisecondsSinceEpoch(0);

          // Get the display text time provided by the backend, or default back to a safe layout
          final String displayText = (ann['display_date'] ?? ann['date'] ?? '')
              .toString();

          return {
            'title': title,
            'content': content,
            'date': displayText.isNotEmpty ? displayText : rawTimeStr,
            'sortDateTime':
                parsedDateTime, // Hidden property strictly for sorting usage
          };
        }).toList();

        // 2. 🟢 CHRONOLOGICAL SORT: Order accurately from newest to oldest using true date objects
        rawList.sort((a, b) {
          final DateTime dateA = a['sortDateTime'] as DateTime;
          final DateTime dateB = b['sortDateTime'] as DateTime;
          return dateB.compareTo(dateA); // Newest timestamp moves up to index 0
        });

        // 3. Assign the perfectly sorted dataset straight into the Obx UI observable list
        announcements.assignAll(rawList);
      }
    } catch (e) {
      debugPrint("Failed to fetch announcements in HomeController: $e");
    }
  }
}
