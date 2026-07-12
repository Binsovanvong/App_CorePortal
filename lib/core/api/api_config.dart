import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:get/get.dart';
import 'package:core_portal/routes/page_route.dart';

class ApiConfig {
  // Set to true if you are testing on a physical mobile device on the same Wi-Fi
  static const bool usePhysicalDevice = false;
  static const String pcIpAddress = ''; // Your computer's IP on Wi-Fi

  static String get bffHost {
    if (usePhysicalDevice) {
      return pcIpAddress;
    }
    if (kIsWeb) {
      return 'localhost';
    }
    if (Platform.isAndroid) {
      return '10.0.2.2'; // Loopback to host machine in Android Emulator
    }
    return 'localhost'; // Default (iOS Simulator / Desktop)
  }

  static String get baseUrl => 'https://core-app.interior.gov.kh';

  late Dio dio;

  ApiConfig() {
    final box = GetStorage();
    final token = box.read('token') ?? '';

    dio =
        Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Content-Type': 'application/json',
                if (token.isNotEmpty) 'Authorization': 'Bearer $token',
              },
            ),
          )
          ..interceptors.add(
            PrettyDioLogger(
              requestBody: true,
              requestHeader: true,
              responseBody: true,
            ),
          );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final box = GetStorage();
            await box.remove('token'); // Clear the expired token
            Get.offAllNamed(AppRoutes.login); // Redirect to Login
          }
          return handler.next(e);
        },
      ),
    );
  }
}
