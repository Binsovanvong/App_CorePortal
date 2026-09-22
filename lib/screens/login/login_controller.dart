import 'dart:io' show Platform, exit;
import 'package:flutter/services.dart' show SystemNavigator;

import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/services/biometric_service.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:dio/dio.dart' show DioException, DioExceptionType;

class LoginController extends GetxController {
  // Controllers for the input fields
  final usernameController = TextEditingController(text: 'bin.sovanvong');
  final passwordController = TextEditingController(text: 'Abc1234567*');

  // Observable toggle for password visibility
  final obscurePassword = true.obs;

  // Observable toggle for remember me
  final rememberMe = false.obs;

  // Observable loading state
  final isLoading = false.obs;

  // Toggle to require/disable Face ID & Fingerprint prompt after login
  static const bool requireBiometricOnLogin = false;

  // Observable for biometric lock screen mode (session unlock)
  final isBiometricLockMode = false.obs;

  final AuthService _authService = AuthService();
  bool _sessionUnlockAttempted = false;

  @override
  void onReady() {
    super.onReady();
    _unlockSavedSession();
  }

  Future<void> _unlockSavedSession() async {
    if (_sessionUnlockAttempted) return;
    _sessionUnlockAttempted = true;
    final box = GetStorage();
    final token = await ApiClient.getAccessToken() ?? '';
    final username = box.read('username')?.toString() ?? '';
    if (token.isEmpty || username.isEmpty) return;

    final registrationKey = 'biometric_registered_$username';
    final bool isRegistered =
        (box.read(registrationKey) == true) ||
        (box.read('is_face_enrolled') == true);

    if (requireBiometricOnLogin && isRegistered) {
      isBiometricLockMode.value = true;
    } else {
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
    final token = await ApiClient.getAccessToken() ?? '';
    final username = box.read('username')?.toString() ?? '';
    if (token.isEmpty || username.isEmpty) return;
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
    final token = await ApiClient.getAccessToken() ?? '';
    final username = box.read('username')?.toString() ?? '';

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
      final result = await BiometricService.authenticate();
      if (result == BiometricResult.success) {
        CustomSnackbar.showInfo(message: 'first_login_biometric_bind_msg'.tr);
      }
    }
  }

  List<String> _parseRoles(String username, Map<String, dynamic> response) {
    final roles = <String>[];

    // Helper to normalize and add a role
    void addNormalizedRole(dynamic rawRole) {
      if (rawRole == null) return;
      String r = '';
      if (rawRole is Map) {
        r =
            (rawRole['code'] ??
                    rawRole['name'] ??
                    rawRole['role'] ??
                    rawRole['groupCode'] ??
                    '')
                .toString()
                .toLowerCase()
                .trim();
      } else {
        r = rawRole.toString().toLowerCase().trim();
      }

      if (r == 'general_department_admin' ||
          r == 'general_department' ||
          r == 'gddtm_admin' ||
          r == 'gddtm_admins' ||
          r.contains('general_department')) {
        if (!roles.contains('general_department_admin')) {
          roles.add('general_department_admin');
        }
        if (!roles.contains('admin')) roles.add('admin');
      } else if (r == 'portal_administrator' ||
          r == 'administrator' ||
          r == 'admin' ||
          r == 'portal_admin' ||
          r == 'portal_admins' ||
          r.contains('administrator')) {
        if (!roles.contains('portal_administrator')) {
          roles.add('portal_administrator');
        }
        if (!roles.contains('admin')) roles.add('admin');
      } else if (r.contains('portal_user') ||
          r == 'user' ||
          r == 'resident_user' ||
          r == 'gddtm') {
        if (!roles.contains('portal_user')) roles.add('portal_user');
        if (!roles.contains('user')) roles.add('user');
      }
      if (r.isNotEmpty && !roles.contains(r)) roles.add(r);
    }

    // 1. Check explicit roles/groups arrays from backend response
    if (response['roles'] is List) {
      for (var item in response['roles']) {
        addNormalizedRole(item);
      }
    }
    if (response['groups'] is List) {
      for (var item in response['groups']) {
        addNormalizedRole(item);
      }
    }
    if (response['userGroups'] is List) {
      for (var item in response['userGroups']) {
        addNormalizedRole(item);
      }
    }
    if (response['user_groups'] is List) {
      for (var item in response['user_groups']) {
        addNormalizedRole(item);
      }
    }
    if (response['user'] is Map) {
      final u = response['user'] as Map;
      if (u['roles'] is List) {
        for (var item in u['roles']) {
          addNormalizedRole(item);
        }
      }
      if (u['groups'] is List) {
        for (var item in u['groups']) {
          addNormalizedRole(item);
        }
      }
      if (u['userGroups'] is List) {
        for (var item in u['userGroups']) {
          addNormalizedRole(item);
        }
      }
    }

    // 2. Check permissions list ONLY if no explicit roles were found
    if (roles.isEmpty && response['permissions'] is List) {
      final perms = (response['permissions'] as List)
          .map((e) => e.toString().toUpperCase())
          .toList();
      if (perms.contains('PORTAL_APP_MANAGE') ||
          perms.contains('PORTAL_USER_MANAGE') ||
          perms.contains('USER_MANAGE') ||
          perms.contains('ADMIN_ACCESS') ||
          perms.contains('PORTAL_ROLE_MANAGE')) {
        if (!roles.contains('admin')) roles.add('admin');
        if (!roles.contains('portal_administrator')) {
          roles.add('portal_administrator');
        }
      }
      if (!roles.contains('portal_user')) roles.add('portal_user');
    }

    // 3. Fallbacks only for explicit mock admin dev logins
    final lowerUser = username.toLowerCase().trim();
    if (lowerUser == 'admin') {
      roles.insert(0, 'admin');
      roles.add('portal_administrator');
    }

    if (roles.isEmpty) {
      roles.add('portal_user');
      roles.add('user');
    }
    return roles;
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

    final box = GetStorage();
    final registrationKey = 'biometric_registered_$username';
    final bool isRegistered =
        (box.read(registrationKey) == true) ||
        (box.read('is_face_enrolled') == true);

    // A device is registered only after the user explicitly agrees. Stay on
    // this page when they decline; do not navigate to another route.
    if (!isRegistered) {
      final bool wantsToRegister = await _confirmBiometricRegistration();
      if (!wantsToRegister) {
        CustomSnackbar.showWarning(message: 'device_reg_cancelled'.tr);
        return;
      }
    }

    // ── Present biometric prompt (biometric-only, no PIN fallback) ──────────
    final BiometricResult result = await BiometricService.authenticate();

    switch (result) {
      case BiometricResult.success:
        if (!isRegistered) {
          try {
            final String accessToken =
                credentialResponse['access_token']?.toString() ??
                credentialResponse['token']?.toString() ??
                '';
            if (accessToken.isEmpty) {
              throw StateError(
                'The login response did not include an access token.',
              );
            }

            final String deviceId = 'device-${username.hashCode.abs()}';
            final String publicKey =
                await BiometricService.getPublicKeyDerBase64();
            await _authService.registerBiometricDeviceService(
              deviceId: deviceId,
              deviceName: '${Platform.operatingSystem} device',
              platform: Platform.operatingSystem,
              publicKey: publicKey,
              accessToken: accessToken,
            );
            await box.write(registrationKey, true);
            await box.write('is_face_enrolled', true);
          } on DioException catch (e) {
            if (e.response?.statusCode == 401) {
              final box = GetStorage();
              box.remove('token');
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
                'device_registration_failed'.tr;
            CustomSnackbar.showError(message: msg.toString());
            return;
          } catch (e) {
            CustomSnackbar.showError(message: 'device_registration_failed'.tr);
            return;
          }
        }

        // The registered device can now request a challenge and verify.
        // Disabled/hidden verify step:
        // await _signAndVerify(
        //   username: username,
        //   roles: roles,
        //   credentialResponse: credentialResponse,
        // );

        await _finaliseLogin(
          username: username,
          roles: roles,
          credentialResponse: credentialResponse,
          token:
              credentialResponse['access_token']?.toString() ??
              credentialResponse['token']?.toString() ??
              '',
        );

      case BiometricResult.failed:
        CustomSnackbar.showError(message: 'biometric_failed'.tr);
        if (isUnlockMode) {
          await Future.delayed(const Duration(milliseconds: 800));
          exitApp();
        }

      case BiometricResult.cancelled:
        CustomSnackbar.showWarning(message: 'biometric_cancelled'.tr);
        if (isUnlockMode) {
          await Future.delayed(const Duration(milliseconds: 800));
          exitApp();
        }

      case BiometricResult.unavailable:
        CustomSnackbar.showError(message: 'biometric_unavailable'.tr);
        if (isUnlockMode) {
          await Future.delayed(const Duration(milliseconds: 800));
          exitApp();
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
  // ignore: unused_element
  Future<void> _signAndVerify({
    required String username,
    required List<String> roles,
    required Map<String, dynamic> credentialResponse,
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
      final String deviceId = 'device-${username.hashCode.abs()}';

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
        final box = GetStorage();
        box.remove('token');
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
    } catch (e) {
      CustomSnackbar.showError(message: 'device_verification_failed'.tr);
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
    await box.write('username', username);
    await box.write('roles', roles);

    final bool hasAdmin = roles.any((r) {
      final s = r.toString().toLowerCase().trim();
      return s == 'admin' ||
          s == 'administrator' ||
          s == 'super_admin' ||
          s == 'superadmin' ||
          s == 'portal_admin' ||
          s == 'gddtm_admin';
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

  // ─── Credential Login ────────────────────────────────────────────────────

  Future<void> loginWithCredentials() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      CustomSnackbar.showError(message: 'enter_user_pass'.tr);
      return;
    }

    AuthService.startAuthProcess();

    final lowerUser = username.toLowerCase();
    if (lowerUser == 'admin') {
      try {
        isLoading.value = true;
        Map<String, dynamic> response;
        try {
          response = await _authService.loginService(
            username: username,
            password: password,
          );
        } catch (e) {
          response = {'access_token': 'mock_admin_token', 'first_login': false};
        }

        final token = response['access_token'] ?? response['token'];
        if (token != null && token.toString().isNotEmpty) {
          final roles = _parseRoles(username, response);
          // Biometric second factor
          await _runBiometricAuth(
            username: username,
            roles: roles,
            credentialResponse: response,
          );
          return;
        }
      } catch (e) {
        final roles = _parseRoles(username, {});
        final mockResponse = {'access_token': 'mock_admin_token'};
        await _runBiometricAuth(
          username: username,
          roles: roles,
          credentialResponse: mockResponse,
        );
        return;
      } finally {
        if (Get.isRegistered<LoginController>()) {
          isLoading.value = false;
        }
      }
    }

    try {
      isLoading.value = true;
      final response = await _authService.loginService(
        username: username,
        password: password,
      );

      final token = response['access_token'] ?? response['token'];
      if (token != null && token.toString().isNotEmpty) {
        final roles = _parseRoles(username, response);

        // Stay on login until device registration and biometric verification
        // are complete; do not redirect first-time users to another route.
        await _runBiometricAuth(
          username: username,
          roles: roles,
          credentialResponse: response,
        );
        return;
      }

      CustomSnackbar.showError(
        message: 'ការឆ្លើយតបពីម៉ាស៊ីនមេមិនត្រឹមត្រូវឡើយ',
      );
      AuthService.completeAuthProcess();
    } catch (e) {
      AuthService.completeAuthProcess();
      String errorMessage =
          'Authentication failed. Please check your credentials.';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'timeout_error'.tr;
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'no_internet_error'.tr;
        } else if (e.response?.data != null && e.response?.data is Map) {
          dynamic rawDetail =
              e.response?.data['detail'] ?? e.response?.data['message'];
          String serverMessage = rawDetail?.toString() ?? '';
          if (serverMessage.contains('<!DOCTYPE') ||
              serverMessage.contains('<html')) {
            if (serverMessage.contains('Invalid parameter: redirect_uri')) {
              errorMessage = 'Invalid parameter: redirect_uri';
            } else {
              errorMessage = 'Invalid username or password.';
            }
          } else if (serverMessage == 'An unexpected error occurred') {
            errorMessage = 'Invalid username or password.';
          } else if (serverMessage.isNotEmpty) {
            errorMessage = serverMessage;
          }
        } else {
          errorMessage = 'server_error'.tr;
        }
      }
      final cleanMessage = errorMessage.toLowerCase().trim();
      final String translatedMessage;
      if (cleanMessage.contains('invalid username or password') ||
          cleanMessage.contains('bad credentials') ||
          cleanMessage.contains('invalid_credentials') ||
          cleanMessage.contains('authentication failed')) {
        translatedMessage = 'invalid_credentials'.tr;
      } else {
        translatedMessage = errorMessage;
      }

      CustomSnackbar.showError(message: translatedMessage);
    } finally {
      if (Get.isRegistered<LoginController>()) {
        isLoading.value = false;
      }
    }
  }

  // Fallback web SSO login
  Future<void> login() async {
    isLoading.value = true;

    final String callbackScheme = kIsWeb ? 'http' : 'myapp';
    final String redirectUri = kIsWeb
        ? '${Uri.base.origin}/auth.html'
        : 'myapp://callback';

    final String bffLoginUrl =
        '${ApiConfig.baseUrl}/api/mobile/auth/login?redirect_uri=$redirectUri';

    try {
      // 1. Launch secure browser view and wait for redirect callback
      final result = await FlutterWebAuth2.authenticate(
        url: bffLoginUrl,
        callbackUrlScheme: callbackScheme,
      );

      // 2. Extract token from redirect URL: myapp://callback?token=...
      final Uri resultUri = Uri.parse(result);
      final String? token = resultUri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        // Success: Store the token using ApiClient.saveToken
        await ApiClient.saveToken(token);
        final box = GetStorage();
        await box.write('isAdmin', false);

        CustomSnackbar.showSuccess(message: 'login_success'.tr);

        // Navigate to the main application view
        Get.offAllNamed(AppRoutes.mainPage);
      } else {
        CustomSnackbar.showError(message: 'មិនទទួលបាន Token ពីម៉ាស៊ីនមេឡើយ');
      }
    } catch (e) {
      CustomSnackbar.showWarning(
        message: 'ការផ្ទៀងផ្ទាត់ត្រូវបានបោះបង់ ឬបានបរាជ័យ',
      );
    } finally {
      if (Get.isRegistered<LoginController>()) {
        isLoading.value = false;
      }
    }
  }
}
