import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core_portal/core/services/app_lock_service.dart';
import 'package:core_portal/widgets/biometric_lock_screen_view.dart';

/// Top-level overlay widget wrapped around GetMaterialApp.
/// Obscures and protects active screens whenever AppLockService.isLocked is true.
class AppLockOverlay extends StatelessWidget {
  final Widget child;

  const AppLockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AppLockService>()) {
      return child;
    }

    final lockService = AppLockService.to;

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Obx(() {
            final bool isLocked = lockService.isLocked.value;
            return IgnorePointer(
              ignoring: !isLocked,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isLocked ? 1.0 : 0.0,
                child: isLocked
                    ? const BiometricLockScreenView()
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
