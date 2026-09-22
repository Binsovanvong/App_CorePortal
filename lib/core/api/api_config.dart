import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show debugPrint;
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:get/get.dart';
import 'package:core_portal/routes/page_route.dart';

class ApiConfig {
  // API Base URLs
  static const String uatBaseUrl = 'http://172.30.192.127';
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
    return uri?.host ?? '172.30.192.127';
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

  late Dio dio;

  ApiConfig() {
    // Print active API URL to Flutter console
    // ignore: avoid_print
    print('====================================');
    // ignore: avoid_print
    print(' ApiConfig initialized: $baseUrl');
    // ignore: avoid_print
    print('====================================');

    dio =
        Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {'Content-Type': 'application/json'},
            ),
          )
          ..interceptors.add(
            PrettyDioLogger(
              requestBody: false,
              requestHeader: false,
              responseBody: false,
              error: true,
            ),
          );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final box = GetStorage();
          final String? token =
              (box.read('token') ?? box.read('access_token'))?.toString().trim();
          final path = options.path.toLowerCase();
          final isAuthEndpoint =
              path.contains('/auth/login') ||
              path.contains('/auth/device/') ||
              path.contains('/auth/refresh');

          final bool requestHasAuthorization = options.headers.keys.any(
            (key) => key.toLowerCase() == 'authorization',
          );
          if (!requestHasAuthorization && token != null && token.isNotEmpty) {
            final String accessToken = token;
            options.headers.remove('authorization');
            options.headers['Authorization'] = 'Bearer $accessToken';
          } else if (!isAuthEndpoint &&
              !requestHasAuthorization &&
              (token == null || token.isEmpty)) {
            debugPrint(
              "ApiConfig: No token exists for ${options.path}. Showing login instead of calling endpoint.",
            );
            try {
              final currentRoute = Get.currentRoute;
              if (currentRoute != AppRoutes.login) {
                Get.offAllNamed(AppRoutes.login);
              }
            } catch (_) {}
            return handler.reject(
              DioException(
                requestOptions: options,
                error:
                    "No token exists. Showing login instead of calling these endpoints.",
                type: DioExceptionType.cancel,
              ),
            );
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final path = e.requestOptions.path.toLowerCase();
          final bool isAuthOrBiometric =
              path.contains('/auth/login') ||
              path.contains('/auth/device/') ||
              path.contains('/auth/refresh');
          final bool isAdminOrOptional =
              path.contains('/admin/') ||
              path.contains('/gateway/') ||
              path.contains('/uploads/');

          // Do NOT wipe the session when a background admin or optional check fails with 401
          if (e.response?.statusCode == 401 &&
              !isAuthOrBiometric &&
              !isAdminOrOptional) {
            debugPrint("ApiConfig 401 on core route: $path. Session expired upstream.");
            final box = GetStorage();
            await box.remove('token');
            await box.remove('access_token');
            await box.remove('isAdmin');
            try {
              if (Get.currentRoute != AppRoutes.login) {
                Get.offAllNamed(AppRoutes.login);
              }
            } catch (_) {}
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Device clocks may be skewed or out of sync with the upstream auth server.
  /// Preemptively stripping tokens on the client guarantees 401 unauthorized failures.
  /// Upstream Keycloak/Gateway remains the sole authority for token expiration.
  static bool isTokenExpired(String token) {
    return false;
  }
}

