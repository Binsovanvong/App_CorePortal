import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/error_codes.dart' as authError;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:pointycastle/export.dart';

enum BiometricResult { success, failed, cancelled, unavailable }

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  static const String _privateKeyStorageKey = 'device_ec_private_key';
  static const String _deviceIdStorageKey = 'device_unique_uuid';
  static final ECDomainParameters _domain = ECDomainParameters('prime256v1');

  /// Returns a persistent canonical RFC 4122 UUID v4 device identifier.
  /// The ID is generated once and saved across iOS Keychain, hardware secure storage,
  /// and persistent local storage fallback so it is never recreated across attempts.
  static Future<String> getDeviceId() async {
    // 1. Try reading from secure storage (iOS Keychain / Android Keystore)
    try {
      final existing = await _secureStorage.read(key: _deviceIdStorageKey);
      if (existing != null && existing.isNotEmpty) {
        try {
          final box = GetStorage();
          if (box.read(_deviceIdStorageKey) != existing) {
            await box.write(_deviceIdStorageKey, existing);
          }
        } catch (_) {}
        return existing;
      }
    } catch (_) {}

    // 2. Check local GetStorage fallback in case of temporary Keychain access delay
    try {
      final box = GetStorage();
      final localExisting = box.read(_deviceIdStorageKey)?.toString();
      if (localExisting != null && localExisting.isNotEmpty) {
        try {
          await _secureStorage.write(
            key: _deviceIdStorageKey,
            value: localExisting,
          );
        } catch (_) {}
        return localExisting;
      }
    } catch (_) {}

    // 3. Generate exactly once if neither storage contains an ID
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // RFC 4122 version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final newId =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
    try {
      await _secureStorage.write(key: _deviceIdStorageKey, value: newId);
    } catch (_) {}
    try {
      await GetStorage().write(_deviceIdStorageKey, newId);
    } catch (_) {}
    return newId;
  }

  /// Resets cryptographic signing key pair. The persistent device identifier
  /// is preserved so device bindings remain consistent.
  static Future<void> resetKeys() async {
    try {
      await _secureStorage.delete(key: _privateKeyStorageKey);
      await _secureStorage.delete(key: _registeredPublicKeyStorageKey);
    } catch (_) {}
  }

  static const String _registeredPublicKeyStorageKey =
      'device_registered_public_key';

  /// Checks whether a valid private key exists in secure hardware storage.
  /// If false, the key was lost (e.g. app reinstalled, secure enclave wiped).
  static Future<bool> hasPrivateKey() async {
    try {
      final storedKey = await _secureStorage.read(key: _privateKeyStorageKey);
      return storedKey != null && storedKey.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Persists the Base64 DER public key that was successfully registered with the backend.
  static Future<void> saveRegisteredPublicKey(String publicKey) async {
    try {
      await _secureStorage.write(
        key: _registeredPublicKeyStorageKey,
        value: publicKey,
      );
    } catch (_) {}
  }

  /// Retrieves the registered public key from secure storage, if any.
  static Future<String?> getRegisteredPublicKey() async {
    try {
      return await _secureStorage.read(key: _registeredPublicKeyStorageKey);
    } catch (_) {
      return null;
    }
  }

  /// Determines whether the active local public/private key pair has changed
  /// compared to what was previously registered.
  static Future<bool> hasKeyPairChanged() async {
    try {
      final registered = await getRegisteredPublicKey();
      if (registered == null || registered.isEmpty) {
        return false;
      }
      final current = await getPublicKeyDerBase64();
      return current != registered;
    } catch (_) {
      return false;
    }
  }

  /// Evaluates whether /device/register must be invoked based on the 4 allowed conditions:
  /// 1. Biometric login is enabled for the first time.
  /// 2. The device was revoked.
  /// 3. The app was reinstalled or the private key was lost.
  /// 4. The stored public/private key pair changed.
  ///
  /// In ALL other cases (e.g. access token expired, regular login, routine challenge/verify),
  /// this returns false.
  static Future<bool> shouldRegisterDevice({
    required String username,
    required String deviceId,
    required List<dynamic> backendDevices,
  }) async {
    // Condition 3: The app was reinstalled or the private key was lost.
    final bool hasKey = await hasPrivateKey();
    if (!hasKey) {
      return true;
    }

    // Condition 4: The stored public/private key pair changed.
    final bool keyChanged = await hasKeyPairChanged();
    if (keyChanged) {
      return true;
    }

    // Check device status on the backend
    Map<String, dynamic>? matchingDevice;
    for (final d in backendDevices) {
      if (d is Map && d['device_id']?.toString() == deviceId) {
        matchingDevice = Map<String, dynamic>.from(d);
        break;
      }
    }

    // Condition 2: The device was revoked.
    if (matchingDevice != null) {
      final bool isRevoked =
          matchingDevice['is_active'] == false ||
          matchingDevice['revoked_at'] != null;
      if (isRevoked) {
        return true;
      }
    }

    // Condition 1: Biometric login is enabled for the first time.
    final bool isEnrolledLocally = await isBiometricEnrolled(username);
    final bool isRegisteredOnBackend =
        matchingDevice != null && matchingDevice['is_active'] != false;

    if (!isEnrolledLocally && !isRegisteredOnBackend) {
      return true;
    }

    // None of the 4 conditions are met. DO NOT register.
    return false;
  }

  /// Checks if biometrics have been enrolled for this user across secure storage and local storage.
  static Future<bool> isBiometricEnrolled(String username) async {
    try {
      final secureVal =
          await _secureStorage.read(key: 'biometric_enrolled_$username');
      if (secureVal == 'true') return true;
    } catch (_) {}
    final box = GetStorage();
    return (box.read('biometric_registered_$username') == true) ||
        (box.read('is_face_enrolled') == true);
  }

  /// Updates enrollment status for this user across secure storage and local storage.
  static Future<void> setBiometricEnrolled(
    String username,
    bool enrolled,
  ) async {
    try {
      await _secureStorage.write(
        key: 'biometric_enrolled_$username',
        value: enrolled ? 'true' : 'false',
      );
    } catch (_) {}
    final box = GetStorage();
    if (enrolled) {
      await box.write('biometric_registered_$username', true);
      await box.write('is_face_enrolled', true);
    } else {
      await box.remove('biometric_registered_$username');
      await box.remove('is_face_enrolled');
    }
  }

  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<BiometricResult> authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'biometric_reason'.tr,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: false,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'biometric_title'.tr,
            biometricHint: 'biometric_hint'.tr,
            cancelButton: 'cancel'.tr,
          ),
          IOSAuthMessages(cancelButton: 'cancel'.tr),
        ],
      );
      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      switch (e.code) {
        case authError.notAvailable:
        case authError.notEnrolled:
        case authError.passcodeNotSet:
          return BiometricResult.unavailable;
        case authError.lockedOut:
        case authError.permanentlyLockedOut:
          return BiometricResult.failed;
        default:
          return BiometricResult.cancelled;
      }
    } catch (_) {
      return BiometricResult.cancelled;
    }
  }

  static Future<ECPrivateKey> _getOrCreatePrivateKey() async {
    final storedKey = await _secureStorage.read(key: _privateKeyStorageKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return ECPrivateKey(BigInt.parse(storedKey, radix: 16), _domain);
    }

    final random = _newSecureRandom();
    final generator = ECKeyGenerator()
      ..init(
        ParametersWithRandom<ECKeyGeneratorParameters>(
          ECKeyGeneratorParameters(_domain),
          random,
        ),
      );
    final keyPair = generator.generateKeyPair();
    final privateKey = keyPair.privateKey as ECPrivateKey;
    await _secureStorage.write(
      key: _privateKeyStorageKey,
      value: privateKey.d!.toRadixString(16).padLeft(64, '0'),
    );
    return privateKey;
  }

  /// Base64 DER SubjectPublicKeyInfo (EC P-256), accepted by the API.
  static Future<String> getPublicKeyDerBase64() async {
    final privateKey = await _getOrCreatePrivateKey();
    // A non-zero valid P-256 private scalar always produces a public point.
    final point = (_domain.G * privateKey.d!)!;
    final rawPoint = <int>[
      0x04,
      ..._bigIntToBytes(point.x!.toBigInteger()!, 32),
      ..._bigIntToBytes(point.y!.toBigInteger()!, 32),
    ];
    const prefix = <int>[
      0x30,
      0x59,
      0x30,
      0x13,
      0x06,
      0x07,
      0x2A,
      0x86,
      0x48,
      0xCE,
      0x3D,
      0x02,
      0x01,
      0x06,
      0x08,
      0x2A,
      0x86,
      0x48,
      0xCE,
      0x3D,
      0x03,
      0x01,
      0x07,
      0x03,
      0x42,
      0x00,
    ];
    return base64Encode([...prefix, ...rawPoint]);
  }

  /// Base64 DER ECDSA-SHA256 signature for the decoded Base64URL challenge
  /// bytes. This matches the API's device signature verification contract.
  static Future<String> signChallenge(String challenge) async {
    final privateKey = await _getOrCreatePrivateKey();
    final signer = ECDSASigner(SHA256Digest())
      ..init(
        true,
        ParametersWithRandom<PrivateKeyParameter<ECPrivateKey>>(
          PrivateKeyParameter<ECPrivateKey>(privateKey),
          _newSecureRandom(),
        ),
      );
    final signature =
        signer.generateSignature(
              Uint8List.fromList(base64Url.decode(challenge)),
            )
            as ECSignature;
    return base64Encode(_encodeDerSignature(signature.r, signature.s));
  }

  static Uint8List _bigIntToBytes(BigInt value, int length) {
    final hex = value.toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList(
      List<int>.generate(
        length,
        (index) =>
            int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
      ),
    );
  }

  /// ECDSA requires entropy for a new nonce on every signature. Supplying it
  /// explicitly avoids PointyCastle's unconfigured default SecureRandom.
  static SecureRandom _newSecureRandom() {
    final random = FortunaRandom();
    random.seed(
      KeyParameter(
        Uint8List.fromList(
          List<int>.generate(32, (_) => Random.secure().nextInt(256)),
        ),
      ),
    );
    return random;
  }

  static Uint8List _encodeDerSignature(BigInt r, BigInt s) {
    List<int> encodeInteger(BigInt value) {
      var hex = value.toRadixString(16);
      if (hex.length.isOdd) hex = '0$hex';
      var bytes = List<int>.generate(
        hex.length ~/ 2,
        (index) =>
            int.parse(hex.substring(index * 2, index * 2 + 2), radix: 16),
      );
      if ((bytes.first & 0x80) != 0) bytes = [0, ...bytes];
      return [0x02, bytes.length, ...bytes];
    }

    final body = [...encodeInteger(r), ...encodeInteger(s)];
    return Uint8List.fromList([0x30, body.length, ...body]);
  }
}
