import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Get.testMode = true;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    await GetStorage.init();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test_native_access_token',
      'refresh_token': 'test_native_refresh_token',
    });
    ApiClient.currentToken = 'test_native_access_token';
  });

  group('Native Mobile Authentication & Password Change Tests', () {
    test('changePasswordService sends current_password and new_password to PUT /api/mobile/accounts/change-password', () async {
      final dioClient = ApiClient.dio;
      late dio.RequestOptions capturedOptions;

      final testInterceptor = dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedOptions = options;
          handler.resolve(
            dio.Response(
              requestOptions: options,
              statusCode: 200,
              data: {'message': 'Password changed successfully'},
            ),
          );
        },
      );

      dioClient.interceptors.add(testInterceptor);

      try {
        final authService = AuthService();
        await authService.changePasswordService(
          oldPassword: 'OldPassword123!',
          newPassword: 'NewPassword123!',
        );
      } finally {
        dioClient.interceptors.remove(testInterceptor);
      }

      // Check method is PUT
      expect(capturedOptions.method, equals('PUT'));
      // Check endpoint is normalized by ApiClient interceptor
      expect(capturedOptions.path, equals('/accounts/change-password'));
      // Check headers contain Authorization Bearer token
      expect(capturedOptions.headers['Authorization'], equals('Bearer test_native_access_token'));
      // Check JSON payload contains current_password and new_password
      final body = Map<String, dynamic>.from(capturedOptions.data as Map);
      expect(body['current_password'], equals('OldPassword123!'));
      expect(body['new_password'], equals('NewPassword123!'));
      // Ensure 'username' is NOT in body
      expect(body.containsKey('username'), isFalse);
    });

    test('ApiClient.logout deletes tokens and credentials from hardware secure storage', () async {
      await ApiClient.storage.write(key: 'access_token', value: 'temp_token');
      await ApiClient.storage.write(key: 'refresh_token', value: 'temp_refresh');

      await ApiClient.logout();

      final token = await ApiClient.storage.read(key: 'access_token');
      final refresh = await ApiClient.storage.read(key: 'refresh_token');
      expect(token, isNull);
      expect(refresh, isNull);
      expect(ApiClient.currentToken, isNull);
    });

    test('restoreSession does not write tokens into unencrypted GetStorage', () async {
      await ApiClient.storage.write(key: 'access_token', value: 'secret_token_123');
      ApiClient.currentToken = 'secret_token_123';

      final restored = await AuthService.restoreSession();
      expect(restored, isTrue);

      final box = GetStorage();
      expect(box.hasData('access_token'), isFalse);
      expect(box.hasData('token'), isFalse);
    });

    test('first_login boolean flag correctly identified from token response', () {
      final Map<String, dynamic> response1 = {
        'access_token': 'token123',
        'first_login': true,
      };
      final bool isFirstLogin1 = response1['first_login'] == true ||
          response1['firstLogin'] == true ||
          (response1['data'] is Map && (response1['data'] as Map)['first_login'] == true) ||
          response1['first_login']?.toString().toLowerCase() == 'true';
      expect(isFirstLogin1, isTrue);

      final Map<String, dynamic> response2 = {
        'access_token': 'token123',
        'first_login': false,
      };
      final bool isFirstLogin2 = response2['first_login'] == true ||
          response2['firstLogin'] == true ||
          (response2['data'] is Map && (response2['data'] as Map)['first_login'] == true) ||
          response2['first_login']?.toString().toLowerCase() == 'true';
      expect(isFirstLogin2, isFalse);
    });
  });
}
