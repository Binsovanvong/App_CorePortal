import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/token_store.dart';
import 'package:core_portal/core/api/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:flutter/services.dart';
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

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ApiClient.logout();
  });

  group('TokenStore Tests', () {
    test('saveTokenResponse saves access_token, refresh_token and expires_at', () async {
      final storage = const FlutterSecureStorage();
      final tokenStore = TokenStore(storage);

      await tokenStore.saveTokenResponse({
        'access_token': 'test_access_token',
        'refresh_token': 'test_refresh_token',
        'expires_in': 300,
      });

      expect(await tokenStore.accessToken, equals('test_access_token'));
      expect(await tokenStore.refreshToken, equals('test_refresh_token'));
      expect(await tokenStore.expiresSoon(), isFalse);
    });

    test('expiresSoon returns true when expiration is within 30 seconds', () async {
      final storage = const FlutterSecureStorage();
      final tokenStore = TokenStore(storage);

      // Token expires in 10 seconds (<= 30 seconds)
      await tokenStore.saveTokenResponse({
        'access_token': 'expiring_token',
        'refresh_token': 'refresh_token',
        'expires_in': 10,
      });

      expect(await tokenStore.expiresSoon(), isTrue);
    });

    test('clear wipes all keys from storage', () async {
      final storage = const FlutterSecureStorage();
      final tokenStore = TokenStore(storage);

      await tokenStore.saveTokenResponse({
        'access_token': 'to_clear',
        'refresh_token': 'refresh_to_clear',
        'expires_in': 300,
      });

      await tokenStore.clear();

      expect(await tokenStore.accessToken, isNull);
      expect(await tokenStore.refreshToken, isNull);
      expect(await tokenStore.expiresSoon(), isTrue);
    });
  });

  group('AuthInterceptor & ApiClient Configuration Tests', () {
    test('Attaches Authorization header with Bearer token automatically', () async {
      await ApiClient.tokenStore.saveTokenResponse({
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testToken',
        'refresh_token': 'test_refresh_token',
        'expires_in': 300,
      });

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
        await dio.get('/accounts/profile');
      } catch (_) {}

      dio.interceptors.remove(testInterceptor);

      expect(
        capturedOptions.headers['Authorization'],
        equals('Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.testToken'),
      );
    });

    test('Path normalization maps /portals and /admin to /api/mobile/...', () async {
      await ApiClient.tokenStore.saveTokenResponse({
        'access_token': 'valid_token',
        'refresh_token': 'refresh_token',
        'expires_in': 300,
      });

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

      expect(capturedOptions.path, equals('/api/mobile/portals/tiles'));
    });

    test('AuthInterceptor retries 401 error once with rotated token', () async {
      final mockStorage = const FlutterSecureStorage();
      final mockStore = TokenStore(mockStorage);
      await mockStore.saveTokenResponse({
        'access_token': 'old_expired_token',
        'refresh_token': 'valid_refresh_token',
        'expires_in': 300,
      });

      final mainApi = Dio(BaseOptions(baseUrl: 'https://test.host'));
      final refreshApi = Dio(BaseOptions(baseUrl: 'https://test.host'));

      // Mock refresh endpoint on refreshApi
      refreshApi.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/api/mobile/auth/refresh')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'access_token': 'new_rotated_token',
                    'refresh_token': 'new_rotated_refresh',
                    'expires_in': 300,
                  },
                ),
              );
              return;
            }
            handler.next(options);
          },
        ),
      );

      bool sessionExpiredCalled = false;
      final authInterceptor = AuthInterceptor(
        api: mainApi,
        refreshApi: refreshApi,
        tokens: mockStore,
        onSessionExpired: () => sessionExpiredCalled = true,
      );

      mainApi.interceptors.add(authInterceptor);

      // Mock backend server behavior via HttpClientAdapter
      int requestCount = 0;
      late RequestOptions lastRequestOptions;
      mainApi.httpClientAdapter = MockAdapter((options) async {
        requestCount++;
        lastRequestOptions = options;
        if (requestCount == 1) {
          return ResponseBody.fromString(
            '{"error": "token_expired"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          return ResponseBody.fromString(
            '{"result": "success"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
      });

      final response =
          await mainApi.get<Map<String, dynamic>>('/api/mobile/auth/device');

        expect(response.statusCode, equals(200));
        expect(response.data?['result'], equals('success'));
        expect(requestCount, equals(2));
        expect(lastRequestOptions.extra['authRetried'], isTrue);
        expect(
          lastRequestOptions.headers['Authorization'],
          equals('Bearer new_rotated_token'),
        );
        expect(await mockStore.accessToken, equals('new_rotated_token'));
        expect(await mockStore.refreshToken, equals('new_rotated_refresh'));
      expect(sessionExpiredCalled, isFalse);
    });

    test('ApiClient.logout clears access_token and refresh_token from secure storage', () async {
      await ApiClient.saveToken('token_to_clear', refreshToken: 'refresh_to_clear');

      await ApiClient.logout();

      final accessToken = await ApiClient.getAccessToken();
      final refreshToken = await ApiClient.getRefreshToken();

      expect(accessToken, isNull);
      expect(refreshToken, isNull);
    });
  });
}

class MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  MockAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}
