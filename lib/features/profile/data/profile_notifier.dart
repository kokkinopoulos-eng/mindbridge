import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/user_profile.dart';

part 'profile_notifier.g.dart';

const _kProfileKey = 'user_profile_v1';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  late FlutterSecureStorage _storage;

  @override
  Future<UserProfile> build() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final raw = await _storage.read(key: _kProfileKey);
    if (raw == null || raw.isEmpty) return const UserProfile();
    try {
      return UserProfile.decode(raw);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    await _storage.write(key: _kProfileKey, value: profile.encode());
    state = AsyncValue.data(profile);
  }
}
