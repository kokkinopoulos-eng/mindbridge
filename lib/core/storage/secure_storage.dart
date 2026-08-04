import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

abstract final class _Keys {
  static const accessToken  = 'mb_access_token';
  static const refreshToken = 'mb_refresh_token';
  static const userId       = 'mb_user_id';
  static const biometricKey = 'mb_biometric_key';
}

@riverpod
SecureStorageService secureStorage(Ref ref) => SecureStorageService._();

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Tokens ────────────────────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _Keys.accessToken, value: accessToken),
      _storage.write(key: _Keys.refreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken()  => _storage.read(key: _Keys.accessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _Keys.refreshToken);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _Keys.accessToken),
      _storage.delete(key: _Keys.refreshToken),
    ]);
  }

  // ── User ──────────────────────────────────────────────────────────────
  Future<void> saveUserId(String id) =>
      _storage.write(key: _Keys.userId, value: id);
  Future<String?> getUserId() => _storage.read(key: _Keys.userId);

  // ── Full clear (logout / erasure) ─────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();

  // ── Existence check ───────────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
