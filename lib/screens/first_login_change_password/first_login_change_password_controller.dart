import 'dart:async';

import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class FirstLoginChangePasswordController extends GetxController {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscureCurrentPassword = true.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  late final String username;
  late final String tempPassword;
  String? ticket;
  int? expiresIn;
  DateTime? _expiresAt;
  Timer? _expiryTimer;

  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      username = (args['username'] ?? '').toString();
      ticket = args['ticket']?.toString();
      expiresIn = args['expiresIn'] is int ? args['expiresIn'] as int : null;
      tempPassword =
          (args['tempPassword'] ?? args['current_password'] ?? '').toString();
      if (ticket != null && ticket!.isNotEmpty && expiresIn != null && expiresIn! > 0) {
        _expiresAt = DateTime.now().add(Duration(seconds: expiresIn!));
        _expiryTimer = Timer(Duration(seconds: expiresIn!), () {
          _clearTicket();
          CustomSnackbar.showWarning(
            message:
                'សម័យកាលប្តូរលេខសម្ងាត់បានផុតកំណត់ សូមចូលប្រើប្រាស់ឡើងវិញ (Your password-change session expired. Sign in again.)',
          );
          cancelAndReturnToLogin();
        });
      }
    } else {
      username = '';
      tempPassword = '';
    }
    if (tempPassword.isNotEmpty) {
      currentPasswordController.text = tempPassword;
    }
  }

  void _clearTicket() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    ticket = null;
    _expiresAt = null;
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  @override
  void onClose() {
    _clearTicket();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Cancels first-login password change, deletes any temporary tokens,
  /// and resets navigation back to login.
  Future<void> cancelAndReturnToLogin() async {
    _clearTicket();
    await ApiClient.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  bool _validatePassword(String password, String oldPassword) {
    if (password.length < 8) {
      CustomSnackbar.showError(
        message: 'pwd_rule_length'.tr,
      );
      return false;
    }

    // Uppercase check
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'pwd_rule_upper'.tr,
      );
      return false;
    }

    // Lowercase check
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'pwd_rule_lower'.tr,
      );
      return false;
    }

    // Number check
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'pwd_rule_number'.tr,
      );
      return false;
    }

    // Special character check
    if (!RegExp(r'[!@#\$&*~%^()_\+=\-\[\]{}|;:<>?\/]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'pwd_rule_special'.tr,
      );
      return false;
    }

    // Prevent using username in password
    if (username.isNotEmpty &&
        password.toLowerCase().contains(username.toLowerCase())) {
      CustomSnackbar.showError(
        message: 'pwd_rule_no_username'.tr,
      );
      return false;
    }

    // Prevent reusing temporary password
    if (oldPassword.isNotEmpty && password == oldPassword) {
      CustomSnackbar.showError(
        message: 'password_same_as_old_error'.tr,
      );
      return false;
    }

    return true;
  }

  Future<void> submitPasswordChange() async {
    // 1. Prevent double taps
    if (isLoading.value) return;

    final hasTicket = ticket != null && ticket!.isNotEmpty;

    // 2. Check ticket expiry before submission
    if (hasTicket && (_expiresAt == null || !DateTime.now().isBefore(_expiresAt!))) {
      _clearTicket();
      CustomSnackbar.showWarning(
        message:
            'សម័យកាលប្តូរលេខសម្ងាត់បានផុតកំណត់ សូមចូលប្រើប្រាស់ឡើងវិញ (Your password-change session expired. Sign in again.)',
      );
      await cancelAndReturnToLogin();
      return;
    }

    final currentPassword = tempPassword.isNotEmpty
        ? tempPassword
        : currentPasswordController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (!hasTicket && currentPassword.isEmpty) {
      CustomSnackbar.showError(
        message: 'enter_current_password_hint'.tr,
      );
      return;
    }

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      CustomSnackbar.showError(
        message: 'pwd_rule_empty'.tr,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackbar.showError(
        message: 'pwd_rule_mismatch'.tr,
      );
      return;
    }

    if (!_validatePassword(newPassword, currentPassword)) {
      return;
    }

    // 3. Drop credentials and ticket from controllers/memory before awaiting network operation
    final currentTicket = ticket;
    if (hasTicket) {
      _clearTicket();
    } else {
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }

    try {
      isLoading.value = true;

      if (hasTicket && currentTicket != null) {
        // Native ticket flow: POST /api/mobile/auth/update-password
        final response = await _authService.updatePasswordWithTicketService(
          ticket: currentTicket,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );

        final token = response['access_token']?.toString() ??
            response['token']?.toString() ??
            response['data']?['access_token']?.toString() ??
            response['data']?['token']?.toString();

        if (token != null && token.isNotEmpty) {
          final box = GetStorage();
          await box.write('username', username);
          await box.write('is_logged_in', true);

          CustomSnackbar.showSuccess(
            message: 'password_changed_success'.tr,
          );
          // Directly enter authenticated application without a second login screen
          Get.offAllNamed(AppRoutes.mainPage);
          return;
        } else {
          // If token exchange failed after password change (password_updated_login_failed)
          CustomSnackbar.showInfo(
            message:
                'លេខសម្ងាត់ត្រូវបានផ្លាស់ប្តូរ សូមចូលប្រើប្រាស់ឡើងវិញ (Password was updated. Sign in with your new password.)',
          );
          Get.offAllNamed(AppRoutes.login);
          return;
        }
      }

      // Legacy first login flow: authenticated PUT /api/mobile/accounts/change-password
      await _authService.changePasswordService(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );

      // On legacy success, reset session and return to login
      await ApiClient.logout();

      CustomSnackbar.showSuccess(
        message: 'password_changed_success'.tr,
      );

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint("Failed to update password during first login: $e");
      String errorMessage = 'password_change_failed'.tr;
      bool returnToLogin = false;

      if (e is DioException) {
        debugPrint(
          "FIRST LOGIN CHANGE PASSWORD STATUS: ${e.response?.statusCode} - DATA: ${e.response?.data}",
        );
        final statusCode = e.response?.statusCode;
        final resData = e.response?.data;

        // Completion timeout or network drop
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            statusCode == 504) {
          // As required: "After a completion timeout, the update may already have succeeded,
          // so the widget advises trying the new password. Do not retry completion automatically."
          errorMessage =
              'ការផ្លាស់ប្តូរមិនអាចបញ្ជាក់បានទេ។ សូមសាកល្បងចូលប្រើដោយប្រើលេខសម្ងាត់ថ្មីរបស់អ្នក។ (The update could not be confirmed. Try signing in with your new password.)';
          returnToLogin = true;
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'no_internet_error'.tr;
          returnToLogin = true;
        } else if (statusCode == 400) {
          // Policy rejection: Keycloak consumed the ticket, so user must start fresh attempt
          returnToLogin = true;
          if (resData is Map && resData['detail'] is Map && resData['detail']['message'] != null) {
            errorMessage = resData['detail']['message'].toString();
          } else {
            errorMessage =
                'លេខសម្ងាត់មិនស្របតាមគោលការណ៍សុវត្ថិភាពទេ។ សូមចូលប្រើឡើងវិញដើម្បីព្យាយាមម្តងទៀត។ (Password does not meet the account password policy. Sign in again to retry.)';
          }
        } else if (statusCode == 401) {
          // Invalid, expired or already used ticket
          returnToLogin = true;
          errorMessage =
              'សម័យកាលប្តូរលេខសម្ងាត់បានផុតកំណត់ ឬមិនត្រឹមត្រូវ។ សូមចូលប្រើម្តងទៀត។ (Your password-change session expired or is invalid. Sign in again.)';
        } else if (statusCode == 409) {
          // Unsupported required action
          returnToLogin = true;
          if (resData is Map && resData['detail'] is Map && resData['detail']['message'] != null) {
            errorMessage = resData['detail']['message'].toString();
          } else {
            errorMessage =
                'គណនីនេះទាមទារសកម្មភាពបន្ថែមដែលមិនអាចបំពេញក្នុងកម្មវិធីបានទេ។ (This account requires an action that cannot be completed in the app.)';
          }
        } else if (statusCode == 503) {
          // Backend native password-change service is not configured (Keycloak extension or credentials missing)
          returnToLogin = true;
          errorMessage =
              'សេវាប្តូរលេខសម្ងាត់នៅលើ Server មិនទាន់ត្រូវបានកំណត់រចនាសម្ព័ន្ធត្រឹមត្រូវទេ។ (Native password-change service is not configured on the server. Please contact administrator or use browser login.)';
        } else if (resData is Map) {
          final detail = resData['detail'] ??
              resData['message'] ??
              resData['error_description'] ??
              resData['error'];
          if (detail != null) {
            if (detail is Map && detail['code'] == 'password_updated_login_failed') {
              errorMessage =
                  'លេខសម្ងាត់ត្រូវបានផ្លាស់ប្តូរ សូមចូលប្រើប្រាស់ឡើងវិញ (Password was updated. Sign in with your new password.)';
              returnToLogin = true;
            } else if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              if (first is Map && first['msg'] != null) {
                errorMessage = first['msg'].toString();
              } else {
                errorMessage = detail.map((i) => i.toString()).join(", ");
              }
            } else if (detail is Map && detail['message'] != null) {
              errorMessage = detail['message'].toString();
            } else if (detail.toString().isNotEmpty) {
              errorMessage = detail.toString();
            }
          }
        }
      }

      CustomSnackbar.showError(
        message: errorMessage,
      );

      if (returnToLogin || hasTicket) {
        // Any failure in ticket mode means the ticket cannot be reused. User starts a fresh login.
        await cancelAndReturnToLogin();
      }
    } finally {
      isLoading.value = false;
    }
  }
}
