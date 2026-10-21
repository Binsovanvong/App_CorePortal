import 'dart:async';
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/token_store.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio api;
  final Dio refreshApi;
  final TokenStore tokens;
  final void Function() onSessionExpired;

  Future<void>? _refreshing;

  AuthInterceptor({
    required this.api,
    required this.refreshApi,
    required this.tokens,
    required this.onSessionExpired,
  });

  Future<void> refreshOnce() => _refreshOnce();

  Future<void> _refreshOnce() {
    final current = _refreshing;
    if (current != null) return current;

    final future = _refreshTokens();
    _refreshing = future;

    return future.whenComplete(() {
      if (identical(_refreshing, future)) {
        _refreshing = null;
      }
    });
  }

  Future<void> _refreshTokens() async {
    final refreshToken = await tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token');
    }

    try {
      final response = await refreshApi.post<Map<String, dynamic>>(
        '/api/mobile/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      await tokens.saveTokenResponse(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await tokens.clear();
        onSessionExpired();
      }
      rethrow;
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      _normalizePath(options);

      var accessToken = await tokens.accessToken;

      if (accessToken != null && await tokens.expiresSoon()) {
        await _refreshOnce();
        accessToken = await tokens.accessToken;
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      handler.next(options);
    } catch (error) {
      await tokens.clear();
      onSessionExpired();
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final alreadyRetried = request.extra['authRetried'] == true;

    if (error.response?.statusCode != 401 || alreadyRetried) {
      handler.next(error);
      return;
    }

    try {
      await _refreshOnce();

      final newAccessToken = await tokens.accessToken;
      if (newAccessToken == null) {
        handler.next(error);
        return;
      }

      request.extra['authRetried'] = true;
      request.headers['Authorization'] = 'Bearer $newAccessToken';

      final response = await api.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      await tokens.clear();
      onSessionExpired();
      handler.next(error);
    }
  }

  void _normalizePath(RequestOptions options) {
    if (options.path.startsWith('http://') ||
        options.path.startsWith('https://')) {
      return;
    }
    if (options.path.startsWith('/api/mobile/')) {
      return;
    }
    if (options.path == '/api/mobile') {
      return;
    }
    if (options.path.startsWith('api/mobile/')) {
      options.path = '/${options.path}';
      return;
    }
    if (!options.path.startsWith('/api/')) {
      final clean =
          options.path.startsWith('/') ? options.path : '/${options.path}';
      options.path = '/api/mobile$clean';
    }
  }
}
