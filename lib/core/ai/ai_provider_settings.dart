import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_provider_settings.g.dart';

enum AiProvider { openai, claude, gemini }

extension AiProviderX on AiProvider {
  String get label => switch (this) {
        AiProvider.openai  => 'OpenAI GPT-4o',
        AiProvider.claude  => 'Anthropic Claude',
        AiProvider.gemini  => 'Google Gemini',
      };

  String get key => name; // 'openai' | 'claude' | 'gemini'
}

class AiSettings {
  const AiSettings({
    this.provider = AiProvider.openai,
    this.openaiKey = '',
    this.claudeKey = '',
    this.geminiKey = '',
  });

  final AiProvider provider;
  final String openaiKey;
  final String claudeKey;
  final String geminiKey;

  String get activeKey => switch (provider) {
        AiProvider.openai => openaiKey,
        AiProvider.claude => claudeKey,
        AiProvider.gemini => geminiKey,
      };

  bool get isConfigured => activeKey.trim().isNotEmpty;

  AiSettings copyWith({
    AiProvider? provider,
    String? openaiKey,
    String? claudeKey,
    String? geminiKey,
  }) =>
      AiSettings(
        provider:   provider  ?? this.provider,
        openaiKey:  openaiKey ?? this.openaiKey,
        claudeKey:  claudeKey ?? this.claudeKey,
        geminiKey:  geminiKey ?? this.geminiKey,
      );
}

// ── Storage keys ──────────────────────────────────────────────────────────────
const _kProvider  = 'ai_provider';
const _kOpenAI    = 'ai_openai_key';
const _kClaude    = 'ai_claude_key';
const _kGemini    = 'ai_gemini_key';

@riverpod
class AiSettingsNotifier extends _$AiSettingsNotifier {
  late FlutterSecureStorage _storage;

  @override
  Future<AiSettings> build() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return _load();
  }

  Future<AiSettings> _load() async {
    final providerStr = await _storage.read(key: _kProvider) ?? 'openai';
    final provider = AiProvider.values.firstWhere(
      (p) => p.key == providerStr,
      orElse: () => AiProvider.openai,
    );
    return AiSettings(
      provider:  provider,
      openaiKey: await _storage.read(key: _kOpenAI) ?? '',
      claudeKey: await _storage.read(key: _kClaude) ?? '',
      geminiKey: await _storage.read(key: _kGemini) ?? '',
    );
  }

  Future<void> save(AiSettings settings) async {
    await Future.wait([
      _storage.write(key: _kProvider,  value: settings.provider.key),
      _storage.write(key: _kOpenAI,    value: settings.openaiKey),
      _storage.write(key: _kClaude,    value: settings.claudeKey),
      _storage.write(key: _kGemini,    value: settings.geminiKey),
    ]);
    state = AsyncValue.data(settings);
  }
}
