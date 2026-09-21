import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:dio/dio.dart';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    await GetStorage.init();
  });

  // Mock FlutterSecureStorage values for tests
  FlutterSecureStorage.setMockInitialValues({
    'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testToken',
    'refresh_token': 'test_refresh_token',
  });

  group('ApiClient & Secure Storage Keycloak Token Tests', () {
    test('Reads token from flutter_secure_storage', () async {
      final token = await ApiClient.storage.read(key: 'access_token');
      expect(token, equals('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testToken'));
    });

    test('Attaches Authorization header with Bearer token automatically', () async {
      final dio = ApiClient.dio;
      late RequestOptions capturedOptions;

      // Add a test interceptor to capture outgoing request options
      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedOptions = options;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Test inspection',
            ),
          );
        },
      );

      dio.interceptors.add(testInterceptor);

      try {
        await dio.get('/accounts/profile');
      } catch (_) {}

      // Clean up test interceptor
      dio.interceptors.remove(testInterceptor);

      expect(capturedOptions.headers['Authorization'], startsWith('Bearer eyJ'));
      expect(capturedOptions.headers['Authorization'], equals('Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testToken'));
    });

    test('Path normalization removes redundant /api/mobile prefix', () async {
      final dio = ApiClient.dio;
      late RequestOptions capturedOptions;

      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedOptions = options;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Test inspection',
            ),
          );
        },
      );

      dio.interceptors.add(testInterceptor);

      try {
        await dio.get('/api/mobile/portals/tiles');
      } catch (_) {}

      dio.interceptors.remove(testInterceptor);

      expect(capturedOptions.path, equals('/portals/tiles'));
    });

    test('ApiClient.logout clears access_token and refresh_token from secure storage', () async {
      await ApiClient.storage.write(key: 'access_token', value: 'token_to_clear');
      await ApiClient.storage.write(key: 'refresh_token', value: 'refresh_to_clear');

      await ApiClient.logout();

      final accessToken = await ApiClient.storage.read(key: 'access_token');
      final refreshToken = await ApiClient.storage.read(key: 'refresh_token');

      expect(accessToken, isNull);
      expect(refreshToken, isNull);
    });
  });
}
