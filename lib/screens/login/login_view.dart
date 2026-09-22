import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  static const bool showLanguageSwitcher = false;
  static const bool showBiometricOptions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF163774),
      body: Obx(() {
        if (controller.isBiometricLockMode.value) {
          return _buildBiometricLockScreen(context);
        }
        return _buildLoginForm(context);
      }),
    );
  }

  // ─── Main Login Form (Official Corporate Navy Theme) ──────────────────────

  Widget _buildLoginForm(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3E82), Color(0xFF163774), Color(0xFF102652)],
        ),
      ),
      child: Stack(
        children: [
          // Main scrollable container
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section: Language switcher & Ministry Branding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showLanguageSwitcher) ...[
                            const SizedBox(height: 12),
                            // Language Switcher at Top Right
                            Align(
                              alignment: Alignment.topRight,
                              child: _buildDiscreetLanguageDropdown(),
                            ),
                            const SizedBox(height: 110),
                          ] else
                            const SizedBox(height: 149),

                          // Circular Logo Badge with double golden border
                          Container(
                            width: 174,
                            height: 174,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 3.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.22),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(5.5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFFEAB308,
                                  ).withOpacity(0.45),
                                  width: 1.1,
                                ),
                              ),
                              padding: const EdgeInsets.all(4.5),
                              child: ClipOval(
                                child: Image.asset(
                                  "assets/img/about-moi-logo.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ministry Title (Royal Gold Khmer)
                          Text(
                            'ក្រសួងមហាផ្ទៃ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD4AF37),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Ministry Subtitle (English - Royal Gold / Champagne)
                          Text(
                            'MINISTRY OF INTERIOR',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDFBC66),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Bottom Section: White Rounded Bottom Card
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 20,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Subtle bottom wave illustration inside card
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 110,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _BottomCardWavePainter(),
                              ),
                            ),
                          ),

                          // Content inside white card
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              28,
                              24,
                              bottomInset > 0 ? bottomInset + 16 : 28,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Title
                                Text(
                                  'welcome_title'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF163774),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Subtitle
                                Text(
                                  'login_hint_subtitle'.tr,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // 1. Email / Username Input
                                TextField(
                                  controller: controller.usernameController,
                                  textInputAction: TextInputAction.next,
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 14.5,
                                    color: const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF163774),
                                        width: 1.8,
                                      ),
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.only(
                                        left: 10,
                                        right: 12,
                                      ),
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF4FB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.mail_outline_rounded,
                                        color: Color(0xFF163774),
                                        size: 20,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 50,
                                      minHeight: 48,
                                    ),
                                    hintText: 'enter_email_hint'.tr,
                                    hintStyle: GoogleFonts.kantumruyPro(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 2. Password Input
                                Obx(
                                  () => TextField(
                                    controller: controller.passwordController,
                                    obscureText:
                                        controller.obscurePassword.value,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (!controller.isLoading.value) {
                                        controller.loginWithCredentials();
                                      }
                                    },
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 14.5,
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF163774),
                                          width: 1.8,
                                        ),
                                      ),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.only(
                                          left: 10,
                                          right: 12,
                                        ),
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF4FB),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Color(0xFF163774),
                                          size: 20,
                                        ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 50,
                                            minHeight: 48,
                                          ),
                                      suffixIcon: IconButton(
                                        splashRadius: 20,
                                        icon: Icon(
                                          controller.obscurePassword.value
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF64748B),
                                          size: 20,
                                        ),
                                        onPressed:
                                            controller.obscurePassword.toggle,
                                      ),
                                      hintText: 'enter_password_hint'.tr,
                                      hintStyle: GoogleFonts.kantumruyPro(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 3. Remember Me & Forgot Password
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Checkbox + Remember Me
                                    GestureDetector(
                                      onTap: () =>
                                          controller.rememberMe.toggle(),
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Obx(
                                            () => SizedBox(
                                              width: 19,
                                              height: 19,
                                              child: Checkbox(
                                                value:
                                                    controller.rememberMe.value,
                                                onChanged: (val) =>
                                                    controller
                                                            .rememberMe
                                                            .value =
                                                        val ?? false,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                  width: 1.5,
                                                ),
                                                activeColor: const Color(
                                                  0xFF163774,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'remember_me'.tr,
                                            style: GoogleFonts.kantumruyPro(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Forgot Password Link
                                    GestureDetector(
                                      onTap: () {
                                        CustomSnackbar.showInfo(
                                          message: 'contact_admin_reset_pwd'.tr,
                                        );
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'forgot_password_q'.tr,
                                            style: GoogleFonts.kantumruyPro(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF163774),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: Color(0xFF163774),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),

                                // 4. Primary Login Button (Navy Gradient)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: Obx(
                                    () => Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF163774),
                                            Color(0xFF244F9C),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF163774,
                                            ).withOpacity(0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: controller.isLoading.value
                                            ? null
                                            : controller.loginWithCredentials,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: controller.isLoading.value
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.4,
                                                    ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'login'.tr,
                                                    style:
                                                        GoogleFonts.kantumruyPro(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // 5. Divider with OR & 6. Biometric Options (Fingerprint & Face ID Cards)
                                if (showBiometricOptions) ...[
                                  // 5. Divider with OR
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          'or_divider'.tr,
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 13,
                                            color: const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // 6. Biometric Options (Fingerprint & Face ID Cards)
                                  Row(
                                    children: [
                                      // Fingerprint Card
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => controller
                                                .loginWithBiometricsQuick(
                                                  isFace: false,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.fingerprint_rounded,
                                                    color: Color(0xFF163774),
                                                    size: 32,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'login_fingerprint'.tr,
                                                    textAlign: TextAlign.center,
                                                    style:
                                                        GoogleFonts.kantumruyPro(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                            0xFF1E293B,
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Face ID Card
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => controller
                                                .loginWithBiometricsQuick(
                                                  isFace: true,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const _FaceIdIconWidget(
                                                    size: 32,
                                                    color: Color(0xFF163774),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'login_face'.tr,
                                                    textAlign: TextAlign.center,
                                                    style:
                                                        GoogleFonts.kantumruyPro(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                            0xFF1E293B,
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // 7. Support / Help Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.headset_mic_outlined,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'need_help_q'.tr,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () =>
                                          _showContactSupportDialog(context),
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'contact_service'.tr,
                                            style: GoogleFonts.kantumruyPro(
                                              fontSize: 13,
                                              color: const Color(0xFF163774),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 17,
                                            color: Color(0xFF163774),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
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
        ],
      ),
    );
  }

  // ─── Biometric Lock Screen ────────────────────────────────────────────────

  Widget _buildBiometricLockScreen(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3E82), Color(0xFF163774), Color(0xFF102652)],
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (showLanguageSwitcher) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.topRight,
                          child: _buildDiscreetLanguageDropdown(),
                        ),
                        const SizedBox(height: 110),
                      ] else
                        const SizedBox(height: 149),
                      Container(
                        width: 155,
                        height: 155,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 3.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(5.0),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/img/about-moi-logo.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Ministry Title (Royal Gold Khmer)
                      Text(
                        'ក្រសួងមហាផ្ទៃ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Ministry Subtitle (English - Royal Gold / Champagne)
                      Text(
                        'MINISTRY OF INTERIOR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDFBC66),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    36,
                    24,
                    bottomInset > 0 ? bottomInset + 20 : 40,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'biometric_title'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'biometric_reason'.tr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEFF4FB),
                          border: Border.all(
                            color: const Color(0xFFC7D7EC),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          size: 48,
                          color: Color(0xFF163774),
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Obx(
                          () => ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.retryBiometricUnlock,
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(Icons.fingerprint_rounded),
                            label: Text(
                              controller.isLoading.value
                                  ? 'biometric_verifying'.tr
                                  : 'verify_again'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF163774),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: controller.exitApp,
                          icon: const Icon(
                            Icons.exit_to_app_rounded,
                            color: Color(0xFFDC2626),
                          ),
                          label: Text(
                            'exit_app'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
        ],
      ),
    );
  }

  // ─── Language Switcher Pill ───────────────────────────────────────────────

  Widget _buildDiscreetLanguageDropdown() {
    return Obx(() {
      final currentLang = LocalizationService.currentLanguageCode.value;
      final isKh = currentLang == 'km';

      return Theme(
        data: Theme.of(Get.context!).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
            elevation: 8,
          ),
        ),
        child: PopupMenuButton<String>(
          onSelected: (String langCode) {
            LocalizationService.changeLanguage(langCode);
          },
          offset: const Offset(0, 36),
          padding: EdgeInsets.zero,
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'km',
              height: 42,
              child: Row(
                children: [
                  const Text('🇰🇭', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ភាសាខ្មែរ (KH)',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        fontWeight: isKh ? FontWeight.bold : FontWeight.w500,
                        color: isKh
                            ? const Color(0xFF163774)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (isKh)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF163774),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<String>(
              value: 'en',
              height: 42,
              child: Row(
                children: [
                  const Text('🇬🇧', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'English (EN)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: !isKh ? FontWeight.bold : FontWeight.w500,
                        color: !isKh
                            ? const Color(0xFF163774)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (!isKh)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF163774),
                    ),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isKh ? '🇰🇭' : '🇬🇧',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 5),
                Text(
                  isKh ? 'KH' : 'EN',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showContactSupportDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF4FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: Color(0xFF163774),
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'contact_service'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'contact_help_desk_desc'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D7EC), width: 1),
                ),
                child: Text(
                  '023 726 828 / 023 726 829',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF163774),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF163774),
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
}

// ─── Face ID Custom Icon (Navy bracket frame with face) ──────────────────────

class _FaceIdIconWidget extends StatelessWidget {
  final double size;
  final Color color;

  const _FaceIdIconWidget({
    this.size = 30,
    this.color = const Color(0xFF163774),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FaceIdPainter(color: color),
    );
  }
}

class _FaceIdPainter extends CustomPainter {
  final Color color;
  _FaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cornerLen = w * 0.25;

    // 4 Corner Brackets
    canvas.drawLine(Offset(0, cornerLen), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerLen, 0), paint);

    canvas.drawLine(Offset(w - cornerLen, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);

    canvas.drawLine(Offset(0, h - cornerLen), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);

    canvas.drawLine(Offset(w - cornerLen, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), paint);

    // Eyes
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.38, h * 0.42), 1.8, fillPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.42), 1.8, fillPaint);

    // Smile
    final smilePath = Path();
    smilePath.moveTo(w * 0.36, h * 0.60);
    smilePath.quadraticBezierTo(w * 0.50, h * 0.72, w * 0.64, h * 0.60);
    canvas.drawPath(smilePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Subtle Bottom Card Wave Painter ────────────────────────────────────────

class _BottomCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFEFF4FB).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.55);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.30,
      size.width * 0.65,
      size.height * 0.85,
      size.width,
      size.height * 0.45,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFC7D7EC).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.cubicTo(
      size.width * 0.40,
      size.height * 0.55,
      size.width * 0.70,
      size.height * 0.90,
      size.width,
      size.height * 0.65,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
