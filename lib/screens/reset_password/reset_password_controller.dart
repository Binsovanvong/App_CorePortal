import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';

class ResetPasswordController extends GetxController {
  final AuthService _authService = AuthService();

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  final newPassword = ''.obs;
  final confirmPassword = ''.obs;

  String username = '';
  String displayName = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      username = (args['username'] ?? args['userName'] ?? args['accountName'] ?? '').toString().trim();
      displayName = (args['displayName'] ?? args['name'] ?? username).toString().trim();
    }
    newPasswordController.addListener(() {
      newPassword.value = newPasswordController.text;
    });
    confirmPasswordController.addListener(() {
      confirmPassword.value = confirmPasswordController.text;
    });
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  bool get hasMinLength => newPassword.value.length >= 8;
  bool get hasBothCases =>
      newPassword.value.contains(RegExp(r'[a-z]')) &&
      newPassword.value.contains(RegExp(r'[A-Z]'));
  bool get hasNumber => newPassword.value.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar =>
      newPassword.value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int get passwordStrengthScore {
    if (newPassword.value.isEmpty) return 1;
    int score = 0;
    if (hasMinLength) score++;
    if (hasBothCases) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;
    return score.clamp(1, 4);
  }

  String get passwordStrengthLabel {
    final score = passwordStrengthScore;
    if (newPassword.value.isEmpty || score == 1) return 'strength_weak'.tr;
    if (score == 2) return 'strength_medium'.tr;
    if (score == 3) return 'strength_good'.tr;
    return 'strength_strong'.tr;
  }

  Color get passwordStrengthColor {
    final score = passwordStrengthScore;
    if (newPassword.value.isEmpty || score == 1) return const Color(0xFF2563EB);
    if (score == 2) return const Color(0xFFF59E0B);
    if (score == 3) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  void clearForm() {
    newPasswordController.clear();
    confirmPasswordController.clear();
    newPassword.value = '';
    confirmPassword.value = '';
  }

  Future<void> submitResetPassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (username.isEmpty) {
      CustomSnackbar.showError(
        title: 'error_title'.tr,
        message: 'username_missing_err'.tr,
      );
      return;
    }

    if (newPass.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'warning_title'.tr,
        message: 'please_enter_new_pwd'.tr,
      );
      return;
    }

    if (newPass.length < 8) {
      CustomSnackbar.showWarning(
        title: 'warning_title'.tr,
        message: 'pwd_must_be_8_chars'.tr,
      );
      return;
    }

    if (confirmPass.isEmpty) {
      CustomSnackbar.showWarning(
        title: 'warning_title'.tr,
        message: 'please_confirm_pwd'.tr,
      );
      return;
    }

    if (newPass != confirmPass) {
      CustomSnackbar.showWarning(
        title: 'warning_title'.tr,
        message: 'pwd_not_match'.tr,
      );
      return;
    }

    // Dismiss keyboard before submitting
    FocusManager.instance.primaryFocus?.unfocus();

    isLoading.value = true;
    try {
      await _authService.resetUserPasswordService(
        username: username,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      final String targetName =
          displayName.isNotEmpty ? displayName : username;

      // 1. Clear all inputs and state on this screen
      clearForm();

      // 2. Clear/pop this reset screen back to the previous screen
      Get.back(result: true);

      // 3. Show success snackbar on the caller screen
      Future.delayed(const Duration(milliseconds: 150), () {
        CustomSnackbar.showSuccess(
          title: 'success_title'.tr,
          message: 'reset_pwd_success'.trParams({'user': targetName}),
        );
      });
    } on DioException catch (e) {
      String errMsg = 'reset_pwd_failed'.tr;
      if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        errMsg = (d['message'] ?? d['error'] ?? d['detail'] ?? d['title'] ?? errMsg).toString();
      } else if (e.response?.data is String && (e.response!.data as String).isNotEmpty) {
        errMsg = e.response!.data.toString();
      }
      CustomSnackbar.showError(
        title: 'failed_title'.tr,
        message: errMsg,
      );
    } catch (e) {
      CustomSnackbar.showError(
        title: 'failed_title'.tr,
        message: '${'technical_issue'.tr}: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
