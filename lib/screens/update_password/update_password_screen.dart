import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';

/// Screen displayed when Keycloak / BFF requires an immediate password update
/// (e.g., HTTP 409 with detail.code == "update_password_required").
///
/// Security: The [ticket] is maintained STRICTLY IN MEMORY and is never
/// persisted into storage (GetStorage, SharedPreferences, SecureStorage)
/// nor logged into console output.
class UpdatePasswordScreen extends StatefulWidget {
  final String ticket;
  final String? username;

  const UpdatePasswordScreen({
    super.key,
    required this.ticket,
    this.username,
  });

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      CustomSnackbar.showError(message: 'pwd_rule_length'.tr);
      return false;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      CustomSnackbar.showError(message: 'pwd_rule_upper'.tr);
      return false;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      CustomSnackbar.showError(message: 'pwd_rule_lower'.tr);
      return false;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      CustomSnackbar.showError(message: 'pwd_rule_number'.tr);
      return false;
    }
    if (!RegExp(r'[!@#\$&*~%^()_\+=\-\[\]{}|;:<>?\/]').hasMatch(password)) {
      CustomSnackbar.showError(message: 'pwd_rule_special'.tr);
      return false;
    }
    final user = widget.username?.trim();
    if (user != null &&
        user.isNotEmpty &&
        password.toLowerCase().contains(user.toLowerCase())) {
      CustomSnackbar.showError(message: 'pwd_rule_no_username'.tr);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      CustomSnackbar.showError(message: 'pwd_rule_empty'.tr);
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackbar.showError(message: 'pwd_rule_mismatch'.tr);
      return;
    }

    if (!_validatePassword(newPassword)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.dio.post(
        '/api/mobile/auth/update-password',
        data: {
          'ticket': widget.ticket,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      // On HTTP 200, save tokens and enter the authenticated app
      if (response.statusCode == 200) {
        final data = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : null;
        final token = data?['access_token']?.toString() ??
            data?['token']?.toString() ??
            data?['data']?['access_token']?.toString() ??
            data?['data']?['token']?.toString();

        if (token != null && token.isNotEmpty) {
          await ApiClient.saveTokens(
            response.data,
            dioHeaders: response.headers,
          );
          CustomSnackbar.showSuccess(message: 'password_changed_success'.tr);
          Get.offAllNamed(AppRoutes.mainPage);
          return;
        }

        // Check if server returned password_updated_login_failed in 200 body
        final code = (data?['code'] ?? data?['detail']?['code'])?.toString();
        if (code == 'password_updated_login_failed') {
          CustomSnackbar.showInfo(
            message: 'pwd_updated_login_again'.tr,
          );
          await ApiClient.logout();
          Get.offAllNamed(AppRoutes.login);
          return;
        }
      }
    } on DioException catch (error) {
      final response = error.response;
      final resData = response?.data;
      final detail = resData is Map ? resData['detail'] : null;
      final errorCode = (detail is Map
              ? detail['code']
              : (resData is Map ? resData['code'] : null))
          ?.toString();

      // On password_updated_login_failed, the password changed successfully;
      // return to login and use the new password.
      if (errorCode == 'password_updated_login_failed') {
        CustomSnackbar.showInfo(
          message: 'pwd_updated_login_again'.tr,
        );
        await ApiClient.logout();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      // Handle ordinary error states without logging sensitive ticket data
      String errorMessage = 'password_change_failed'.tr;
      bool returnToLogin = false;
      final statusCode = response?.statusCode;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          statusCode == 504) {
        errorMessage = 'pwd_update_timeout'.tr;
        returnToLogin = true;
      } else if (error.type == DioExceptionType.connectionError) {
        errorMessage = 'no_internet_error'.tr;
        returnToLogin = true;
      } else if (statusCode == 400) {
        returnToLogin = true;
        if (detail is Map && detail['message'] != null) {
          errorMessage = detail['message'].toString();
        } else {
          errorMessage = 'pwd_policy_failed'.tr;
        }
      } else if (statusCode == 401) {
        returnToLogin = true;
        errorMessage = 'pwd_session_expired'.tr;
      } else if (statusCode == 409) {
        returnToLogin = true;
        if (detail is Map && detail['message'] != null) {
          errorMessage = detail['message'].toString();
        } else {
          errorMessage = 'account_action_unsupported'.tr;
        }
      } else if (statusCode == 503) {
        returnToLogin = true;
        errorMessage = 'pwd_service_not_configured'.tr;
      } else if (detail != null) {
        if (detail is Map && detail['message'] != null) {
          errorMessage = detail['message'].toString();
        } else if (detail is String) {
          errorMessage = detail;
        }
      }

      CustomSnackbar.showError(message: errorMessage);

      if (returnToLogin) {
        await ApiClient.logout();
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      CustomSnackbar.showError(message: 'password_change_failed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Warning / Guideline Card matching user specification ─────────────────
  Widget _buildPasswordGuidelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Warning Icon Badge with Exclamation Mark
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE047).withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              '!',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Guideline Text Rules
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'must_change_password'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'password_guideline_rule1'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  'password_guideline_rule2'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  'password_guideline_rule3'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'password_guideline_example'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF163774),
      body: Obx(() {
        // Track language changes to instantly update all strings
        final _ = LocalizationService.currentLanguageCode.value;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: isKeyboardOpen
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF163774), Color(0xFF102652)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Navy Section (Ministry Emblem & Golden Titles)
                          Expanded(
                            child: SafeArea(
                              bottom: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 6,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Ministry Emblem
                                      Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFD4AF37),
                                            width: 2.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.20,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(3.5),
                                        child: ClipOval(
                                          child: Image.asset(
                                            "assets/img/about-moi-logo.png",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Ministry Title (Royal Gold Khmer)
                                      Text(
                                        'ក្រសួងមហាផ្ទៃ',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFD4AF37),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Ministry Subtitle (English - Royal Gold / Champagne)
                                      Text(
                                        'MINISTRY OF INTERIOR',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFDFBC66),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // White Rounded Bottom Card Container
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 20,
                                  offset: Offset(0, -6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.fromLTRB(
                              20,
                              16,
                              20,
                              bottomSafeArea > 0 ? bottomSafeArea + 6 : 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Page Title and Subtitle (Centered)
                                Center(
                                  child: Text(
                                    'change_password'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Center(
                                  child: Text(
                                    'for_first_login'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Guidelines Box (Warm Amber Card with Exclamation Badge)
                                _buildPasswordGuidelineCard(),

                                const SizedBox(height: 10),

                                // New Password Label & Field
                                Text(
                                  'new_password'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNewPassword,
                                  textInputAction: TextInputAction.next,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 14,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'enter_new_password'.tr,
                                    hintStyle: GoogleFonts.kantumruyPro(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 13.5,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 19,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                        size: 19,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNewPassword =
                                              !_obscureNewPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF163774),
                                        width: 1.8,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Confirm Password Label & Field
                                Text(
                                  'confirm_new_password'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 14,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'reenter_new_password'.tr,
                                    hintStyle: GoogleFonts.kantumruyPro(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 13.5,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 19,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF94A3B8),
                                        size: 19,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF163774),
                                        width: 1.8,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Primary Submit Button (Navy Gradient)
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF163774),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF94A3B8,
                                      ),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : Text(
                                            'btn_change_password'.tr,
                                            style: GoogleFonts.kantumruyPro(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // Cancel Button (Returns to Login)
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            await ApiClient.logout();
                                            Get.offAllNamed(AppRoutes.login);
                                          },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF64748B),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'cancel'.tr,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
