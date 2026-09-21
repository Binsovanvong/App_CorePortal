part of 'setting_view.dart';

class SettingViewController extends GetxController {
  final AuthService _authService = AuthService();

  final userName = "Loading...".obs;
  final username = "".obs;
  final userPhoto = "".obs;
  final isLoading = false.obs;
  final bureauName = ''.obs;

  // Real-time grid metrics split between Institution, Department, and Status
  final userInstitution = "—".obs;
  final userDepartment = "—".obs;
  final employmentStatus = "—".obs;

  final allUsersList = <Map<String, dynamic>>[].obs;

  bool _isAdmin = false;

  @override
  void onInit() {
    super.onInit();
    updateRoleDisplay();
    loadCompleteProfileDashboard();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> loadCompleteProfileDashboard() async {
    try {
      isLoading.value = true;

      // Step 1: Download basic profile mapping safely (This gets your Khmer names!)
      await getProfileData();

      // Step 2: Fetch extra details like Employment Status
      await fetchNormalUserEmploymentData();
    } catch (e) {
      debugPrint("Error loading profile layout: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getProfileData() async {
    try {
      final rawData = await _authService.fetchProfile();

      if (rawData != null && rawData is Map) {
        // Safely unwrap data['user'] or data['data'] if nested
        final Map<String, dynamic> data = rawData['user'] is Map
            ? Map<String, dynamic>.from(rawData['user'])
            : rawData['data'] is Map
                ? Map<String, dynamic>.from(rawData['data'])
                : Map<String, dynamic>.from(rawData);

        userName.value =
            data['displayName'] ?? data['display_name'] ?? "No Name";
        username.value = data['username'] ?? "";
        final box = GetStorage();
        if (username.value.isNotEmpty) {
          box.write('username', username.value);
        }
        if (userName.value.isNotEmpty && userName.value != "No Name") {
          box.write('user_display_name', userName.value);
          box.write('displayName', userName.value);
        }

        // Read the populated Khmer names directly from the profile response
        if (data['generalDepartmentNameKh'] != null &&
            data['generalDepartmentNameKh'].toString().isNotEmpty) {
          userInstitution.value = data['generalDepartmentNameKh'];
        } else if (data['generalDepartmentName'] != null &&
            data['generalDepartmentName'].toString().isNotEmpty) {
          userInstitution.value = data['generalDepartmentName'];
        }

        if (data['departmentNameKh'] != null &&
            data['departmentNameKh'].toString().isNotEmpty) {
          userDepartment.value = data['departmentNameKh'];
        } else if (data['departmentName'] != null &&
            data['departmentName'].toString().isNotEmpty) {
          userDepartment.value = data['departmentName'];
        }

        if (data['bureauNameKh'] != null &&
            data['bureauNameKh'].toString().isNotEmpty) {
          bureauName.value = data['bureauNameKh'];
        } else if (data['bureauName'] != null &&
            data['bureauName'].toString().isNotEmpty) {
          bureauName.value = data['bureauName'];
        }

        // Save user profile ID for gateway queries
        final profileId =
            data['userProfileUserId'] ?? data['id'] ?? data['sub'];
        if (profileId != null && profileId.toString().isNotEmpty) {
          final box = GetStorage();
          await box.write('userProfileUserId', profileId.toString());
        }

        // Extract employment status or employmentInfos directly from profile if present
        final dynamic empInfos = data['employmentInfos'] ??
            data['employments'] ??
            data['employment_infos'] ??
            rawData['employmentInfos'];
        if (empInfos is List && empInfos.isNotEmpty) {
          final firstEmp = empInfos.first;
          if (firstEmp is Map) {
            final rawStatus = (firstEmp['employmentStatus'] ??
                    data['employmentStatus'] ??
                    data['status'] ??
                    '')
                .toString();
            if (rawStatus.isNotEmpty) {
              _setFormattedEmploymentStatus(rawStatus);
            }
            if (bureauName.value.isEmpty || bureauName.value == "—") {
              final b = (firstEmp['bureauNameKh'] ?? firstEmp['bureauName'] ?? '')
                  .toString()
                  .trim();
              if (b.isNotEmpty) bureauName.value = b;
            }
          }
        } else if (data['employmentStatus'] != null &&
            data['employmentStatus'].toString().isNotEmpty) {
          _setFormattedEmploymentStatus(data['employmentStatus'].toString());
        } else if (data['status'] != null &&
            data['status'].toString().isNotEmpty) {
          _setFormattedEmploymentStatus(data['status'].toString());
        }

        // Save real roles & permissions from profile into storage & controller
        final List rolesList = data['roles'] ?? [];
        final List permsList = data['permissions'] ?? [];
        if (rolesList.isNotEmpty) {
          await box.write('roles', rolesList);
        }
        if (permsList.isNotEmpty) {
          await box.write('permissions', permsList);
        }

        final normalized = [
          ...rolesList.map((e) => e.toString().toLowerCase().trim()),
          ...permsList.map((e) => e.toString().toLowerCase().trim()),
        ];

        final bool isAdm = normalized.any(
          (r) =>
              r == 'admin' ||
              r == 'administrator' ||
              r == 'portal_administrator' ||
              r == 'general_department_admin' ||
              r == 'general_department' ||
              r == 'portal_admin' ||
              r == 'gddtm_admin' ||
              r.contains('general_department') ||
              r.contains('administrator') ||
              r.contains('app_manage') ||
              r.contains('user_manage'),
        );

        _isAdmin = isAdm;
        isAdminUser.value = isAdm;
        await box.write('isAdmin', _isAdmin);
        updateRoleDisplay();
        if (Get.isRegistered<NavController>()) {
          Get.find<NavController>().checkAdminRole();
        }

        final profileMap = data['profile'];
        if (profileMap != null && profileMap is Map) {
          userPhoto.value = profileMap['avatar'] ?? profileMap['photo'] ?? "";
        }
      }
    } catch (e) {
      debugPrint("Failed to load standard account info: $e");
    }
  }

  void _setFormattedEmploymentStatus(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty || clean == "—") return;
    final upper = clean.toUpperCase();
    if (upper == "SUSPENDED" || upper.contains("SUSPEND")) {
      employmentStatus.value = "ផ្អាកការងារបណ្តោះអាសន្ន (Suspended)";
    } else if (upper == "ACTIVE" || upper == "សកម្ម" || upper == "APPROVED") {
      employmentStatus.value = "កំពុងបម្រើការងារ (Active)";
    } else if (upper == "TERMINATED" || upper.contains("TERMINAT")) {
      employmentStatus.value = "ឈប់បម្រើការងារ (Terminated)";
    } else {
      employmentStatus.value = clean;
    }
  }

  /// Fetch employment details to get the Status and Bureau configuration mappings safely
  Future<void> fetchNormalUserEmploymentData() async {
    try {
      final box = GetStorage();
      final targetUserId = box.read('userProfileUserId')?.toString();
      final response =
          await _authService.fetchMyEmploymentInfos(userId: targetUserId);
      debugPrint("👉 Employment Info Payload: $response");

      List employmentList = [];
      if (response is List) {
        employmentList = response;
      } else if (response is Map) {
        employmentList =
            response['value'] ?? response['data'] ?? response['items'] ?? [];
      }

      if (employmentList.isNotEmpty) {
        // 🟢 FIX: Handle the Array/List structure [ { ... } ] cleanly from the first row index
        final Map<String, dynamic> primaryRecord = Map<String, dynamic>.from(
          employmentList[0],
        );

        // Only fallback to employment-infos values if the main profile was empty
        if (userInstitution.value == "—" || userInstitution.value.isEmpty) {
          userInstitution.value =
              primaryRecord['generalDepartmentNameKh'] ??
              primaryRecord['generalDepartmentName'] ??
              "—";
        }

        if (userDepartment.value == "—" || userDepartment.value.isEmpty) {
          userDepartment.value =
              primaryRecord['departmentNameKh'] ??
              primaryRecord['departmentName'] ??
              "—";
        }

        // 🟢 FIX: Populate bureau values using dynamic fallbacks targeting the correct array payload keys
        final bName = (primaryRecord['bureauNameKh'] ??
                primaryRecord['bureauName'] ??
                '')
            .toString()
            .trim();
        if (bName.isNotEmpty &&
            (bureauName.value.isEmpty || bureauName.value == "—")) {
          bureauName.value = bName;
        }

        // Map the API status to a clean readable Khmer label
        final rawStatus = (primaryRecord['employmentStatus'] ?? "").toString();
        if (rawStatus.isNotEmpty) {
          _setFormattedEmploymentStatus(rawStatus);
        }
      }
    } catch (e) {
      debugPrint(
        "Gracefully intercepted employment API notice. Retaining existing values: $e",
      );
    }
  }

  Future<void> fetchAllBackendUsers() async {
    try {
      dynamic response;
      try {
        response = await _authService.apiService.get(
          endpoint: '/api/mobile/admin/user-profiles?page=0&size=1000',
        );
      } catch (e) {
        debugPrint("User directory fetch notice: $e");
      }

      if (response != null) {
        List rawUsers = [];
        if (response is List) {
          rawUsers = response;
        } else if (response is Map) {
          final data =
              response['value'] ?? response['data'] ?? response['items'] ?? [];
          if (data is List) rawUsers = data;
        }

        final parsedUsers = rawUsers.map<Map<String, dynamic>>((usr) {
          final hasEmployment =
              usr['employmentInfos'] != null &&
              (usr['employmentInfos'] as List).isNotEmpty;
          final emp = hasEmployment ? usr['employmentInfos'][0] : null;

          return {
            'username': usr['username'] ?? '',
            'institutionName': emp != null
                ? (emp['generalDepartmentNameKh'] ??
                      emp['generalDepartmentName'] ??
                      '—')
                : '—',
            'departmentName': emp != null
                ? (emp['departmentNameKh'] ?? emp['departmentName'] ?? '—')
                : '—',
            'bureauName': emp != null
                ? (emp['bureauNameKh'] ?? emp['bureauName'] ?? '')
                : '',
          };
        }).toList();

        allUsersList.assignAll(parsedUsers);

        final currentUserRecord = parsedUsers.firstWhere(
          (u) => u['username'] == username.value,
          orElse: () => {},
        );

        if (currentUserRecord.isNotEmpty) {
          userInstitution.value = currentUserRecord['institutionName'];
          userDepartment.value = currentUserRecord['departmentName'];
          bureauName.value = currentUserRecord['bureauName'];
        }
      }
    } catch (e) {
      debugPrint("Admin directory fetch error: $e");
    }
  }

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isUpdatingPassword = false.obs;
  final passwordStrength = 0.obs;

  void _updatePasswordStrength(String password) {
    if (password.isEmpty) {
      passwordStrength.value = 0;
      return;
    }
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) {
      passwordStrength.value = 1;
    } else if (score <= 3) {
      passwordStrength.value = 2;
    } else {
      passwordStrength.value = 3;
    }
  }

  void changePassword() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    isUpdatingPassword.value = false;
    passwordStrength.value = 0;

    final obscureCurrent = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(Get.context!).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 2, bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header: Icon + Title/Subtitle + Close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'change_password'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'change_password_desc'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: Color(0xFF64748B),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Security Guideline Banner Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF2563EB),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'security_level'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'password_rule_desc'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11.5,
                              color: const Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 1. Current Password Label
              Text(
                'current_password'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // 1. Current Password Input
              Obx(
                () => TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent.value,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'enter_current_password_hint'.tr,
                    hintStyle: GoogleFonts.kantumruyPro(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: obscureCurrent.toggle,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. New Password Label
              Text(
                'new_password'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // 2. New Password Input
              Obx(
                () => TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew.value,
                  onChanged: _updatePasswordStrength,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'enter_new_password_hint'.tr,
                    hintStyle: GoogleFonts.kantumruyPro(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: obscureNew.toggle,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Password Strength Indicator Row
              Obx(() {
                final strength = passwordStrength.value;
                Color bar1 = const Color(0xFFCBD5E1);
                Color bar2 = const Color(0xFFCBD5E1);
                Color bar3 = const Color(0xFFCBD5E1);
                String label = 'strength_weak'.tr;
                Color labelColor = const Color(0xFFEF4444);

                if (strength == 1) {
                  bar1 = const Color(0xFFEF4444);
                  label = 'strength_weak'.tr;
                  labelColor = const Color(0xFFEF4444);
                } else if (strength == 2) {
                  bar1 = const Color(0xFFF59E0B);
                  bar2 = const Color(0xFFF59E0B);
                  label = 'strength_medium'.tr;
                  labelColor = const Color(0xFFF59E0B);
                } else if (strength == 3) {
                  bar1 = const Color(0xFF10B981);
                  bar2 = const Color(0xFF10B981);
                  bar3 = const Color(0xFF10B981);
                  label = 'strength_strong'.tr;
                  labelColor = const Color(0xFF10B981);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: bar1,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: bar2,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: bar3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${'password_strength'.tr} ',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            label,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),

              // 3. Confirm New Password Label
              Text(
                'confirm_new_password'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // 3. Confirm New Password Input
              Obx(
                () => TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm.value,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'enter_confirm_password_hint'.tr,
                    hintStyle: GoogleFonts.kantumruyPro(
                      fontSize: 13.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: obscureConfirm.toggle,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button: "ធ្វើបច្ចុប្បន្នភាពលេខសម្ងាត់ ➔"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: isUpdatingPassword.value
                        ? null
                        : _submitChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: isUpdatingPassword.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'update_password'.tr,
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  bool _validateNewPassword(String password, String oldPassword) {
    if (password.length < 8) {
      CustomSnackbar.showWarning(
        message: 'password_length_error'.tr,
      );
      return false;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      CustomSnackbar.showWarning(
        message: 'password_uppercase_error'.tr,
      );
      return false;
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      CustomSnackbar.showWarning(
        message: 'password_lowercase_error'.tr,
      );
      return false;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      CustomSnackbar.showWarning(
        message: 'password_number_error'.tr,
      );
      return false;
    }

    if (!RegExp(r'[!@#\$&*~%^()_\+=\-\[\]{}|;:<>?\/]').hasMatch(password)) {
      CustomSnackbar.showWarning(
        message: 'password_special_error'.tr,
      );
      return false;
    }

    if (username.value.isNotEmpty &&
        password.toLowerCase().contains(username.value.toLowerCase())) {
      CustomSnackbar.showWarning(
        message: 'password_username_error'.tr,
      );
      return false;
    }

    if (password == oldPassword) {
      CustomSnackbar.showWarning(
        message: 'password_same_as_old_error'.tr,
      );
      return false;
    }

    return true;
  }

  Future<void> _submitChangePassword() async {
    final oldPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      CustomSnackbar.showWarning(
        message: 'fill_all_fields'.tr,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackbar.showError(
        message: 'password_not_match'.tr,
      );
      return;
    }

    if (!_validateNewPassword(newPassword, oldPassword)) {
      return;
    }

    String targetUsername = username.value.trim();
    if (targetUsername.isEmpty) {
      final box = GetStorage();
      targetUsername = (box.read('username') ?? '').toString().trim();
    }
    if (targetUsername.isEmpty) {
      final token = await ApiClient.getAccessToken();
      targetUsername = ApiClient.extractUsernameFromToken(token)?.trim() ?? '';
    }

    try {
      isUpdatingPassword.value = true;
      await _authService.changePasswordService(
        username: targetUsername,
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      Get.back();
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      passwordStrength.value = 0;
      CustomSnackbar.showSuccess(
        message: 'password_changed_success'.tr,
      );
    } catch (e) {
      debugPrint("CHANGE PASSWORD IN SETTINGS ERROR: $e");
      String errorMessage = 'password_change_failed'.tr;
      if (e is DioException) {
        debugPrint(
          "CHANGE PASSWORD STATUS: ${e.response?.statusCode} - DATA: ${e.response?.data}",
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
      isUpdatingPassword.value = false;
    }
  }

  Future<void> testBiometric() async {
    final bool canAuth = await BiometricService.canAuthenticate();
    if (!canAuth) {
      CustomSnackbar.showWarning(
        title: 'Face ID / Touch ID',
        message: 'biometric_not_supported'.tr,
      );
      return;
    }
    final result = await BiometricService.authenticate();
    switch (result) {
      case BiometricResult.success:
        CustomSnackbar.showSuccess(
          title: 'Face ID / Touch ID',
          message: 'biometric_auth_success'.tr,
        );
      case BiometricResult.failed:
        CustomSnackbar.showError(
          title: 'Face ID / Touch ID',
          message: 'biometric_failed'.tr,
        );
      case BiometricResult.cancelled:
        break;
      case BiometricResult.unavailable:
        CustomSnackbar.showError(
          title: 'Face ID / Touch ID',
          message: 'biometric_unavailable'.tr,
        );
    }
  }

  final isAdminUser = false.obs;
  final userRoleDisplay = "portal_user".obs;

  void updateRoleDisplay() {
    final box = GetStorage();
    final rawRoles = box.read('roles');
    final List list = (rawRoles is List && rawRoles.isNotEmpty) ? rawRoles : [];
    final roles = list.map((e) => e.toString().toLowerCase().trim()).toList();

    if (roles.contains('general_department_admin') ||
        roles.contains('general_department') ||
        roles.contains('gddtm_admin') ||
        roles.any((r) => r.contains('general_department'))) {
      userRoleDisplay.value = 'general_department_admin';
      return;
    }
    if (roles.contains('portal_administrator') ||
        roles.contains('administrator') ||
        roles.contains('admin') ||
        roles.contains('portal_admin') ||
        roles.any((r) => r.contains('administrator'))) {
      userRoleDisplay.value = 'portal_administrator';
      return;
    }
    userRoleDisplay.value = 'portal_user';
  }

  bool get hasAdminRole {
    if (isAdminUser.value) return true;
    final box = GetStorage();
    final isAdm = box.read('isAdmin');
    if (isAdm == true) return true;

    final rawRoles = box.read('roles');
    final List list = (rawRoles is List && rawRoles.isNotEmpty) ? rawRoles : [];
    final roles = list.map((e) => e.toString().toLowerCase().trim()).toList();

    return roles.any((r) =>
        r == 'admin' ||
        r == 'administrator' ||
        r == 'portal_administrator' ||
        r == 'general_department_admin' ||
        r == 'general_department' ||
        r == 'portal_admin' ||
        r == 'gddtm_admin' ||
        r.contains('general_department') ||
        r.contains('administrator'));
  }

  void goToAdmin() {
    Get.toNamed(AppRoutes.admin);
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authService.logout();
    } catch (e) {
      debugPrint("Failed to logout: $e");
    } finally {
      final box = GetStorage();
      box.remove('token');
      box.remove('isAdmin');
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
