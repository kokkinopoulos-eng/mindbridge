import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_state.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository(
      dio:     ref.watch(dioProvider),
      storage: ref.watch(secureStorageProvider),
    );

class AuthRepository {
  AuthRepository({required this.dio, required this.storage});

  final Dio dio;
  final SecureStorageService storage;

  // ── Register ───────────────────────────────────────────────────────────
  Future<AppUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await dio.post('/auth/register', data: {
        'email':    email,
        'password': password,
      });
      await storage.saveTokens(
        accessToken:  resp.data['access_token'] as String,
        refreshToken: resp.data['refresh_token'] as String,
      );
      return AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await dio.post('/auth/login', data: {
        'email':    email,
        'password': password,
      });
      await storage.saveTokens(
        accessToken:  resp.data['access_token'] as String,
        refreshToken: resp.data['refresh_token'] as String,
      );
      return AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Anonymous session ─────────────────────────────────────────────────
  Future<AppUser> loginAnonymous() async {
    // TODO: Replace with real API call when backend is ready
    // Mock anonymous user for development/demo
    await Future.delayed(const Duration(milliseconds: 500));
    return const AppUser(
      id:          'anon-dev-001',
      isAnonymous: true,
      isOnboarded: true,
      displayName: 'Επισκέπτης',
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await dio.delete('/auth/logout');
    } catch (_) {
      // best-effort
    } finally {
      await storage.clearTokens();
    }
  }

  // ── Restore session ───────────────────────────────────────────────────
  Future<AppUser?> restoreSession() async {
    if (!await storage.hasValidSession()) return null;
    try {
      final resp = await dio.get('/auth/me');
      return AppUser.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await storage.clearTokens();
      return null;
    }
  }
}
