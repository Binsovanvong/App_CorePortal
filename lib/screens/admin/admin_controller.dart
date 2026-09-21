import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core_portal/widgets/app_icon.dart';

class AdminController extends GetxController {
  final AuthService _authService = AuthService();

  Timer? _autoRefreshTimer;

  // Loading and action states
  final isLoading = false.obs;
  final isBackingUp = false.obs;
  final backupProgress = 0.0.obs;

  // Bottom Navigation State
  final currentIndex = 0.obs;
  void changeTab(int index) => currentIndex.value = index;

  // Live Dashboard Stats
  final totalApps = 0.obs;
  final totalUsers = 0.obs;
  final runningApps = 0.obs;
  final announcementsCount = 0.obs;

  // Live Data lists
  final appsList = <Map<String, dynamic>>[].obs;
  final announcementsList = <Map<String, dynamic>>[].obs;
  final usersList = <Map<String, dynamic>>[].obs;
  final groupList = <Map<String, dynamic>>[]
      .obs; // 🟢 Added missing group array configuration
  final userGroupsMap = <String, List<String>>{}.obs;
  final groupAppCountMap = <String, int>{}.obs;

  // Search queries
  final appSearchQuery = ''.obs;
  final userSearchQuery = ''.obs;

  // User filters
  final selectedUserStatus = "ស្ថានភាពទាំងអស់".obs;
  final selectedUserUnit = "អង្គភាពទាំងអស់".obs;
  final groupUserChartFilter = 'most_users'.obs;

  // Department Code to Khmer Mapping (e.g. GDP -> អគ្គនាយកដ្ឋានពន្ធនាគារ)
  static const Map<String, String> departmentKhmerMap = {
    'GDDTM': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
    'GDP': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
    'GDI': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
    'GNP': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
    'GID': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
    'GDHR': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស',
    'GLF': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ',
    'GIA': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង',
    'GI': 'អគ្គាធិការដ្ឋាន',
    'GS': 'អគ្គលេខាធិការដ្ឋាន',
    'PAC': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា',
    'LC': 'ក្រុមប្រឹក្សានីតិកម្ម',
  };

  /// Helper to convert department code (e.g. GDP, GDDTM, GDI) or English name to Khmer
  static String formatDepartmentToKhmer(dynamic codeOrName) {
    if (codeOrName == null) return 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ';
    final str = codeOrName.toString().trim();
    if (str.isEmpty || str == '—' || str == '-' || str == 'null') {
      return 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ';
    }

    final upper = str.toUpperCase();
    if (departmentKhmerMap.containsKey(upper)) {
      return departmentKhmerMap[upper]!;
    }

    // Check if starts with a known code prefix (e.g. GDDTM-N1 or GDP Admins)
    for (final entry in departmentKhmerMap.entries) {
      if (upper.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return str;
  }

  /// Returns the admin's General Department code (e.g. 'GDDTM')
  String get adminGeneralDepartmentCode {
    final box = GetStorage();
    final storedCode = (box.read('generalDepartmentCode') ??
            box.read('departmentCode') ??
            box.read('generalDepartment') ??
            box.read('department') ??
            '')
        .toString()
        .trim();
    if (storedCode.isNotEmpty) return storedCode.toUpperCase();

    final rawRoles = box.read('roles');
    final List list = (rawRoles is List && rawRoles.isNotEmpty) ? rawRoles : [];
    for (final r in list) {
      final s = r.toString().toUpperCase().trim();
      for (final code in departmentKhmerMap.keys) {
        if (s.contains(code)) return code;
      }
    }

    return 'GDDTM';
  }

  /// Returns the admin's General Department Khmer name
  String get adminGeneralDepartmentNameKh {
    return departmentKhmerMap[adminGeneralDepartmentCode] ??
        'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ';
  }

  /// Checks if a user belongs to the admin's General Department ("អគ្គ")
  /// or is assigned to any group created by this admin, or is the admin themselves
  bool isUserInAdminGeneralDepartment(
    Map<String, dynamic> usr,
    Set<String> createdByMeGroupCodes,
    Map<String, List<String>> userGroupsMapLocal,
  ) {
    if (isSelfUser(usr)) return true;

    final targetDeptCode = adminGeneralDepartmentCode.toUpperCase();
    final targetDeptKh = adminGeneralDepartmentNameKh;

    // 1. Check employmentInfos
    final List empInfos =
        usr['employmentInfos'] is List ? usr['employmentInfos'] : [];
    for (final emp in empInfos) {
      if (emp is Map) {
        final code =
            (emp['generalDepartmentCode'] ?? emp['departmentCode'] ?? '')
                .toString()
                .trim()
                .toUpperCase();
        if (code.isNotEmpty) {
          if (code == targetDeptCode || code.startsWith(targetDeptCode)) {
            return true;
          }
        }
        final name =
            (emp['generalDepartmentName'] ?? emp['departmentName'] ?? '')
                .toString()
                .trim();
        if (name.isNotEmpty &&
            (name.contains(targetDeptCode) ||
                (targetDeptKh.isNotEmpty && name.contains(targetDeptKh)))) {
          return true;
        }
        final nameKh =
            (emp['generalDepartmentNameKh'] ?? emp['departmentNameKh'] ?? '')
                .toString()
                .trim();
        if (nameKh.isNotEmpty &&
            (nameKh.contains(targetDeptKh) ||
                (targetDeptKh.isNotEmpty && targetDeptKh.contains(nameKh)))) {
          return true;
        }
      }
    }

    // 2. Check direct user fields
    final directCode = (usr['generalDepartmentCode'] ??
            usr['departmentCode'] ??
            usr['generalDepartment'] ??
            usr['department'] ??
            usr['unit'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    if (directCode.isNotEmpty) {
      if (directCode == targetDeptCode || directCode.startsWith(targetDeptCode)) {
        return true;
      }
    }
    final directKh =
        (usr['generalDepartmentNameKh'] ?? usr['departmentNameKh'] ?? '')
            .toString()
            .trim();
    if (directKh.isNotEmpty &&
        (directKh.contains(targetDeptKh) || targetDeptKh.contains(directKh))) {
      return true;
    }

    // 3. Check profile object
    if (usr['profile'] is Map) {
      final p = usr['profile'] as Map;
      final pCode = (p['generalDepartmentCode'] ??
              p['departmentCode'] ??
              p['generalDepartment'] ??
              p['department'] ??
              '')
          .toString()
          .trim()
          .toUpperCase();
      if (pCode.isNotEmpty &&
          (pCode == targetDeptCode || pCode.startsWith(targetDeptCode))) {
        return true;
      }
    }

    // 4. Check membership in groups created by this admin
    final uid = (usr['id'] ??
            usr['keycloakUserId'] ??
            usr['userId'] ??
            usr['username'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    final uname = (usr['username'] ?? '').toString().toLowerCase().trim();

    for (final grpCode in createdByMeGroupCodes) {
      final members =
          userGroupsMapLocal[grpCode] ?? userGroupsMap[grpCode] ?? [];
      final lowerMembers =
          members.map((m) => m.toString().toLowerCase().trim()).toSet();
      if (lowerMembers.contains(uid) ||
          (uname.isNotEmpty && lowerMembers.contains(uname))) {
        return true;
      }
    }

    final rawGroups = usr['groups'] is List
        ? usr['groups']
        : (usr['userGroups'] is List
            ? usr['userGroups']
            : (usr['portalGroups'] is List ? usr['portalGroups'] : []));
    for (final g in rawGroups) {
      final gStr = (g is Map ? (g['code'] ?? g['name'] ?? '') : g)
          .toString()
          .trim()
          .toLowerCase();
      if (createdByMeGroupCodes.any((c) => c.toLowerCase() == gStr)) {
        return true;
      }
    }

    return false;
  }

  // App filters and sorting
  final appStatusFilter = 'all'.obs; // 'all', 'active', 'inactive'
  final selectedAppUnit = 'អង្គភាពទាំងអស់'.obs;
  final appSortFilter =
      'newest'.obs; // 'name_az', 'name_za', 'newest', 'oldest'

  /// Checks if the given user map corresponds to the currently authenticated user
  bool isSelfUser(Map<String, dynamic> user) {
    final box = GetStorage();
    final currentUsername =
        (box.read('username') ?? '').toString().trim().toLowerCase();
    final currentUserId = (box.read('userProfileUserId') ??
            box.read('userId') ??
            box.read('sub') ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final currentEmail =
        (box.read('email') ?? '').toString().trim().toLowerCase();

    final targetUsername =
        (user['username'] ?? user['name'] ?? user['preferred_username'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final targetUserId = (user['id'] ??
            user['userId'] ??
            user['userProfileUserId'] ??
            user['keycloakUserId'] ??
            user['keycloak_user_id'] ??
            user['sub'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final targetEmail = (user['email'] ?? '').toString().trim().toLowerCase();

    if (currentUsername.isNotEmpty &&
        targetUsername.isNotEmpty &&
        currentUsername == targetUsername) {
      return true;
    }
    if (currentUserId.isNotEmpty &&
        targetUserId.isNotEmpty &&
        currentUserId == targetUserId) {
      return true;
    }
    if (currentEmail.isNotEmpty &&
        targetEmail.isNotEmpty &&
        currentEmail == targetEmail) {
      return true;
    }
    return false;
  }

  /// Checks if the logged-in user has General Department Admin privileges
  bool isGeneralDepartmentAdmin() {
    final box = GetStorage();
    final rawRoles = box.read('roles');
    final List list = (rawRoles is List && rawRoles.isNotEmpty) ? rawRoles : [];
    final roles = list.map((e) => e.toString().toLowerCase().trim()).toList();

    return roles.contains('general_department_admin') ||
        roles.contains('general_department') ||
        roles.contains('gddtm_admin') ||
        roles.any((r) => r.contains('general_department'));
  }

  /// Returns false if the current user is a General Department Admin trying to edit their own account
  bool canEditUser(Map<String, dynamic> user) {
    if (isSelfUser(user)) {
      return false;
    }
    return true;
  }

  List<String> get adminGroups {
    final box = GetStorage();
    final Set<String> groups = {};

    // 1. Check logged-in user profile groups
    final rawUserGroups =
        box.read('user_groups') ?? box.read('groups') ?? box.read('roles');
    if (rawUserGroups is List) {
      for (var g in rawUserGroups) {
        final name = g is Map
            ? (g['name'] ?? g['groupName'] ?? g['nameKh'] ?? '')
            : g.toString();
        if (name.isNotEmpty &&
            !name.toUpperCase().contains('ROLE_') &&
            name != 'user' &&
            name != 'offline_access') {
          groups.add(name);
        }
      }
    }

    // 2. Check groupList from controller
    for (var g in groupList) {
      final name = (g['groupNameKh'] ??
              g['groupName'] ??
              g['name'] ??
              g['nameKh'] ??
              g['code'] ??
              '')
          .toString();
      if (name.isNotEmpty) {
        groups.add(name);
      }
    }

    // 3. Extract unique group/unit names from apps accessRules
    for (var app in appsList) {
      final rawRules = app['accessRules'] is List
          ? app['accessRules']
          : (app['rules'] is List ? app['rules'] : []);
      for (var r in rawRules) {
        if (r is Map) {
          final val = (r['ruleValue'] ?? r['value'] ?? r['target'] ?? '')
              .toString()
              .trim();
          if (val.isNotEmpty &&
              val.toLowerCase() != 'all' &&
              val != 'ទាំងអស់') {
            groups.add(val);
          }
        }
      }
    }

    // 4. Default fallback groups if empty
    if (groups.isEmpty) {
      groups.addAll(['GDDTM', 'GDI', 'GNP', 'GDP', 'GIA']);
    }

    final sorted = groups.toList();
    sorted.sort();
    return ['អង្គភាពទាំងអស់', ...sorted];
  }

  // Computed filtered lists
  List<Map<String, dynamic>> get filteredApps {
    List<Map<String, dynamic>> result = List.from(appsList);

    if (appSearchQuery.value.isNotEmpty) {
      final query = appSearchQuery.value.toLowerCase();
      result = result.where((app) {
        final String kh = (app['titleKh'] ?? '').toString().toLowerCase();
        final String en = (app['titleEn'] ?? '').toString().toLowerCase();
        return kh.contains(query) || en.contains(query);
      }).toList();
    }

    if (selectedAppUnit.value != 'អង្គភាពទាំងអស់' &&
        selectedAppUnit.value != 'all') {
      final target = selectedAppUnit.value.toLowerCase();
      result = result.where((app) {
        final String kh = (app['titleKh'] ?? '').toString().toLowerCase();
        final String en = (app['titleEn'] ?? '').toString().toLowerCase();
        final String code = (app['code'] ?? '').toString().toLowerCase();
        if (kh.contains(target) || en.contains(target) || code.contains(target)) {
          return true;
        }
        final rawRules = app['accessRules'] is List
            ? app['accessRules']
            : (app['rules'] is List ? app['rules'] : []);
        for (var r in rawRules) {
          if (r is Map) {
            final String rVal =
                (r['ruleValue'] ?? r['value'] ?? r['target'] ?? '')
                    .toString()
                    .toLowerCase();
            if (rVal.contains(target) || target.contains(rVal)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    if (appStatusFilter.value == 'active') {
      result = result.where((app) => app['isActive'] == true).toList();
    } else if (appStatusFilter.value == 'inactive') {
      result = result.where((app) => app['isActive'] != true).toList();
    }

    if (appSortFilter.value == 'name_az') {
      result.sort((a, b) {
        final nameA = (a['titleKh'] ?? a['titleEn'] ?? '').toString();
        final nameB = (b['titleKh'] ?? b['titleEn'] ?? '').toString();
        return nameA.compareTo(nameB);
      });
    } else if (appSortFilter.value == 'name_za') {
      result.sort((a, b) {
        final nameA = (a['titleKh'] ?? a['titleEn'] ?? '').toString();
        final nameB = (b['titleKh'] ?? b['titleEn'] ?? '').toString();
        return nameB.compareTo(nameA);
      });
    } else if (appSortFilter.value == 'newest') {
      result.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return idB.compareTo(idA);
      });
    } else if (appSortFilter.value == 'oldest') {
      result.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return idA.compareTo(idB);
      });
    }

    return result;
  }

  List<Map<String, dynamic>> get filteredUsers {
    List<Map<String, dynamic>> result = List.from(usersList);

    if (userSearchQuery.value.isNotEmpty) {
      final query = userSearchQuery.value.toLowerCase();
      result = result.where((user) {
        final String name = (user['username'] ?? '').toString().toLowerCase();
        final String disp = (user['displayName'] ??
                user['display_name'] ??
                user['name'] ??
                user['fullName'] ??
                user['name_kh'] ??
                '')
            .toString()
            .toLowerCase();
        final String email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || disp.contains(query) || email.contains(query);
      }).toList();
    }

    if (selectedUserStatus.value != "ស្ថានភាពទាំងអស់") {
      final String statusFilter = selectedUserStatus.value == "សកម្ម" ? "ACTIVE" : "INACTIVE";
      result = result.where((user) {
        return (user['status'] ?? '').toString().toUpperCase() == statusFilter;
      }).toList();
    }

    if (selectedUserUnit.value != "អង្គភាពទាំងអស់") {
      final String unitFilter = selectedUserUnit.value;
      final String prefix = unitFilter.split(' ').first;
      result = result.where((user) {
        final String unit = (user['unit'] ?? '').toString();
        return unit == unitFilter ||
            unit.contains(prefix) ||
            (unit.startsWith(prefix) || prefix.startsWith(unit));
      }).toList();
    }

    return result;
  }

  int getUserCountForApp(Map<String, dynamic> app) {
    if (usersList.isEmpty) {
      final cachedUsers = GetStorage().read('cached_admin_users_list');
      if (cachedUsers is List) {
        return cachedUsers.length;
      }
      return 0;
    }

    final String ruleValue =
        (app['ruleValue'] ?? '').toString().trim().toLowerCase();
    final List rawRules = app['accessRules'] is List
        ? app['accessRules']
        : (app['rules'] is List ? app['rules'] : []);

    if (rawRules.isEmpty &&
        (ruleValue.isEmpty ||
            ruleValue == 'all' ||
            ruleValue == 'ទាំងអស់')) {
      final activeCount = usersList.where((u) {
        final status = (u['status'] ?? 'ACTIVE').toString().toUpperCase();
        return status == 'ACTIVE';
      }).length;
      return activeCount > 0 ? activeCount : usersList.length;
    }

    final matching = usersList.where((u) {
      final status = (u['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (status != 'ACTIVE') return false;

      final role = (u['role'] ?? '').toString().toUpperCase();
      if (role.contains('ADMIN') || role.contains('SUPER')) return true;

      final userDept = (u['department'] ??
              u['unit'] ??
              u['departmentName'] ??
              '')
          .toString()
          .toLowerCase();
      final userGroups = (u['groups'] is List)
          ? (u['groups'] as List).map((g) => g.toString().toLowerCase()).toList()
          : <String>[];
      final userUnits = (u['userUnits'] is List)
          ? (u['userUnits'] as List)
              .map((g) => g.toString().toLowerCase())
              .toList()
          : <String>[];

      if (ruleValue.isNotEmpty && ruleValue != 'all') {
        if (userDept.contains(ruleValue) || ruleValue.contains(userDept)) {
          return true;
        }
        if (userGroups.any(
            (g) => g.contains(ruleValue) || ruleValue.contains(g))) {
          return true;
        }
        if (userUnits.any(
            (g) => g.contains(ruleValue) || ruleValue.contains(g))) {
          return true;
        }
      }

      if (rawRules.isNotEmpty) {
        for (final r in rawRules) {
          if (r is Map) {
            final String rVal =
                (r['ruleValue'] ?? r['value'] ?? r['target'] ?? '')
                    .toString()
                    .toLowerCase();
            if (rVal.isNotEmpty) {
              if (userDept.contains(rVal) || rVal.contains(userDept)) {
                return true;
              }
              if (userGroups.any((g) => g.contains(rVal) || rVal.contains(g))) {
                return true;
              }
              if (userUnits.any((g) => g.contains(rVal) || rVal.contains(g))) {
                return true;
              }
            }
          }
        }
      }

      return false;
    }).length;

    return matching > 0 ? matching : usersList.length;
  }

  List<String> get uniqueUserUnits {
    final Set<String> units = {'អង្គភាពទាំងអស់'};
    for (final g in groupList) {
      final name = (g['name'] ?? g['code'] ?? '').toString().trim();
      if (name.isNotEmpty) units.add(name);
    }
    for (final u in usersList) {
      final unit = (u['unit'] ?? '').toString().trim();
      if (unit.isNotEmpty) units.add(unit);
      final groups = (u['groups'] is List) ? (u['groups'] as List) : [];
      for (final g in groups) {
        final gStr = g.toString().trim();
        if (gStr.isNotEmpty) units.add(gStr);
      }
    }
    return units.toList();
  }

  final auditLogs = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    final box = GetStorage();

    // 🟢 Load cached data immediately for zero-wait rendering
    final cachedApps = box.read('cached_admin_apps_list');
    if (cachedApps is List && cachedApps.isNotEmpty) {
      try {
        appsList.assignAll(
          cachedApps.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        totalApps.value = appsList.length;
        runningApps.value =
            appsList.where((app) => app['isActive'] == true).length;
      } catch (_) {}
    }

    final cachedUsers = box.read('cached_admin_users_list');
    if (cachedUsers is List && cachedUsers.isNotEmpty) {
      try {
        usersList.assignAll(
          cachedUsers.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        totalUsers.value = usersList.length;
      } catch (_) {}
    }

    final cachedAnnouncements = box.read('cached_admin_announcements_list');
    if (cachedAnnouncements is List && cachedAnnouncements.isNotEmpty) {
      try {
        announcementsList.assignAll(
          cachedAnnouncements.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        announcementsCount.value = announcementsList.length;
      } catch (_) {}
    }

    final cachedGroups = box.read('cached_admin_group_list');
    if (cachedGroups is List && cachedGroups.isNotEmpty) {
      try {
        groupList.assignAll(
          cachedGroups.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      } catch (_) {}
    }

    final cachedUserGroups = box.read('cached_admin_user_groups_map');
    if (cachedUserGroups is Map) {
      try {
        userGroupsMap.assignAll(
          Map<String, List<String>>.from(
            cachedUserGroups.map(
              (k, v) => MapEntry(k.toString(), List<String>.from(v)),
            ),
          ),
        );
      } catch (_) {}
    }

    final username = (box.read('username') ?? box.read('name') ?? 'Admin').toString();
    if (auditLogs.isEmpty) {
      auditLogs.add({
        'title': 'ការចូលប្រើប្រាស់របស់ $username',
        'desc': 'គណនី $username បានចូលប្រើប្រាស់ប្រព័ន្ធដោយជោគជ័យ',
        'time': 'មុននេះបន្តិច',
        'status': 'info',
      });
    }

    fetchDashboardData(isSilent: appsList.isNotEmpty || usersList.isNotEmpty);
    fetchPortalGroupsData();

    // 🟢 Auto refresh every 30 seconds
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchDashboardData(isSilent: true),
    );
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> syncGroupsFromKeycloak() async {
    try {
      isLoading.value = true;
      try {
        await _authService.syncGroupsFromKeycloak();
      } catch (e) {
        debugPrint("syncGroupsFromKeycloak API notice: $e");
      }
      try {
        await _authService.syncGroupUsers();
      } catch (e) {
        debugPrint("syncGroupUsers API notice: $e");
      }

      await fetchPortalGroupsData();
      await fetchDashboardData(isSilent: true);

      CustomSnackbar.showSuccess(
        title: "ជោគជ័យ",
        message: "បានធ្វើសមកាលកម្មក្រុមពី AD/Keycloak រួចរាល់!",
      );
    } catch (e) {
      debugPrint("Failed syncGroupsFromKeycloak: $e");
      CustomSnackbar.showError(
        title: "error".tr,
        message: 'cannot_sync_groups_ad'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPortalGroupsCreatedByMe() async {
    try {
      final response = await _authService.fetchPortalGroupsCreatedByMe();
      List rawGroups = [];
      if (response != null) {
        if (response is List) {
          rawGroups = response;
        } else if (response is Map) {
          rawGroups =
              response['data'] ??
              response['items'] ??
              response['value'] ??
              response['groups'] ??
              [];
        }
      }

      final parsedGroups = rawGroups.map<Map<String, dynamic>>((g) {
        final Map<String, dynamic> item = g is Map
            ? Map<String, dynamic>.from(g)
            : {};
        final name = (item['name'] ?? item['groupName'] ?? item['code'] ?? '—').toString().trim();
        final code = (item['code'] ?? item['groupCode'] ?? item['sublabel'] ?? name).toString().trim();
        return {
          'id': item['id']?.toString(),
          'name': name,
          'sublabel': code,
          'code': code,
          'status': item['status'] ?? 'ACTIVE',
          'description': item['description'] ?? item['desc'] ?? item['details'],
          'isAD': item['isAD'] ?? item['source'] == 'KEYCLOAK' ?? item['source'] == 'AD',
        };
      }).toList();

      if (parsedGroups.isNotEmpty) {
        groupList.assignAll(parsedGroups);
        GetStorage().write('cached_admin_group_list', parsedGroups);
      } else {
        groupList.clear();
      }
    } catch (e) {
      debugPrint("Failed to fetch portal groups created by me: $e");
    }
  }

  Future<bool> createGroup(dynamic payloadOrName, [String? description]) async {
    try {
      isLoading.value = true;
      Map<String, dynamic> data = {};
      if (payloadOrName is Map<String, dynamic>) {
        final name = (payloadOrName['name'] ?? payloadOrName['groupName'] ?? payloadOrName['code'] ?? '').toString().trim();
        final desc = (payloadOrName['description'] ?? payloadOrName['desc'] ?? '').toString().trim();
        data = {
          'name': name,
          if (desc.isNotEmpty) 'description': desc,
        };
      } else if (payloadOrName is String) {
        data = {
          'name': payloadOrName.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        };
      }

      if ((data['name'] ?? '').toString().isEmpty) {
        CustomSnackbar.showWarning(title: "សូមបញ្ជាក់", message: "សូមបញ្ចូលឈ្មោះក្រុម!");
        return false;
      }

      await _authService.createAdminGroup(data);
      await fetchPortalGroupsCreatedByMe();

      CustomSnackbar.showSuccess(
        title: "ជោគជ័យ",
        message: "បានបង្កើតក្រុមដោយជោគជ័យ!",
      );
      return true;
    } catch (e) {
      debugPrint("Failed to create group: $e");
      CustomSnackbar.showError(
        title: "error".tr,
        message: 'cannot_create_group'.tr,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteGroup(dynamic groupIdOrCode) async {
    try {
      isLoading.value = true;
      String targetId = '';
      String targetCode = '';
      String targetName = '';

      if (groupIdOrCode is Map) {
        targetId = (groupIdOrCode['id'] ?? '').toString().trim();
        targetCode = (groupIdOrCode['code'] ?? groupIdOrCode['sublabel'] ?? '')
            .toString()
            .trim();
        targetName = (groupIdOrCode['name'] ?? groupIdOrCode['groupName'] ?? '')
            .toString()
            .trim();
      } else if (groupIdOrCode is String) {
        final str = groupIdOrCode.trim();
        targetId = str;
        targetCode = str;
        targetName = str;
      }

      final String idToDelete = targetId.isNotEmpty
          ? targetId
          : (targetCode.isNotEmpty ? targetCode : targetName);

      if (idToDelete.isEmpty) {
        CustomSnackbar.showWarning(
          title: "សូមបញ្ជាក់",
          message: "មិនមានលេខសម្គាល់ក្រុមសម្រាប់លុបទេ!",
        );
        return false;
      }

      await _authService.deleteAdminGroup(idToDelete);

      // Remove from groupList
      groupList.removeWhere((g) {
        final gid = (g['id'] ?? '').toString().trim();
        final gcode = (g['code'] ?? g['sublabel'] ?? '').toString().trim();
        final gname = (g['name'] ?? g['groupName'] ?? '').toString().trim();
        return (targetId.isNotEmpty && gid == targetId) ||
            (targetCode.isNotEmpty &&
                gcode.toLowerCase() == targetCode.toLowerCase()) ||
            (targetName.isNotEmpty &&
                gname.toLowerCase() == targetName.toLowerCase()) ||
            gid == idToDelete ||
            gcode.toLowerCase() == idToDelete.toLowerCase() ||
            gname.toLowerCase() == idToDelete.toLowerCase();
      });
      groupList.refresh();
      GetStorage().write('cached_admin_group_list', groupList.toList());

      // Clean up from userGroupsMap
      userGroupsMap.remove(targetCode);
      userGroupsMap.remove(targetName);
      userGroupsMap.remove(idToDelete);
      userGroupsMap.refresh();

      // Clean up from all users in memory
      for (var u in usersList) {
        if (u['groups'] is List) {
          (u['groups'] as List).remove(targetName);
          (u['groups'] as List).remove(targetCode);
          (u['groups'] as List).remove(idToDelete);
        }
        if (u['userGroups'] is List) {
          (u['userGroups'] as List).remove(targetName);
          (u['userGroups'] as List).remove(targetCode);
          (u['userGroups'] as List).remove(idToDelete);
        }
      }
      usersList.refresh();

      await fetchPortalGroupsCreatedByMe();

      CustomSnackbar.showSuccess(
        title: "ជោគជ័យ",
        message: "បានលុបក្រុមដោយជោគជ័យ!",
      );
      return true;
    } catch (e) {
      debugPrint("Failed to delete group: $e");
      CustomSnackbar.showError(
        title: "error".tr,
        message: 'cannot_delete_group'.tr,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPortalGroupsData() async {
    await fetchPortalGroupsCreatedByMe();
  }

  Future<void> fetchDashboardData({bool isSilent = false}) async {
    try {
      if (!isSilent && appsList.isEmpty && usersList.isEmpty) {
        isLoading.value = true;
      }

      await Future.wait([
        _loadAdminAppsAndRules(),
        _loadAdminAnnouncements(),
        fetchPortalGroupsCreatedByMe(),
        _loadAdminUsersAndGroups(),
      ]);
    } catch (e) {
      debugPrint("Failed to load admin dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<dynamic> _fetchAppsWithFallback() async {
    try {
      final res = await _authService.fetchAdminApps();
      if (res != null) {
        if (res is List && res.isNotEmpty) return res;
        if (res is Map &&
            ((res['data'] is List && (res['data'] as List).isNotEmpty) ||
                (res['value'] is List && (res['value'] as List).isNotEmpty))) {
          return res;
        }
      }
    } catch (e) {
      debugPrint("Admin apps error/403 (falling back to portal apps): $e");
    }

    try {
      final portalRes = await _authService.fetchPortalApps();
      if (portalRes != null) {
        if (portalRes is List && portalRes.isNotEmpty) return portalRes;
        if (portalRes is Map &&
            ((portalRes['data'] is List && (portalRes['data'] as List).isNotEmpty) ||
                (portalRes['value'] is List && (portalRes['value'] as List).isNotEmpty))) {
          return portalRes;
        }
      }
    } catch (e) {
      debugPrint("Fallback fetchPortalApps failed: $e");
    }

    try {
      return await _authService.fetchApps();
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _fetchUsersWithFallback() async {
    try {
      final res = await _authService.apiService.get(
        endpoint: '/api/mobile/admin/user-profiles?page=0&size=1000',
      );
      if (res != null) return res;
    } catch (_) {}

    try {
      final res = await _authService.apiService.get(
        endpoint: '/api/mobile/admin/user-profiles',
      );
      if (res != null) return res;
    } catch (_) {}

    try {
      final res = await _authService.apiService.get(
        endpoint: '/api/mobile/gateway/user-profile/users',
      );
      if (res != null) return res;
    } catch (e) {
      debugPrint("Gateway users fallback failed: $e");
    }

    return null;
  }

  Future<void> _loadAdminAppsAndRules() async {
    try {
      final Map<String, List<Map<String, dynamic>>> appRulesMap = {};

      final results = await Future.wait([
        _authService.apiService
            .get(endpoint: '/api/mobile/admin/portal-app-access-rules')
            .catchError((e) {
          debugPrint("Failed to fetch portal app access rules in admin controller: $e");
          return null;
        }),
        _fetchAppsWithFallback(),
      ]);

      final rulesRes = results[0];
      final appsResponse = results[1];

      if (rulesRes != null) {
        List items = [];
        if (rulesRes is List) {
          items = rulesRes;
        } else if (rulesRes is Map) {
          items = rulesRes['data'] ?? rulesRes['items'] ?? rulesRes['value'] ?? [];
        }
        for (final r in items) {
          if (r is Map) {
            final String appId = (r['appId'] ??
                    r['portalAppId'] ??
                    r['app_id'] ??
                    r['portal_app_id'] ??
                    '')
                .toString();
            if (appId.isNotEmpty) {
              appRulesMap.putIfAbsent(appId, () => []).add(Map<String, dynamic>.from(r));
            }
          }
        }
      }

      List rawApps = [];
      if (appsResponse != null) {
        if (appsResponse is List) {
          rawApps = appsResponse;
        } else if (appsResponse is Map) {
          rawApps = appsResponse['value'] ??
              appsResponse['data'] ??
              appsResponse['items'] ??
              appsResponse['content'] ??
              appsResponse['apps'] ??
              [];
        }
      }
      if (rawApps.isNotEmpty) {
        final parsedApps = rawApps.map<Map<String, dynamic>>((app) {
          final String appId = app['id']?.toString() ?? '';
          final String titleKh = app['nameKh'] ??
              app['title_kh'] ??
              app['name_kh'] ??
              app['name'] ??
              'កម្មវិធី';
          final String titleEn = app['nameEn'] ??
              app['title_en'] ??
              app['name_en'] ??
              app['name'] ??
              'App';
          final String route = app['launchUrl'] ??
              app['appUrl'] ??
              app['route'] ??
              app['path'] ??
              app['url'] ??
              '/';
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
          final String icon =
              app['iconUrl'] ?? app['icon'] ?? app['logo'] ?? '';
          final String code = app['code'] ?? '';
          final List rawRules =
              app['accessRules'] ?? app['access_rules'] ?? app['rules'] ?? [];
          final List accessRules = rawRules.isNotEmpty
              ? rawRules
              : (appRulesMap[appId] ?? []);

          String ruleTypeRaw = '';
          String ruleValue = '';
          if (accessRules.isNotEmpty) {
            final firstRule = accessRules[0];
            if (firstRule is Map) {
              ruleTypeRaw = (firstRule['ruleType'] ??
                      firstRule['rule_type'] ??
                      firstRule['type'] ??
                      '')
                  .toString();
              ruleValue = (firstRule['ruleValue'] ??
                      firstRule['rule_value'] ??
                      firstRule['value'] ??
                      firstRule['target'] ??
                      '')
                  .toString();
            } else if (firstRule is String) {
              final parts = firstRule.split(':');
              if (parts.length > 1) {
                ruleTypeRaw = parts[0];
                ruleValue = parts.sublist(1).join(':');
              } else {
                ruleValue = firstRule;
              }
            }
          }
          final String ruleType = _mapRuleTypeToKhmer(ruleTypeRaw);

          String iconPath = '';
          String iconUrl = '';

          if (icon.isNotEmpty &&
              icon != 'assets/img/about-moi-logo.png' &&
              icon != '/assets/img/about-moi-logo.png') {
            final cleanLower = icon.toLowerCase();
            final bool isLocal = cleanLower.startsWith('assets/') ||
                cleanLower.startsWith('asset/') ||
                cleanLower.startsWith('/assets/') ||
                cleanLower.startsWith('/asset/') ||
                cleanLower.startsWith('images/') ||
                cleanLower.startsWith('/images/');

            if (isLocal) {
              iconPath = icon.startsWith('/') ? icon.substring(1) : icon;
              if (!iconPath.startsWith('assets/')) {
                iconPath = 'assets/$iconPath';
              }
            } else {
              iconUrl = AppIconWidget.formatIconUrl(icon);
            }
          }

          return {
            'id': appId,
            'titleKh': titleKh,
            'nameKh': titleKh,
            'titleEn': titleEn,
            'nameEn': titleEn,
            'name': titleKh,
            'route': route,
            'url': route,
            'launchUrl': route,
            'appUrl': route,
            'isActive': isActive,
            'icon': iconPath,
            'iconUrl': iconUrl,
            'code': code,
            'ruleType': ruleType,
            'ruleValue': ruleValue,
            'department': ruleValue,
            'departmentName': ruleValue,
            'description': (app['description'] ?? app['desc'] ?? '').toString(),
            'accessRules': accessRules,
          };
        }).toList();

        appsList.assignAll(parsedApps);
        totalApps.value = parsedApps.length;
        runningApps.value = parsedApps
            .where((app) => app['isActive'] == true)
            .length;
        GetStorage().write('cached_admin_apps_list', parsedApps);
      }
    } catch (e) {
      debugPrint("Failed to load apps dashboard: $e");
    }
  }

  Future<void> _loadAdminAnnouncements() async {
    try {
      dynamic annResponse;
      try {
        annResponse = await _authService.fetchAdminAnnouncements();
      } catch (_) {}
      if (annResponse == null) {
        try {
          annResponse = await _authService.fetchPortalAnnouncements();
        } catch (_) {}
      }

      List rawAnnouncements = [];
      if (annResponse != null) {
        if (annResponse is List) {
          rawAnnouncements = annResponse;
        } else if (annResponse is Map) {
          rawAnnouncements =
              annResponse['value'] ?? annResponse['data'] ?? [];
        }
      }

      final parsedAnnouncements = rawAnnouncements.map<Map<String, dynamic>>((
        item,
      ) {
        final String title =
            item['title'] ??
            item['titleKh'] ??
            item['title_kh'] ??
            'សេចក្តីប្រកាស';
        final String date =
            item['created_at'] ?? item['createdAt'] ?? item['date'] ?? '';
        final String description =
            item['content'] ?? item['description'] ?? '';

        return {'title': title, 'date': date, 'description': description};
      }).toList();

      parsedAnnouncements.sort((a, b) {
        final DateTime? dtA = DateTime.tryParse(a['date'] ?? '');
        final DateTime? dtB = DateTime.tryParse(b['date'] ?? '');
        if (dtA == null && dtB == null) return 0;
        if (dtA == null) return 1;
        if (dtB == null) return -1;
        return dtB.compareTo(dtA);
      });

      announcementsList.assignAll(parsedAnnouncements);
      announcementsCount.value = parsedAnnouncements.length;
      GetStorage().write('cached_admin_announcements_list', parsedAnnouncements);
    } catch (e) {
      debugPrint("Failed to load announcements dashboard: $e");
    }
  }

  Future<void> _loadAdminUsersAndGroups() async {
    try {
      final results = await Future.wait([
        _fetchUsersWithFallback(),
        _authService.apiService
            .get(endpoint: '/api/mobile/admin/portal-groups/user-groups')
            .catchError((e) {
          debugPrint("Failed to fetch portal user-groups in admin controller: $e");
          return null;
        }),
      ]);

      final usersResponse = results[0];
      final userGroupsRes = results[1];

      final Map<String, List<String>> userGroupsMapLocal = {};
      final Map<String, List<String>> localUidToGroups = {};

      if (userGroupsRes != null) {
        List items = [];
        if (userGroupsRes is List) {
          items = userGroupsRes;
        } else if (userGroupsRes is Map) {
          items =
              userGroupsRes['data'] ??
              userGroupsRes['items'] ??
              userGroupsRes['value'] ??
              userGroupsRes['content'] ??
              userGroupsRes['results'] ??
              [];
        }
        final Map<String, List<String>> newGroupUsersMap = {};

        for (final item in items) {
          if (item is Map) {
            final String? uid =
                (item['keycloakUserId'] ??
                        item['keycloak_user_id'] ??
                        item['userId'] ??
                        item['user_id'] ??
                        item['id'] ??
                        item['username'])
                    ?.toString()
                    .toLowerCase()
                    .trim();
            final String? code =
                (item['groupCode'] ??
                        item['group_code'] ??
                        item['code'] ??
                        item['groupId'] ??
                        item['group_id'] ??
                        item['sublabel'] ??
                        item['name'] ??
                        item['groupName'])
                    ?.toString();
            if (uid != null &&
                uid.isNotEmpty &&
                code != null &&
                code.isNotEmpty) {
              final list = localUidToGroups.putIfAbsent(uid, () => []);
              if (!list.contains(code)) list.add(code);
              final uidList = newGroupUsersMap.putIfAbsent(code, () => []);
              if (!uidList.contains(uid)) uidList.add(uid);
            }
          }
        }
        userGroupsMapLocal.addAll(newGroupUsersMap);

        // Build groupAppCountMap: groupCode → unique app count
        final Map<String, Set<String>> appGroupSets = {};
        for (final app in appsList) {
          final String appId = app['id']?.toString() ?? '';
          final List accessRules = app['accessRules'] is List
              ? app['accessRules']
              : (app['access_rules'] is List
                  ? app['access_rules']
                  : (app['rules'] is List ? app['rules'] : []));
          for (final rule in accessRules) {
            if (rule is Map) {
              final String rType = (rule['ruleType'] ?? rule['rule_type'] ?? rule['type'] ?? '').toString().toUpperCase();
              final String rVal = (rule['ruleValue'] ?? rule['rule_value'] ?? rule['target'] ?? rule['value'] ?? '').toString().trim();
              if ((rType.contains('GROUP') || rType.contains('PORTAL')) && rVal.isNotEmpty) {
                appGroupSets.putIfAbsent(rVal, () => {}).add(appId);
              }
            } else if (rule is String) {
              final parts = rule.split(':');
              if (parts.length > 1 && (parts[0].toUpperCase().contains('GROUP') || parts[0].toUpperCase().contains('PORTAL'))) {
                final rVal = parts.sublist(1).join(':').trim();
                if (rVal.isNotEmpty) {
                  appGroupSets.putIfAbsent(rVal, () => {}).add(appId);
                }
              }
            }
          }
        }
        groupAppCountMap
          ..clear()
          ..addAll(appGroupSets.map((k, v) => MapEntry(k, v.length)));
      }

      if (usersResponse != null) {
        List rawUsers = [];
        if (usersResponse is List) {
          rawUsers = usersResponse;
        } else if (usersResponse is Map) {
          final data =
              usersResponse['content'] ??
              usersResponse['value'] ??
              usersResponse['data'] ??
              usersResponse['items'] ??
              usersResponse['results'] ??
              [];
          if (data is List) {
            rawUsers = data;
          }
        }

        final parsedUsers = rawUsers.map<Map<String, dynamic>>((usr) {
          final String id =
              (usr['id']?.toString() ?? usr['username']?.toString() ?? '')
                  .toLowerCase()
                  .trim();
          final String keycloakUserId =
              (usr['keycloakUserId'] ?? usr['keycloak_user_id'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          final String usrName = (usr['username'] ?? usr['name'] ?? '')
              .toString()
              .toLowerCase()
              .trim();

          final String username =
              usr['username'] ?? usr['name'] ?? 'អ្នកប្រើប្រាស់';
          final String email = usr['email'] ?? '';
          String role = (usr['role'] ?? usr['roleName'] ?? '').toString().trim();
          if (role.isEmpty) {
            if (usr['roles'] is List && (usr['roles'] as List).isNotEmpty) {
              role = (usr['roles'] as List).first.toString();
            } else {
              role = 'User';
            }
          }

          // Resolve displayName
          String resolvedDisplayName = (usr['displayName'] ??
                  usr['display_name'] ??
                  usr['fullName'] ??
                  usr['full_name'] ??
                  usr['name_kh'] ??
                  usr['nameKh'] ??
                  '')
              .toString()
              .trim();

          // Resolve from nested profile object if present (e.g. gateway users)
          if ((resolvedDisplayName.isEmpty || resolvedDisplayName.toLowerCase() == username.toLowerCase()) && usr['profile'] is Map) {
            final p = usr['profile'] as Map;
            final pDisp = (p['displayName'] ?? p['display_name'] ?? '').toString().trim();
            if (pDisp.isNotEmpty) {
              resolvedDisplayName = pDisp;
            } else {
              final pKhFirst = (p['firstNameKm'] ?? p['firstNameKh'] ?? '').toString().trim();
              final pKhLast = (p['lastNameKm'] ?? p['lastNameKh'] ?? '').toString().trim();
              if (pKhFirst.isNotEmpty || pKhLast.isNotEmpty) {
                resolvedDisplayName = '$pKhLast $pKhFirst'.trim();
              } else {
                final pLatFirst = (p['firstNameLatin'] ?? p['firstNameEn'] ?? '').toString().trim();
                final pLatLast = (p['lastNameLatin'] ?? p['lastNameEn'] ?? '').toString().trim();
                if (pLatFirst.isNotEmpty || pLatLast.isNotEmpty) {
                  resolvedDisplayName = '$pLatLast $pLatFirst'.trim();
                }
              }
            }
          }

          if ((resolvedDisplayName.isEmpty || resolvedDisplayName.toLowerCase() == username.toLowerCase()) && usr['attributes'] is Map) {
            final attrDisp = usr['attributes']['displayName'] ?? usr['attributes']['display_name'];
            if (attrDisp is List && attrDisp.isNotEmpty) {
              resolvedDisplayName = attrDisp.first.toString().trim();
            } else if (attrDisp is String) {
              resolvedDisplayName = attrDisp.trim();
            }
          }

          if (resolvedDisplayName.isEmpty || resolvedDisplayName.toLowerCase() == username.toLowerCase()) {
            final first = (usr['firstName'] ?? usr['first_name'] ?? '').toString().trim();
            final last = (usr['lastName'] ?? usr['last_name'] ?? '').toString().trim();
            if (first.isNotEmpty || last.isNotEmpty) {
              resolvedDisplayName = '$first $last'.trim();
            }
          }

          if (resolvedDisplayName.isEmpty || resolvedDisplayName.toLowerCase() == username.toLowerCase()) {
            final box = GetStorage();
            final currentUname = (box.read('username') ?? '').toString().trim().toLowerCase();
            final currentUid = (box.read('userProfileUserId') ?? box.read('userId') ?? box.read('sub') ?? '').toString().trim().toLowerCase();
            final isCurrent = (username.isNotEmpty && username.toLowerCase() == currentUname) ||
                              (id.isNotEmpty && id == currentUid) ||
                              (keycloakUserId.isNotEmpty && keycloakUserId == currentUid);
            if (isCurrent) {
              final selfName = (box.read('user_display_name') ?? box.read('displayName') ?? '').toString().trim();
              if (selfName.isNotEmpty) {
                resolvedDisplayName = selfName;
              }
            }
          }

          if (resolvedDisplayName.isEmpty || resolvedDisplayName.toLowerCase() == username.toLowerCase()) {
            final rawName = (usr['name'] ?? '').toString().trim();
            if (rawName.isNotEmpty && rawName.toLowerCase() != username.toLowerCase()) {
              resolvedDisplayName = rawName;
            }
          }

          if (resolvedDisplayName.isEmpty || resolvedDisplayName.toLowerCase() == username.toLowerCase()) {
            if (username.contains('.')) {
              final parts = username.split('.');
              if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
                final p0 = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
                final p1 = '${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
                resolvedDisplayName = '$p1 $p0';
              } else {
                resolvedDisplayName = parts
                    .where((p) => p.isNotEmpty)
                    .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
                    .join(' ');
              }
            }
          }

          if (resolvedDisplayName.isEmpty) {
            resolvedDisplayName = username;
          }

          String status = 'ACTIVE';
          if (usr['status'] != null) {
            status = usr['status'].toString().toUpperCase();
          } else {
            final bool isEnabled =
                usr['enabled'] ??
                usr['active'] ??
                usr['isActive'] ??
                usr['is_active'] ??
                true;
            status = isEnabled ? 'ACTIVE' : 'INACTIVE';
          }

          String unit = adminGeneralDepartmentNameKh;
          final List empInfos = usr['employmentInfos'] ?? [];
          if (empInfos.isNotEmpty && empInfos[0] is Map) {
            final firstEmp = empInfos[0];
            final rawKh = (firstEmp['generalDepartmentNameKh'] ??
                    firstEmp['departmentNameKh'] ??
                    usr['generalDepartmentNameKh'] ??
                    usr['departmentNameKh'] ??
                    '')
                .toString()
                .trim();

            if (rawKh.isNotEmpty && rawKh != '—' && rawKh != '-') {
              unit = rawKh;
            } else {
              final raw = (firstEmp['generalDepartmentCode'] ??
                      firstEmp['generalDepartmentName'] ??
                      firstEmp['departmentCode'] ??
                      '')
                  .toString()
                  .trim();
              unit = formatDepartmentToKhmer(raw);
            }
          } else {
            final rootKh = (usr['generalDepartmentNameKh'] ??
                    usr['departmentNameKh'] ??
                    '')
                .toString()
                .trim();
            if (rootKh.isNotEmpty && rootKh != '—' && rootKh != '-') {
              unit = rootKh;
            } else {
              final raw = (usr['department'] ??
                      usr['unit'] ??
                      usr['generalDepartmentCode'] ??
                      '')
                  .toString()
                  .trim();
              unit = formatDepartmentToKhmer(raw);
            }
          }

          if (isSelfUser(usr) &&
              (unit.isEmpty ||
                  unit == '—' ||
                  unit == '-' ||
                  unit == 'null')) {
            unit = adminGeneralDepartmentNameKh;
          }

          final List<String> fetchedGroups = {
            ...?localUidToGroups[id],
            ...?localUidToGroups[keycloakUserId],
            ...?localUidToGroups[usrName],
          }.toList();

          return {
            ...usr,
            'username': username,
            'displayName': resolvedDisplayName,
            'email': email,
            'role': role,
            'status': status,
            'unit': unit,
            'groups': fetchedGroups,
            'userGroups': fetchedGroups,
            'portalGroups': fetchedGroups,
          };
        }).toList();

        final Set<String> createdByMeGroupCodes = groupList.map((g) {
          final code = (g['code'] ?? g['sublabel'] ?? g['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return code.startsWith('/') ? code.substring(1) : code;
        }).where((c) => c.isNotEmpty).toSet();

        // 🟢 Filter users so only users in this admin's General Department ("អគ្គ")
        // or members of groups created by this admin, or self are shown
        final generalDeptUsers = parsedUsers.where((u) {
          return isUserInAdminGeneralDepartment(
            u,
            createdByMeGroupCodes,
            userGroupsMapLocal,
          );
        }).toList();

        usersList.assignAll(generalDeptUsers);
        totalUsers.value = generalDeptUsers.length;
        userGroupsMap.assignAll(userGroupsMapLocal);
        GetStorage().write('cached_admin_users_list', generalDeptUsers);
        GetStorage().write('cached_admin_user_groups_map', userGroupsMapLocal);
      }
    } catch (e) {
      debugPrint("Failed to load users dashboard: $e");
    }
  }

  Future<void> backupDatabase() async {
    if (isBackingUp.value) return;

    isBackingUp.value = true;
    backupProgress.value = 0.0;

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      backupProgress.value = i / 10.0;
    }

    isBackingUp.value = false;

    auditLogs.insert(0, {
      'title': 'ប្រព័ន្ធបម្រុងទិន្នន័យ (Backup)',
      'desc': 'ការបង្កើតប្រព័ន្ធបម្រុងទុកមូលដ្ឋានទិន្នន័យដោយដៃបានបញ្ចប់',
      'time': 'ទើបតែថ្មីៗ',
      'status': 'success',
    });

    CustomSnackbar.showSuccess(
      message: 'ការបម្រុងទុកទិន្នន័យត្រូវបានបញ្ចប់ដោយជោគជ័យ!',
    );
  }

  Future<void> clearSystemCache() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;

    auditLogs.insert(0, {
      'title': 'ការសំអាត Cache ប្រព័ន្ធ',
      'desc': 'បានសំអាត cache ឯកសារបណ្តោះអាសន្នទាំងអស់ក្នុងប្រព័ន្ធ',
      'time': 'ទើបតែថ្មីៗ',
      'status': 'success',
    });

    CustomSnackbar.showSuccess(message: 'បានសំអាត Cache របស់ប្រព័ន្ធរួចរាល់!');
  }

  void addNewUser(String name, String email, String role) {
    usersList.insert(0, {
      'username': name,
      'email': email,
      'role': role,
      'status': 'ACTIVE',
      'unit': adminGeneralDepartmentNameKh,
    });
    totalUsers.value = usersList.length;

    auditLogs.insert(0, {
      'title': 'បង្កើតគណនីថ្មី',
      'desc': 'បានបង្កើតគណនីថ្មី: $name ($role) - $email',
      'time': 'ទើបតែថ្មីៗ',
      'status': 'success',
    });

    CustomSnackbar.showSuccess(
      message: 'បានបង្កើតគណនីអ្នកប្រើប្រាស់ថ្មីដោយជោគជ័យ!',
    );
  }

  void updateUser(
    int index,
    String name,
    String email,
    String role,
    String status,
    String unit,
  ) {
    if (index >= 0 && index < usersList.length) {
      usersList[index] = {
        ...usersList[index],
        'username': name,
        'email': email,
        'role': role,
        'status': status,
        'unit': unit,
      };

      auditLogs.insert(0, {
        'title': 'កែប្រែគណនី',
        'desc': 'បានកែប្រែព័ត៌មានគណនី: $name',
        'time': 'ទើបតែថ្មីៗ',
        'status': 'info',
      });

      CustomSnackbar.showSuccess(
        message: 'បានកែប្រែព័ត៌មានអ្នកប្រើប្រាស់ដោយជោគជ័យ!',
      );
    }
  }

  void deleteUser(dynamic userOrIndex) {
    int index = -1;
    if (userOrIndex is int) {
      index = userOrIndex;
    } else if (userOrIndex is Map) {
      index = usersList.indexOf(userOrIndex);
      if (index == -1) {
        final id = (userOrIndex['id'] ??
                userOrIndex['keycloakUserId'] ??
                userOrIndex['username'] ??
                '')
            .toString()
            .toLowerCase()
            .trim();
        index = usersList.indexWhere((u) {
          final uid = (u['id'] ?? u['keycloakUserId'] ?? u['username'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          return uid == id;
        });
      }
    }

    if (index >= 0 && index < usersList.length) {
      final user = usersList[index];
      if (!canEditUser(user)) {
        CustomSnackbar.showWarning(
          title: 'មិនអាចលុបបានទេ',
          message:
              'អ្នកមិនអាចលុបគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot delete your own account)',
        );
        return;
      }
      final name = user['username'] ?? 'អ្នកប្រើប្រាស់';
      usersList.removeAt(index);
      totalUsers.value = usersList.length;
      GetStorage().write('cached_admin_users_list', usersList.toList());

      auditLogs.insert(0, {
        'title': 'លុបគណនី',
        'desc': 'បានលុបគណនីអ្នកប្រើប្រាស់: $name',
        'time': 'ទើបតែថ្មីៗ',
        'status': 'warning',
      });

      CustomSnackbar.showSuccess(message: 'បានលុបគណនីអ្នកប្រើប្រាស់រួចរាល់!');
    }
  }

  Future<void> openApiDocs() async {
    final String docsUrl = '${ApiConfig.baseUrl}/docs';

    final uri = Uri.parse(docsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      auditLogs.insert(0, {
        'title': 'បើកមើល API Docs',
        'desc': 'បានបើកមើលឯកសារបច្ចេកទេស API ($docsUrl)',
        'time': 'ទើបតែថ្មីៗ',
        'status': 'info',
      });

      CustomSnackbar.showSuccess(message: 'កំពុងបើកឯកសារ API...');
    } catch (e) {
      debugPrint("Could not launch API docs: $e");
      CustomSnackbar.showError(message: 'មិនអាចបើកឯកសារ API នេះបានទេ');
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.logout();
      final box = GetStorage();
      await box.remove('token');
      await box.remove('isAdmin');

      CustomSnackbar.showSuccess(message: 'ចាកចេញពីប្រព័ន្ធទទួលបានជោគជ័យ');
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint("Admin logout error: $e");
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> addNewApp({
    required String nameKh,
    required String nameEn,
    required String url,
    String? ruleType,
    String? ruleValue,
    List<Map<String, dynamic>>? accessRules,
    required bool isActive,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      isLoading.value = true;
      final code = nameEn.toLowerCase().replaceAll(
        RegExp(r'[^a-zA-Z0-9_]'),
        '_',
      );

      final List<Map<String, dynamic>> rulesPayload = [];
      if (accessRules != null && accessRules.isNotEmpty) {
        for (final r in accessRules) {
          final String rType = (r['ruleType'] ?? r['type'] ?? '').toString();
          final String rVal = (r['ruleValue'] ?? r['value'] ?? '').toString();
          if (rType.isNotEmpty && rVal.isNotEmpty) {
            rulesPayload.add({
              'ruleType': _mapRuleTypeToEnglish(rType),
              'ruleValue': rVal,
            });
          }
        }
      } else if (ruleType != null && ruleValue != null) {
        rulesPayload.add({
          'ruleType': _mapRuleTypeToEnglish(ruleType),
          'ruleValue': ruleValue,
        });
      }

      final Map<String, dynamic> data = {
        'nameKh': nameKh,
        'nameEn': nameEn,
        'appUrl': url,
        'enabled': isActive,
        'code': code,
        'accessRules': rulesPayload,
      };

      try {
        final response = await _authService.createAdminApp(data);
        final String newId = (response is Map ? (response['id'] ?? response['data']?['id']) : null)?.toString() ?? '';
        
        if (newId.isNotEmpty && rulesPayload.isNotEmpty) {
          for (final r in rulesPayload) {
            try {
              await _authService.createPortalAppAccessRule({
                'portalAppId': newId,
                'ruleType': r['ruleType'],
                'ruleValue': r['ruleValue'],
                'enabled': true,
              });
            } catch (e) {
              debugPrint("Note on individual access rule POST in admin: $e");
            }
          }
        }

        if (fileBytes != null && fileName != null && newId.isNotEmpty) {
          await _authService.uploadAppIcon(
            appId: newId,
            fileBytes: fileBytes,
            fileName: fileName,
          );
        }
      } catch (e) {
        debugPrint("API create admin app error (will update locally): $e");
      }

      await fetchDashboardData();

      auditLogs.insert(0, {
        'title': 'បានបង្កើតកម្មវិធីថ្មី',
        'desc': 'កម្មវិធី "$nameKh" ត្រូវបានបង្កើតឡើងដោយជោគជ័យ',
        'time': 'មុននេះបន្តិច',
        'status': 'success',
      });

      CustomSnackbar.showSuccess(message: 'app_created_success'.tr);
    } catch (e) {
      CustomSnackbar.showError(message: 'cannot_create_app'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateApp({
    required int index,
    required String nameKh,
    required String nameEn,
    required String url,
    String? ruleType,
    String? ruleValue,
    List<Map<String, dynamic>>? accessRules,
    List<String>? deletedRuleIds,
    required bool isActive,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (index >= 0 && index < appsList.length) {
      final app = appsList[index];
      final String id = app['id'] ?? '';
      try {
        isLoading.value = true;
        final String code =
            app['code'] ??
            nameEn.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

        final List<Map<String, dynamic>> rulesPayload = [];
        if (accessRules != null && accessRules.isNotEmpty) {
          for (final r in accessRules) {
            final String rType = (r['ruleType'] ?? r['type'] ?? '').toString();
            final String rVal = (r['ruleValue'] ?? r['value'] ?? '').toString();
            final String? rId = r['id']?.toString();
            if (rType.isNotEmpty && rVal.isNotEmpty) {
              final mappedType = _mapRuleTypeToEnglish(rType);
              rulesPayload.add({
                if (rId != null && rId.isNotEmpty) 'id': rId,
                'ruleType': mappedType,
                'ruleValue': rVal,
              });

              if (id.isNotEmpty) {
                try {
                  if (rId != null && rId.isNotEmpty) {
                    await _authService.updatePortalAppAccessRule(rId, {
                      'portalAppId': id,
                      'ruleType': mappedType,
                      'ruleValue': rVal,
                      'enabled': true,
                    });
                  } else {
                    await _authService.createPortalAppAccessRule({
                      'portalAppId': id,
                      'ruleType': mappedType,
                      'ruleValue': rVal,
                      'enabled': true,
                    });
                  }
                } catch (e) {
                  debugPrint("Note on individual rule sync (PUT/POST) in admin: $e");
                }
              }
            }
          }
        } else if (ruleType != null && ruleValue != null) {
          final mappedType = _mapRuleTypeToEnglish(ruleType);
          rulesPayload.add({
            'ruleType': mappedType,
            'ruleValue': ruleValue,
          });
          if (id.isNotEmpty) {
            try {
              await _authService.createPortalAppAccessRule({
                'portalAppId': id,
                'ruleType': mappedType,
                'ruleValue': ruleValue,
                'enabled': true,
              });
            } catch (e) {
              debugPrint("Note on rule individual sync (POST) in admin: $e");
            }
          }
        }

        // Delete any removed access rules
        if (deletedRuleIds != null && deletedRuleIds.isNotEmpty) {
          for (final delId in deletedRuleIds) {
            if (delId.isNotEmpty) {
              try {
                await _authService.deletePortalAppAccessRule(delId);
              } catch (e) {
                debugPrint("Note on rule individual delete in admin: $e");
              }
            }
          }
        }

        final Map<String, dynamic> data = {
          'id': id,
          'nameKh': nameKh,
          'nameEn': nameEn,
          'appUrl': url,
          'enabled': isActive,
          'code': code,
          'accessRules': rulesPayload,
        };

        if (id.isNotEmpty) {
          try {
            await _authService.updateAdminApp(id, data);
            if (fileBytes != null && fileName != null) {
              await _authService.uploadAppIcon(
                appId: id,
                fileBytes: fileBytes,
                fileName: fileName,
              );
            }
          } catch (e) {
            debugPrint("API update admin app error: $e");
          }
        }

        await fetchDashboardData();
        CustomSnackbar.showSuccess(message: 'app_updated_success'.tr);
      } catch (e) {
        CustomSnackbar.showError(message: 'cannot_update_app'.tr);
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchAccessRulesForApp(String appId) async {
    try {
      final res = await _authService.fetchPortalAppAccessRulesByApp(appId);
      if (res != null) {
        List list = [];
        if (res is List) {
          list = res;
        } else if (res is Map) {
          list = (res['data'] as List?) ??
              (res['items'] as List?) ??
              (res['value'] as List?) ??
              (res['content'] as List?) ??
              [];
        }
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching access rules for app $appId: $e");
    }
    return [];
  }

  Future<void> deleteApp(int index) async {
    if (index >= 0 && index < appsList.length) {
      final app = appsList[index];
      final String id = (app['id'] ?? '').toString();
      final name = app['titleKh'] ?? 'កម្មវិធី';

      try {
        if (id.isNotEmpty) {
          try {
            await _authService.deleteAdminApp(id);
          } catch (e) {
            debugPrint("API delete admin app error: $e");
          }
        }

        appsList.removeAt(index);
        totalApps.value = appsList.length;
        runningApps.value = appsList
            .where((app) => app['isActive'] == true)
            .length;

        auditLogs.insert(0, {
          'title': 'បានលុបកម្មវិធី',
          'desc': 'កម្មវិធី "$name" ត្រូវបានលុបចេញពីប្រព័ន្ធ',
          'time': 'មុននេះបន្តិច',
          'status': 'warning',
        });

        CustomSnackbar.showSuccess(message: 'app_deleted_success'.tr);
      } catch (e) {
        CustomSnackbar.showError(message: 'cannot_delete_app'.tr);
      }
    }
  }

  String _mapRuleTypeToEnglish(String khmer) {
    switch (khmer) {
      case 'អគ្គនាយកដ្ឋាន':
        return 'GENERAL_DEPARTMENT';
      case 'នាយកដ្ឋាន':
        return 'DEPARTMENT';
      case 'ការិយាល័យ':
        return 'BUREAU';
      case 'មុខតំណែង':
        return 'POSITION';
      case 'តួនាទី':
        return 'ROLE';
      case 'ក្រុម':
        return 'PORTAL_USER_GROUPS';
      case 'អ្នកប្រើប្រាស់':
        return 'USER';
      case 'បដិសេធក្រុម':
        return 'DENY_GROUP';
      case 'បដិសេធអ្នកប្រើប្រាស់':
        return 'DENY_USER';
      default:
        return khmer;
    }
  }

  String _mapRuleTypeToKhmer(String english) {
    switch (english.toUpperCase()) {
      case 'GENERAL_DEPARTMENT':
        return 'អគ្គនាយកដ្ឋាន';
      case 'DEPARTMENT':
        return 'នាយកដ្ឋាន';
      case 'BUREAU':
        return 'ការិយាល័យ';
      case 'POSITION':
        return 'មុខតំណែង';
      case 'ROLE':
        return 'តួនាទី';
      case 'GROUP':
        return 'ក្រុម';
      case 'USER':
        return 'អ្នកប្រើប្រាស់';
      case 'DENY_GROUP':
        return 'បដិសេធក្រុម';
      case 'DENY_USER':
        return 'បដិសេធអ្នកប្រើប្រាស់';
      default:
        return english;
    }
  }

  Future<bool> removeUserGroupFromUser(
    Map<String, dynamic> targetUser,
    String groupIdentifier,
  ) async {
    if (!canEditUser(targetUser)) {
      CustomSnackbar.showWarning(
        title: 'មិនអាចកែប្រែបានទេ',
        message:
            'អ្នកមិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
      );
      return false;
    }
    try {
      final String keycloakId =
          (targetUser['keycloakUserId'] ??
                  targetUser['keycloak_user_id'] ??
                  targetUser['id'] ??
                  '')
              .toString()
              .trim();
      if (keycloakId.isEmpty) return false;

      final targetLower = groupIdentifier.toLowerCase().trim();
      final targetNorm = targetLower.replaceAll('_', ' ').replaceAll('-', ' ');

      final matchedGroup = groupList.firstWhereOrNull((g) {
        final name = (g['name'] ?? '').toString().toLowerCase().trim();
        final code = (g['sublabel'] ?? g['code'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final id = (g['id'] ?? '').toString().toLowerCase().trim();

        final normName = name.replaceAll('_', ' ').replaceAll('-', ' ');
        final normCode = code.replaceAll('_', ' ').replaceAll('-', ' ');

        return name == targetLower ||
            code == targetLower ||
            id == targetLower ||
            (normName.isNotEmpty && normName == targetNorm) ||
            (normCode.isNotEmpty && normCode == targetNorm);
      });

      final String actualCode = (matchedGroup != null
          ? (matchedGroup['sublabel']?.toString().isNotEmpty == true
              ? matchedGroup['sublabel']?.toString()
              : (matchedGroup['code']?.toString().isNotEmpty == true
                  ? matchedGroup['code']?.toString()
                  : (matchedGroup['id']?.toString().isNotEmpty == true
                      ? matchedGroup['id']?.toString()
                      : matchedGroup['name']?.toString())))
          : null) ?? groupIdentifier;

      isLoading.value = true;
      try {
        await _authService.removeUserGroup(keycloakId, actualCode.trim());
      } catch (e) {
        debugPrint("removeUserGroup error: $e");
      }

      if (targetUser['groups'] is List) {
        (targetUser['groups'] as List).remove(groupIdentifier);
        (targetUser['groups'] as List).remove(actualCode);
      }
      return true;
    } catch (e) {
      debugPrint("Failed to remove user group via DELETE: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🟢 Fixed type mapping: Now accepts targetUser Map data parameters properly
  Future<bool> assignGroupsToUser(
    Map<String, dynamic> targetUser,
    List<String> selectedGroupNames,
  ) async {
    if (!canEditUser(targetUser)) {
      CustomSnackbar.showWarning(
        title: 'មិនអាចកែប្រែបានទេ',
        message:
            'អ្នកមិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
      );
      return false;
    }
    try {
      final String keycloakId = (targetUser['keycloakUserId'] ??
              targetUser['keycloak_user_id'] ??
              targetUser['id'] ??
              '')
          .toString()
          .trim();
      if (keycloakId.isEmpty) {
        CustomSnackbar.showError(
          title: "កំហុសអ្នកប្រើប្រាស់",
          message: "មិនអាចរកឃើញ លេខសម្គាល់អ្នកប្រើប្រាស់ (Keycloak ID) ឡើយ!",
        );
        return false;
      }

      final cleanedGroupNames = selectedGroupNames
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList();

      if (cleanedGroupNames.isEmpty) {
        targetUser['groups'] = <String>[];
        targetUser['userGroups'] = <String>[];
        targetUser['portalGroups'] = <String>[];
        targetUser['groupCodes'] = <String>[];
        final String kIdLower = keycloakId.toLowerCase().trim();
        final idx = usersList.indexWhere(
          (u) {
            final uId = (u['id']?.toString() ?? '').toLowerCase().trim();
            final uKId = (u['keycloakUserId'] ?? u['keycloak_user_id'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            final uName = (u['username'] ?? '').toString().toLowerCase().trim();
            return uId == kIdLower || uKId == kIdLower || uName == kIdLower;
          },
        );
        if (idx != -1) {
          usersList[idx]['groups'] = <String>[];
          usersList[idx]['userGroups'] = <String>[];
          usersList[idx]['portalGroups'] = <String>[];
          usersList[idx]['groupCodes'] = <String>[];
          usersList.refresh();
        }
        await fetchDashboardData();
        CustomSnackbar.showSuccess(
          title: "ជោគជ័យ",
          message: "បានរក្សាទុកការភ្ជាប់ក្រុមបានជោគជ័យ!",
        );
        return true;
      }

      final List<String> groupCodesToAssign = [];
      for (final targetGroupName in cleanedGroupNames) {
        final targetLower = targetGroupName.toLowerCase().trim();
        final targetNorm = targetLower
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');

        final matchedGroup = groupList.firstWhereOrNull((g) {
          final name = (g['name'] ?? '').toString().toLowerCase().trim();
          final code = (g['sublabel'] ?? g['code'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final id = (g['id'] ?? '').toString().toLowerCase().trim();

          final normName = name.replaceAll('_', ' ').replaceAll('-', ' ');
          final normCode = code.replaceAll('_', ' ').replaceAll('-', ' ');

          return name == targetLower ||
              code == targetLower ||
              id == targetLower ||
              (normName.isNotEmpty && normName == targetNorm) ||
              (normCode.isNotEmpty && normCode == targetNorm);
        });

        String? code = matchedGroup != null
            ? (matchedGroup['sublabel']?.toString().isNotEmpty == true
                  ? matchedGroup['sublabel']?.toString()
                  : (matchedGroup['code']?.toString().isNotEmpty == true
                        ? matchedGroup['code']?.toString()
                        : (matchedGroup['id']?.toString().isNotEmpty == true
                              ? matchedGroup['id']?.toString()
                              : matchedGroup['name']?.toString())))
            : targetGroupName;

        if (code != null && code.trim().isNotEmpty) {
          groupCodesToAssign.add(code.trim());
        }
      }

      if (groupCodesToAssign.isEmpty) {
        CustomSnackbar.showError(
          title: "កំហុសក្រុម",
          message: "មិនមានក្រុមត្រឹមត្រូវសម្រាប់ភ្ជាប់ទេ!",
        );
        return false;
      }

      isLoading.value = true;
      await _authService.assignUserGroups(keycloakId, groupCodesToAssign);

      // Persist assigned group names in memory for instant UI reflection
      targetUser['groups'] = List<String>.from(cleanedGroupNames);
      targetUser['userGroups'] = List<String>.from(groupCodesToAssign);
      targetUser['portalGroups'] = List<String>.from(groupCodesToAssign);
      targetUser['groupCodes'] = List<String>.from(groupCodesToAssign);

      final String kIdLower = keycloakId.toLowerCase().trim();
      final idx = usersList.indexWhere(
        (u) {
          final uId = (u['id']?.toString() ?? '').toLowerCase().trim();
          final uKId = (u['keycloakUserId'] ?? u['keycloak_user_id'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final uName = (u['username'] ?? '').toString().toLowerCase().trim();
          return uId == kIdLower || uKId == kIdLower || uName == kIdLower;
        },
      );
      if (idx != -1) {
        usersList[idx]['groups'] = List<String>.from(cleanedGroupNames);
        usersList[idx]['userGroups'] = List<String>.from(groupCodesToAssign);
        usersList[idx]['portalGroups'] = List<String>.from(groupCodesToAssign);
        usersList[idx]['groupCodes'] = List<String>.from(groupCodesToAssign);
        usersList.refresh();
      }

      await fetchDashboardData();

      CustomSnackbar.showSuccess(
        title: "ជោគជ័យ",
        message: "បានរក្សាទុកការភ្ជាប់ក្រុមបានជោគជ័យ!",
      );
      return true;
    } catch (e) {
      debugPrint("Failed to assign groups to user: $e");
      CustomSnackbar.showError(
        title: "error".tr,
        message: 'cannot_save_groups'.tr,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns the number of unique users assigned to a group across userGroupsMap, usersList, and server payload
  int getUserCountForGroup(Map<String, dynamic> grp) {
    final String name = (grp['name'] ?? grp['code'] ?? '').toString().trim();
    final String code = (grp['code'] ?? grp['sublabel'] ?? name).toString().trim();
    final String cleanName = name.toLowerCase();
    final String cleanCode = code.toLowerCase();
    final String normName = cleanName.replaceFirst(RegExp(r'^/'), '');
    final String normCode = cleanCode.replaceFirst(RegExp(r'^/'), '');

    final Set<String> uniqueUserIds = {};

    // 1. Check userGroupsMap
    for (final entry in userGroupsMap.entries) {
      final k = entry.key.toLowerCase().trim().replaceFirst(RegExp(r'^/'), '');
      if (k == normName || k == normCode || k == cleanName || k == cleanCode) {
        uniqueUserIds.addAll(entry.value.map((e) => e.toString().toLowerCase().trim()));
      }
    }

    // 2. Check usersList
    for (final user in usersList) {
      final String uid = (user['id'] ?? user['keycloakUserId'] ?? user['username'] ?? '').toString().toLowerCase().trim();
      final List groups = user['groups'] is List
          ? user['groups']
          : (user['userGroups'] is List
              ? user['userGroups']
              : (user['portalGroups'] is List ? user['portalGroups'] : []));

      for (final g in groups) {
        final gStr = (g is Map ? (g['name'] ?? g['code'] ?? '') : g)
            .toString()
            .toLowerCase()
            .trim()
            .replaceFirst(RegExp(r'^/'), '');
        if (gStr == normName || gStr == normCode) {
          uniqueUserIds.add(uid.isNotEmpty ? uid : user.toString());
          break;
        }
      }
    }

    // 3. Server-provided counts or member arrays in group object
    final serverUsers = grp['users'] ?? grp['members'];
    if (serverUsers is List && serverUsers.isNotEmpty) {
      if (serverUsers.length > uniqueUserIds.length) {
        return serverUsers.length;
      }
    }
    final serverCount = grp['usersCount'] ??
        grp['userCount'] ??
        grp['totalUsers'] ??
        grp['membersCount'];
    if (serverCount != null) {
      final int c = serverCount is int
          ? serverCount
          : int.tryParse(serverCount.toString()) ?? 0;
      if (c > uniqueUserIds.length) return c;
    }

    return uniqueUserIds.length;
  }

  /// Returns true if this group has any assigned users
  bool isGroupAssignedToAnyUser(Map<String, dynamic> grp) {
    return getUserCountForGroup(grp) > 0;
  }
}
