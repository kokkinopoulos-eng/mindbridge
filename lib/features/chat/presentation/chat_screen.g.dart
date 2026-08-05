// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiChatServiceHash() => r'd263046674a58a8fb51ca7f250a3cd401a1eaad5';

/// See also [aiChatService].
@ProviderFor(aiChatService)
final aiChatServiceProvider = AutoDisposeProvider<AiChatService?>.internal(
  aiChatService,
  name: r'aiChatServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiChatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AiChatServiceRef = AutoDisposeProviderRef<AiChatService?>;
String _$chatNotifierHash() => r'68b13334e2b709ef459d022f777d253efbbf4fc7';

/// See also [ChatNotifier].
@ProviderFor(ChatNotifier)
final chatNotifierProvider =
    AutoDisposeNotifierProvider<ChatNotifier, ChatState>.internal(
  ChatNotifier.new,
  name: r'chatNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$chatNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatNotifier = AutoDisposeNotifier<ChatState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
