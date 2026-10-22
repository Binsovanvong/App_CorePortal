import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/services/biometric_service.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:dio/dio.dart' show DioException;

/// Service responsible for managing application lifecycle auto-locking,
/// native biometric authentication prompts on resume/reopen,
/// and security policy enforcement (Option C: auto-lock on background,
/// full session logout on explicit logout).
class AppLockService extends GetxService with WidgetsBindingObserver {
  static AppLockService get to => Get.find<AppLockService>();

  /// Whether the app is currently in locked state
  final RxBool isLocked = false.obs;

  /// Whether a native biometric prompt is currently active on screen
  final RxBool isAuthenticating = false.obs;

  /// Last timestamp when app transitioned to background
  DateTime? lastBackgroundTime;

  /// Configured background lock delay (0 = immediate upon backgrounding)
  static const Duration backgroundLockTimeout = Duration.zero;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Determines if current state qualifies for locking:
  /// - User has an authenticated session (is_logged_in == true or active token)
  /// - User has enrolled biometrics (Face ID / Fingerprint registered)
  /// - Current route is NOT an unprotected screen (login, splash, reset password, etc.)
  bool get shouldLock {
    final box = GetStorage();
    final bool isLoggedIn = box.read('is_logged_in') == true;
    final token = ApiClient.currentToken;
    if (!isLoggedIn && (token == null || token.isEmpty)) {
      return false;
    }

    final currentRoute = Get.currentRoute;
    if (currentRoute == AppRoutes.login ||
        currentRoute == AppRoutes.splash ||
        currentRoute == AppRoutes.resetPassword ||
        currentRoute == AppRoutes.updatePassword ||
        currentRoute == AppRoutes.firstLoginChangePassword) {
      return false;
    }

    final username = box.read('username')?.toString() ??
        box.read('cached_current_username')?.toString() ??
        '';
    if (username.isEmpty) return false;

    final isEnrolled = (box.read('biometric_registered_$username') == true) ||
        (box.read('is_face_enrolled') == true);
    return isEnrolled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Prevent re-triggering while native OS biometric prompt dialog is open
    if (isAuthenticating.value) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (shouldLock && !isLocked.value) {
        lastBackgroundTime = DateTime.now();
        isLocked.value = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (isLocked.value && !isAuthenticating.value) {
        triggerBiometricUnlock();
      }
    }
  }

  /// Manually locks the app from Settings or Security menu without revoking session
  void lockNow() {
    if (shouldLock) {
      isLocked.value = true;
      triggerBiometricUnlock();
    }
  }

  /// Initiates native Face ID / Fingerprint verification to unlock the active session
  Future<void> triggerBiometricUnlock() async {
    if (isAuthenticating.value) return;
    isAuthenticating.value = true;

    try {
      // 1. Verify biometric hardware availability
      final bool canAuth = await BiometricService.canAuthenticate();
      if (!canAuth) {
        // Biometrics unavailable (e.g. removed in OS settings), keep locked
        return;
      }

      // 2. Display native Face ID (iOS) or Fingerprint/Biometrics (Android) dialog
      final BiometricResult result = await BiometricService.authenticate();

      if (result == BiometricResult.success) {
        // 3. Verify server session validity with BFF / Keycloak
        String? token = await ApiClient.getAccessToken();
        final bool isExpiredOrExpiring =
            token == null || token.isEmpty || await ApiClient.tokenStore.expiresSoon();

        if (isExpiredOrExpiring) {
          final refreshed = await ApiClient.refreshSession();
          if (!refreshed) {
            // Server-side session was revoked or refresh token expired
            await unlockWithFullLogout(
              sessionExpiredMessage:
                  'សម័យការចូលប្រើប្រាស់បានផុតកំណត់ សូមចូលដោយប្រើពាក្យសម្ងាត់ (Session expired. Please log in with password)',
            );
            return;
          }
          token = await ApiClient.getAccessToken();
        }

        if (token == null || token.isEmpty) {
          await unlockWithFullLogout(
            sessionExpiredMessage:
                'សម័យការចូលប្រើប្រាស់បានផុតកំណត់ សូមចូលដោយប្រើពាក្យសម្ងាត់ (Session expired. Please log in with password)',
          );
          return;
        }

        // 4. Authenticate device against FastAPI BFF by using persistent device ID
        final String deviceId = await BiometricService.getDeviceId();
        final box = GetStorage();
        final username = box.read('username')?.toString() ??
            box.read('cached_current_username')?.toString() ??
            '';

        if (username.isNotEmpty) {
          final authService = AuthService();
          try {
            // Request one-time challenge for this device_id
            final String challenge =
                await authService.requestBiometricChallengeService(
              username: username,
              deviceId: deviceId,
              accessToken: token,
            );

            if (challenge.isNotEmpty) {
              // Sign challenge with this hardware device's ECC P-256 private key
              final String signedChallenge =
                  await BiometricService.signChallenge(challenge);

              // Verify cryptographic challenge with backend by using device_id
              final Map<String, dynamic> verifyResponse =
                  await authService.verifyBiometricService(
                deviceId: deviceId,
                challenge: challenge,
                signature: signedChallenge,
                accessToken: token,
              );

              final String? refreshedToken =
                  verifyResponse['access_token']?.toString() ??
                  verifyResponse['token']?.toString();

              if (refreshedToken != null && refreshedToken.isNotEmpty) {
                await ApiClient.saveToken(refreshedToken);
              }
            }
          } on DioException catch (e) {
            final statusCode = e.response?.statusCode;
            if (statusCode == 401 || statusCode == 403) {
              // Device was revoked or session terminated on Keycloak/BFF
              await unlockWithFullLogout(
                sessionExpiredMessage:
                    'ឧបករណ៍នេះត្រូវបានលុបចោល ឬសម័យកាលបានផុតកំណត់ (Device revoked or session expired. Please log in again)',
              );
              return;
            }
            debugPrint("Device challenge verification warning: $e");
          } catch (e) {
            debugPrint("Device challenge verification error: $e");
          }
        }

        // Biometrics passed and device verified by device ID -> Unlock interface
        isLocked.value = false;
      } else {
        // Biometric failed or cancelled: keep app locked
        debugPrint("Biometric unlock failed or cancelled ($result). Remaining locked.");
      }
    } catch (e) {
      debugPrint("AppLockService unlock error: $e");
    } finally {
      isAuthenticating.value = false;
    }
  }

  /// Handles user choosing full logout or when refresh token is revoked/expired.
  /// Revokes session, clears tokens across secure storage, and routes to password login.
  Future<void> unlockWithFullLogout({String? sessionExpiredMessage}) async {
    isLocked.value = false;
    isAuthenticating.value = false;
    await ApiClient.logout();
    if (sessionExpiredMessage != null && sessionExpiredMessage.isNotEmpty) {
      CustomSnackbar.showInfo(message: sessionExpiredMessage);
    }
    Get.offAllNamed(AppRoutes.login);
  }

  /// Gracefully terminates the application
  void exitApp() {
    SystemNavigator.pop();
    exit(0);
  }
}
