import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PkceParams {
  final String codeVerifier;
  final String codeChallenge;
  final String state;
  final String nonce;

  const PkceParams({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.state,
    required this.nonce,
  });
}

class PkceHelper {
  static String _base64UrlUnpadded(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String generateRandomString(int byteLength) {
    final random = Random.secure();
    final values = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return _base64UrlUnpadded(values);
  }

  /// Generates code_verifier, code_challenge (S256), state, and nonce.
  /// Complies strictly with OpenAPI constraints:
  /// - code_challenge: pattern ^[A-Za-z0-9_-]{43}$
  /// - code_verifier: length 43 (between 43 and 128)
  /// - state: length 32 (minLength 22, maxLength 512)
  /// - nonce: length 32 (minLength 22, maxLength 512)
  static PkceParams generate() {
    // 32 random bytes -> exactly 43 unpadded base64url characters
    final codeVerifier = generateRandomString(32);
    final bytes = ascii.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = _base64UrlUnpadded(digest.bytes);
    final state = generateRandomString(24);
    final nonce = generateRandomString(24);

    return PkceParams(
      codeVerifier: codeVerifier,
      codeChallenge: codeChallenge,
      state: state,
      nonce: nonce,
    );
  }
}
