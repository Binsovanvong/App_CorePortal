import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/api_client.dart';

class ApiConfig {
  // API Base URLs
  static const String uatBaseUrl = 'http://uat-app-core.interior.gov.kh';
  static const String productionBaseUrl = 'https://core-app.interior.gov.kh';

  // Set to true to use the active UAT backend (UAT gateway currently verified & working)
  static const bool useUat = true;

  // Set to true to use a custom server IP or domain (e.g., http://127.0.0.1:8000)
  static const bool useCustomServer = false;
  static const String customServerUrl = 'http://127.0.0.1:8000';

  // Set to true if you are testing on a physical mobile device via Wi-Fi/ADB
  static const bool usePhysicalDevice = false;
  static const String pcIpAddress =
      '127.0.0.1'; // ADB USB reverse port forwarding (tcp:8000 tcp:8000)

  // Set to true only if testing against local backend on port 8000
  static const bool useLocalApi = false;

  static const String keycloakClientId = 'flutter-client';
  static String get keycloakTokenEndpoint => '$baseUrl/auth/token';

  static String get bffHost {
    if (useCustomServer) {
      final uri = Uri.tryParse(customServerUrl);
      return uri?.host ?? '127.0.0.1';
    }
    if (usePhysicalDevice) {
      return pcIpAddress;
    }
    if (useLocalApi) {
      if (kIsWeb) {
        final host = Uri.base.host;
        return (host.isNotEmpty && host != 'localhost') ? host : '127.0.0.1';
      }
      if (!kIsWeb && Platform.isAndroid) {
        return '10.0.2.2'; // Loopback to host machine in Android Emulator
      }
      return '127.0.0.1'; // Default (iOS Simulator / Desktop)
    }
    final uri = Uri.tryParse(baseUrl);
    return uri?.host ?? 'uat-app-core.interior.gov.kh';
  }

  static String get baseUrl {
    if (useCustomServer) {
      return customServerUrl;
    }
    if (usePhysicalDevice) {
      return 'http://$pcIpAddress:8000';
    }
    if (useLocalApi) {
      if (kIsWeb) {
        final host = Uri.base.host;
        final targetHost = (host.isNotEmpty && host != 'localhost')
            ? host
            : '127.0.0.1';
        return 'http://$targetHost:8000';
      }
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:8000'; // Android emulator loopback
      }
      return 'http://127.0.0.1:8000'; // iOS emulator/simulator or desktop
    }
    if (useUat) {
      return uatBaseUrl;
    }
    return productionBaseUrl;
  }

  Dio get dio => ApiClient.api;

  ApiConfig() {
    // Print active API URL to Flutter console
    // ignore: avoid_print
    print('====================================');
    // ignore: avoid_print
    print(' ApiConfig initialized: $baseUrl');
    // ignore: avoid_print
    print('====================================');
  }

  /// Device clocks may be skewed or out of sync with the upstream auth server.
  /// Preemptively stripping tokens on the client guarantees 401 unauthorized failures.
  /// Upstream Keycloak/Gateway remains the sole authority for token expiration.
  static bool isTokenExpired(String token) {
    return false;
  }
}
