import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';

part 'api_client.g.dart';

// ── Constants ──────────────────────────────────────────────────────────────
abstract final class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.mindbridge.gr/api/v1',
  );
  static const wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.mindbridge.gr/api/v1',
  );
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);
}

// ── Provider ───────────────────────────────────────────────────────────────
@riverpod
Dio dio(Ref ref) {
  final storage = ref.watch(secureStorageProvider);
  final logger  = Logger();

  final dio = Dio(BaseOptions(
    baseUrl:        ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept':       'application/json',
      'X-Client':     'mindbridge-flutter/1.0',
    },
  ));

  // ── Auth interceptor ──────────────────────────────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      logger.d('[→] ${options.method} ${options.path}');
      handler.next(options);
    },
    onResponse: (response, handler) {
      logger.d('[←] ${response.statusCode} ${response.requestOptions.path}');
      handler.next(response);
    },
    onError: (error, handler) async {
      logger.e('[✗] ${error.response?.statusCode} ${error.requestOptions.path}');

      // ── 401: token refresh ─────────────────────────────────────────
      if (error.response?.statusCode == 401) {
        try {
          final refreshToken = await storage.getRefreshToken();
          if (refreshToken == null) throw Exception('No refresh token');

          final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
          final resp = await refreshDio.post('/auth/refresh', data: {
            'refresh_token': refreshToken,
          });

          final newAccessToken = resp.data['access_token'] as String;
          final newRefreshToken = resp.data['refresh_token'] as String;
          await storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Retry original request
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResp = await dio.fetch(opts);
          return handler.resolve(retryResp);
        } catch (_) {
          await storage.clearTokens();
          // Router redirect will handle logout
        }
      }
      handler.next(error);
    },
  ));

  // ── Logging interceptor (debug only) ─────────────────────────────────
  assert(() {
    dio.interceptors.add(LogInterceptor(
      request:      true,
      requestBody:  true,
      responseBody: true,
      error:        true,
    ));
    return true;
  }());

  return dio;
}

// ── API exception ─────────────────────────────────────────────────────────
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    return ApiException(
      statusCode: e.response?.statusCode ?? 0,
      message: (data is Map ? data['detail'] ?? data['message'] : null)
              as String? ??
          e.message ??
          'Unknown error',
      errors: data is Map ? data['errors'] as Map<String, dynamic>? : null,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
