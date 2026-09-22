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
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  bool get hasMinLength => newPasswordController.text.length >= 8;
  bool get hasBothCases =>
      newPasswordController.text.contains(RegExp(r'[a-z]')) &&
      newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get hasNumber => newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar =>
      newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  Future<void> submitResetPassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (username.isEmpty) {
      CustomSnackbar.showError(
        message: 'មិនមានឈ្មោះអ្នកប្រើប្រាស់សម្រាប់កំណត់ពាក្យសម្ងាត់ទេ (Username is missing)',
      );
      return;
    }

    if (newPass.isEmpty) {
      CustomSnackbar.showWarning(
        message: 'សូមបញ្ចូលពាក្យសម្ងាត់ថ្មី (Please enter new password)',
      );
      return;
    }

    if (newPass.length < 8) {
      CustomSnackbar.showWarning(
        message: 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៨ តួអក្សរ (Password must be at least 8 characters)',
      );
      return;
    }

    if (confirmPass.isEmpty) {
      CustomSnackbar.showWarning(
        message: 'សូមបញ្ចូលការបញ្ជាក់ពាក្យសម្ងាត់ (Please confirm password)',
      );
      return;
    }

    if (newPass != confirmPass) {
      CustomSnackbar.showWarning(
        message: 'ពាក្យសម្ងាត់ទាំងពីរមិនត្រូវគ្នាទេ (Passwords do not match)',
      );
      return;
    }

    isLoading.value = true;
    try {
      await _authService.resetUserPasswordService(
        username: username,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      CustomSnackbar.showSuccess(
        message: 'កំណត់ពាក្យសម្ងាត់ថ្មីសម្រាប់ $username បានជោគជ័យ',
      );

      // Navigate back
      Get.back(result: true);
    } on DioException catch (e) {
      String errMsg = 'បរាជ័យក្នុងការកំណត់ពាក្យសម្ងាត់ថ្មី';
      if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        errMsg = (d['message'] ?? d['error'] ?? d['detail'] ?? errMsg).toString();
      }
      CustomSnackbar.showError(
        message: errMsg,
      );
    } catch (e) {
      CustomSnackbar.showError(
        message: 'មានបញ្ហាបច្ចេកទេស: $e',
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
