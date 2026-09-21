import 'dart:async';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/core/api/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  final ApiService apiService = ApiService();

  // ─── Auth Synchronization & Session Restoration ───────────────────────────
  static Completer<void>? _authCompleter;

  /// Starts or resets the auth synchronization lock during login or session restoration.
  static void startAuthProcess() {
    if (_authCompleter == null || _authCompleter!.isCompleted) {
      _authCompleter = Completer<void>();
    }
  }

  /// Completes the auth synchronization lock so waiting callers can proceed.
  static void completeAuthProcess() {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete();
    }
  }

  /// Waits until the active login or session restoration process completes.
  static Future<void> waitForAuth() async {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      await _authCompleter!.future;
    }
  }

  /// Restores session by validating saved tokens from storage.
  /// Returns true if a valid, unexpired token exists; otherwise false.
  static Future<bool> restoreSession() async {
    startAuthProcess();
    try {
      final token = await ApiClient.getAccessToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      if (ApiConfig.isTokenExpired(token)) {
        debugPrint("Session restoration: Stored token has expired.");
        await ApiClient.logout();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Session restoration error: $e");
      return false;
    } finally {
      completeAuthProcess();
    }
  }

  // ─── Keycloak & Token Management (Shared ApiClient & FlutterSecureStorage) ─

  /// 1. Shared login using ApiClient.dio and saving tokens to flutter_secure_storage
  Future<void> login(String username, String password) async {
    final response = await ApiClient.dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final accessToken =
        data['access_token']?.toString() ??
        data['token']?.toString() ??
        data['data']?['access_token']?.toString() ??
        data['data']?['token']?.toString();
    final refreshToken =
        data['refresh_token']?.toString() ??
        data['data']?['refresh_token']?.toString();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Login response did not contain an access token');
    }

    String? cpSession;
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      for (final c in setCookie) {
        if (c.contains('CP_SESSION=')) {
          cpSession = c.split('CP_SESSION=')[1].split(';')[0];
        }
      }
    }

    await ApiClient.saveToken(
      accessToken,
      refreshToken: refreshToken,
      cpSession: cpSession,
    );
  }

  /// 2. Protected profile endpoint using ApiClient (/portals/me with fallback to /accounts/profile)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      // 1. Try /portals/me first (returns aggregated Portal session with "user": {...}, roles, perms, khmer names)
      final response = await ApiClient.dio.get('/portals/me');
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint(
        "Warning: /portals/me failed, falling back to /accounts/profile: $e",
      );
    }

    // 2. Fallback to /accounts/profile if /portals/me is unavailable
    final response = await ApiClient.dio.get('/accounts/profile');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 3. Protected tiles endpoint using ApiClient
  Future<List<dynamic>> getTiles() async {
    final response = await ApiClient.dio.get('/portals/tiles');
    return response.data as List<dynamic>;
  }

  /// 4. Protected announcements endpoint using ApiClient
  Future<List<dynamic>> getAnnouncements() async {
    final response = await ApiClient.dio.get('/portals/announcements');
    return response.data as List<dynamic>;
  }

  /// Compatibility login service returning full payload Map
  Future<Map<String, dynamic>> loginService({
    required String username,
    required String password,
    String redirectUri = 'myapp://callback',
  }) async {
    final response = await ApiClient.dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final accessToken =
        data['access_token']?.toString() ??
        data['token']?.toString() ??
        data['data']?['access_token']?.toString() ??
        data['data']?['token']?.toString();
    final refreshToken =
        data['refresh_token']?.toString() ??
        data['data']?['refresh_token']?.toString();

    String? cpSession;
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      for (final c in setCookie) {
        if (c.contains('CP_SESSION=')) {
          cpSession = c.split('CP_SESSION=')[1].split(';')[0];
        }
      }
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      await ApiClient.saveToken(
        accessToken,
        refreshToken: refreshToken,
        cpSession: cpSession,
      );
    }

    return data;
  }

  Future<dynamic> fetchProfile() async {
    try {
      return await getProfile();
    } on DioException catch (e) {
      debugPrint("PROFILE STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  /// For Flutter JWT flow: immediately logging out clears locally stored tokens
  Future<void> logout() async {
    await ApiClient.logout();
  }

  /// Compatibility method for existing controllers
  Future<dynamic> logoutService() async {
    await logout();
    return {'success': true};
  }

  Future<dynamic> fetchApps() async {
    try {
      return await getTiles();
    } on DioException catch (e) {
      debugPrint("APPS STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> fetchPortalApps() async {
    try {
      final response = await ApiClient.dio.get('/portals/apps');
      return response.data;
    } on DioException catch (e) {
      debugPrint("PORTAL APPS STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> fetchAdminApps() async {
    try {
      final response = await ApiClient.dio.get('/admin/portal-apps');
      return response.data;
    } on DioException catch (e) {
      debugPrint("ADMIN APPS STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> changePasswordService({
    String? username,
    required String oldPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    String resolvedUsername = username?.trim() ?? '';
    if (resolvedUsername.isEmpty) {
      try {
        final box = GetStorage();
        resolvedUsername = (box.read('username') ?? '').toString().trim();
      } catch (_) {}
    }
    if (resolvedUsername.isEmpty) {
      try {
        final token = await ApiClient.getAccessToken();
        resolvedUsername =
            ApiClient.extractUsernameFromToken(token)?.trim() ?? '';
      } catch (_) {}
    }

    try {
      final Map<String, dynamic> data = {
        'current_password': oldPassword,
        'new_password': newPassword,
        if (confirmPassword != null && confirmPassword.isNotEmpty)
          'confirm_password': confirmPassword,
        if (resolvedUsername.isNotEmpty) 'username': resolvedUsername,
        'currentPassword': oldPassword,
        'newPassword': newPassword,
        if (confirmPassword != null && confirmPassword.isNotEmpty)
          'confirmPassword': confirmPassword,
      };

      debugPrint(
        "CHANGE PASSWORD PAYLOAD: username=$resolvedUsername, current_password length=${oldPassword.length}, new_password length=${newPassword.length}",
      );

      final response = await ApiClient.dio.put(
        '/accounts/change-password',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("CHANGE PASSWORD STATUS: ${e.response?.statusCode} - DATA: ${e.response?.data}");
      rethrow;
    }
  }

  Future<dynamic> fetchAnnouncements() async {
    try {
      return await getAnnouncements();
    } on DioException catch (e) {
      debugPrint("ANNOUNCEMENTS STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> fetchAdminAnnouncements() async {
    try {
      final response = await ApiClient.dio.get('/admin/announcements');
      return response.data;
    } on DioException catch (e) {
      debugPrint("ADMIN ANN STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> fetchPortalAnnouncements() async {
    try {
      final response = await ApiClient.dio.get('/portals/announcements');
      return response.data;
    } on DioException catch (e) {
      debugPrint("PORTAL ANN STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> createAdminAnnouncement(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.post(
        '/admin/announcements',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("CREATE ANN STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> updateAdminAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiClient.dio.put(
        '/admin/announcements/$id',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("UPDATE ANN STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> deleteAdminAnnouncement(String id) async {
    try {
      final response = await ApiClient.dio.delete('/admin/announcements/$id');
      return response.data;
    } on DioException catch (e) {
      debugPrint("DELETE ANN STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  // ─── Portal Apps CRUD ─────────────────────────────────────────────────────

  Future<dynamic> createAdminApp(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.post(
        '/admin/portal-apps',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("CREATE APP STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> updateAdminApp(String id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.put(
        '/admin/portal-apps/$id',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("UPDATE APP STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> deleteAdminApp(String id) async {
    try {
      final response = await ApiClient.dio.delete('/admin/portal-apps/$id');
      return response.data;
    } on DioException catch (e) {
      debugPrint("DELETE APP STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> uploadAppIcon({
    required String appId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await ApiClient.dio.post(
        '/admin/portal-apps/$appId/icon',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("UPLOAD ICON STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  // ─── Portal Roles & Permissions ───────────────────────────────────────────

  Future<dynamic> fetchPortalRoles() async {
    try {
      try {
        final r = await ApiClient.dio.get('/v1/admin/portal-roles');
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get('/admin/portal-roles');
        return r.data;
      }
    } catch (e) {
      debugPrint("FETCH PORTAL ROLES ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> fetchPortalPermissions() async {
    try {
      try {
        final r = await ApiClient.dio.get('/v1/admin/portal-permissions');
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get('/admin/portal-permissions');
        return r.data;
      }
    } catch (e) {
      debugPrint("FETCH PORTAL PERMISSIONS ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> fetchPortalGroupRoles() async {
    try {
      try {
        final r = await ApiClient.dio.get('/v1/admin/portal-group-roles');
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get('/admin/portal-group-roles');
        return r.data;
      }
    } catch (e) {
      debugPrint("FETCH PORTAL GROUP ROLES ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> fetchPortalUserRoles() async {
    try {
      try {
        final r = await ApiClient.dio.get('/v1/admin/portal-user-roles');
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get('/admin/portal-user-roles');
        return r.data;
      }
    } catch (e) {
      debugPrint("FETCH PORTAL USER ROLES ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> createAdminRole(Map<String, dynamic> data) async {
    try {
      try {
        final r = await ApiClient.dio.post(
          '/v1/admin/portal-roles',
          data: data,
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.post('/admin/portal-roles', data: data);
        return r.data;
      }
    } on DioException catch (e) {
      debugPrint("CREATE ROLE STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> updateAdminRole(String id, Map<String, dynamic> data) async {
    try {
      try {
        final r = await ApiClient.dio.put(
          '/v1/admin/portal-roles/$id',
          data: data,
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.put(
          '/admin/portal-roles/$id',
          data: data,
        );
        return r.data;
      }
    } on DioException catch (e) {
      debugPrint("UPDATE ROLE STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> deleteAdminRole(String id) async {
    try {
      try {
        final r = await ApiClient.dio.delete('/v1/admin/portal-roles/$id');
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.delete('/admin/portal-roles/$id');
        return r.data;
      }
    } on DioException catch (e) {
      debugPrint("DELETE ROLE STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  // ─── Groups & User Groups ─────────────────────────────────────────────────

  Future<dynamic> fetchPortalGroups() async {
    try {
      final r = await ApiClient.dio.get('/admin/portal-groups');
      return r.data;
    } on DioException catch (e) {
      debugPrint("FETCH PORTAL GROUPS STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> fetchPortalGroupsCreatedByMe() async {
    try {
      final r = await ApiClient.dio.get('/admin/portal-groups/created-by-me');
      return r.data;
    } on DioException catch (e) {
      debugPrint(
        "FETCH PORTAL GROUPS CREATED BY ME STATUS: ${e.response?.statusCode}",
      );
      rethrow;
    }
  }

  Future<dynamic> createAdminGroup(Map<String, dynamic> data) async {
    try {
      final cleanName =
          (data['name'] ?? data['groupName'] ?? data['code'] ?? '')
              .toString()
              .trim();
      final desc = (data['description'] ?? data['desc'] ?? '')
          .toString()
          .trim();
      final payload = <String, dynamic>{
        'name': cleanName,
        if (desc.isNotEmpty) 'description': desc,
      };
      final r = await ApiClient.dio.post('/admin/portal-groups', data: payload);
      return r.data;
    } on DioException catch (e) {
      debugPrint("CREATE GROUP STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> updateAdminGroup(String id, Map<String, dynamic> data) async {
    try {
      final r = await ApiClient.dio.put('/admin/portal-groups/$id', data: data);
      return r.data;
    } on DioException catch (e) {
      debugPrint("UPDATE GROUP STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> deleteAdminGroup(String id) async {
    try {
      final r = await ApiClient.dio.delete('/admin/portal-groups/$id');
      return r.data;
    } on DioException catch (e) {
      debugPrint("DELETE GROUP STATUS: ${e.response?.statusCode}");
      rethrow;
    }
  }

  Future<dynamic> assignUserGroups(
    String keycloakUserId,
    dynamic groupCodes,
  ) async {
    try {
      List<String> codesList = [];
      if (groupCodes is List) {
        codesList = groupCodes
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (groupCodes is String && groupCodes.trim().isNotEmpty) {
        codesList = [groupCodes.trim()];
      }

      if (codesList.isEmpty) {
        return {"message": "No groups to assign"};
      }

      dynamic lastResult;
      for (final code in codesList) {
        final body = {
          'keycloakUserId': keycloakUserId,
          'groupCode': code,
        };
        try {
          final r = await ApiClient.dio.post(
            '/admin/portal-groups/user-groups',
            data: body,
          );
          lastResult = r.data;
        } on DioException catch (dioErr) {
          if (dioErr.response?.statusCode != 409) rethrow;
        }
      }
      return lastResult ?? {"message": "Groups processed"};
    } on DioException catch (e) {
      debugPrint("ASSIGN GROUPS STATUS: ${e.response?.statusCode}");
      if (e.response?.statusCode == 409) {
        return e.response?.data ??
            {"message": "Portal user group already exists"};
      }
      rethrow;
    }
  }

  Future<dynamic> updateUserGroups(
    String keycloakUserId,
    List<String> groupCodes,
  ) async {
    return await assignUserGroups(keycloakUserId, groupCodes);
  }

  Future<dynamic> removeUserGroup(
    String keycloakUserId,
    String groupCode, {
    String? assignmentId,
  }) async {
    // 1. If assignmentId is provided, delete directly via /admin/portal-groups/user-groups/{assignment_id}
    if (assignmentId != null && assignmentId.isNotEmpty) {
      try {
        final r = await ApiClient.dio.delete(
          '/admin/portal-groups/user-groups/$assignmentId',
        );
        return r.data;
      } on DioException catch (e) {
        debugPrint("REMOVE USER GROUP BY ID STATUS: ${e.response?.statusCode}");
      } catch (_) {}
    }

    // 2. Fetch assignments to find assignmentId for this keycloakUserId and groupCode
    try {
      final assignments = await fetchUserGroups(keycloakUserId);
      List items = [];
      if (assignments is List) {
        items = assignments;
      } else if (assignments is Map) {
        items = assignments['data'] ??
            assignments['items'] ??
            assignments['value'] ??
            [];
      }
      Map? match;
      for (final item in items) {
        if (item is Map) {
          final u = (item['keycloakUserId'] ?? item['userId'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final g = (item['groupCode'] ?? item['code'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          if (u == keycloakUserId.toLowerCase().trim() &&
              g == groupCode.toLowerCase().trim()) {
            match = item;
            break;
          }
        }
      }
      if (match != null) {
        final String foundId = (match['id'] ??
                match['assignmentId'] ??
                match['assignment_id'] ??
                '')
            .toString();
        if (foundId.isNotEmpty) {
          final r = await ApiClient.dio.delete(
            '/admin/portal-groups/user-groups/$foundId',
          );
          return r.data;
        }
      }
    } catch (e) {
      debugPrint("Could not find assignmentId to delete: $e");
    }

    // 3. Fallback: try query parameters
    try {
      final r = await ApiClient.dio.delete(
        '/admin/portal-groups/user-groups',
        queryParameters: {
          'keycloakUserId': keycloakUserId,
          'groupCode': groupCode,
        },
      );
      return r.data;
    } on DioException catch (e) {
      debugPrint("REMOVE USER GROUP STATUS: ${e.response?.statusCode}");
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> fetchUserGroups(String keycloakUserId) async {
    // 1. Try with query parameter
    try {
      final r = await ApiClient.dio.get(
        '/admin/portal-groups/user-groups',
        queryParameters: {'keycloakUserId': keycloakUserId},
      );
      if (r.data != null) return r.data;
    } on DioException catch (e) {
      debugPrint("FETCH USER GROUPS WITH QUERY STATUS: ${e.response?.statusCode}");
    } catch (_) {}

    // 2. Fallback to GET without query parameters
    try {
      final r = await ApiClient.dio.get('/admin/portal-groups/user-groups');
      return r.data;
    } on DioException catch (e) {
      debugPrint("FETCH USER GROUPS STATUS: ${e.response?.statusCode}");
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> syncGroupsFromKeycloak() async {
    try {
      final r = await ApiClient.dio.post(
        '/admin/portal-groups/sync-from-keycloak',
      );
      return r.data;
    } on DioException catch (e) {
      debugPrint("SYNC GROUPS FROM KEYCLOAK STATUS: ${e.response?.statusCode}");
      return null;
    } catch (e) {
      debugPrint("SYNC GROUPS FROM KEYCLOAK ERROR: $e");
      return null;
    }
  }

  Future<dynamic> syncGroupUsers() async {
    try {
      final r = await ApiClient.dio.post('/admin/portal-groups/sync-users');
      return r.data;
    } on DioException catch (e) {
      debugPrint("SYNC GROUP USERS STATUS: ${e.response?.statusCode}");
      return null;
    } catch (e) {
      debugPrint("SYNC GROUP USERS ERROR: $e");
      return null;
    }
  }

  // ─── Portal App Access Rules ──────────────────────────────────────────────

  Future<dynamic> fetchPortalAppAccessRules() async {
    try {
      try {
        final r = await ApiClient.dio.get('/v1/admin/portal-app-access-rules');
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get('/admin/portal-app-access-rules');
        return r.data;
      }
    } catch (e) {
      debugPrint("FETCH PORTAL APP ACCESS RULES ERROR: $e");
      return null;
    }
  }

  Future<dynamic> getPortalAppAccessRuleById(String id) async {
    try {
      try {
        final r = await ApiClient.dio.get(
          '/v1/admin/portal-app-access-rules/$id',
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get('/admin/portal-app-access-rules/$id');
        return r.data;
      }
    } catch (e) {
      debugPrint("GET PORTAL APP ACCESS RULE ERROR: $e");
      return null;
    }
  }

  Future<dynamic> fetchPortalAppAccessRulesByApp(String appId) async {
    try {
      try {
        final r = await ApiClient.dio.get(
          '/v1/admin/portal-app-access-rules/by-app/$appId',
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get(
          '/admin/portal-app-access-rules/by-app/$appId',
        );
        return r.data;
      }
    } catch (e) {
      debugPrint("FETCH APP ACCESS RULES BY APP ERROR: $e");
      return null;
    }
  }

  Future<dynamic> createPortalAppAccessRule(Map<String, dynamic> data) async {
    try {
      try {
        final r = await ApiClient.dio.post(
          '/v1/admin/portal-app-access-rules',
          data: data,
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.post(
          '/admin/portal-app-access-rules',
          data: data,
        );
        return r.data;
      }
    } catch (e) {
      debugPrint("CREATE ACCESS RULE ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> updatePortalAppAccessRule(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      try {
        final r = await ApiClient.dio.put(
          '/v1/admin/portal-app-access-rules/$id',
          data: data,
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.put(
          '/admin/portal-app-access-rules/$id',
          data: data,
        );
        return r.data;
      }
    } catch (e) {
      debugPrint("UPDATE ACCESS RULE ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> deletePortalAppAccessRule(String id) async {
    try {
      try {
        final r = await ApiClient.dio.delete(
          '/v1/admin/portal-app-access-rules/$id',
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.delete(
          '/admin/portal-app-access-rules/$id',
        );
        return r.data;
      }
    } catch (e) {
      debugPrint("DELETE ACCESS RULE ERROR: $e");
      rethrow;
    }
  }

  Future<dynamic> fetchRuleValues(String ruleType) async {
    try {
      try {
        final r = await ApiClient.dio.get(
          '/v1/admin/portal-app-access-rules/rule-values',
          queryParameters: {'ruleType': ruleType},
        );
        return r.data;
      } catch (_) {
        final r = await ApiClient.dio.get(
          '/admin/portal-app-access-rules/rule-values',
          queryParameters: {'ruleType': ruleType},
        );
        return r.data;
      }
    } on DioException catch (e) {
      debugPrint("FETCH RULE VALUES STATUS: ${e.response?.statusCode}");
      return null;
    } catch (e) {
      debugPrint("FETCH RULE VALUES UNEXPECTED ERROR: $e");
      return null;
    }
  }

  // ─── Biometric / Device Auth ──────────────────────────────────────────────

  Future<void> registerBiometricDeviceService({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String publicKey,
    required String accessToken,
  }) async {
    try {
      await ApiClient.dio.post(
        '/auth/device/register',
        data: {
          'device_id': deviceId,
          'device_name': deviceName,
          'platform': platform,
          'public_key': publicKey,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      debugPrint(
        'BIOMETRIC REGISTER API ERROR: ${e.response?.statusCode} — ${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<String> requestBiometricChallengeService({
    required String username,
    required String deviceId,
    required String accessToken,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/device/challenge',
        data: {'device_id': deviceId},
        queryParameters: {'username': username},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final respData = response.data;
      if (respData is Map) {
        return (respData['challenge'] ?? respData['data'] ?? '').toString();
      }
      return respData?.toString() ?? '';
    } on DioException catch (e) {
      debugPrint(
        'BIOMETRIC CHALLENGE API ERROR: ${e.response?.statusCode} — ${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyBiometricService({
    required String deviceId,
    required String challenge,
    required String signature,
    required String accessToken,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/device/verify',
        data: {
          'device_id': deviceId,
          'challenge': challenge,
          'signature': signature,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'access_token': null};
    } on DioException catch (e) {
      debugPrint(
        'BIOMETRIC VERIFY API ERROR: ${e.response?.statusCode} — ${e.response?.data}',
      );
      rethrow;
    }
  }

  // ─── Employment Infos ─────────────────────────────────────────────────────

  Future<dynamic> fetchMyEmploymentInfos({String? userId}) async {
    try {
      final r = await ApiClient.dio.get('/accounts/profile/employment-infos');
      return r.data;
    } on DioException catch (e) {
      debugPrint(
        "ACCOUNTS EMPLOYMENT INFO API STATUS: ${e.response?.statusCode}",
      );

      // If 403 (forbidden) or 404, fallback to gateway user-profile endpoint
      String? targetUserId = userId;
      if (targetUserId == null || targetUserId.isEmpty) {
        try {
          final box = GetStorage();
          targetUserId = box.read('userProfileUserId')?.toString() ??
              box.read('userId')?.toString() ??
              box.read('sub')?.toString();
        } catch (_) {}
      }

      if (targetUserId != null && targetUserId.isNotEmpty) {
        try {
          final r = await ApiClient.dio.get(
            '/gateway/user-profile/users/$targetUserId/employment-infos',
          );
          return r.data;
        } catch (gatewayErr) {
          debugPrint("GATEWAY EMPLOYMENT INFO API ERROR: $gatewayErr");
        }
      }
      return null;
    } catch (e) {
      debugPrint("EMPLOYMENT INFO API ERROR: $e");
      return null;
    }
  }
}
