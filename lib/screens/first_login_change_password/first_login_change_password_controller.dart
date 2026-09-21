import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class FirstLoginChangePasswordController extends GetxController {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  late final String username;
  late final String tempPassword;

  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    username = Get.arguments?['username'] ?? '';
    tempPassword = Get.arguments?['tempPassword'] ?? '';
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  bool _validatePassword(String password) {
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
    if (tempPassword.isNotEmpty && password == tempPassword) {
      CustomSnackbar.showError(
        message: 'password_same_as_old_error'.tr,
      );
      return false;
    }

    return true;
  }

  Future<void> submitPasswordChange() async {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

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

    if (!_validatePassword(newPassword)) {
      return;
    }

    try {
      isLoading.value = true;

      await _authService.changePasswordService(
        username: username,
        oldPassword: tempPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      CustomSnackbar.showSuccess(
        message: 'password_changed_success'.tr,
      );

      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint("Failed to update password during first login: $e");
      String errorMessage = 'password_change_failed'.tr;
      if (e is DioException) {
        debugPrint(
          "FIRST LOGIN CHANGE PASSWORD STATUS: ${e.response?.statusCode} - DATA: ${e.response?.data}",
        );
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'timeout_error'.tr;
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'no_internet_error'.tr;
        } else if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          final detail = data['detail'] ??
              data['message'] ??
              data['error_description'] ??
              data['error'];
          if (detail != null) {
            if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              if (first is Map && first['msg'] != null) {
                errorMessage = first['msg'].toString();
              } else {
                errorMessage = detail.map((i) => i.toString()).join(", ");
              }
            } else if (detail.toString().isNotEmpty) {
              errorMessage = detail.toString();
            }
          }
        }
      }
      CustomSnackbar.showError(
        message: errorMessage,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
