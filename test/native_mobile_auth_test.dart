import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/services/biometric_service.dart';
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

  setUp(() async {
    await GetStorage().erase();
    final futureExpiry =
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test_native_access_token',
      'refresh_token': 'test_native_refresh_token',
      'access_token_expires_at': futureExpiry.toString(),
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
      expect(capturedOptions.path, equals('/api/mobile/accounts/change-password'));
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

    test('ApiClient.logout deletes session tokens but preserves biometric registration', () async {
      final box = GetStorage();
      await box.write('username', 'john_doe');
      await box.write('biometric_registered_john_doe', true);
      await box.write('is_face_enrolled', true);
      await ApiClient.storage.write(key: 'access_token', value: 'temp_token');
      await ApiClient.storage.write(key: 'refresh_token', value: 'temp_refresh');

      await ApiClient.logout();

      final token = await ApiClient.storage.read(key: 'access_token');
      final refresh = await ApiClient.storage.read(key: 'refresh_token');
      expect(token, isNull);
      expect(refresh, isNull);
      expect(ApiClient.currentToken, isNull);
      // Biometric registration must persist across session logouts so /register does not run on every login
      expect(box.read('biometric_registered_john_doe'), isTrue);
      expect(box.read('is_face_enrolled'), isTrue);
    });

    test('BiometricService.getDeviceId generates UUID once and reuses it consistently', () async {
      final id1 = await BiometricService.getDeviceId();
      final id2 = await BiometricService.getDeviceId();
      expect(id1, isNotEmpty);
      expect(id1, equals(id2));

      // Validate RFC 4122 v4 format (8-4-4-4-12 hex chars)
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(id1), isTrue);
    });

    test('BiometricService.resetKeys does not wipe the device_id', () async {
      final idBefore = await BiometricService.getDeviceId();
      await BiometricService.resetKeys();
      final idAfter = await BiometricService.getDeviceId();
      expect(idAfter, equals(idBefore));
    });

    test('BiometricService.isBiometricEnrolled and setBiometricEnrolled persist across stores', () async {
      expect(await BiometricService.isBiometricEnrolled('alice_test'), isFalse);
      await BiometricService.setBiometricEnrolled('alice_test', true);
      expect(await BiometricService.isBiometricEnrolled('alice_test'), isTrue);

      await BiometricService.setBiometricEnrolled('alice_test', false);
      expect(await BiometricService.isBiometricEnrolled('alice_test'), isFalse);
    });

    test('device matching strictly requires both matching currentDeviceId and active status', () {
      const currentDeviceId = 'uuid-current-device-123';

      final backendDevicesOtherActive = [
        {'device_id': 'uuid-other-phone-999', 'is_active': true},
      ];

      // Must be false: having another active device should NOT mark currentDeviceId as registered!
      final bool matchesOther = backendDevicesOtherActive.any(
        (d) =>
            d is Map &&
            d['device_id'] == currentDeviceId &&
            d['is_active'] != false,
      );
      expect(matchesOther, isFalse);

      final backendDevicesSameActive = [
        {'device_id': currentDeviceId, 'is_active': true},
      ];
      final bool matchesSame = backendDevicesSameActive.any(
        (d) =>
            d is Map &&
            d['device_id'] == currentDeviceId &&
            d['is_active'] != false,
      );
      expect(matchesSame, isTrue);

      final backendDevicesSameInactive = [
        {'device_id': currentDeviceId, 'is_active': false},
      ];
      final bool matchesInactive = backendDevicesSameInactive.any(
        (d) =>
            d is Map &&
            d['device_id'] == currentDeviceId &&
            d['is_active'] != false,
      );
      expect(matchesInactive, isFalse);
    });

    test('BiometricService.shouldRegisterDevice returns false when token expired and logging in normally', () async {
      const username = 'test_user_expired';
      final deviceId = await BiometricService.getDeviceId();

      // Ensure key pair exists and matches registered key
      final pubKey = await BiometricService.getPublicKeyDerBase64();
      await BiometricService.saveRegisteredPublicKey(pubKey);
      await BiometricService.setBiometricEnrolled(username, true);

      final backendDevices = [
        {'device_id': deviceId, 'is_active': true},
      ];

      // Access token expired, user logged in normally, evaluating shouldRegister:
      // Must NOT register again!
      final bool shouldRegister = await BiometricService.shouldRegisterDevice(
        username: username,
        deviceId: deviceId,
        backendDevices: backendDevices,
      );
      expect(shouldRegister, isFalse);
    });

    test('BiometricService.shouldRegisterDevice evaluates true ONLY for the 4 explicit conditions', () async {
      const username = 'test_user_conditions';
      final deviceId = await BiometricService.getDeviceId();
      final pubKey = await BiometricService.getPublicKeyDerBase64();

      // Setup clean baseline: enrolled, active device, key saved
      await BiometricService.saveRegisteredPublicKey(pubKey);
      await BiometricService.setBiometricEnrolled(username, true);

      // Baseline should be false
      expect(
        await BiometricService.shouldRegisterDevice(
          username: username,
          deviceId: deviceId,
          backendDevices: [{'device_id': deviceId, 'is_active': true}],
        ),
        isFalse,
      );

      // Condition 1: Biometric login is enabled for the first time
      await BiometricService.setBiometricEnrolled('brand_new_user', false);
      expect(
        await BiometricService.shouldRegisterDevice(
          username: 'brand_new_user',
          deviceId: deviceId,
          backendDevices: [], // Not on backend
        ),
        isTrue,
      );

      // Condition 2: The device was revoked
      expect(
        await BiometricService.shouldRegisterDevice(
          username: username,
          deviceId: deviceId,
          backendDevices: [
            {'device_id': deviceId, 'is_active': false, 'revoked_at': '2026-10-21T00:00:00Z'},
          ],
        ),
        isTrue,
      );

      // Condition 3: App was reinstalled or private key was lost
      await BiometricService.resetKeys();
      expect(await BiometricService.hasPrivateKey(), isFalse);
      expect(
        await BiometricService.shouldRegisterDevice(
          username: username,
          deviceId: deviceId,
          backendDevices: [{'device_id': deviceId, 'is_active': true}],
        ),
        isTrue,
      );

      // Condition 4: The stored public/private key pair changed
      // Regenerate fresh key
      final freshPubKey = await BiometricService.getPublicKeyDerBase64();
      await BiometricService.setBiometricEnrolled(username, true);
      // Simulate stored registered key being different from current key
      await BiometricService.saveRegisteredPublicKey('different_previous_public_key');
      expect(await BiometricService.hasKeyPairChanged(), isTrue);
      expect(
        await BiometricService.shouldRegisterDevice(
          username: username,
          deviceId: deviceId,
          backendDevices: [{'device_id': deviceId, 'is_active': true}],
        ),
        isTrue,
      );
    });
  });
}
