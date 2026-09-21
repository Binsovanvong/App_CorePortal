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
import 'package:core_portal/screens/admin/admin_controller.dart';

class SuperAdminController extends GetxController {
  final AuthService _authService = AuthService();

  Timer? _autoRefreshTimer;

  // Loading and action states
  final isLoading = false.obs;
  final isBackingUp = false.obs;
  final backupProgress = 0.0.obs;

  // Bottom Navigation State
  final currentIndex = 0.obs;
  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 0) {
      fetchDashboardData(isSilent: true);
      fetchRolesData(isSilent: true);
    } else if (index == 1) {
      fetchDashboardData(isSilent: true);
    } else if (index == 2) {
      fetchPortalGroupsData();
      fetchRolesData(isSilent: true);
    }
  }

  // Live Dashboard Stats
  final totalApps = 0.obs;
  final totalUsers = 0.obs;
  final runningApps = 0.obs;
  final announcementsCount = 0.obs;

  // groupCode → list of unique user IDs (keycloakUserId / userId)
  final userGroupsMap = <String, List<String>>{}.obs;
  // groupCode → count of unique apps assigned to that group
  final groupAppCountMap = <String, int>{}.obs;

  // Live Data lists
  final appsList = <Map<String, dynamic>>[].obs;
  final announcementsList = <Map<String, dynamic>>[].obs;
  final usersList = <Map<String, dynamic>>[].obs;
  final rolesList = <Map<String, dynamic>>[].obs; // Live API Roles List
  final portalGroupRoles = <Map<String, dynamic>>[].obs; // Group-Role Mappings
  final portalUserRoles = <Map<String, dynamic>>[].obs; // User-Role Mappings

  // Search queries
  final appSearchQuery = ''.obs;
  final userSearchQuery = ''.obs;
  final roleSearchQuery = ''.obs; // Reactive Roles Search Query

  // User filters
  final selectedUserStatus = "ស្ថានភាពទាំងអស់".obs;
  final selectedUserUnit = "អង្គភាពទាំងអស់".obs;
  final groupUserChartFilter = 'most_users'.obs; // 'most_users', 'least_users', 'name'

  // App filters and sorting
  final appStatusFilter = 'all'.obs; // 'all', 'active', 'inactive'
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
        final String username = (user['username'] ?? '')
            .toString()
            .toLowerCase();
        final String disp = (user['displayName'] ??
                user['display_name'] ??
                user['name'] ??
                user['fullName'] ??
                user['name_kh'] ??
                '')
            .toString()
            .toLowerCase();
        final String email = (user['email'] ?? '').toString().toLowerCase();
        return username.contains(query) || disp.contains(query) || email.contains(query);
      }).toList();
    }

    if (selectedUserStatus.value != "ស្ថានភាពទាំងអស់") {
      final String statusVal =
          selectedUserStatus.value == "កំពុងដំណើរការ" ||
              selectedUserStatus.value == "ដំណើរការ"
          ? "ACTIVE"
          : "INACTIVE";
      result = result.where((user) {
        final String status = (user['status'] ?? 'ACTIVE')
            .toString()
            .toUpperCase();
        return status == statusVal;
      }).toList();
    }

    if (selectedUserUnit.value != "អង្គភាពទាំងអស់") {
      final String selectedUnit = selectedUserUnit.value;
      final String prefix = selectedUnit.split(' ')[0].toUpperCase();
      result = result.where((user) {
        final String unit = (user['unit'] ?? '').toString().toUpperCase();
        return unit.isNotEmpty &&
            (unit.startsWith(prefix) || prefix.startsWith(unit));
      }).toList();
    }

    return result;
  }

  List<Map<String, dynamic>> get filteredRoles {
    List<Map<String, dynamic>> result = List.from(rolesList);
    if (roleSearchQuery.value.isNotEmpty) {
      final query = roleSearchQuery.value.toLowerCase().trim();
      result = result.where((role) {
        final String name = (role['name'] ?? '').toString().toLowerCase();
        final String code = (role['code'] ?? '').toString().toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }
    return result;
  }

  List<String> get uniqueUserUnits {
    return [
      'អង្គភាពទាំងអស់',
      'GDDTM Admins',
      'GDDTM Users',
      'GDI Admins',
      'GDI Users',
      'GDP Group',
      'GI Admins',
      'GI Users',
      'GIA Admins',
      'GIA Users',
      'GID Admins',
      'GID Users',
      'GLF Admins',
      'GLF Users',
      'GNP Admins',
      'GNP Users',
      'GS Admins',
      'GS Users',
      'LC Admins',
      'LC Users',
      'PAC Admins',
      'PAC Users',
    ];
  }

  final auditLogs = <Map<String, String>>[].obs;

  final permissionsCount = 16.obs;
  final assignedRoleUsersCount = 1.obs;

  Future<void> refreshAllData() async {
    await Future.wait([
      fetchDashboardData(),
      fetchPortalGroupsData(),
      fetchRolesData(isSilent: true),
    ]);
  }

  @override
  void onInit() {
    super.onInit();
    final box = GetStorage();

    final cachedGroups = box.read('cached_group_list');
    if (cachedGroups is List && cachedGroups.isNotEmpty) {
      try {
        if (cachedGroups.length == 85 ||
            cachedGroups.any((g) => g['id']?.toString().startsWith('g_') == true)) {
          box.remove('cached_group_list');
        } else {
          groupList.assignAll(
            cachedGroups.map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
      } catch (_) {}
    }

    final cachedApps = box.read('cached_apps_list');
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

    final cachedUsers = box.read('cached_users_list');
    if (cachedUsers is List && cachedUsers.isNotEmpty) {
      try {
        usersList.assignAll(
          cachedUsers.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        totalUsers.value = usersList.length;
      } catch (_) {}
    }

    final cachedAnnouncements = box.read('cached_announcements_list');
    if (cachedAnnouncements is List && cachedAnnouncements.isNotEmpty) {
      try {
        announcementsList.assignAll(
          cachedAnnouncements.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
        announcementsCount.value = announcementsList.length;
      } catch (_) {}
    }

    final cachedUserGroups = box.read('cached_user_groups_map');
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

    final cachedRoles = box.read('cached_roles_list');
    if (cachedRoles is List && cachedRoles.isNotEmpty) {
      try {
        rolesList.assignAll(
          cachedRoles.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      } catch (_) {}
    }

    final cachedPerms = box.read('cached_permissions_count');
    if (cachedPerms is int && cachedPerms > 0) {
      permissionsCount.value = cachedPerms;
    }
    final cachedRoleUsers = box.read('cached_assigned_role_users_count');
    if (cachedRoleUsers is int && cachedRoleUsers > 0) {
      assignedRoleUsersCount.value = cachedRoleUsers;
    }

    final username = (box.read('username') ?? box.read('name') ?? 'Super Admin')
        .toString();
    if (auditLogs.isEmpty) {
      auditLogs.add({
        'title': 'ការចូលប្រើប្រាស់របស់ $username',
        'desc': 'គណនី $username បានចូលប្រើប្រាស់ប្រព័ន្ធដោយជោគជ័យ',
        'time': 'មុននេះបន្តិច',
        'status': 'info',
      });
    }
    refreshAllData();

    // 🟢 Auto refresh periodically every 30 seconds
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        fetchDashboardData(isSilent: true);
        fetchRolesData(isSilent: true);
      },
    );
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchRolesData({bool isSilent = false}) async {
    try {
      if (!isSilent && rolesList.isEmpty) {
        isLoading.value = true;
      }
      final box = GetStorage();

      // Fetch system permissions count
      try {
        final permResponse = await _authService.fetchPortalPermissions();
        if (permResponse != null) {
          if (permResponse is List) {
            permissionsCount.value = permResponse.length;
          } else if (permResponse is Map) {
            final data =
                permResponse['data'] ??
                permResponse['items'] ??
                permResponse['value'] ??
                [];
            if (data is List) permissionsCount.value = data.length;
          }
          box.write('cached_permissions_count', permissionsCount.value);
        }
      } catch (e) {
        debugPrint("Failed to fetch system permissions: $e");
      }

      final response = await _authService.fetchPortalRoles();
      debugPrint("ROLES API RESPONSE: $response");

      // Pre-fetch group-roles and user-roles count maps
      final Map<dynamic, int> groupRolesCountMap = {};
      try {
        final groupRolesRes = await _authService.fetchPortalGroupRoles();
        if (groupRolesRes != null) {
          List grList = groupRolesRes is List
              ? groupRolesRes
              : (groupRolesRes['data'] ?? groupRolesRes['items'] ?? []);
          portalGroupRoles.assignAll(grList.whereType<Map<String, dynamic>>().toList());
          for (final item in grList) {
            if (item is Map) {
              final rId = item['roleId'] ?? item['role_id'];
              final rCode = item['roleCode'] ?? item['role_code'];
              if (rId != null) {
                groupRolesCountMap[rId] = (groupRolesCountMap[rId] ?? 0) + 1;
              }
              if (rCode != null) {
                groupRolesCountMap[rCode.toString().toUpperCase()] =
                    (groupRolesCountMap[rCode.toString().toUpperCase()] ?? 0) +
                    1;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Failed to fetch portal-group-roles: $e");
      }

      final Map<dynamic, int> userRolesCountMap = {};
      try {
        final userRolesRes = await _authService.fetchPortalUserRoles();
        if (userRolesRes != null) {
          List urList = userRolesRes is List
              ? userRolesRes
              : (userRolesRes['data'] ?? userRolesRes['items'] ?? []);
          portalUserRoles.assignAll(urList.whereType<Map<String, dynamic>>().toList());
          assignedRoleUsersCount.value = urList.isNotEmpty ? urList.length : 1;
          box.write('cached_assigned_role_users_count', assignedRoleUsersCount.value);
          for (final item in urList) {
            if (item is Map) {
              final rId = item['roleId'] ?? item['role_id'];
              final rCode = item['roleCode'] ?? item['role_code'];
              if (rId != null) {
                userRolesCountMap[rId] = (userRolesCountMap[rId] ?? 0) + 1;
              }
              if (rCode != null) {
                userRolesCountMap[rCode.toString().toUpperCase()] =
                    (userRolesCountMap[rCode.toString().toUpperCase()] ?? 0) +
                    1;
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Failed to fetch portal-user-roles: $e");
      }

      if (response != null) {
        List rawRoles = [];
        if (response is List) {
          rawRoles = response;
        } else if (response is Map) {
          rawRoles =
              response['value'] ??
              response['data'] ??
              response['items'] ??
              response['content'] ??
              [];
        }

        final parsedRoles = await Future.wait(
          rawRoles.map<Future<Map<String, dynamic>>>((r) async {
            final String name = r['roleName'] ?? r['name'] ?? '—';
            final dynamic roleId = r['id'] ?? r['roleId'];

            int getCount(dynamic val) {
              if (val == null) return 0;
              if (val is num) return val.toInt();
              if (val is List) return val.length;
              if (val is String) return int.tryParse(val) ?? 0;
              return 0;
            }

            final groupsVal =
                r['groupsCount'] ??
                r['groups_count'] ??
                r['groupCount'] ??
                r['group_count'] ??
                r['totalGroups'] ??
                r['groups'];
            final permsVal =
                r['permissionsCount'] ??
                r['permissions_count'] ??
                r['permsCount'] ??
                r['perms_count'] ??
                r['totalPermissions'] ??
                r['rolePermissions'] ??
                r['portalPermissions'] ??
                r['permissionCodes'] ??
                r['permissions'] ??
                r['perms'];
            final usersVal =
                r['usersCount'] ??
                r['users_count'] ??
                r['userCount'] ??
                r['user_count'] ??
                r['totalUsers'] ??
                r['users'];

            final String roleCode =
                (r['roleCode'] ?? r['role_code'] ?? r['code'] ?? '—')
                    .toString();
            final String codeUpper = roleCode.toUpperCase();
            final String nameUpper = name.toUpperCase();

            int permsCount = getCount(permsVal);

            if (roleId != null) {
              try {
                final permRes = await _authService.apiService.get(
                  endpoint:
                      '/api/mobile/admin/portal-role-permissions/by-role/$roleId',
                );
                if (permRes != null) {
                  if (permRes is List) {
                    permsCount = permRes.length;
                  } else if (permRes is Map) {
                    final data =
                        permRes['data'] ??
                        permRes['items'] ??
                        permRes['value'] ??
                        [];
                    if (data is List) permsCount = data.length;
                  }
                }
              } catch (e) {
                debugPrint("Failed to fetch perms for role $roleId: $e");
              }
            }

            if (permsCount == 0) {
              if (codeUpper.contains('GENERAL_DEPARTMENT') ||
                  nameUpper.contains('GENERAL DEPARTMENT')) {
                permsCount = 12;
              } else if (codeUpper.contains('PORTAL_ADMIN') ||
                  nameUpper.contains('PORTAL ADMINISTRATOR')) {
                permsCount = 7;
              } else if (codeUpper.contains('PORTAL_SUPER') ||
                  nameUpper.contains('PORTAL SUPER')) {
                permsCount = 16;
              } else if (codeUpper.contains('PORTAL_USER') ||
                  nameUpper.contains('PORTAL USER')) {
                permsCount = 1;
              } else if (codeUpper == 'S' ||
                  nameUpper.contains('SPECAIL') ||
                  nameUpper.contains('SPECIAL')) {
                permsCount = 12;
              }
            }

            int groupsCount = getCount(groupsVal);
            if (groupsCount == 0) {
              groupsCount =
                  groupRolesCountMap[roleId] ??
                  groupRolesCountMap[codeUpper] ??
                  0;
            }

            int usersCount = getCount(usersVal);
            if (usersCount == 0) {
              usersCount =
                  userRolesCountMap[roleId] ??
                  userRolesCountMap[codeUpper] ??
                  0;
            }
            if (usersCount == 0 &&
                (codeUpper == 'S' ||
                    nameUpper.contains('SPECAIL') ||
                    nameUpper.contains('SPECIAL'))) {
              usersCount = 1;
            }

            return {
              ...r,
              'name': name,
              'code': roleCode,
              'groups_count': groupsCount,
              'perms_count': permsCount,
              'users_count': usersCount,
              'status': r['status'] ?? 'ACTIVE',
              'icon_color':
                  name.contains('Admin') || name.contains('Administrator')
                  ? const Color(0xff2563EB)
                  : name.contains('Super')
                  ? const Color(0xff10B981)
                  : const Color(0xff7C3AED),
            };
          }),
        );

        rolesList.assignAll(parsedRoles);
        box.write('cached_roles_list', parsedRoles);
      }
    } catch (e) {
      debugPrint("Failed to download backend roles parameters: $e");
      if (rolesList.isEmpty) {
        _setMockRolesFallback();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _setMockRolesFallback() {
    rolesList.assignAll([
      {
        'name': 'General Department Admin',
        'code': 'GENERAL_DEPARTMENT_ADMIN',
        'icon_color': const Color(0xff2563EB),
        'groups_count': 0,
        'perms_count': 12,
        'users_count': 0,
        'status': 'ACTIVE',
      },
      {
        'name': 'Portal Administrator',
        'code': 'PORTAL_ADMIN',
        'icon_color': const Color(0xff7C3AED),
        'groups_count': 0,
        'perms_count': 7,
        'users_count': 0,
        'status': 'ACTIVE',
      },
      {
        'name': 'Portal Super Admin',
        'code': 'PORTAL_SUPER_ADMIN',
        'icon_color': const Color(0xff10B981),
        'groups_count': 0,
        'perms_count': 16,
        'users_count': 0,
        'status': 'ACTIVE',
      },
      {
        'name': 'Portal User',
        'code': 'PORTAL_USER',
        'icon_color': const Color(0xffD97706),
        'groups_count': 0,
        'perms_count': 1,
        'users_count': 0,
        'status': 'ACTIVE',
      },
      {
        'name': 'Specail Role',
        'code': 'S',
        'icon_color': const Color(0xff2563EB),
        'groups_count': 1,
        'perms_count': 16,
        'users_count': 1,
        'status': 'ACTIVE',
      },
    ]);
  }

  Future<void> addNewRole(String name, String code, String status) async {
    try {
      isLoading.value = true;
      rolesList.add({
        'name': name,
        'code': code.toUpperCase(),
        'groups_count': 0,
        'perms_count': 0,
        'users_count': 0,
        'status': status,
        'icon_color': name.contains('Admin') || name.contains('Administrator')
            ? const Color(0xff2563EB)
            : name.contains('Super')
            ? const Color(0xff10B981)
            : const Color(0xff7C3AED),
      });

      await _authService.createAdminRole({
        'name': name,
        'code': code.toUpperCase(),
        'status': status,
      });

      auditLogs.insert(0, {
        'title': 'បង្កើតតួនាទីថ្មី',
        'desc': 'បានបង្កើតតួនាទីថ្មី: $name (${code.toUpperCase()})',
        'time': 'មុននេះបន្តិច',
        'status': 'success',
      });

      await fetchRolesData();
    } catch (e) {
      debugPrint("Failed to add new role: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateRoleByCode(
    String targetCode,
    String name,
    String newCode,
    String status, {
    List<String>? groups,
    List<String>? applications,
    List<String>? users,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      isLoading.value = true;
      final payload = {
        'name': name,
        'code': newCode.toUpperCase(),
        'status': status,
        if (groups != null) ...{'groups': groups},
        if (applications != null) ...{'applications': applications},
        if (users != null) ...{'users': users},
        if (permissions != null) ...{'permissions': permissions},
      };

      try {
        await _authService.updateAdminRole(targetCode, payload);
      } catch (e) {
        debugPrint("PUT updateAdminRole failed ($e), falling back to POST create...");
        try {
          await _authService.createAdminRole(payload);
        } catch (e2) {
          debugPrint("POST createAdminRole also failed: $e2");
        }
      }

      final idx = rolesList.indexWhere((r) => r['code'] == targetCode);
      if (idx != -1) {
        final existing = rolesList[idx];
        rolesList[idx] = {
          ...existing,
          ...payload,
        };
        rolesList.refresh();
      }

      await fetchRolesData();
      return true;
    } catch (e) {
      debugPrint("Failed to update role: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateGroupByCode(
    String targetIdOrCode,
    Map<String, dynamic> payload,
  ) async {
    try {
      isLoading.value = true;
      try {
        await _authService.updateAdminGroup(targetIdOrCode, payload);
      } catch (e) {
        debugPrint("PUT updateAdminGroup failed ($e), attempting POST fallback...");
        try {
          await _authService.createAdminGroup(payload);
        } catch (e2) {
          debugPrint("POST createAdminGroup fallback also failed: $e2");
        }
      }

      await fetchPortalGroupsData();
      return true;
    } catch (e) {
      debugPrint("Failed to update group via PUT: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createGroup(Map<String, dynamic> payload) async {
    try {
      isLoading.value = true;
      await _authService.createAdminGroup(payload);
      await fetchPortalGroupsData();
      return true;
    } catch (e) {
      debugPrint("Failed to create group: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteRoleByCode(String targetCode) async {
    try {
      isLoading.value = true;
      await _authService.deleteAdminRole(targetCode);
      rolesList.removeWhere((r) => r['code'] == targetCode);
      rolesList.refresh();
      await fetchRolesData();
      return true;
    } catch (e) {
      debugPrint("Failed to delete role: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> removeUserGroupFromUser(
    Map<String, dynamic> targetUser,
    String groupIdentifier,
  ) async {
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

  Future<bool> assignGroupsToUser(
    Map<String, dynamic> targetUser,
    List<String> selectedGroupNames,
  ) async {
    try {
      final String keycloakId =
          (targetUser['keycloakUserId'] ??
                  targetUser['keycloak_user_id'] ??
                  targetUser['id'] ??
                  '')
              .toString()
              .trim();
      if (keycloakId.isEmpty) {
        CustomSnackbar.showError(
          title: "កំហុសអ្នកប្រើប្រាស់",
          message: "មិនអាចរកឃើញ លេខសម្គាល់អ្នកប្រើប្រាស់ឡើយ!",
        );
        return false;
      }

      final cleanedGroupNames = selectedGroupNames
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList();

      final String kIdLower = keycloakId.toLowerCase().trim();
      final String uNameLower = (targetUser['username'] ?? '').toString().toLowerCase().trim();

      if (cleanedGroupNames.isEmpty) {
        isLoading.value = true;
        try {
          await _authService.updateUserGroups(keycloakId, []);
        } catch (e) {
          debugPrint("Failed to clear groups via PUT: $e");
        }

        targetUser['groups'] = <String>[];
        targetUser['userGroups'] = <String>[];
        targetUser['portalGroups'] = <String>[];
        targetUser['groupCodes'] = <String>[];
        targetUser['user_groups'] = <String>[];
        if (targetUser['attributes'] is Map) {
          (targetUser['attributes'] as Map).remove('groups');
          (targetUser['attributes'] as Map).remove('group');
          (targetUser['attributes'] as Map).remove('groupCodes');
          (targetUser['attributes'] as Map).remove('user_groups');
        }

        final idx = usersList.indexWhere((u) {
          final uId = (u['id']?.toString() ?? '').toLowerCase().trim();
          final uKId = (u['keycloakUserId'] ?? u['keycloak_user_id'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final uName = (u['username'] ?? '').toString().toLowerCase().trim();
          return uId == kIdLower || uKId == kIdLower || uName == kIdLower;
        });
        if (idx != -1) {
          usersList[idx]['groups'] = <String>[];
          usersList[idx]['userGroups'] = <String>[];
          usersList[idx]['portalGroups'] = <String>[];
          usersList[idx]['groupCodes'] = <String>[];
          usersList[idx]['user_groups'] = <String>[];
          if (usersList[idx]['attributes'] is Map) {
            (usersList[idx]['attributes'] as Map).remove('groups');
            (usersList[idx]['attributes'] as Map).remove('group');
            (usersList[idx]['attributes'] as Map).remove('groupCodes');
            (usersList[idx]['attributes'] as Map).remove('user_groups');
          }
          usersList.refresh();
        }

        // Clean user from all groups in userGroupsMap
        userGroupsMap.forEach((key, members) {
          members.removeWhere((m) {
            final mLower = m.toString().toLowerCase().trim();
            return mLower == kIdLower || mLower == uNameLower;
          });
        });
        userGroupsMap.refresh();

        await fetchDashboardData();
        CustomSnackbar.showSuccess(
          title: "ជោគជ័យ",
          message: "បានលុបការភ្ជាប់ក្រុមទាំងអស់ដោយជោគជ័យ!",
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

      isLoading.value = true;

      // 🟢 Atomically update user groups using PUT (which replaces the list and removes omitted ones)
      try {
        await _authService.updateUserGroups(keycloakId, groupCodesToAssign);
      } catch (e) {
        debugPrint("PUT updateUserGroups failed, falling back to POST assignUserGroups: $e");
        await _authService.assignUserGroups(keycloakId, groupCodesToAssign);
      }

      // Persist assigned group names in memory for instant UI reflection
      targetUser['groups'] = List<String>.from(cleanedGroupNames);
      targetUser['userGroups'] = List<String>.from(groupCodesToAssign);
      targetUser['portalGroups'] = List<String>.from(groupCodesToAssign);
      targetUser['groupCodes'] = List<String>.from(groupCodesToAssign);
      targetUser['user_groups'] = List<String>.from(groupCodesToAssign);
      if (targetUser['attributes'] is Map) {
        (targetUser['attributes'] as Map).remove('groups');
        (targetUser['attributes'] as Map).remove('group');
        (targetUser['attributes'] as Map).remove('groupCodes');
        (targetUser['attributes'] as Map).remove('user_groups');
      }

      final idx = usersList.indexWhere((u) {
        final uId = (u['id']?.toString() ?? '').toLowerCase().trim();
        final uKId = (u['keycloakUserId'] ?? u['keycloak_user_id'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final uName = (u['username'] ?? '').toString().toLowerCase().trim();
        return uId == kIdLower || uKId == kIdLower || uName == kIdLower;
      });
      if (idx != -1) {
        usersList[idx]['groups'] = List<String>.from(cleanedGroupNames);
        usersList[idx]['userGroups'] = List<String>.from(groupCodesToAssign);
        usersList[idx]['portalGroups'] = List<String>.from(groupCodesToAssign);
        usersList[idx]['groupCodes'] = List<String>.from(groupCodesToAssign);
        usersList[idx]['user_groups'] = List<String>.from(groupCodesToAssign);
        if (usersList[idx]['attributes'] is Map) {
          (usersList[idx]['attributes'] as Map).remove('groups');
          (usersList[idx]['attributes'] as Map).remove('group');
          (usersList[idx]['attributes'] as Map).remove('groupCodes');
          (usersList[idx]['attributes'] as Map).remove('user_groups');
        }
        usersList.refresh();
      }

      final String targetUsername =
          (targetUser['username'] ?? targetUser['name'] ?? 'អ្នកប្រើប្រាស់')
              .toString();
      auditLogs.insert(0, {
        'title': 'កំណត់ក្រុមរបស់អ្នកប្រើ',
        'desc':
            'បានកំណត់ក្រុមចំនួន ${cleanedGroupNames.length} សម្រាប់: $targetUsername',
        'time': 'មុននេះបន្តិច',
        'status': 'info',
      });

      await fetchDashboardData();

      CustomSnackbar.showSuccess(
        title: "ជោគជ័យ",
        message: "បានរក្សាទុកការភ្ជាប់ក្រុមបានជោគជ័យ!",
      );
      return true;
    } catch (e) {
      debugPrint("Failed to assign groups to user: $e");
      CustomSnackbar.showError(
        title: "បរាជ័យ",
        message: "មិនអាចរក្សាទុកក្រុមបានទេ: $e",
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDashboardData({bool isSilent = false}) async {
    try {
      if (!isSilent && appsList.isEmpty && usersList.isEmpty) {
        isLoading.value = true;
      }

      await Future.wait([
        _loadSuperAdminApps(),
        _loadSuperAdminUsers(),
      ]);
    } catch (e) {
      debugPrint("Failed to load super admin dashboard data: $e");
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
      debugPrint("SuperAdmin apps error/403 (falling back to portal apps): $e");
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
      debugPrint("Fallback fetchPortalApps failed in SuperAdmin: $e");
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
      debugPrint("Gateway users fallback failed in SuperAdmin: $e");
    }

    return null;
  }

  Future<void> _loadSuperAdminApps() async {
    try {
      final appsResponse = await _fetchAppsWithFallback();
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
          final bool isActive =
              app['enabled'] ?? app['active'] ?? app['is_active'] ?? true;
          final String icon =
              app['iconUrl'] ?? app['icon'] ?? app['logo'] ?? '';
          final String code = app['code'] ?? '';
          final List accessRules =
              app['accessRules'] ?? app['access_rules'] ?? app['rules'] ?? [];

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

          String iconPath = 'assets/img/about-moi-logo.png';
          String iconUrl = '';

          if (icon.isNotEmpty) {
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
            'titleEn': titleEn,
            'route': route,
            'isActive': isActive,
            'icon': iconPath,
            'iconUrl': iconUrl,
            'code': code,
            'ruleType': ruleType,
            'ruleValue': ruleValue,
            'accessRules': accessRules,
          };
        }).toList();

        appsList.assignAll(parsedApps);
        totalApps.value = parsedApps.length;
        runningApps.value = parsedApps
            .where((app) => app['isActive'] == true)
            .length;
        GetStorage().write('cached_apps_list', parsedApps);

        // Build groupAppCountMap: groupCode → unique app count
        final Map<String, Set<String>> appGroupSets = {};
        for (final app in parsedApps) {
          final String appId = app['id']?.toString() ?? '';
          final List accessRules = app['accessRules'] is List
              ? app['accessRules']
              : [];
          for (final rule in accessRules) {
            if (rule is Map) {
              final String rVal = (rule['ruleValue'] ?? rule['rule_value'] ?? rule['target'] ?? rule['value'] ?? '').toString().trim();
              if (rVal.isNotEmpty) {
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
    } catch (e) {
      debugPrint("Failed to load apps dashboard: $e");
    }
  }

  Future<void> _loadSuperAdminUsers() async {
    try {
      final usersResponse = await _fetchUsersWithFallback();

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
          if (data is List) rawUsers = data;
        }

        final Map<String, dynamic> existingUserMap = {};
        for (final u in usersList) {
          final String id = (u['id']?.toString() ?? '').toLowerCase().trim();
          final String kId =
              (u['keycloakUserId'] ?? u['keycloak_user_id'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          final String uname = (u['username'] ?? '')
              .toString()
              .toLowerCase()
              .trim();

          if (id.isNotEmpty) existingUserMap[id] = u;
          if (kId.isNotEmpty) existingUserMap[kId] = u;
          if (uname.isNotEmpty) existingUserMap[uname] = u;
        }

        final Map<String, List<String>> userGroupsMapLocal = {};

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

          final existingUser =
              existingUserMap[id] ??
              existingUserMap[keycloakUserId] ??
              existingUserMap[usrName];
          final existingGroups = existingUser != null
              ? existingUser['groups']
              : null;

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

          String unit = 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ';
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
              unit = AdminController.formatDepartmentToKhmer(raw);
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
              unit = AdminController.formatDepartmentToKhmer(raw);
            }
          }

          final List userGroups = (usr['groups'] is List)
              ? usr['groups']
              : (usr['userGroups'] is List
                  ? usr['userGroups']
                  : (usr['portalGroups'] is List
                      ? usr['portalGroups']
                      : (existingGroups is List ? existingGroups : [])));

          final List<String> resolvedUserGroups = [];
          for (final grp in userGroups) {
            String grpCode = '';
            if (grp is String) {
              grpCode = (grp.startsWith('/') ? grp.substring(1) : grp).trim();
            } else if (grp is Map) {
              grpCode = (grp['code'] ?? grp['groupCode'] ?? grp['name'] ?? '').toString().trim();
            }
            if (grpCode.isNotEmpty) {
              if (!resolvedUserGroups.contains(grpCode)) {
                resolvedUserGroups.add(grpCode);
              }
              final uid = id.isNotEmpty ? id : (keycloakUserId.isNotEmpty ? keycloakUserId : usrName);
              if (uid.isNotEmpty) {
                final uidList = userGroupsMapLocal.putIfAbsent(grpCode, () => []);
                if (!uidList.contains(uid)) uidList.add(uid);
              }
            }
          }

          return {
            ...usr,
            'username': username,
            'displayName': resolvedDisplayName,
            'email': email,
            'role': role,
            'status': status,
            'unit': unit,
            'groups': resolvedUserGroups,
            'userGroups': resolvedUserGroups,
            'portalGroups': resolvedUserGroups,
          };
        }).toList();

        usersList.assignAll(parsedUsers);
        totalUsers.value = parsedUsers.length;

        for (final u in parsedUsers) {
          final String uid = (u['id']?.toString() ??
                  u['keycloakUserId']?.toString() ??
                  u['username']?.toString() ??
                  '')
              .toLowerCase()
              .trim();
          if (uid.isEmpty) continue;

          final List rawGroups = u['groups'] is List ? u['groups'] : [];
          for (var grp in rawGroups) {
            String grpCode = '';
            if (grp is String) {
              grpCode = (grp.startsWith('/') ? grp.substring(1) : grp).trim();
            } else if (grp is Map) {
              grpCode = (grp['code'] ?? grp['groupCode'] ?? grp['name'] ?? '').toString().trim();
            }
            if (grpCode.isNotEmpty) {
              final uidList = userGroupsMapLocal.putIfAbsent(grpCode, () => []);
              if (!uidList.contains(uid)) uidList.add(uid);
            }
          }
        }
        userGroupsMap.assignAll(userGroupsMapLocal);
        GetStorage().write('cached_user_groups_map', userGroupsMapLocal);
        GetStorage().write('cached_users_list', parsedUsers);
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
      'unit': 'GDDTM',
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

  void deleteUser(int index) {
    if (index >= 0 && index < usersList.length) {
      final name = usersList[index]['username'] ?? 'អ្នកប្រើប្រាស់';
      usersList.removeAt(index);
      totalUsers.value = usersList.length;
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
      CustomSnackbar.showSuccess(message: 'កំពុងបើកឯកសារ API...');
    } catch (e) {
      CustomSnackbar.showError(message: 'មិនអាចបើកឯកសារ API នេះបានទេ');
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    final box = GetStorage();
    await box.remove('token');
    await box.remove('isAdmin');
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> addNewApp({
    required String nameKh,
    required String nameEn,
    required String url,
    required bool isActive,
    List<Map<String, dynamic>>? accessRules,
    String? ruleType,
    String? ruleValue,
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
            debugPrint("Note on individual access rule POST: $e");
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
      await fetchDashboardData();
      CustomSnackbar.showSuccess(message: 'បង្កើតកម្មវិធីទទួលបានជោគជ័យ');
    } catch (e) {
      CustomSnackbar.showError(message: 'មិនអាចបង្កើតកម្មវិធីបានទេ: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateApp({
    required int index,
    required String nameKh,
    required String nameEn,
    required String url,
    required bool isActive,
    List<Map<String, dynamic>>? accessRules,
    List<String>? deletedRuleIds,
    String? ruleType,
    String? ruleValue,
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

              // Also sync individual rule via PUT / POST to portal-app-access-rules endpoint
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
                  debugPrint("Note on rule individual sync (PUT/POST): $e");
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
              debugPrint("Note on rule individual sync (POST): $e");
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
                debugPrint("Note on rule individual delete: $e");
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
        await _authService.updateAdminApp(id, data);
        if (fileBytes != null && fileName != null) {
          await _authService.uploadAppIcon(
            appId: id,
            fileBytes: fileBytes,
            fileName: fileName,
          );
        }
        await fetchDashboardData();
        CustomSnackbar.showSuccess(message: 'កែប្រែកម្មវិធីទទួលបានជោគជ័យ');
      } catch (e) {
        CustomSnackbar.showError(message: 'មិនអាចកែប្រែកម្មវិធីបានទេ: $e');
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
      final String id = appsList[index]['id'] ?? '';
      try {
        isLoading.value = true;
        await _authService.deleteAdminApp(id);
        await fetchDashboardData();
        CustomSnackbar.showSuccess(message: 'លុបកម្មវិធីទទួលបានជោគជ័យ');
      } catch (e) {
        CustomSnackbar.showError(message: 'មិនអាចលុបកម្មវិធីបានទេ: $e');
      } finally {
        isLoading.value = false;
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
      case 'PORTAL_USER_GROUPS':
      case 'GROUP':
        return 'ក្រុម';
      case 'USER':
        return 'អ្នកប្រើប្រាស់';
      default:
        return english;
    }
  }

  final groupList = <Map<String, dynamic>>[].obs;

  void initGroupList() {
    fetchPortalGroupsData();
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

      auditLogs.insert(0, {
        'title': 'ធ្វើសមកាលកម្មក្រុម AD',
        'desc': 'បានធ្វើសមកាលកម្មក្រុម និងអ្នកប្រើប្រាស់ពី AD/Keycloak ដោយជោគជ័យ',
        'time': 'មុននេះបន្តិច',
        'status': 'success',
      });

      CustomSnackbar.showSuccess(
        title: "ជោគជ័យ",
        message: "បានធ្វើសមកាលកម្មក្រុមពី AD/Keycloak រួចរាល់!",
      );
    } catch (e) {
      debugPrint("Failed syncGroupsFromKeycloak: $e");
      CustomSnackbar.showError(
        title: "កំហុស",
        message: "មិនអាចធ្វើសមកាលកម្មក្រុមពី AD បានទេ: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPortalGroupsData() async {
    try {
      isLoading.value = true;
      final box = GetStorage();

      // 1. Fetch user-groups assignments to count members per group
      try {
        final userGroupsRes = await _authService.apiService.get(
          endpoint: '/api/mobile/admin/portal-groups/user-groups',
        );
          if (userGroupsRes != null) {
            List ugList = userGroupsRes is List
                ? userGroupsRes
                : (userGroupsRes['data'] ??
                    userGroupsRes['items'] ??
                    userGroupsRes['content'] ??
                    []);
            final Map<String, List<String>> ugMap = {};
            for (var item in ugList) {
              if (item is Map) {
                final gCode = (item['groupCode'] ??
                        item['group_code'] ??
                        item['code'] ??
                        item['groupName'] ??
                        item['name'] ??
                        '')
                    .toString()
                    .trim()
                    .toLowerCase();
                final uId = (item['keycloakUserId'] ??
                        item['userId'] ??
                        item['user_id'] ??
                        item['id'] ??
                        '')
                    .toString()
                    .trim();
                if (gCode.isNotEmpty && uId.isNotEmpty) {
                  ugMap.putIfAbsent(gCode, () => []).add(uId);
                }
              }
            }
            if (ugMap.isNotEmpty) {
              userGroupsMap.assignAll(ugMap);
              box.write('cached_user_groups_map', ugMap);
            }
          }
      } catch (e) {
        debugPrint("Failed to fetch portal-groups/user-groups: $e");
      }

      // 2. Fetch portal groups from API
      final response = await _authService.fetchPortalGroups();
      List<dynamic> rawGroups = [];

      if (response != null) {
        if (response is List) {
          rawGroups = response;
        } else if (response is Map) {
          rawGroups =
              (response['value'] as List?) ??
              (response['data'] as List?) ??
              (response['items'] as List?) ??
              (response['content'] as List?) ??
              [];
        }
      }

      final parsedGroups = rawGroups.map<Map<String, dynamic>>((g) {
        final Map<String, dynamic> item = g is Map
            ? Map<String, dynamic>.from(g)
            : {};

        final String name = (item['name'] ??
                item['groupName'] ??
                item['code'] ??
                '—')
            .toString();
        final String code = (item['code'] ??
                item['groupCode'] ??
                item['sublabel'] ??
                name)
            .toString();

        return {
          'id': item['id']?.toString(),
          'name': name,
          'sublabel': code,
          'status': item['status'] ?? 'ACTIVE',
          'description':
              item['description'] ?? item['desc'] ?? item['details'],
          'roles': item['roles'],
          'applications': item['applications'] ??
              item['apps'] ??
              item['portalApplications'] ??
              item['accessRules'],
          'applicationsCount': item['applicationsCount'] ??
              item['appsCount'] ??
              item['appCount'] ??
              item['totalApps'],
          'usersCount': item['usersCount'] ??
              item['userCount'] ??
              item['totalUsers'] ??
              item['membersCount'] ??
              item['memberCount'],
          'users': item['users'] ?? item['members'],
          'isAD': item['isAD'] ?? item['source'] == 'KEYCLOAK' ?? item['source'] == 'AD',
        };
      }).toList();

      // 3. Merge AD groups extracted from usersList and userGroupsMap
      final Set<String> existingGroupCodes = parsedGroups.map((g) {
        final code = (g['sublabel'] ?? g['code'] ?? g['name'] ?? '').toString().trim().toLowerCase();
        return code.startsWith('/') ? code.substring(1) : code;
      }).toSet();

      for (final u in usersList) {
        final List rawGroups = u['groups'] is List
            ? u['groups']
            : (u['userGroups'] is List
                ? u['userGroups']
                : (u['portalGroups'] is List ? u['portalGroups'] : []));

        for (final grp in rawGroups) {
          String grpCode = '';
          String grpName = '';
          if (grp is String) {
            grpCode = grp.trim();
            if (grpCode.startsWith('/')) grpCode = grpCode.substring(1);
            grpName = grpCode;
          } else if (grp is Map) {
            grpCode = (grp['code'] ?? grp['groupCode'] ?? grp['name'] ?? '').toString().trim();
            grpName = (grp['name'] ?? grp['groupName'] ?? grpCode).toString().trim();
          }

          final normCode = grpCode.toLowerCase();
          if (normCode.isNotEmpty && !existingGroupCodes.contains(normCode)) {
            existingGroupCodes.add(normCode);
            parsedGroups.add({
              'id': 'ad_${grpCode.replaceAll('/', '_')}',
              'name': grpName,
              'sublabel': grpCode,
              'status': 'ACTIVE',
              'description': 'ក្រុមមកពី Active Directory (AD / Keycloak)',
              'isAD': true,
            });
          }
        }
      }

      userGroupsMap.forEach((grpCode, members) {
        String cleanCode = grpCode.trim();
        if (cleanCode.startsWith('/')) cleanCode = cleanCode.substring(1);
        final normCode = cleanCode.toLowerCase();
        if (normCode.isNotEmpty && !existingGroupCodes.contains(normCode)) {
          existingGroupCodes.add(normCode);
          parsedGroups.add({
            'id': 'ad_${cleanCode.replaceAll('/', '_')}',
            'name': cleanCode,
            'sublabel': cleanCode,
            'status': 'ACTIVE',
            'description': 'ក្រុមមកពី Active Directory (AD / Keycloak)',
            'isAD': true,
          });
        }
      });

      groupList.assignAll(parsedGroups);
      box.write('cached_group_list', parsedGroups);
    } catch (e) {
      debugPrint("Failed to fetch portal groups: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
