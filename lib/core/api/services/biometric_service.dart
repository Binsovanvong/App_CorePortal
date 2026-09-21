import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:local_auth/error_codes.dart' as authError;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:pointycastle/export.dart';

enum BiometricResult { success, failed, cancelled, unavailable }

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const String _privateKeyStorageKey = 'device_ec_private_key';
  static final ECDomainParameters _domain = ECDomainParameters('prime256v1');

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
