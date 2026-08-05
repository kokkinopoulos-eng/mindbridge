import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthSessionState> build() async {
    // TODO: Replace with real session restore for production
    // Dev bypass — goes straight to home
    return const AuthSessionState.authenticated(
      user: AppUser(
        id:          'dev-001',
        isAnonymous: true,
        isOnboarded: true,
        displayName: 'Επισκέπτης',
      ),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(
            email:    email,
            password: password,
          );
      return AuthSessionState.authenticated(user: user);
    });
  }

  Future<void> register({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).register(
            email:    email,
            password: password,
          );
      return AuthSessionState.authenticated(user: user);
    });
  }

  Future<void> loginAnonymous() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).loginAnonymous();
      return AuthSessionState.authenticated(user: user);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthSessionState.unauthenticated());
  }
}
