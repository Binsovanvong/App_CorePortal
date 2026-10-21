import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _expiresKey = 'access_token_expires_at';

  final FlutterSecureStorage storage;

  TokenStore(this.storage);

  Future<String?> get accessToken => storage.read(key: _accessKey);
  Future<String?> get refreshToken => storage.read(key: _refreshKey);

  Future<void> saveTokenResponse(Map<String, dynamic> json) async {
    final accessToken = (json['access_token'] ??
            json['token'] ??
            (json['data'] is Map
                ? json['data']['access_token'] ?? json['data']['token']
                : null))
        as String?;
    final newRefreshToken = (json['refresh_token'] ??
            (json['data'] is Map ? json['data']['refresh_token'] : null))
        as String?;
    final rawExpiresIn = json['expires_in'] ??
        (json['data'] is Map ? json['data']['expires_in'] : null);
    final expiresIn = (rawExpiresIn as num?)?.toInt() ?? 300;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Authentication response has no access token');
    }

    // Strip leading "Bearer " if present for clean storage
    String cleanAccessToken = accessToken.trim();
    if (cleanAccessToken.toLowerCase().startsWith('bearer ')) {
      cleanAccessToken = cleanAccessToken.substring(7).trim();
    }

    await storage.write(key: _accessKey, value: cleanAccessToken);
    // Write legacy 'token' key for backwards compatibility
    await storage.write(key: 'token', value: cleanAccessToken);

    // Keycloak may rotate the refresh token.
    if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
      final cleanRefreshToken = newRefreshToken.trim();
      await storage.write(key: _refreshKey, value: cleanRefreshToken);
    }

    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;

    await storage.write(
      key: _expiresKey,
      value: expiresAt.toString(),
    );
  }

  Future<bool> expiresSoon() async {
    final value = await storage.read(key: _expiresKey);
    if (value == null) return true;

    final expiresAt = int.tryParse(value);
    if (expiresAt == null) return true;

    // Refresh 30 seconds before expiration.
    return DateTime.now().millisecondsSinceEpoch >= expiresAt - 30000;
  }

  Future<void> clear() => storage.deleteAll();
}
