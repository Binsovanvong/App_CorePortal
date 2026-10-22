import 'dart:io' show Platform, exit;
import 'package:flutter/services.dart' show SystemNavigator;

import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/services/biometric_service.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/core/services/app_lock_service.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'dart:convert' show base64Url, json, utf8;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:dio/dio.dart' show DioException, DioExceptionType, Options;
import 'package:core_portal/core/api/pkce_helper.dart';
import 'package:core_portal/screens/update_password/update_password_screen.dart';

class LoginController extends GetxController {
  // Controllers for the input fields
  final usernameController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: '');

  // Observable toggle for password visibility
  final obscurePassword = true.obs;

  // Observable toggle for remember me
  final rememberMe = false.obs;

  // Observable loading state
  final isLoading = false.obs;

  // Toggle to require/disable Face ID & Fingerprint prompt after login
  static const bool requireBiometricOnLogin = true;

  // Observable for biometric lock screen mode (session unlock)
  final isBiometricLockMode = false.obs;

  final AuthService _authService = AuthService();
  bool _sessionUnlockAttempted = false;

  @override
  void onReady() {
    super.onReady();
    _unlockSavedSession();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.isLocked.value = false;
      }
    });
  }

  Future<void> _unlockSavedSession() async {
    if (_sessionUnlockAttempted) return;
    _sessionUnlockAttempted = true;
    final box = GetStorage();

    // Option C: If the user tapped Logout or has no active session, do NOT restore.
    // They must explicitly log in with username and password.
    final bool isLoggedIn = box.read('is_logged_in') == true;
    if (!isLoggedIn) {
      isBiometricLockMode.value = false;
      return;
    }

    final username = box.read('username')?.toString() ??
        box.read('cached_current_username')?.toString() ??
        '';
    if (username.isEmpty) return;

    final bool isRegistered =
        await BiometricService.isBiometricEnrolled(username);

    if (requireBiometricOnLogin && isRegistered) {
      isBiometricLockMode.value = true;
    } else {
      return;
    }

    String token = await ApiClient.getAccessToken() ?? '';

    // Step 1: Ensure we have a valid access token. Refresh if expired or expiring soon.
    final bool isExpiredOrExpiring =
        token.isEmpty || await ApiClient.tokenStore.expiresSoon();

    if (isExpiredOrExpiring) {
      final refreshed = await ApiClient.refreshSession();
      if (refreshed) {
        token = await ApiClient.getAccessToken() ?? '';
      }
    }

    // In current API architecture, /challenge and /verify require a valid bearer token.
    // If the token is expired and cannot be refreshed, the device cannot perform biometric login.
    // Fall back cleanly to normal login: do NOT register again.
    if (token.isEmpty) {
      debugPrint(
        'Token expired and cannot be refreshed. Switching to password login.',
      );
      isBiometricLockMode.value = false;
      return;
    }

    final rawRoles = box.read('roles');
    final roles = rawRoles is List
        ? rawRoles.map((role) => role.toString()).toList()
        : <String>['user'];
    isLoading.value = true;
    try {
      await _runBiometricAuth(
        username: username,
        roles: roles,
        credentialResponse: {'access_token': token},
        isUnlockMode: true,
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> retryBiometricUnlock() async {
    final box = GetStorage();
    final username = box.read('username')?.toString() ??
        box.read('cached_current_username')?.toString() ??
        '';
    if (username.isEmpty) return;

    String token = await ApiClient.getAccessToken() ?? '';

    final bool isExpiredOrExpiring =
        token.isEmpty || await ApiClient.tokenStore.expiresSoon();
    if (isExpiredOrExpiring) {
      final refreshed = await ApiClient.refreshSession();
      if (refreshed) {
        token = await ApiClient.getAccessToken() ?? '';
      }
    }

    if (token.isEmpty) {
      isBiometricLockMode.value = false;
      CustomSnackbar.showInfo(
        message:
            'សម័យការចូលប្រើប្រាស់បានផុតកំណត់ សូមចូលដោយប្រើពាក្យសម្ងាត់ (Session expired. Please log in with password)',
      );
      return;
    }

    final rawRoles = box.read('roles');
    final roles = rawRoles is List
        ? rawRoles.map((role) => role.toString()).toList()
        : <String>['user'];
    isLoading.value = true;
    try {
      await _runBiometricAuth(
        username: username,
        roles: roles,
        credentialResponse: {'access_token': token},
        isUnlockMode: true,
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void exitApp() {
    SystemNavigator.pop();
    exit(0);
  }

  Future<void> switchToPasswordLogin() async {
    isBiometricLockMode.value = false;
    await ApiClient.logout();
  }

  Future<void> loginWithBiometricsQuick({bool isFace = false}) async {
    final bool canAuth = await BiometricService.canAuthenticate();
    if (!canAuth) {
      CustomSnackbar.showWarning(
        title: isFace ? 'Face ID' : 'Fingerprint',
        message: 'biometric_not_supported'.tr,
      );
      return;
    }

    final box = GetStorage();
    String token = await ApiClient.getAccessToken() ?? '';
    String username =
        box.read('username')?.toString() ??
        box.read('cached_current_username')?.toString() ??
        '';

    // Step 1: Ensure we have a valid access token. Refresh if expired or expiring soon.
    final bool isExpiredOrExpiring =
        token.isEmpty || await ApiClient.tokenStore.expiresSoon();
    if (isExpiredOrExpiring) {
      final refreshed = await ApiClient.refreshSession();
      if (refreshed) {
        token = await ApiClient.getAccessToken() ?? '';
        username =
            box.read('username')?.toString() ??
            box.read('cached_current_username')?.toString() ??
            '';
      }
    }

    if (token.isNotEmpty && username.isNotEmpty) {
      final rawRoles = box.read('roles');
      final roles = rawRoles is List
          ? rawRoles.map((role) => role.toString()).toList()
          : <String>['user'];
      isLoading.value = true;
      try {
        await _runBiometricAuth(
          username: username,
          roles: roles,
          credentialResponse: {'access_token': token},
          isUnlockMode: true,
        );
      } finally {
        if (!isClosed) isLoading.value = false;
      }
    } else {
      final bool isEnrolled = username.isNotEmpty &&
          await BiometricService.isBiometricEnrolled(username);
      if (isEnrolled) {
        CustomSnackbar.showInfo(
          message:
              'សម័យការចូលប្រើប្រាស់បានផុតកំណត់ សូមចូលដោយប្រើពាក្យសម្ងាត់ (Session expired. Please log in with password)',
        );
      } else {
        final result = await BiometricService.authenticate();
        if (result == BiometricResult.success) {
          CustomSnackbar.showInfo(message: 'first_login_biometric_bind_msg'.tr);
        }
      }
    }
  }

  List<String> _parseRoles(String username, Map<String, dynamic> response) {
    final roles = <String>{};

    void addRole(dynamic rawRole) {
      if (rawRole == null) return;
      final String str =
          (rawRole is Map
                  ? (rawRole['code'] ??
                        rawRole['name'] ??
                        rawRole['role'] ??
                        '')
                  : rawRole)
              .toString()
              .trim();
      if (str.isEmpty) return;

      final lower = str.toLowerCase();
      roles.add(str);
      roles.add(lower);

      // Automatically detect administrative privilege from role string
      final upper = str.toUpperCase();
      if (upper.contains('ADMIN') ||
          upper.contains('ADMINISTRATOR') ||
          upper.contains('SUPER')) {
        roles.add('admin');
        if (upper.contains('GENERAL_DEPARTMENT')) {
          roles.add('general_department_admin');
        } else if (upper.contains('PORTAL')) {
          roles.add('portal_administrator');
        }
      }
    }

    // 1. Roles array directly from backend response or nested user object
    final dynamic rolesData =
        response['roles'] ??
        response['user']?['roles'] ??
        response['data']?['roles'] ??
        response['data']?['user']?['roles'];
    if (rolesData is List) {
      for (final item in rolesData) {
        addRole(item);
      }
    }

    // 2. Groups array from backend response or nested user object
    final dynamic groupsData =
        response['groups'] ??
        response['user']?['groups'] ??
        response['userGroups'] ??
        response['user_groups'] ??
        response['data']?['groups'] ??
        response['data']?['user']?['groups'];
    if (groupsData is List) {
      for (final item in groupsData) {
        final g = (item is Map ? (item['code'] ?? item['name'] ?? '') : item)
            .toString()
            .trim();
        if (g.toUpperCase().contains('ADMIN')) {
          addRole(g);
        }
      }
    }

    // 3. Permissions check: auto-grant admin if user has any management permissions
    final dynamic permsData =
        response['permissions'] ??
        response['user']?['permissions'] ??
        response['data']?['permissions'] ??
        response['data']?['user']?['permissions'];
    if (permsData is List) {
      final perms = permsData
          .map((e) => e.toString().toUpperCase().trim())
          .toList();
      final hasAdminPerms = perms.any(
        (p) =>
            p.contains('MANAGE') ||
            p.contains('ADMIN') ||
            p.contains('CREATE') ||
            p.contains('DELETE') ||
            p.contains('ASSIGN'),
      );
      if (hasAdminPerms && !roles.contains('admin')) {
        roles.add('admin');
        if (!roles.contains('portal_administrator') &&
            !roles.contains('general_department_admin')) {
          roles.add('portal_administrator');
        }
      }
    }

    // 4. Fallback decode from JWT access token payload if present
    final token = (response['access_token'] ?? response['token'])?.toString();
    if (token != null && token.isNotEmpty) {
      try {
        final clean = token
            .replaceFirst(RegExp(r'^Bearer ', caseSensitive: false), '')
            .trim();
        final parts = clean.split('.');
        if (parts.length >= 2) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final Map<String, dynamic> jwtMap = json.decode(decoded);
          final realmRoles = jwtMap['realm_access']?['roles'];
          if (realmRoles is List) {
            for (final r in realmRoles) {
              addRole(r);
            }
          }
        }
      } catch (_) {}
    }

    if (roles.isEmpty) {
      roles.addAll(['portal_user', 'user']);
    } else {
      if (!roles.contains('portal_user') && !roles.contains('admin')) {
        roles.add('portal_user');
      }
    }

    return roles.toList();
  }

  void _routeUserByRoles(List<String> roles) {
    Get.offAllNamed(AppRoutes.mainPage);
  }

  // ─── Biometric second factor ──────────────────────────────────────────────

  /// Called after credentials are verified. Runs biometric-only prompt, then
  /// (on success only) signs the backend challenge and finalises authentication.
  ///
  /// On FAILED or CANCELLED: stops immediately — nothing is sent to FastAPI,
  /// no access token is issued, no PIN/passcode fallback is offered.
  Future<void> _runBiometricAuth({
    required String username,
    required List<String> roles,
    required Map<String, dynamic> credentialResponse,
    bool isUnlockMode = false,
  }) async {
    // Skip biometric prompt when requireBiometricOnLogin is false or on non-mobile platforms
    if (!requireBiometricOnLogin ||
        kIsWeb ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      await _finaliseLogin(
        username: username,
        roles: roles,
        credentialResponse: credentialResponse,
        token:
            credentialResponse['access_token']?.toString() ??
            credentialResponse['token']?.toString() ??
            '',
      );
      return;
    }

    // Check biometric availability
    final bool canAuth = await BiometricService.canAuthenticate();
    if (!canAuth) {
      CustomSnackbar.showError(message: 'biometric_not_supported'.tr);
      if (isUnlockMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        exitApp();
      }
      return; // Do NOT route user — biometric is required
    }

    final String deviceId = await BiometricService.getDeviceId();
    final String accessToken =
        credentialResponse['access_token']?.toString() ??
        credentialResponse['token']?.toString() ??
        '';

    // Query backend devices if access token is available
    List<dynamic> backendDevices = [];
    if (accessToken.isNotEmpty) {
      try {
        backendDevices =
            await _authService.listUserDevicesService(accessToken: accessToken);
      } catch (_) {}
    }

    // Evaluate the 4 strict conditions for registration:
    // 1. Biometric login is enabled for the first time.
    // 2. The device was revoked.
    // 3. The app was reinstalled or the private key was lost.
    // 4. The stored public/private key pair changed.
    final bool needsRegistration = await BiometricService.shouldRegisterDevice(
      username: username,
      deviceId: deviceId,
      backendDevices: backendDevices,
    );

    // If registration is required for first-time enablement, ask user confirmation
    if (needsRegistration) {
      final bool isFirstTime =
          !await BiometricService.isBiometricEnrolled(username);
      if (isFirstTime) {
        final bool wantsToRegister = await _confirmBiometricRegistration();
        if (!wantsToRegister) {
          CustomSnackbar.showWarning(message: 'device_reg_cancelled'.tr);
          if (!isUnlockMode) {
            await ApiClient.logout();
          }
          return;
        }
      }
    }

    // ── Present biometric prompt (biometric-only, no PIN fallback) ──────────
    final BiometricResult result = await BiometricService.authenticate();

    switch (result) {
      case BiometricResult.success:
        if (needsRegistration) {
          try {
            if (accessToken.isEmpty) {
              throw StateError(
                'The login response did not include an access token.',
              );
            }

            // Revoke any stale devices for this user first so backend has only this clean device
            for (final d in backendDevices) {
              if (d is Map) {
                final oldId = d['device_id']?.toString();
                if (oldId != null && oldId.isNotEmpty && oldId != deviceId) {
                  try {
                    await _authService.revokeDeviceService(
                      deviceId: oldId,
                      accessToken: accessToken,
                    );
                  } catch (_) {}
                }
              }
            }

            final String publicKey =
                await BiometricService.getPublicKeyDerBase64();
            final int regStatus = await _authService.registerBiometricDeviceService(
              deviceId: deviceId,
              deviceName: Platform.isIOS ? 'iOS Device' : 'Android Device',
              platform: Platform.isIOS ? 'ios' : 'android',
              publicKey: publicKey,
              accessToken: accessToken,
            );

            if (regStatus >= 200 && regStatus < 300) {
              await BiometricService.saveRegisteredPublicKey(publicKey);
              await BiometricService.setBiometricEnrolled(username, true);
            } else {
              throw StateError('Device registration failed with status $regStatus');
            }
          } on DioException catch (e) {
            final statusCode = e.response?.statusCode;
            if (statusCode == 401) {
              await ApiClient.logout();
              isBiometricLockMode.value = false;
              CustomSnackbar.showError(
                message:
                    'សម័យកាលបានផុតកំណត់ សូមចូលប្រើប្រាស់ឡើងវិញ (Session expired. Please log in again)',
              );
              return;
            } else if (statusCode == 403) {
              final detail = e.response?.data?['detail'] ?? 'Access is denied';
              CustomSnackbar.showError(
                message:
                    'ការចុះឈ្មោះឧបករណ៍មិនត្រូវបានអនុញ្ញាត (Gateway 403: $detail)។ សូមទាក់ទងអ្នកគ្រប់គ្រងប្រព័ន្ធ។',
              );
              if (!isUnlockMode) {
                await ApiClient.logout();
              }
              return;
            } else {
              final msg =
                  e.response?.data?['detail'] ??
                  e.response?.data?['message'] ??
                  'device_registration_failed'.tr;
              CustomSnackbar.showError(message: msg.toString());
              if (!isUnlockMode) {
                await ApiClient.logout();
              }
              return;
            }
          } catch (e) {
            CustomSnackbar.showError(message: 'device_registration_failed'.tr);
            if (!isUnlockMode) {
              await ApiClient.logout();
            }
            return;
          }
        }

        // 🟢 Authenticate device via Challenge & Verify
        await _signAndVerify(
          username: username,
          roles: roles,
          credentialResponse: credentialResponse,
          isUnlockMode: isUnlockMode,
        );
        break;

      case BiometricResult.failed:
        CustomSnackbar.showError(message: 'biometric_failed'.tr);
        if (isUnlockMode && isBiometricLockMode.value) {
          await Future.delayed(const Duration(milliseconds: 800));
          exitApp();
        } else {
          await ApiClient.logout();
        }

      case BiometricResult.cancelled:
        CustomSnackbar.showWarning(message: 'biometric_cancelled'.tr);
        if (isUnlockMode && isBiometricLockMode.value) {
          await Future.delayed(const Duration(milliseconds: 800));
          exitApp();
        } else {
          await ApiClient.logout();
        }

      case BiometricResult.unavailable:
        CustomSnackbar.showError(message: 'biometric_unavailable'.tr);
        if (isUnlockMode && isBiometricLockMode.value) {
          await Future.delayed(const Duration(milliseconds: 800));
          exitApp();
        } else {
          await ApiClient.logout();
        }
    }
  }

  Future<bool> _confirmBiometricRegistration() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('register_device_title'.tr),
        content: Text('register_device_content'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('not_now'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('register'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  /// Called only after biometric SUCCESS. Gets challenge → signs → POST verify.
  Future<void> _signAndVerify({
    required String username,
    required List<String> roles,
    required Map<String, dynamic> credentialResponse,
    bool isUnlockMode = false,
  }) async {
    try {
      final String accessToken =
          credentialResponse['access_token']?.toString() ??
          credentialResponse['token']?.toString() ??
          '';
      if (accessToken.isEmpty) {
        throw StateError('The login response did not include an access token.');
      }

      // 1. Get a stable device identifier for both challenge and verification.
      final String deviceId = await BiometricService.getDeviceId();

      // 2. Request a one-time challenge from the backend.
      final String challenge = await _authService
          .requestBiometricChallengeService(
            username: username,
            deviceId: deviceId,
            accessToken: accessToken,
          );
      if (challenge.isEmpty) {
        throw StateError('The biometric challenge response was empty.');
      }

      // 3. Sign challenge with this device's HMAC key (stored in secure storage)
      final String signedChallenge = await BiometricService.signChallenge(
        challenge,
      );

      // 4. POST /api/mobile/auth/device/verify
      final Map<String, dynamic> verifyResponse = await _authService
          .verifyBiometricService(
            deviceId: deviceId,
            challenge: challenge,
            signature: signedChallenge,
            accessToken: accessToken,
          );

      // 5. Extract access token from verify response
      final String? finalToken =
          verifyResponse['access_token']?.toString() ??
          verifyResponse['token']?.toString();

      if (finalToken != null && finalToken.isNotEmpty) {
        await _finaliseLogin(
          username: username,
          roles: roles,
          credentialResponse: credentialResponse,
          token: finalToken,
        );
      } else {
        // Backend verify succeeded structurally but returned no token —
        // fall back to the credential token (covers dev environments)
        final fallbackToken =
            credentialResponse['access_token']?.toString() ??
            credentialResponse['token']?.toString() ??
            '';
        await _finaliseLogin(
          username: username,
          roles: roles,
          credentialResponse: credentialResponse,
          token: fallbackToken,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await ApiClient.logout();
        isBiometricLockMode.value = false;
        CustomSnackbar.showError(
          message:
              'សម័យកាលបានផុតកំណត់ សូមចូលប្រើប្រាស់ឡើងវិញ (Session expired. Please log in again)',
        );
        return;
      }
      final msg =
          e.response?.data?['detail'] ??
          e.response?.data?['message'] ??
          'device_verification_failed'.tr;
      CustomSnackbar.showError(message: msg.toString());
      if (!isUnlockMode) {
        await ApiClient.logout();
      }
    } catch (e) {
      CustomSnackbar.showError(message: 'device_verification_failed'.tr);
      if (!isUnlockMode) {
        await ApiClient.logout();
      }
    }
  }

  /// Stores the final token, writes roles, and routes the user.
  Future<void> _finaliseLogin({
    required String username,
    required List<String> roles,
    required Map<String, dynamic> credentialResponse,
    required String token,
  }) async {
    final dynamic refreshToken =
        credentialResponse['refresh_token'] ??
        credentialResponse['data']?['refresh_token'];
    final dynamic cpSession =
        credentialResponse['cp_session'] ??
        credentialResponse['CP_SESSION'] ??
        credentialResponse['session'];

    // 🟢 CRITICAL: Await token saving across both FlutterSecureStorage and GetStorage
    // BEFORE routing the user, ensuring immediate availability for initial API calls.
    await ApiClient.saveToken(
      token,
      refreshToken: refreshToken?.toString(),
      cpSession: cpSession?.toString(),
    );

    // 🟢 Signal that login/authentication has finished so waiting callers can proceed
    AuthService.completeAuthProcess();

    final box = GetStorage();
    final prevUser = box.read('cached_current_username');
    if (prevUser != null &&
        prevUser.toString().toLowerCase() != username.toLowerCase()) {
      box.remove('cached_admin_users_list');
      box.remove('cached_admin_user_groups_map');
      box.remove('cached_admin_apps_list');
      box.remove('cached_portal_services');
    }
    await box.write('cached_current_username', username);
    await box.write('username', username);
    await box.write('roles', roles);

    // 🟢 Extract and persist user profile metadata (General Department, Groups, Display Name)
    final userMap = credentialResponse['user'] is Map
        ? Map<String, dynamic>.from(credentialResponse['user'] as Map)
        : credentialResponse;

    final gCode =
        userMap['generalDepartmentCode'] ??
        userMap['departmentCode'] ??
        userMap['orgCode'];
    if (gCode != null && gCode.toString().isNotEmpty) {
      await box.write('generalDepartmentCode', gCode.toString().trim());
    }

    final gNameKh =
        userMap['generalDepartmentNameKh'] ?? userMap['departmentNameKh'];
    if (gNameKh != null && gNameKh.toString().isNotEmpty) {
      await box.write('generalDepartmentNameKh', gNameKh.toString().trim());
    }

    final gName = userMap['generalDepartmentName'] ?? userMap['departmentName'];
    if (gName != null && gName.toString().isNotEmpty) {
      await box.write('generalDepartmentName', gName.toString().trim());
    }

    final orgCode = userMap['orgCode'];
    if (orgCode != null && orgCode.toString().isNotEmpty) {
      await box.write('orgCode', orgCode.toString().trim());
    }

    final empInfos = userMap['employmentInfos'];
    if (empInfos is List && empInfos.isNotEmpty && empInfos[0] is Map) {
      final firstEmp = empInfos[0];
      final empGCode =
          firstEmp['generalDepartmentCode'] ??
          firstEmp['departmentCode'] ??
          firstEmp['orgCode'];
      if (empGCode != null && empGCode.toString().isNotEmpty) {
        await box.write('generalDepartmentCode', empGCode.toString().trim());
      }
      final empGNameKh =
          firstEmp['generalDepartmentNameKh'] ?? firstEmp['departmentNameKh'];
      if (empGNameKh != null && empGNameKh.toString().isNotEmpty) {
        await box.write(
          'generalDepartmentNameKh',
          empGNameKh.toString().trim(),
        );
      }
      final empGName =
          firstEmp['generalDepartmentName'] ?? firstEmp['departmentName'];
      if (empGName != null && empGName.toString().isNotEmpty) {
        await box.write('generalDepartmentName', empGName.toString().trim());
      }
    }

    final dispName =
        userMap['displayName'] ??
        userMap['display_name'] ??
        userMap['fullName'] ??
        userMap['name'];
    if (dispName != null && dispName.toString().isNotEmpty) {
      await box.write('displayName', dispName.toString().trim());
      await box.write('user_display_name', dispName.toString().trim());
    }

    final groups =
        userMap['groups'] ??
        credentialResponse['groups'] ??
        userMap['userGroups'] ??
        credentialResponse['userGroups'];
    if (groups is List && groups.isNotEmpty) {
      await box.write('groups', groups);
      await box.write('user_groups', groups);
      await box.write('userGroups', groups);
    }

    final userProfileUserId =
        userMap['userProfileUserId'] ?? userMap['id'] ?? userMap['subject'];
    if (userProfileUserId != null && userProfileUserId.toString().isNotEmpty) {
      await box.write('userProfileUserId', userProfileUserId.toString().trim());
    }

    final bool hasAdmin = roles.any((r) {
      final s = r.toString().toUpperCase().trim();
      return s.contains('ADMIN') ||
          s.contains('ADMINISTRATOR') ||
          s.contains('SUPER') ||
          s.contains('MANAGE');
    });
    await box.write('isAdmin', hasAdmin);

    if (Get.isRegistered<NavController>()) {
      Get.find<NavController>().checkAdminRole();
    }

    final perms =
        credentialResponse['permissions'] ??
        credentialResponse['user']?['permissions'];
    if (perms is List) {
      await box.write('permissions', perms);
    }

    CustomSnackbar.showSuccess(message: 'login_success'.tr);
    _routeUserByRoles(roles);
  }

  /// Helper to query live user profile and merge roles, groups, and department information
  Future<Map<String, dynamic>> _enrichWithProfileData(
    Map<String, dynamic> rawCredentials,
  ) async {
    final Map<String, dynamic> enriched = Map<String, dynamic>.from(
      rawCredentials,
    );
    try {
      final profile = await _authService.fetchProfile();
      if (profile is Map) {
        final profileUser = profile['user'] is Map
            ? Map<String, dynamic>.from(profile['user'] as Map)
            : Map<String, dynamic>.from(profile);

        enriched['user'] = profileUser;
        if (profile['roles'] is List) enriched['roles'] = profile['roles'];
        if (profile['groups'] is List) enriched['groups'] = profile['groups'];
        if (profile['permissions'] is List)
          enriched['permissions'] = profile['permissions'];
        if (profileUser['roles'] is List)
          enriched['roles'] = profileUser['roles'];
        if (profileUser['groups'] is List)
          enriched['groups'] = profileUser['groups'];
        if (profileUser['permissions'] is List)
          enriched['permissions'] = profileUser['permissions'];
      }
    } catch (e) {
      debugPrint("Live profile enrichment notice: $e");
    }
    return enriched;
  }

  // ─── Credential Login ────────────────────────────────────────────────────

  Future<void> loginWithCredentials([BuildContext? context]) async {
    if (isLoading.value) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      CustomSnackbar.showError(message: 'enter_user_pass'.tr);
      return;
    }

    passwordController.clear();
    AuthService.startAuthProcess();

    try {
      isLoading.value = true;
      final response = await ApiClient.refreshApi.post(
        '/api/mobile/auth/login',
        data: {'username': username, 'password': password},
        options: Options(
          validateStatus: (status) =>
              status != null &&
              ((status >= 200 && status < 300) || status == 409),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        await ApiClient.tokenStore.saveTokenResponse(data);
        await ApiClient.saveTokens(response.data, dioHeaders: response.headers);

        final token =
            data['access_token'] ??
            data['token'] ??
            data['data']?['access_token'] ??
            data['data']?['token'];

        if (token != null && token.toString().isNotEmpty) {
          final bool isFirstLogin =
              data['first_login'] == true ||
              data['firstLogin'] == true ||
              data['data']?['first_login'] == true ||
              data['data']?['firstLogin'] == true ||
              data['first_login']?.toString().toLowerCase() == 'true' ||
              data['first_login'] == 1;

          if (isFirstLogin) {
            AuthService.completeAuthProcess();
            Get.offAllNamed(
              AppRoutes.firstLoginChangePassword,
              arguments: {
                'username': username,
                'tempPassword': password,
                'current_password': password,
              },
            );
            return;
          }

          // 🟢 Fetch live profile to populate real roles, department and permissions
          final combinedData = await _enrichWithProfileData(data);
          final roles = _parseRoles(username, combinedData);

          await _runBiometricAuth(
            username: username,
            roles: roles,
            credentialResponse: combinedData,
          );
          return;
        }

        CustomSnackbar.showError(
          message: 'ការឆ្លើយតបពីម៉ាស៊ីនមេមិនត្រឹមត្រូវឡើយ',
        );
        AuthService.completeAuthProcess();
        return;
      }

      if (response.statusCode == 409) {
        final body = response.data;

        if (body is Map) {
          final detail = body['detail'];

          debugPrint('LOGIN STATUS: ${response.statusCode}');
          if (detail is Map && detail['code'] != null) {
            debugPrint('LOGIN ACTION: ${detail['code']}');
          }

          if (detail is Map &&
              detail['code'] == 'update_password_required' &&
              detail['ticket'] is String) {
            final ticket = detail['ticket'] as String;
            final rawExpiresIn = detail['expires_in'];
            final expiresIn = rawExpiresIn is int
                ? rawExpiresIn
                : int.tryParse(rawExpiresIn?.toString() ?? '');

            // Keep the ticket only in memory. Do not log or save in storage.
            passwordController.clear();
            AuthService.completeAuthProcess();

            final navContext = context ?? Get.context;
            if (navContext != null) {
              await Navigator.of(navContext).push(
                MaterialPageRoute(
                  builder: (_) => UpdatePasswordScreen(
                    ticket: ticket,
                    username: username,
                    expiresIn: expiresIn,
                  ),
                ),
              );
              return;
            }

            await Get.to(
              () => UpdatePasswordScreen(
                ticket: ticket,
                username: username,
                expiresIn: expiresIn,
              ),
            );
            return;
          }

          if (detail is Map &&
              detail['code'] == 'unsupported_required_action') {
            throw Exception(
              'This account has another required action that cannot be completed in the app.',
            );
          }
        }

        throw Exception('Account requires an unsupported action.');
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (error) {
      AuthService.completeAuthProcess();
      final response = error.response;
      final detail = response?.data is Map ? response?.data['detail'] : null;

      debugPrint('LOGIN STATUS: ${response?.statusCode}');
      if (detail is Map && detail['code'] != null) {
        debugPrint('LOGIN ACTION: ${detail['code']}');
      }

      if (response?.statusCode == 409 &&
          detail is Map &&
          detail['code'] == 'update_password_required' &&
          detail['ticket'] is String) {
        final ticket = detail['ticket'] as String;
        final rawExpiresIn = detail['expires_in'];
        final expiresIn = rawExpiresIn is int
            ? rawExpiresIn
            : int.tryParse(rawExpiresIn?.toString() ?? '');

        // Keep the ticket only in memory.
        passwordController.clear();

        final navContext = context ?? Get.context;
        if (navContext != null) {
          await Navigator.of(navContext).push(
            MaterialPageRoute(
              builder: (_) => UpdatePasswordScreen(
                ticket: ticket,
                username: username,
                expiresIn: expiresIn,
              ),
            ),
          );
        } else {
          await Get.to(
            () => UpdatePasswordScreen(
              ticket: ticket,
              username: username,
              expiresIn: expiresIn,
            ),
          );
        }
        return;
      }

      // Offline dev fallback for admin only
      if (kDebugMode &&
          username.toLowerCase() == 'admin' &&
          (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout)) {
        final roles = _parseRoles(username, {});
        final mockResponse = {'access_token': 'mock_admin_token'};
        await _runBiometricAuth(
          username: username,
          roles: roles,
          credentialResponse: mockResponse,
        );
        return;
      }

      await _showLoginError(detail, error, username);
    } catch (e) {
      AuthService.completeAuthProcess();
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      CustomSnackbar.showError(message: errorMsg);
    } finally {
      if (Get.isRegistered<LoginController>()) {
        isLoading.value = false;
      }
    }
  }

  /// Handles ordinary login errors without leaking sensitive payload data
  Future<void> _showLoginError(
    dynamic detail,
    DioException error,
    String username,
  ) async {
    // DO NOT log the ticket or raw request/response body
    debugPrint('LOGIN STATUS: ${error.response?.statusCode}');
    if (detail is Map && detail['code'] != null) {
      debugPrint('LOGIN ACTION: ${detail['code']}');
    }

    String errorMessage = 'invalid_credentials'.tr;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'timeout_error'.tr;
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'no_internet_error'.tr;
    } else if (error.response?.statusCode == 429) {
      // 429 Too Many Requests: Rate limited to 5 attempts per minute per IP
      final resData = error.response?.data;
      String msg = '';
      if (resData is Map) {
        msg = (resData['detail'] ?? resData['message'] ?? '').toString();
      }
      errorMessage = msg.isNotEmpty
          ? msg
          : 'Login attempt limit exceeded (5 attempts per minute). Please try again shortly.';
    } else if (error.response?.statusCode == 409) {
      // 409 Conflict: Not update_password_required (do not treat every 409 as Update Password!)
      if (detail is Map && detail['code'] == 'required_action') {
        final browserEndpoint = detail['browser_login_endpoint']?.toString();
        if (browserEndpoint != null && browserEndpoint.isNotEmpty) {
          debugPrint(
            "Keycloak reported required_action: starting browser-login with PKCE...",
          );
          try {
            await loginWithBrowserPkce(username: username);
            return;
          } catch (browserError) {
            if (browserError is DioException &&
                browserError.response?.statusCode == 503) {
              final errData = browserError.response?.data;
              final detailMsg =
                  (errData is Map ? errData['detail'] : null) ??
                  'Mobile browser callbacks are not configured on server';
              CustomSnackbar.showError(message: detailMsg.toString());
              return;
            }
            final errStr = browserError.toString().toLowerCase();
            if (errStr.contains('cancel') || errStr.contains('user')) {
              CustomSnackbar.showWarning(
                message: 'ការផ្ទៀងផ្ទាត់ត្រូវបានបោះបង់ (Login cancelled)',
              );
              return;
            }
            CustomSnackbar.showError(
              message:
                  'Browser login failed: ${browserError.toString().replaceAll("Exception: ", "")}',
            );
            return;
          }
        }
      }

      String msg = '';
      if (detail is Map && detail['message'] != null) {
        msg = detail['message'].toString();
      } else if (detail is String) {
        msg = detail;
      } else if (error.response?.data is Map &&
          error.response?.data['message'] != null) {
        msg = error.response!.data['message'].toString();
      }
      errorMessage = msg.isNotEmpty ? msg : 'server_error'.tr;
    } else if (detail != null) {
      if (detail is Map && detail['message'] != null) {
        errorMessage = detail['message'].toString();
      } else if (detail is String && detail.isNotEmpty) {
        errorMessage = detail;
      }
    } else if (error.response?.data != null && error.response?.data is Map) {
      final resData = error.response!.data as Map;
      final rawMsg = resData['message'] ?? resData['detail'];
      if (rawMsg != null && rawMsg.toString().isNotEmpty) {
        errorMessage = rawMsg.toString();
      }
    }

    final cleanMessage = errorMessage.toLowerCase().trim();
    final String translatedMessage;
    if (error.response?.statusCode == 409 ||
        error.response?.statusCode == 429) {
      translatedMessage = errorMessage;
    } else if (cleanMessage.contains('invalid username or password') ||
        cleanMessage.contains('bad credentials') ||
        cleanMessage.contains('invalid_credentials') ||
        cleanMessage.contains('authentication failed')) {
      translatedMessage = 'invalid_credentials'.tr;
    } else {
      translatedMessage = errorMessage;
    }

    CustomSnackbar.showError(message: translatedMessage);
  }

  /// Starts PKCE browser login via BFF /api/mobile/auth/browser-login
  /// and exchanges the callback code via /api/mobile/auth/exchange-code
  Future<void> loginWithBrowserPkce({String? username}) async {
    isLoading.value = true;
    try {
      final effectiveUsername = (username ?? usernameController.text).trim();
      final String callbackScheme = kIsWeb ? 'http' : 'myapp';
      final String redirectUri = kIsWeb
          ? '${Uri.base.origin}/auth.html'
          : 'myapp://callback';

      final pkce = PkceHelper.generate();

      final browserResp = await _authService.browserLoginService(
        username: effectiveUsername,
        redirectUri: redirectUri,
        codeChallenge: pkce.codeChallenge,
        state: pkce.state,
        nonce: pkce.nonce,
      );

      final String? browserUrl =
          browserResp['url']?.toString() ??
          browserResp['login_url']?.toString() ??
          browserResp['authorization_url']?.toString() ??
          browserResp['redirect_url']?.toString() ??
          browserResp['data']?['url']?.toString() ??
          browserResp['data']?['login_url']?.toString();

      if (browserUrl == null || browserUrl.isEmpty) {
        throw StateError('Server did not return a browser login URL.');
      }

      final String callbackResult = await FlutterWebAuth2.authenticate(
        url: browserUrl,
        callbackUrlScheme: callbackScheme,
      );

      final Uri callbackUri = Uri.parse(callbackResult);
      final String? code = callbackUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw StateError(
          'No authorization code returned from browser callback.',
        );
      }

      final exchangeResp = await _authService.exchangeCodeService(
        code: code,
        redirectUri: redirectUri,
        codeVerifier: pkce.codeVerifier,
      );

      final String token =
          exchangeResp['access_token']?.toString() ??
          exchangeResp['token']?.toString() ??
          exchangeResp['data']?['access_token']?.toString() ??
          exchangeResp['data']?['token']?.toString() ??
          '';

      if (token.isEmpty) {
        throw StateError(
          'Token exchange succeeded but returned no access token.',
        );
      }

      final combinedResp = await _enrichWithProfileData(exchangeResp);
      final roles = _parseRoles(effectiveUsername, combinedResp);
      await _runBiometricAuth(
        username: effectiveUsername,
        roles: roles,
        credentialResponse: combinedResp,
      );
    } finally {
      if (Get.isRegistered<LoginController>()) {
        isLoading.value = false;
      }
    }
  }

  // Fallback web SSO login
  Future<void> login() async {
    try {
      await loginWithBrowserPkce();
    } catch (e) {
      debugPrint("SSO login error: $e");
      if (e is DioException && e.response?.statusCode == 503) {
        final errData = e.response?.data;
        final detailMsg =
            (errData is Map ? errData['detail'] : null) ??
            'Mobile browser callbacks are not configured';
        CustomSnackbar.showError(message: detailMsg.toString());
      } else {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('cancel') || errStr.contains('user')) {
          CustomSnackbar.showWarning(
            message: 'ការផ្ទៀងផ្ទាត់ត្រូវបានបោះបង់ (Login cancelled)',
          );
        } else {
          CustomSnackbar.showError(
            message: e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }
}
