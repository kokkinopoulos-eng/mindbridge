// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiChatServiceHash() => r'71eb2ff18b100d2b5b848b5c7417683d05d38c9e';

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
String _$chatNotifierHash() => r'bd06526bca3e3d38ce1477f68cf504f8fed10f96';

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
