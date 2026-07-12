part of 'setting_view.dart';

class SettingViewController extends GetxController {
  final AuthService _authService = AuthService();

  final userName = "Loading...".obs;
  final username = "".obs;
  final userPhoto = "".obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getProfileData();
  }

  Future<void> getProfileData() async {
    try {
      isLoading.value = true;

      final data = await _authService.fetchProfile();

      if (data != null) {
        if (data is Map) {
          userName.value =
              data['displayName'] ??
              data['display_name'] ??
              data['name'] ??
              data['full_name'] ??
              data['username'] ??
              "No Name";
          username.value = data['username'] ?? "";

          final profile = data['profile'];
          if (profile != null && profile is Map) {
            userPhoto.value = profile['avatar'] ?? profile['photo'] ?? "";
          } else {
            userPhoto.value = data['photo'] ?? data['avatar'] ?? "";
          }
        } else if (data is String) {
          userName.value = data;
        } else {
          userName.value = data.toString();
        }
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load profile data from server",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isUpdatingPassword = false.obs;

  void changePassword() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    isUpdatingPassword.value = false;

    final obscureCurrent = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ប្តូរលេខសម្ងាត់",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "ការផ្លាស់ប្តូរលេខសម្ងាត់",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // Current Password
              Obx(
                () => TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent.value,
                  decoration: InputDecoration(
                    labelText: "លេខសម្ងាត់បច្ចុប្បន្ន",
                    hintText: "បញ្ចូលលេខសម្ងាត់បច្ចុប្បន្ន",
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: obscureCurrent.toggle,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // New Password
              Obx(
                () => TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew.value,
                  decoration: InputDecoration(
                    labelText: "លេខសម្ងាត់ថ្មី",
                    hintText: "បញ្ចូលលេខសម្ងាត់ថ្មី",
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: obscureNew.toggle,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Confirm Password
              Obx(
                () => TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm.value,
                  decoration: InputDecoration(
                    labelText: "បញ្ជាក់លេខសម្ងាត់ថ្មី",
                    hintText: "បញ្ចូលលេខសម្ងាត់ថ្មីឡើងវិញ",
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: obscureConfirm.toggle,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: isUpdatingPassword.value
                        ? null
                        : _submitChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isUpdatingPassword.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "ធ្វើបច្ចុប្បន្នភាពលេខសម្ងាត់",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _submitChangePassword() async {
    final oldPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar(
        "Error",
        "New passwords do not match",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPassword.length < 6) {
      Get.snackbar(
        "Error",
        "Password must be at least 6 characters long",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isUpdatingPassword.value = true;
      await _authService.changePasswordService(
        username: username.value,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      Get.back(); // Close bottom sheet
      Get.snackbar(
        "Success",
        "Password updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update password. Please check current password.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdatingPassword.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authService.logoutService();
    } catch (e) {
      debugPrint("Failed to logout on backend: $e");
    } finally {
      final box = GetStorage();
      box.remove('token');
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
