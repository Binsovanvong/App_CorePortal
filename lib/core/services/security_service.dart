import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceIntegrityStatus {
  final bool isJailbrokenOrRooted;
  final bool isDeveloperMode;
  final bool isSafe;
  final String? issueSummary;

  const DeviceIntegrityStatus({
    required this.isJailbrokenOrRooted,
    required this.isDeveloperMode,
    required this.isSafe,
    this.issueSummary,
  });
}

class SecurityService {
  /// Set to true to strictly block execution on rooted/jailbroken devices even in debug builds.
  /// By default, in release builds it will always enforce blocking.
  static const bool enforceStrictInDebug = false;

  /// Performs device integrity and tamper detection checks.
  static Future<DeviceIntegrityStatus> checkDeviceIntegrity() async {
    // Desktop and Web platforms don't have mobile root/jailbreak mechanisms
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const DeviceIntegrityStatus(
        isJailbrokenOrRooted: false,
        isDeveloperMode: false,
        isSafe: true,
      );
    }

    bool jailbroken = false;
    bool devMode = false;

    try {
      jailbroken = await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      debugPrint('[SecurityService] Root/Jailbreak detection error: $e');
    }

    if (Platform.isAndroid) {
      try {
        devMode = await FlutterJailbreakDetection.developerMode;
      } catch (e) {
        debugPrint('[SecurityService] Developer mode detection error: $e');
      }
    }

    final bool shouldBlock = jailbroken && (!kDebugMode || enforceStrictInDebug);
    final String? issue = jailbroken
        ? 'Device is rooted or jailbroken.'
        : (devMode ? 'Developer options / USB debugging enabled.' : null);

    if (jailbroken) {
      debugPrint('[SecurityService] ⚠️ CRITICAL: Root/Jailbreak detected!');
    }
    if (devMode) {
      debugPrint('[SecurityService] ℹ️ Notice: Developer mode enabled.');
    }

    return DeviceIntegrityStatus(
      isJailbrokenOrRooted: jailbroken,
      isDeveloperMode: devMode,
      isSafe: !shouldBlock,
      issueSummary: issue,
    );
  }
}
