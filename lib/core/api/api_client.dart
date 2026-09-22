import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/widgets.dart' show debugPrint;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/routes/page_route.dart';

class ApiClient {
  static const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Extracts the username (preferred_username, username, or sub) from a JWT payload
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
        final user = map['preferred_username'] ?? map['username'] ?? map['sub'];
        return user?.toString();
      }
    } catch (_) {}
    return null;
  }

  static String get defaultBaseUrl {
    try {
      return '${ApiConfig.baseUrl}/api/mobile';
    } catch (_) {
      return 'https://core-app.interior.gov.kh/api/mobile';
    }
  }

  /// In-memory token cache for instantaneous, synchronous access by widgets and formatters
  static String? currentToken;
  static String? currentCpSession;

  /// Retrieves the current access token:
  /// 1. In-memory currentToken (fast synchronous cache)
  /// 2. FlutterSecureStorage ('access_token', then 'token') - hardware Keystore/Keychain
  static Future<String?> getAccessToken() async {
    String? token = currentToken;
    if (token != null && token.isNotEmpty && token != 'null') {
      return token;
    }

    try {
      token = await storage.read(key: 'access_token');
      token ??= await storage.read(key: 'token');
    } catch (e) {
      debugPrint("FlutterSecureStorage read warning: $e");
    }

    // Clean up any legacy plaintext tokens from GetStorage to prevent data leakage
    try {
      final box = GetStorage();
      if (box.hasData('access_token') ||
          box.hasData('token') ||
          box.hasData('refresh_token') ||
          box.hasData('CP_SESSION')) {
        box.remove('access_token');
        box.remove('token');
        box.remove('refresh_token');
        box.remove('CP_SESSION');
      }
    } catch (_) {}

    if (token != null) {
      token = token.trim();
      if (token.toLowerCase().startsWith('bearer ')) {
        token = token.substring(7).trim();
      }
      if (token.isEmpty || token == 'null' || token == 'undefined') {
        token = null;
      } else {
        currentToken = token;
      }
    }
    return token;
  }

  /// Persists authentication secrets strictly inside FlutterSecureStorage (hardware-backed).
  /// Only non-sensitive metadata (username, login state) is saved in GetStorage.
  static Future<void> saveToken(
    String token, {
    String? refreshToken,
    String? cpSession,
  }) async {
    String cleanToken = token.trim();
    if (cleanToken.toLowerCase().startsWith('bearer ')) {
      cleanToken = cleanToken.substring(7).trim();
    }
    currentToken = cleanToken;
    currentCpSession = cpSession;

    // 1. Write non-sensitive metadata only to GetStorage
    try {
      final box = GetStorage();
      // Ensure plaintext tokens do not linger in unencrypted storage
      box.remove('access_token');
      box.remove('token');
      box.remove('refresh_token');
      box.remove('CP_SESSION');

      final extractedUser = extractUsernameFromToken(cleanToken);
      if (extractedUser != null && extractedUser.isNotEmpty) {
        await box.write('username', extractedUser);
      }
      await box.write('is_logged_in', true);
    } catch (_) {}

    // 2. Persist tokens strictly in hardware-backed FlutterSecureStorage
    try {
      await storage.write(key: 'access_token', value: cleanToken);
      await storage.write(key: 'token', value: cleanToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
      if (cpSession != null && cpSession.isNotEmpty) {
        await storage.write(key: 'CP_SESSION', value: cpSession);
      }
    } catch (e) {
      debugPrint("FlutterSecureStorage write warning: $e");
    }
  }

  /// Clears stored tokens and sessions across secure storage and cache
  static Future<void> logout() async {
    currentToken = null;
    currentCpSession = null;
    try {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'token');
      await storage.delete(key: 'CP_SESSION');
    } catch (_) {}

    try {
      final box = GetStorage();
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

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: defaultBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.addAll([
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              // 1. Normalize path so baseUrl (/api/mobile) is not duplicated
              if (options.path.startsWith('/api/mobile/')) {
                options.path = options.path.substring('/api/mobile'.length);
              } else if (options.path.startsWith('/api/mobile')) {
                options.path = options.path.substring('/api/mobile'.length);
              } else if (options.path.startsWith('api/mobile/')) {
                options.path =
                    '/${options.path.substring('api/mobile/'.length)}';
              }
              if (!options.path.startsWith('/') &&
                  !options.path.startsWith('http')) {
                options.path = '/${options.path}';
              }

              // 2. Enable browser credentials on Web for session cookies (CP_SESSION)
              if (kIsWeb) {
                options.extra['withCredentials'] = true;
              }

              // 3. Extract any explicit Authorization header already provided
              String? explicitAuth;
              for (final key in options.headers.keys) {
                if (key.toString().toLowerCase() == 'authorization') {
                  explicitAuth = options.headers[key]?.toString();
                  break;
                }
              }

              // Remove all case variations to guarantee no duplicate Authorization headers
              options.headers.removeWhere(
                (key, value) => key.toLowerCase() == 'authorization',
              );

              // 4. Resolve token (prefer explicit if valid, else get from storage)
              String? token;
              if (explicitAuth != null &&
                  explicitAuth.isNotEmpty &&
                  explicitAuth != 'Bearer null' &&
                  explicitAuth != 'null' &&
                  explicitAuth != 'Bearer undefined') {
                token = explicitAuth;
              } else {
                token = await getAccessToken();
              }

              // 5. Inject Authorization: Bearer <accessToken>
              String? accessToken;
              if (token != null && token.isNotEmpty) {
                String cleanToken = token.trim();
                if (cleanToken.toLowerCase().startsWith('bearer ')) {
                  cleanToken = cleanToken.substring(7).trim();
                }
                if (cleanToken.isNotEmpty &&
                    cleanToken != 'null' &&
                    cleanToken != 'undefined') {
                  accessToken = cleanToken;
                  options.headers['Authorization'] = 'Bearer $accessToken';
                }
              }

              // 6. If no token exists, show login instead of calling these endpoints
              final path = options.path.toLowerCase();
              final isAuthEndpoint =
                  path.contains('/auth/login') ||
                  path.contains('/auth/device/') ||
                  path.contains('/auth/refresh');

              if (!isAuthEndpoint &&
                  (accessToken == null || accessToken.isEmpty)) {
                debugPrint(
                  "ApiClient: No token exists for ${options.path}. Showing login instead of calling these endpoints.",
                );
                try {
                  final currentRoute = Get.currentRoute;
                  if (currentRoute != AppRoutes.login) {
                    Get.offAllNamed(AppRoutes.login);
                  }
                } catch (_) {}
                return handler.reject(
                  DioException(
                    requestOptions: options,
                    error:
                        "No token exists. Showing login instead of calling these endpoints.",
                    type: DioExceptionType.cancel,
                  ),
                );
              }

              // 6. On mobile/desktop, attach CP_SESSION cookie if available
              if (!kIsWeb) {
                String? sessionCookie = currentCpSession;
                if (sessionCookie == null || sessionCookie.isEmpty) {
                  try {
                    sessionCookie = await storage.read(key: 'CP_SESSION');
                  } catch (_) {}
                  if (sessionCookie != null && sessionCookie.isNotEmpty) {
                    currentCpSession = sessionCookie;
                  }
                }
                if (sessionCookie != null && sessionCookie.isNotEmpty) {
                  final existingCookie = options.headers['Cookie']?.toString();
                  if (existingCookie == null ||
                      !existingCookie.contains('CP_SESSION')) {
                    options.headers['Cookie'] =
                        existingCookie != null && existingCookie.isNotEmpty
                        ? '$existingCookie; CP_SESSION=$sessionCookie'
                        : 'CP_SESSION=$sessionCookie';
                  }
                }
              }

              // Ensure Accept header is always present
              options.headers['Accept'] = 'application/json';

              handler.next(options);
            },
            onError: (DioException e, handler) async {
              final path = e.requestOptions.path.toLowerCase();
              final isAuthEndpoint =
                  path.contains('/auth/login') ||
                  path.contains('/auth/device/') ||
                  path.contains('/auth/refresh');

              // Handle 401 unauthorized on protected endpoints
              if (e.response?.statusCode == 401 && !isAuthEndpoint) {
                debugPrint(
                  "ApiClient 401 on ${e.requestOptions.path}: ${e.response?.data}",
                );
                // Redirect to login only if not already there, avoiding infinite loops
                try {
                  final currentRoute = Get.currentRoute;
                  if (currentRoute != AppRoutes.login) {
                    await logout();
                    Get.offAllNamed(AppRoutes.login);
                  }
                } catch (_) {}
              }
              return handler.next(e);
            },
          ),
          LogInterceptor(
            requestHeader: false,
            requestBody: false,
            responseBody: false,
            responseHeader: false,
            error: true,
            logPrint: (object) {
              if (kDebugMode) {
                // ignore: avoid_print
                print(object);
              }
            },
          ),
        ]);
}
