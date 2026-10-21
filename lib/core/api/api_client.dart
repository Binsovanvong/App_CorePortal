import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart' show debugPrint;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/core/api/token_store.dart';
import 'package:core_portal/core/api/auth_interceptor.dart';
import 'package:core_portal/routes/page_route.dart';

class ApiClient {
  static const storage = FlutterSecureStorage();

  static final TokenStore tokenStore = TokenStore(storage);

  /// In-memory token cache for instantaneous, synchronous access by widgets and formatters
  static String? currentToken;
  static String? currentRefreshToken;
  static String? currentCpSession;

  static String get defaultBaseUrl => ApiConfig.baseUrl;

  /// Dedicated Dio instance for authentication calls (refresh, login) to prevent recursive interceptor loops
  static final Dio refreshApi = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Main authenticated Dio instance with AuthInterceptor attached
  static final Dio api = _createApiInstance();

  /// Alias for `api` so that all repositories using ApiClient.dio automatically use the interceptor
  static Dio get dio => api;

  static Dio _createApiInstance() {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    client.interceptors.add(
      AuthInterceptor(
        api: client,
        refreshApi: refreshApi,
        tokens: tokenStore,
        onSessionExpired: _handleSessionExpired,
      ),
    );

    if (kDebugMode) {
      client.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    return client;
  }

  static void _handleSessionExpired() {
    debugPrint(
      "ApiClient: Session expired. Wiping session and redirecting to login.",
    );
    currentToken = null;
    currentRefreshToken = null;
    currentCpSession = null;
    try {
      final box = GetStorage();
      box.remove('is_logged_in');
      box.remove('token');
      box.remove('access_token');
      box.remove('refresh_token');
      box.remove('isAdmin');
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint("Session expired handler error: $e");
    }
  }

  /// Extracts the username from a JWT payload
  static String? extractUsernameFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      String clean = token.trim();
      if (clean.toLowerCase().startsWith('bearer ')) {
        clean = clean.substring(7).trim();
      }
      final parts = clean.split('.');
      if (parts.length >= 2) {
        final String payload = parts[1];
        final String normalized = base64Url.normalize(payload);
        final String decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> map = json.decode(decoded);
        final user =
            map['preferred_username'] ?? map['username'] ?? map['sub'];
        return user?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Retrieves the current access token:
  /// 1. In-memory currentToken (fast synchronous cache)
  /// 2. TokenStore (hardware Keystore/Keychain via FlutterSecureStorage)
  static Future<String?> getAccessToken() async {
    if (currentToken != null &&
        currentToken!.isNotEmpty &&
        currentToken != 'null') {
      return currentToken;
    }

    final token = await tokenStore.accessToken;
    if (token != null && token.isNotEmpty) {
      currentToken = token;
    }
    return token;
  }

  /// Retrieves the current refresh token from memory or hardware secure storage
  static Future<String?> getRefreshToken() async {
    if (currentRefreshToken != null &&
        currentRefreshToken!.isNotEmpty &&
        currentRefreshToken != 'null') {
      return currentRefreshToken;
    }

    final rToken = await tokenStore.refreshToken;
    if (rToken != null && rToken.isNotEmpty) {
      currentRefreshToken = rToken;
    }
    return rToken;
  }

  /// Persists authentication secrets inside TokenStore and updates cache
  static Future<void> saveToken(
    String token, {
    String? refreshToken,
    String? cpSession,
  }) async {
    await tokenStore.saveTokenResponse({
      'access_token': token,
      if (refreshToken != null && refreshToken.isNotEmpty)
        'refresh_token': refreshToken,
    });

    currentToken = token;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      currentRefreshToken = refreshToken;
    }
    currentCpSession = cpSession;

    if (cpSession != null && cpSession.isNotEmpty) {
      try {
        await storage.write(key: 'CP_SESSION', value: cpSession);
      } catch (_) {}
    }

    try {
      final box = GetStorage();
      final extractedUser = extractUsernameFromToken(token);
      if (extractedUser != null && extractedUser.isNotEmpty) {
        await box.write('username', extractedUser);
      }
      await box.write('is_logged_in', true);
    } catch (_) {}
  }

  /// Persists authentication tokens returned from login, refresh, or update-password endpoints
  static Future<void> saveTokens(
    dynamic responseData, {
    Map<String, dynamic>? headers,
    Headers? dioHeaders,
  }) async {
    if (responseData is! Map) return;
    final data = Map<String, dynamic>.from(responseData);
    await tokenStore.saveTokenResponse(data);

    final token = await tokenStore.accessToken;
    if (token != null) {
      currentToken = token;
      final extractedUser = extractUsernameFromToken(token);
      try {
        final box = GetStorage();
        if (extractedUser != null && extractedUser.isNotEmpty) {
          await box.write('username', extractedUser);
        }
        await box.write('is_logged_in', true);
      } catch (_) {}
    }

    final rToken = await tokenStore.refreshToken;
    if (rToken != null) {
      currentRefreshToken = rToken;
    }

    // Capture CP_SESSION cookie if returned
    dynamic setCookie = headers?['set-cookie'] ?? dioHeaders?['set-cookie'];
    if (setCookie is List) {
      for (final c in setCookie) {
        final cookieStr = c.toString();
        if (cookieStr.contains('CP_SESSION=')) {
          currentCpSession = cookieStr.split('CP_SESSION=')[1].split(';')[0];
          await storage.write(key: 'CP_SESSION', value: currentCpSession);
          break;
        }
      }
    } else if (setCookie is String && setCookie.contains('CP_SESSION=')) {
      currentCpSession = setCookie.split('CP_SESSION=')[1].split(';')[0];
      await storage.write(key: 'CP_SESSION', value: currentCpSession);
    }
  }

  /// Renews the login session via AuthInterceptor
  static Future<bool> refreshSession() async {
    try {
      final interceptor =
          api.interceptors.whereType<AuthInterceptor>().firstOrNull;
      if (interceptor != null) {
        await interceptor.refreshOnce();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("ApiClient: Token refresh failed: $e");
      return false;
    }
  }

  /// Clears stored tokens across secure storage, cache, and GetStorage
  static Future<void> logout() async {
    currentToken = null;
    currentRefreshToken = null;
    currentCpSession = null;
    await tokenStore.clear();

    try {
      final box = GetStorage();
      final username = box.read('username')?.toString() ??
          box.read('cached_current_username')?.toString();
      if (username != null && username.isNotEmpty) {
        await box.remove('biometric_registered_$username');
      }
      await box.remove('is_face_enrolled');
      await box.remove('access_token');
      await box.remove('token');
      await box.remove('refresh_token');
      await box.remove('CP_SESSION');
      await box.remove('is_logged_in');
      await box.remove('isAdmin');
      await box.remove('userProfile');
      await box.remove('roles');
      await box.remove('username');
      await box.remove('cached_portal_services');
    } catch (_) {}
  }
}
