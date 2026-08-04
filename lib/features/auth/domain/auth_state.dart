import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    String? email,
    @Default(false) bool isAnonymous,
    @Default(false) bool isOnboarded,
    String? displayName,
    @Default('free') String subscriptionTier,
    UserPreferences? preferences,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default('friendly') String aiTone,           // 'friendly' | 'professional' | 'neutral'
    @Default(['anxiety']) List<String> concerns,   // user's stated issues
    @Default(15) int preferredSessionMinutes,
    @Default(true) bool notificationsEnabled,
    @Default('el') String language,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}

@freezed
class AuthSessionState with _$AuthSessionState {
  const factory AuthSessionState.initial()        = _Initial;
  const factory AuthSessionState.loading()        = _Loading;
  const factory AuthSessionState.authenticated({
    required AppUser user,
  }) = _Authenticated;
  const factory AuthSessionState.unauthenticated() = _Unauthenticated;
  const factory AuthSessionState.error(String message) = _Error;
}

extension AuthSessionStateX on AuthSessionState {
  bool get isAuthenticated => maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );

  bool get isOnboarded => maybeWhen(
        authenticated: (user) => user.isOnboarded,
        orElse: () => false,
      );

  AppUser? get user => maybeWhen(
        authenticated: (user) => user,
        orElse: () => null,
      );
}
