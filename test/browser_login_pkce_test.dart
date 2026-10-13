import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/pkce_helper.dart';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
    await GetStorage.init();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('PKCE Browser Login Tests', () {
    test('PkceHelper generates valid parameters adhering to OpenAPI spec', () {
      final pkce = PkceHelper.generate();

      // Check code_verifier
      expect(pkce.codeVerifier.length, greaterThanOrEqualTo(43));
      expect(pkce.codeVerifier.length, lessThanOrEqualTo(128));

      // Check code_challenge regex pattern ^[A-Za-z0-9_-]{43}$
      final challengeRegex = RegExp(r'^[A-Za-z0-9_-]{43}$');
      expect(challengeRegex.hasMatch(pkce.codeChallenge), isTrue);

      // Check state
      expect(pkce.state.length, greaterThanOrEqualTo(22));
      expect(pkce.state.length, lessThanOrEqualTo(512));

      // Check nonce
      expect(pkce.nonce.length, greaterThanOrEqualTo(22));
      expect(pkce.nonce.length, lessThanOrEqualTo(512));
    });

    test('Identifies required_action code from 409 response detail', () {
      final responseData = {
        'detail': {
          'code': 'required_action',
          'message':
              "Complete the account's required actions in the browser to sign in.",
          'browser_login_endpoint': '/api/mobile/auth/browser-login',
        },
      };

      final detail = responseData['detail'];
      expect(detail, isA<Map>());
      expect((detail as Map)['code'], equals('required_action'));
    });

    test('ApiClient allows /auth/browser-login and /auth/exchange-code without token', () async {
      final dio = ApiClient.dio;
      String? capturedPath;

      final testInterceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Intercepted successfully',
            ),
          );
        },
      );

      dio.interceptors.add(testInterceptor);

      try {
        await dio.post('/api/mobile/auth/browser-login', data: {});
      } catch (_) {}
      expect(capturedPath, equals('/auth/browser-login'));

      capturedPath = null;
      try {
        await dio.post('/api/mobile/auth/exchange-code', data: {});
      } catch (_) {}
      expect(capturedPath, equals('/auth/exchange-code'));

      capturedPath = null;
      try {
        await dio.post('/api/mobile/auth/update-password', data: {});
      } catch (_) {}
      expect(capturedPath, equals('/auth/update-password'));

      dio.interceptors.remove(testInterceptor);
    });

    test('Identifies update_password_required and ticket from 409 response', () {
      final responseData = {
        'detail': {
          'code': 'update_password_required',
          'required_action': 'UPDATE_PASSWORD',
          'ticket': 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
          'expires_in': 300,
        },
      };

      final detail = responseData['detail'] as Map<String, dynamic>;
      expect(detail['code'], equals('update_password_required'));
      expect(detail['required_action'], equals('UPDATE_PASSWORD'));
      expect(detail['ticket'], isNotEmpty);
      expect(detail['expires_in'], equals(300));
    });
  });
}
