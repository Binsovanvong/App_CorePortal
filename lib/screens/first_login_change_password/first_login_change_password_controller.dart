import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
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
        message: 'ពាក្យសម្ងាត់ថ្មីត្រូវមានយ៉ាងហោចណាស់ ៨ តួអក្សរ',
      );
      return false;
    }

    // Uppercase check
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'ពាក្យសម្ងាត់ត្រូវមានអក្សរធំ (A-Z) យ៉ាងហោចណាស់មួយតួ',
      );
      return false;
    }

    // Lowercase check
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'ពាក្យសម្ងាត់ត្រូវមានអក្សរតូច (a-z) យ៉ាងហោចណាស់មួយតួ',
      );
      return false;
    }

    // Number check
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'ពាក្យសម្ងាត់ត្រូវមានលេខ (0-9) យ៉ាងហោចណាស់មួយតួ',
      );
      return false;
    }

    // Special character check
    if (!RegExp(r'[!@#\$&*~%^()_\+=\-\[\]{}|;:<>?\/]').hasMatch(password)) {
      CustomSnackbar.showError(
        message: 'ពាក្យសម្ងាត់ត្រូវមានសញ្ញាពិសេស (ឧទាហរណ៍: @, #, \$, *, !) យ៉ាងហោចណាស់មួយ',
      );
      return false;
    }

    // Prevent using username in password
    if (username.isNotEmpty && password.toLowerCase().contains(username.toLowerCase())) {
      CustomSnackbar.showError(
        message: 'ពាក្យសម្ងាត់មិនត្រូវមានឈ្មោះគណនីរបស់អ្នកឡើយ',
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
        message: 'សូមបញ្ចូលពាក្យសម្ងាត់ថ្មី និងបញ្ជាក់ពាក្យសម្ងាត់ថ្មី',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackbar.showError(
        message: 'ពាក្យសម្ងាត់ថ្មី និងពាក្យសម្ងាត់បញ្ជាក់មិនផ្ទៀងផ្ទាត់គ្នាឡើយ',
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
      );

      CustomSnackbar.showSuccess(
        message: 'ការផ្លាស់ប្តូរពាក្យសម្ងាត់ទទួលបានជោគជ័យ',
      );

      Get.offAllNamed(AppRoutes.mainPage);
    } catch (e) {
      debugPrint("Failed to update password during first login: $e");
      CustomSnackbar.showError(
        message: 'មិនអាចផ្លាស់ប្តូរពាក្យសម្ងាត់បានឡើយ។ សូមព្យាយាមម្តងទៀត។',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
