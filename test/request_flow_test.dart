import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/screens/home/home_controller.dart';

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

  setUp(() async {
    await ApiClient.logout();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Flutter Request Flow Tests', () {
    test('Requirement 1: Waits until login or session restoration finishes', () async {
      AuthService.startAuthProcess();
      bool appsFetched = false;

      // Simulate background app fetch waiting for auth
      unawaited(() async {
        await AuthService.waitForAuth();
        appsFetched = true;
      }());

      // Ensure that apps are NOT fetched while auth is still in progress
      await Future.delayed(const Duration(milliseconds: 50));
      expect(appsFetched, isFalse);

      // Finish auth process
      AuthService.completeAuthProcess();

      // Now apps fetch proceeds
      await Future.delayed(const Duration(milliseconds: 50));
      expect(appsFetched, isTrue);
    });

    test('Requirement 2: Attaches returned access token with Bearer prefix', () async {
      const testToken = 'my_test_access_token_123';
      await ApiClient.saveToken(testToken);

      final dio = ApiClient.dio;
      late RequestOptions capturedOptions;

      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedOptions = options;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Captured options',
            ),
          );
        },
      );

      dio.interceptors.add(testInterceptor);

      try {
        await dio.get('/portals/tiles');
      } catch (_) {}

      dio.interceptors.remove(testInterceptor);

      expect(capturedOptions.headers['Authorization'], equals('Bearer $testToken'));
    });

    test('Requirement 3: If no token exists, reject protected request instead of calling endpoints', () async {
      await ApiClient.logout();
      FlutterSecureStorage.setMockInitialValues({});

      final dio = ApiClient.dio;
      bool networkCallMade = false;

      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          networkCallMade = true;
          handler.next(options);
        },
      );

      dio.interceptors.add(testInterceptor);

      DioException? caughtException;
      try {
        await dio.get('/portals/tiles');
      } on DioException catch (e) {
        caughtException = e;
      }

      dio.interceptors.remove(testInterceptor);

      // The request should be rejected before downstream network execution
      expect(caughtException, isNotNull);
      expect(networkCallMade, isFalse);
      expect(
        caughtException?.error.toString(),
        contains('No token exists. Showing login instead of calling these endpoints.'),
      );
    });

    test('Requirement 4: Auth endpoints are allowed without token, protected endpoints are not', () async {
      await ApiClient.logout();
      FlutterSecureStorage.setMockInitialValues({});

      final dio = ApiClient.dio;
      late RequestOptions capturedOptions;

      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedOptions = options;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Login intercepted',
            ),
          );
        },
      );

      dio.interceptors.add(testInterceptor);

      try {
        await dio.post('/auth/login', data: {'username': 'test', 'password': '123'});
      } catch (_) {}

      dio.interceptors.remove(testInterceptor);

      expect(capturedOptions.path, equals('/auth/login'));
    });

    test('Requirement 5: Does not retry the admin endpoint after a 401', () async {
      await ApiClient.saveToken('valid_test_token');
      final dio = ApiClient.dio;
      bool adminEndpointCalled = false;

      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/portals/tiles')) {
            // Simulate 401 Unauthorized response from server
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'detail': 'Unauthorized'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          } else if (options.path.contains('/admin/portal-apps')) {
            adminEndpointCalled = true;
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          } else {
            handler.next(options);
          }
        },
      );

      dio.interceptors.add(testInterceptor);

      final homeController = HomeController();
      await homeController.fetchPortalApps();

      dio.interceptors.remove(testInterceptor);

      // Verify that after 401, the admin endpoint was NOT called
      expect(adminEndpointCalled, isFalse);
    });
  });
}
