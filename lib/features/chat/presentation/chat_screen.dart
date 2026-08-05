import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/ai/ai_provider_settings.dart';
import '../../../core/ai/ai_chat_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/crisis_banner.dart';

part 'chat_screen.g.dart';

// ── Domain ─────────────────────────────────────────────────────────────────
enum MessageRole { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isStreaming = false,
  });

  final String id;
  final MessageRole role;
  String content;
  final DateTime createdAt;
  bool isStreaming;
}

// ── State ──────────────────────────────────────────────────────────────────
class ChatState {
  const ChatState({
    this.messages  = const [],
    this.isTyping  = false,
    this.error,
    this.needsKey  = false,
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;
  /// true when the user hasn't configured an API key yet
  final bool needsKey;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    bool? needsKey,
  }) =>
      ChatState(
        messages: messages  ?? this.messages,
        isTyping: isTyping  ?? this.isTyping,
        error:    error,
        needsKey: needsKey  ?? this.needsKey,
      );
}

// ── Service provider ───────────────────────────────────────────────────────
@riverpod
AiChatService? aiChatService(Ref ref) {
  final settingsAsync = ref.watch(aiSettingsNotifierProvider);
  return settingsAsync.when(
    data:    (s) => s.isConfigured ? AiChatService(s) : null,
    loading: () => null,
    error:   (_, __) => null,
  );
}

// ── Chat notifier ──────────────────────────────────────────────────────────
@riverpod
class ChatNotifier extends _$ChatNotifier {
  static const _welcomeMsg =
      'Γεια σου! Είμαι εδώ για σένα. Πώς νιώθεις σήμερα; 😊';

  StreamSubscription<ChatChunk>? _sub;

  @override
  ChatState build() {
    ref.onDispose(() => _sub?.cancel());

    // React to settings changes — update needsKey without resetting chat
    ref.listen<AiChatService?>(aiChatServiceProvider, (_, next) {
      state = state.copyWith(needsKey: next == null);
    });

    _init();
    return const ChatState();
  }

  void _init() {
    final welcome = ChatMessage(
      id:        'welcome',
      role:      MessageRole.assistant,
      content:   _welcomeMsg,
      createdAt: DateTime.now(),
    );
    Future.microtask(() {
      final service = ref.read(aiChatServiceProvider);
      state = state.copyWith(
        messages: [welcome],
        needsKey: service == null,
      );
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final service = ref.read(aiChatServiceProvider);
    if (service == null) {
      state = state.copyWith(needsKey: true);
      return;
    }

    // Build history in API format
    final history = state.messages
        .where((m) => m.id != 'welcome')
        .map((m) => {
              'role':    m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList()
      ..add({'role': 'user', 'content': text.trim()});

    final userMsg = ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      role:      MessageRole.user,
      content:   text.trim(),
      createdAt: DateTime.now(),
    );
    final placeholder = ChatMessage(
      id:          '${userMsg.id}_r',
      role:        MessageRole.assistant,
      content:     '',
      createdAt:   DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, placeholder],
      isTyping: true,
      error:    null,
    );

    await _sub?.cancel();
    bool hasCrisis = false;

    _sub = service.sendMessage(history).listen(
      (chunk) {
        if (chunk.isDone) {
          final msgs = [...state.messages];
          if (msgs.isNotEmpty) msgs.last.isStreaming = false;
          state = state.copyWith(messages: msgs, isTyping: false);
          return;
        }
        if (chunk.isCrisis) hasCrisis = true;

        final msgs = [...state.messages];
        if (msgs.isNotEmpty && msgs.last.isStreaming) {
          msgs.last.content += chunk.text;
        }
        state = state.copyWith(
          messages: msgs,
          error:    hasCrisis ? '__crisis__' : null,
        );
      },
      onError: (e) {
        final msgs = [...state.messages];
        if (msgs.isNotEmpty && msgs.last.isStreaming) {
          msgs.last
            ..content     = 'Σφάλμα σύνδεσης — δοκίμασε ξανά.'
            ..isStreaming  = false;
        }
        state = state.copyWith(
          messages: msgs,
          isTyping: false,
          error:    e.toString(),
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl       = TextEditingController();
  final _scrollCtrl     = ScrollController();
  final _inputFocusNode = FocusNode();
  bool _showCrisis = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    // Crisis detection
    if (chatState.error == '__crisis__' && !_showCrisis) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _showCrisis = true),
      );
    }

    // Auto-scroll
    ref.listen(chatNotifierProvider, (_, __) => _scrollToBottom());

    // Which provider is active (for status label)
    final settingsAsync = ref.watch(aiSettingsNotifierProvider);
    final providerLabel = settingsAsync.valueOrNull?.provider.label ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const _AiAvatar(),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MindBridge AI',
                    style: TextStyle(fontSize: 15)),
                Text(
                  chatState.needsKey
                      ? 'Χωρίς API key'
                      : chatState.isTyping
                          ? 'Γράφει...'
                          : providerLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: chatState.needsKey
                        ? AppColors.statusCritical
                        : AppColors.statusGood,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded,
                color: AppColors.statusCritical),
            tooltip: 'Γραμμές βοήθειας',
            onPressed: () => setState(() => _showCrisis = true),
          ),
          // Settings shortcut
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ρυθμίσεις AI',
            onPressed: () => context.push(AppRoutes.apiSettings),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // No-key banner
              if (chatState.needsKey) _NoKeyBanner(),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: chatState.messages.length,
                  itemBuilder: (_, i) =>
                      _MessageBubble(message: chatState.messages[i]),
                ),
              ),

              // Typing indicator
              if (chatState.isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const _AiAvatar(size: 28),
                      const SizedBox(width: 8),
                      _TypingIndicator(),
                    ],
                  ),
                ),

              // Error banner (non-crisis, non-key)
              if (chatState.error != null &&
                  chatState.error != '__crisis__' &&
                  !chatState.needsKey)
                _ErrorBanner(message: chatState.error!),

              // Input bar
              _InputBar(
                controller: _textCtrl,
                focusNode: _inputFocusNode,
                onSend: _send,
                enabled: !chatState.needsKey,
              ),
            ],
          ),

          // Crisis overlay
          if (_showCrisis)
            CrisisBanner(onDismiss: () => setState(() => _showCrisis = false)),
        ],
      ),
    );
  }
}

// ── No-key banner ──────────────────────────────────────────────────────────
class _NoKeyBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
        color: AppColors.statusCritical.withOpacity(0.08),
        child: InkWell(
          onTap: () => context.push(AppRoutes.apiSettings),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(Icons.key_off,
                    color: AppColors.statusCritical, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Δεν έχεις ορίσει API key — πάτα εδώ για ρυθμίσεις',
                    style: TextStyle(
                      color: AppColors.statusCritical,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.statusCritical, size: 18),
              ],
            ),
          ),
        ),
      );
}

// ── Error banner ───────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.statusCritical.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.statusCritical,
            fontSize: 12,
          ),
        ),
      );
}

// ── Message bubble ─────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _AiAvatar(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.brand : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: message.isStreaming && message.content.isEmpty
                      ? const SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            color: AppColors.brand,
                            minHeight: 2,
                          ),
                        )
                      : Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isUser
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                ),
                const SizedBox(height: 3),
                Text(
                  message.createdAt.timeHm,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── AI avatar ──────────────────────────────────────────────────────────────
class _AiAvatar extends StatelessWidget {
  const _AiAvatar({this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.favorite,
            color: Colors.white, size: size * 0.45),
      );
}

// ── Typing indicator ───────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 160), c.repeat);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(16),
            topRight:    Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft:  Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7 + _controllers[i].value * 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      );
}

// ── Input bar ──────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gridline)),
        ),
        padding: EdgeInsets.only(
          left:   AppSpacing.md,
          right:  AppSpacing.md,
          top:    AppSpacing.sm,
          bottom: AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode:  focusNode,
                enabled:    enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Γράψε εδώ...'
                      : 'Ορισε πρώτα API key...',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.rFull),
                    borderSide:
                        const BorderSide(color: AppColors.gridline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.rFull),
                    borderSide:
                        const BorderSide(color: AppColors.gridline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.rFull),
                    borderSide: const BorderSide(
                        color: AppColors.brand, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: enabled ? AppColors.brand : AppColors.textMuted,
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, size: 18),
                color: Colors.white,
                onPressed: enabled ? onSend : null,
                tooltip: 'Αποστολή',
              ),
            ),
          ],
        ),
      );
}
