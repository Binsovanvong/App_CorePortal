import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/services/security_service.dart';
import 'package:core_portal/routes/page_route.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> progressAnimation;

  final RxDouble progress = 0.0.obs;
  final RxString statusText = 'processing_dot'.tr.obs;

  bool _isSessionRestored = false;
  Future<bool>? _sessionRestorationFuture;

  @override
  void onInit() {
    super.onInit();

    // Start session restoration check immediately
    _sessionRestorationFuture = AuthService.restoreSession().then((restored) {
      _isSessionRestored = restored;
      return restored;
    });

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    progressAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    animationController.addListener(() {
      progress.value = progressAnimation.value;
    });

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    animationController.forward();
  }

  Future<void> _navigateToNext() async {
    // 1. Verify device integrity against root/jailbreak exploits
    final integrity = await SecurityService.checkDeviceIntegrity();
    if (!integrity.isSafe) {
      _showSecurityBlockDialog();
      return;
    }

    // 2. Ensure session restoration check finishes before deciding destination
    if (_sessionRestorationFuture != null) {
      await _sessionRestorationFuture;
    }

    if (_isSessionRestored) {
      Get.offAllNamed(AppRoutes.mainPage);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _showSecurityBlockDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'device_security_alert'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            'device_compromised_msg'.tr,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => exit(0),
              child: Text('exit_app'.tr),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Allows skipping splash on tap
  void skip() {
    if (!animationController.isCompleted) {
      animationController.stop();
      _navigateToNext();
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
