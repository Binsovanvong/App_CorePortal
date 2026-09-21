import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/services/biometric_service.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/api_client.dart';

import '../../routes/page_route.dart';

part 'setting_binding.dart';
part 'setting_controller.dart';

class SettingView extends GetView<SettingViewController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                    Color(0xFFEFF4FB),
                  ],
                ),
              ),
            ),
          ),

          // Subtle soft bottom curve wave matching concept
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 240,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SubtleBackgroundWavePainter(),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Profile Hero Card
                        _buildProfileHeroCard(),
                        const SizedBox(height: 14),

                        // 2. My Account Card ("គណនីរបស់ខ្ញុំ")
                        _buildMyAccountCard(),
                        const SizedBox(height: 14),

                        // 3. Language Selection Card ("ភាសា")
                        _buildLanguageSelectionCard(),
                        const SizedBox(height: 14),

                        // 4. Security & Privacy Card ("សុវត្ថិភាព និងភាពឯកជន")
                        _buildSecurityActionsCard(context),
                        const SizedBox(height: 14),

                        // 5. Standalone Logout Card ("ចាកចេញពីគណនី")
                        _buildLogoutCard(context),
                        const SizedBox(height: 24),

                        // 6. Version info footer
                        _buildAppFooter(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clean, modern open header with title & subtitle
  Widget _buildHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF0F172A),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'settings'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'settings_subtitle'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Profile Hero Card (Concept Vibrant Blue)
  Widget _buildProfileHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _showPersonalInfoDialog,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Solid/Gradient Blue Circle Avatar with initials
                Obx(() {
                  final photo = controller.userPhoto.value;
                  final name = controller.userName.value;
                  final initials = _getInitials(name);

                  return Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: photo.isNotEmpty
                          ? Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  _buildInitialsAvatar(initials),
                            )
                          : _buildInitialsAvatar(initials),
                    ),
                  );
                }),
                const SizedBox(width: 16),

                // Name, Email, and Verified Role Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => Text(
                          controller.userName.value,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Obx(
                        () {
                          final uname = controller.username.value;
                          return Text(
                            uname.isNotEmpty ? uname : "—",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      const SizedBox(height: 7),

                      // Role Pill Badge (Concept Blue)
                      Obx(() {
                        final String roleKey = controller.userRoleDisplay.value;
                        final String roleLabel = roleKey.tr;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE).withOpacity(0.7),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13.5,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4.5),
                              Flexible(
                                child: Text(
                                  roleLabel,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty || name == "Loading...") return "U";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final f = parts[0].isNotEmpty ? parts[0].characters.first : '';
      final s = parts[1].isNotEmpty ? parts[1].characters.first : '';
      return '$f$s'.toUpperCase();
    }
    return name.trim().characters.take(2).toString().toUpperCase();
  }

  /// 2. My Account Card ("គណនីរបស់ខ្ញុំ")
  Widget _buildMyAccountCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _showPersonalInfoDialog,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'my_account'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'my_account_subtitle'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3. Language Selection Card ("ភាសា")
  Widget _buildLanguageSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'language'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'choose_language_desc'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two Language Options
          Obx(() {
            final currentLang = LocalizationService.currentLanguageCode.value;
            final isKh = currentLang == 'km';

            return Row(
              children: [
                // Khmer Option
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => LocalizationService.changeLanguage('km'),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: isKh
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isKh
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: isKh ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇰🇭', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'khmer'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 14.5,
                                fontWeight: isKh
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (isKh) ...[
                              const Spacer(),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // English Option
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => LocalizationService.changeLanguage('en'),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: !isKh
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isKh
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: !isKh ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'english'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: !isKh
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (!isKh) ...[
                              const Spacer(),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// 4. Security & Privacy Card ("សុវត្ថិភាព និងភាពឯកជន")
  Widget _buildSecurityActionsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'security_and_privacy'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'security_and_privacy_desc'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 4),

          // 1. Change Password Tile
          _buildSecurityTile(
            icon: Icons.lock_outline_rounded,
            title: 'change_password'.tr,
            onTap: controller.changePassword,
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),

          // 2. Notifications Tile
          _buildSecurityTile(
            icon: Icons.notifications_none_rounded,
            title: 'notification'.tr,
            onTap: () => Get.toNamed(AppRoutes.notification),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),

          // 3. Privacy Tile
          _buildSecurityTile(
            icon: Icons.verified_user_outlined,
            title: 'privacy'.tr,
            onTap: () => _showPrivacyDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 5. Standalone Logout Card ("ចាកចេញពីគណនី")
  Widget _buildLogoutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => showLogoutConfirmDialog(
            context,
            onConfirm: controller.logout,
          ),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'logout'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Privacy Information Modal Dialog
  void _showPrivacyDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'privacy_policy'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'privacy_desc'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'close'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Personal Info Modal Dialog
  void _showPersonalInfoDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'personal_info'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xffF1F5F9), thickness: 1),
              const SizedBox(height: 14),

              // Institution Row
              Obx(
                () => _buildInfoTile(
                  icon: Icons.account_balance_outlined,
                  iconBgColor: const Color(0xffE0F2FE),
                  iconColor: const Color(0xff0284C7),
                  label: 'institution'.tr,
                  value: controller.userInstitution.value,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(height: 1, color: Color(0xffF8FAFC), thickness: 1),
              ),

              // Department Row
              Obx(
                () => _buildInfoTile(
                  icon: Icons.domain_rounded,
                  iconBgColor: const Color(0xffFEF3C7),
                  iconColor: const Color(0xffD97706),
                  label: 'department'.tr,
                  value: controller.userDepartment.value,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(height: 1, color: Color(0xffF8FAFC), thickness: 1),
              ),

              // Bureau Row
              Obx(() {
                final bureau = controller.bureauName.value;
                return _buildInfoTile(
                  icon: Icons.apartment_rounded,
                  iconBgColor: const Color(0xffDCFCE7),
                  iconColor: const Color(0xff16A34A),
                  label: 'bureau'.tr,
                  value: bureau.isNotEmpty ? bureau : "—",
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(height: 1, color: Color(0xffF8FAFC), thickness: 1),
              ),

              // Employment Status Row
              Obx(() {
                final status = controller.employmentStatus.value;
                final isSuspended =
                    status.contains("Suspended") || status.contains("ផ្អាក");

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSuspended
                            ? const Color(0xffFEE2E2)
                            : const Color(0xffDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuspended
                            ? Icons.pause_circle_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: isSuspended
                            ? const Color(0xffDC2626)
                            : const Color(0xff16A34A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'employment_status'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              color: const Color(0xff64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSuspended
                                  ? const Color(0xffDC2626)
                                  : const Color(0xff16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSuspended
                            ? const Color(0xffFEF2F2)
                            : const Color(0xffF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSuspended
                              ? const Color(0xffF87171)
                              : const Color(0xff86EFAC),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isSuspended ? 'suspended'.tr : 'active'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSuspended
                              ? const Color(0xffDC2626)
                              : const Color(0xff16A34A),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'close'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  color: const Color(0xff64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'moi_service_app'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xff475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Version 1.0.0",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle soft background wave painter matching corporate mobile portal design
class _SubtleBackgroundWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFE2EDFB).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.45);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.65,
      size.height * 0.25,
      size.width,
      size.height * 0.45,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFE8F1FC).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.4,
      size.height * 0.45,
      size.width * 0.7,
      size.height * 0.75,
      size.width,
      size.height * 0.55,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
