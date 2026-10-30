import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/services/biometric_service.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/logout_dialog.dart';
import 'package:core_portal/widgets/password_requirements_card.dart';
import 'package:core_portal/widgets/portal_top_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/services/app_lock_service.dart';
import 'package:core_portal/theme/app_colors.dart';

import '../../routes/page_route.dart';

part 'setting_binding.dart';
part 'setting_controller.dart';

class SettingView extends GetView<SettingViewController> {
  const SettingView({super.key});

  static const bool showConnectedDevices = false;
  static const bool showNotifications = false;

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFAF9F6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Government Portal Header
            PortalTopAppBar(canPop: canPop),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      final bool isKh =
                          LocalizationService.currentLanguageCode.value == 'km';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // 2. Screen Title: | ការកំណត់
                          _buildScreenTitle(isKh),
                          const SizedBox(height: 16),

                          // 3. Profile Card (Avatar with double gold ring, Name, Role, Department)
                          _buildProfileHeroCard(isKh),
                          const SizedBox(height: 20),

                          // 4. Section 1: គណនី (Account)
                          _buildAccountSection(isKh),
                          const SizedBox(height: 20),

                          // 5. Section 2: ការជូនដំណឹង (Notifications) - Hidden
                          if (showNotifications) ...[
                            _buildNotificationSection(isKh),
                            const SizedBox(height: 20),
                          ],

                          // 6. Section 3: សុវត្ថិភាព និងភាពឯកជន (Security & Privacy)
                          _buildSecuritySection(context, isKh),
                          const SizedBox(height: 20),

                          // 7. Logout Card (ចាកចេញពីគណនី)
                          _buildLogoutCard(context, isKh),
                          const SizedBox(height: 24),

                          // 8. Version Info Footer
                          _buildAppFooter(),

                          // Bottom padding to clear floating nav bar
                          const SizedBox(height: 120),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // ---------------------------------------------------------------------------
  // Screen Title: | ការកំណត់
  // ---------------------------------------------------------------------------
  Widget _buildScreenTitle(bool isKh) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3.5,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.royalGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isKh ? 'ការកំណត់' : 'Settings',
          style: isKh
              ? GoogleFonts.kantumruyPro(
                  color: const Color(0xFF1E293B),
                  fontSize: 18.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                )
              : GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 17.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Hero Card (Double-ring Avatar, Name, Position, Department)
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeroCard(bool isKh) {
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
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
                // Avatar with outer gold ring and inner solid gold circle
                Obx(() {
                  final photo = controller.userPhoto.value;
                  String initial = 'B';
                  final name = controller.userName.value.trim();
                  if (name.isNotEmpty &&
                      name != "Loading..." &&
                      name != "No Name") {
                    initial = name.startsWith('លោក ')
                        ? (name.length > 5
                            ? name.substring(4, 5).toUpperCase()
                            : 'B')
                        : name.substring(0, 1).toUpperCase();
                  } else if (controller.username.value.isNotEmpty) {
                    initial =
                        controller.username.value.substring(0, 1).toUpperCase();
                  }

                  return Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.royalGold,
                        width: 2.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(3.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.royalGold,
                      ),
                      child: ClipOval(
                        child: photo.isNotEmpty
                            ? Image.network(
                                photo,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 16),

                // Name, Role, Department
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        String displayName = controller.userName.value.trim();
                        if (displayName.isEmpty ||
                            displayName == "Loading..." ||
                            displayName == "No Name") {
                          displayName = controller.username.value.isNotEmpty
                              ? controller.username.value
                              : "bin sovanvong";
                        }
                        return Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      const SizedBox(height: 3),
                      Obx(() {
                        String role = controller.userRoleDisplay.value;
                        String roleText = role == 'portal_user'
                            ? (isKh ? 'មន្ត្រីរដ្ឋបាល' : 'Administrative Officer')
                            : role.tr;
                        return Text(
                          roleText,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      const SizedBox(height: 2),
                      Obx(() {
                        String dept = controller.userInstitution.value.trim();
                        if (dept.isEmpty || dept == "—") {
                          dept = controller.userDepartment.value.trim();
                        }
                        if (dept.isEmpty || dept == "—") {
                          dept = isKh
                              ? 'អគ្គនាយកដ្ឋានរដ្ឋបាល'
                              : 'General Department of Administration';
                        }
                        return Text(
                          dept,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1: គណនី (Account)
  // ---------------------------------------------------------------------------
  Widget _buildAccountSection(bool isKh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isKh ? 'គណនី' : 'account'.tr),
        _buildSectionCard(
          children: [
            // Personal Info
            _buildSettingTile(
              iconWidget: _buildSquircleIcon(icon: Icons.person_outline_rounded),
              title: 'personal_info'.tr,
              trailing: _buildChevronTrailing(),
              onTap: _showPersonalInfoDialog,
            ),
            if (showConnectedDevices) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              // Logged-in Devices
              _buildSettingTile(
                iconWidget: _buildSquircleIcon(icon: Icons.phone_iphone_rounded),
                title: isKh ? 'ឧបករណ៍ដែលបានចូល' : 'connected_devices'.tr,
                trailing: _buildChevronTrailing(text: isKh ? '២' : '2'),
                onTap: () => _showConnectedDevicesDialog(isKh),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2: ការជូនដំណឹង (Notifications)
  // ---------------------------------------------------------------------------
  Widget _buildNotificationSection(bool isKh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isKh ? 'ការជូនដំណឹង' : 'notification'.tr),
        _buildSectionCard(
          children: [
            // Receive Notifications
            Obx(
              () => _buildSettingTile(
                iconWidget: _buildSquircleIcon(
                  icon: Icons.notifications_none_rounded,
                ),
                title: isKh ? 'ទទួលការជូនដំណឹង' : 'receive_notifications'.tr,
                subtitle: isKh
                    ? 'ពីកម្មវិធី និងអង្គភាព'
                    : 'receive_notifications_desc'.tr,
                trailing: _buildCustomSwitch(
                  value: controller.receiveNotifications.value,
                  onChanged: controller.toggleReceiveNotifications,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            // Notification Sound
            Obx(
              () => _buildSettingTile(
                iconWidget: _buildSquircleIcon(
                  icon: Icons.volume_up_outlined,
                ),
                title: isKh ? 'សំឡេងជូនដំណឹង' : 'notification_sound'.tr,
                subtitle: isKh
                    ? 'បន្លឺសំឡេងពេលមានដំណឹងថ្មី'
                    : 'notification_sound_desc'.tr,
                trailing: _buildCustomSwitch(
                  value: controller.notificationSound.value,
                  onChanged: controller.toggleNotificationSound,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3: សុវត្ថិភាព និងភាពឯកជន (Security & Privacy)
  // ---------------------------------------------------------------------------
  Widget _buildSecuritySection(BuildContext context, bool isKh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          isKh ? 'សុវត្ថិភាព និងភាពឯកជន' : 'security_and_privacy'.tr,
        ),
        _buildSectionCard(
          children: [
            // Change Password
            _buildSettingTile(
              iconWidget: _buildSquircleIcon(
                icon: Icons.lock_outline_rounded,
              ),
              title: 'change_password'.tr,
              trailing: _buildChevronTrailing(),
              onTap: controller.changePassword,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            // Lock App Now
            _buildSettingTile(
              iconWidget: _buildSquircleIcon(
                icon: Icons.screen_lock_portrait_rounded,
              ),
              title: 'lock_app_now'.tr,
              trailing: _buildChevronTrailing(),
              onTap: () {
                if (Get.isRegistered<AppLockService>()) {
                  AppLockService.to.lockNow();
                }
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            // Privacy Policy
            _buildSettingTile(
              iconWidget: _buildSquircleIcon(
                icon: Icons.verified_user_outlined,
              ),
              title: 'privacy'.tr,
              trailing: _buildChevronTrailing(),
              onTap: () => _showPrivacyDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Standalone Logout Card (ចាកចេញពីគណនី)
  // ---------------------------------------------------------------------------
  Widget _buildLogoutCard(BuildContext context, bool isKh) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showLogoutConfirmDialog(
              context,
              onConfirm: controller.logout,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'logout'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Helper Components
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.kantumruyPro(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: AppColors.royalGold,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSquircleIcon({
    IconData? icon,
    Widget? child,
    Color bgColor = const Color(0xFFF6EEDB),
    Color iconColor = AppColors.royalGold,
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: child ??
          Icon(
            icon,
            color: iconColor,
            size: 21,
          ),
    );
  }

  Widget _buildSettingTile({
    required Widget iconWidget,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChevronTrailing({String? text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (text != null && text.isNotEmpty) ...[
          Text(
            text,
            style: GoogleFonts.kantumruyPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
        ],
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF64748B),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? AppColors.royalGold : const Color(0xFFCBD5E1),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modal Dialogs (Connected Devices, Language)
  // ---------------------------------------------------------------------------
  void _showConnectedDevicesDialog(bool isKh) {
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6EEDB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEDE3CE),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.devices_rounded,
                          color: AppColors.royalGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isKh ? 'ឧបករណ៍ដែលបានចូល' : 'connected_devices'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
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
              const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),
              const SizedBox(height: 14),

              // Device 1: Current Mobile Device
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_iphone_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKh
                              ? 'ស្មាតហ្វូន (ឧបករណ៍នេះ)'
                              : 'Smartphone (This Device)',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Core Portal Mobile App',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
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
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF86EFAC),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isKh ? 'កំពុងសកម្ម' : 'Active now',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: Color(0xFFF8FAFC),
                  thickness: 1,
                ),
              ),

              // Device 2: Web Session
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.laptop_mac_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKh
                              ? 'កុំព្យូទ័រ (Web Portal)'
                              : 'Workstation (Web Portal)',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chrome on Windows',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isKh ? 'ម្សិលមិញ' : 'Yesterday',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalGold,
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
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EEDB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEDE3CE),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.royalGold,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'privacy_policy'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
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
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalGold,
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
                          color: const Color(0xFFF6EEDB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEDE3CE),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.royalGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'personal_info'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
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
              const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1),
              const SizedBox(height: 14),

              // Institution Row
              Obx(
                () => _buildInfoTile(
                  icon: Icons.account_balance_outlined,
                  iconBgColor: const Color(0xFFF6EEDB),
                  iconColor: AppColors.royalGold,
                  label: 'institution'.tr,
                  value: controller.userInstitution.value,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(height: 1, color: Color(0xFFF8FAFC), thickness: 1),
              ),

              // Department Row
              Obx(
                () => _buildInfoTile(
                  icon: Icons.domain_rounded,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  label: 'department'.tr,
                  value: controller.userDepartment.value,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(height: 1, color: Color(0xFFF8FAFC), thickness: 1),
              ),

              // Bureau Row
              Obx(() {
                final bureau = controller.bureauName.value;
                return _buildInfoTile(
                  icon: Icons.apartment_rounded,
                  iconBgColor: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  label: 'bureau'.tr,
                  value: bureau.isNotEmpty ? bureau : "—",
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child:
                    Divider(height: 1, color: Color(0xFFF8FAFC), thickness: 1),
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
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuspended
                            ? Icons.pause_circle_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: isSuspended
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
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
                              color: const Color(0xFF64748B),
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
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
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
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSuspended
                              ? const Color(0xFFF87171)
                              : const Color(0xFF86EFAC),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isSuspended ? 'suspended'.tr : 'active'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSuspended
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
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
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalGold,
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
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
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
              color: const Color(0xFF475569),
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
