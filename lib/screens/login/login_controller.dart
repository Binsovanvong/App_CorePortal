import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart' show TextEditingController;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:dio/dio.dart' show DioException;

class LoginController extends GetxController {
  // Controllers for the input fields
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable toggle for password visibility
  final obscurePassword = true.obs;

  // Observable toggle for remember me
  final rememberMe = false.obs;

  // Observable loading state
  final isLoading = false.obs;

  final AuthService _authService = AuthService();

  Future<void> loginWithCredentials() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      CustomSnackbar.showError(
        message: 'សូមបញ្ចូលឈ្មោះអ្នកប្រើប្រាស់ និងលេខសម្ងាត់',
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await _authService.loginService(
        username: username,
        password: password,
      );

      final token = response['access_token'] ?? response['token'];
      if (token != null && token.toString().isNotEmpty) {
        final box = GetStorage();
        await box.write("token", token.toString());

        // Check if first-login or password change is required
        final bool isFirstLogin = response['first_login'] == true ||
            response['firstLogin'] == true ||
            response['must_change_password'] == true ||
            response['mustChangePassword'] == true ||
            response['change_password_required'] == true ||
            (response['required_actions'] is List &&
                (response['required_actions'] as List).contains('UPDATE_PASSWORD')) ||
            (response['requiredActions'] is List &&
                (response['requiredActions'] as List).contains('UPDATE_PASSWORD'));

        if (isFirstLogin) {
          Get.offAllNamed(
            AppRoutes.firstLoginChangePassword,
            arguments: {
              'username': username,
              'tempPassword': password,
            },
          );
          return;
        }

        CustomSnackbar.showSuccess(message: 'ការចូលប្រើប្រាស់ទទួលបានជោគជ័យ');

        Get.offAllNamed(AppRoutes.mainPage);
        return;
      }

      CustomSnackbar.showError(
        message: 'ការឆ្លើយតបពីម៉ាស៊ីនមេមិនត្រឹមត្រូវឡើយ',
      );
    } catch (e) {
      String errorMessage =
          'Authentication failed. Please check your credentials.';
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          final serverMessage =
              e.response?.data['detail'] ?? e.response?.data['message'];
          if (serverMessage == 'An unexpected error occurred') {
            errorMessage = 'Invalid username or password.';
          } else {
            errorMessage = serverMessage ?? errorMessage;
          }
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      }
      final cleanMessage = errorMessage.toLowerCase().trim();
      final String translatedMessage;
      if (cleanMessage.contains('invalid username or password') ||
          cleanMessage.contains('bad credentials') ||
          cleanMessage.contains('invalid_credentials') ||
          cleanMessage.contains('authentication failed')) {
        translatedMessage = 'ឈ្មោះអ្នកប្រើប្រាស់ ឬលេខសម្ងាត់មិនត្រឹមត្រូវឡើយ';
      } else {
        translatedMessage = errorMessage;
      }

      CustomSnackbar.showError(
        message: translatedMessage,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Fallback web SSO login
  Future<void> login() async {
    isLoading.value = true;

    final String callbackScheme = kIsWeb ? 'http' : 'myapp';
    final String redirectUri = kIsWeb
        ? '${Uri.base.origin}/auth.html'
        : 'myapp://callback';

    final String bffLoginUrl =
        '${ApiConfig.baseUrl}/api/mobile/auth/login?redirect_uri=$redirectUri';

    try {
      // 1. Launch secure browser view and wait for redirect callback
      final result = await FlutterWebAuth2.authenticate(
        url: bffLoginUrl,
        callbackUrlScheme: callbackScheme,
      );

      // 2. Extract token from redirect URL: myapp://callback?token=...
      final Uri resultUri = Uri.parse(result);
      final String? token = resultUri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        // Success: Store the token using GetStorage
        final box = GetStorage();
        await box.write("token", token);

        CustomSnackbar.showSuccess(message: 'ការចូលប្រើប្រាស់ទទួលបានជោគជ័យ');

        // Navigate to the main application view
        Get.offAllNamed(AppRoutes.mainPage);
      } else {
        CustomSnackbar.showError(message: 'មិនទទួលបាន Token ពីម៉ាស៊ីនមេឡើយ');
      }
    } catch (e) {
      CustomSnackbar.showWarning(
        message: 'ការផ្ទៀងផ្ទាត់ត្រូវបានបោះបង់ ឬបានបរាជ័យ',
      );
    } finally {
      isLoading.value = false;
    }
  }

}
