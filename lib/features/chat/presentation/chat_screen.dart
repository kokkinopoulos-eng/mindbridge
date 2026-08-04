import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_client.dart';
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
    this.messages = const [],
    this.isConnected = false,
    this.isTyping = false,
    this.sessionId,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isConnected;
  final bool isTyping;
  final String? sessionId;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnected,
    bool? isTyping,
    String? sessionId,
    String? error,
  }) => ChatState(
        messages:    messages    ?? this.messages,
        isConnected: isConnected ?? this.isConnected,
        isTyping:    isTyping    ?? this.isTyping,
        sessionId:   sessionId   ?? this.sessionId,
        error:       error,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────
@riverpod
class ChatNotifier extends _$ChatNotifier {
  WebSocketChannel? _channel;
  static const _welcomeMsg = 'Γεια σου! Είμαι εδώ για σένα. Πώς νιώθεις σήμερα; 😊';

  @override
  ChatState build() {
    ref.onDispose(_disconnect);
    _init();
    return const ChatState();
  }

  Future<void> _init() async {
    // Start with welcome message
    final welcome = ChatMessage(
      id:        'welcome',
      role:      MessageRole.assistant,
      content:   _welcomeMsg,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [welcome]);
    await _connect();
  }

  Future<void> _connect() async {
    try {
      final wsUrl = '${ApiConstants.wsUrl}/chat/stream';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      state = state.copyWith(isConnected: true);

      _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          state = state.copyWith(
            isConnected: false,
            error: 'Σφάλμα σύνδεσης — επανασύνδεση...',
          );
          Future.delayed(const Duration(seconds: 3), _connect);
        },
        onDone: () => state = state.copyWith(isConnected: false),
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = data['type'] as String?;

    switch (type) {
      case 'session_created':
        state = state.copyWith(sessionId: data['session_id'] as String?);

      case 'chunk':
        // Streaming: append to last assistant message
        final msgs = [...state.messages];
        final last = msgs.lastOrNull;
        if (last != null && last.role == MessageRole.assistant && last.isStreaming) {
          last.content += data['content'] as String? ?? '';
          state = state.copyWith(messages: msgs);
        }

      case 'message_end':
        final msgs = [...state.messages];
        msgs.lastWhere((m) => m.isStreaming, orElse: () => msgs.first)
            .isStreaming = false;
        state = state.copyWith(messages: msgs, isTyping: false);

      case 'crisis_detected':
        // Safety layer triggered — handled in UI via crisisDetected flag
        state = state.copyWith(
          isTyping: false,
          error: '__crisis__',
        );

      case 'error':
        state = state.copyWith(
          isTyping: false,
          error: data['message'] as String? ?? 'Σφάλμα AI',
        );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message immediately
    final userMsg = ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      role:      MessageRole.user,
      content:   text.trim(),
      createdAt: DateTime.now(),
    );
    // Add placeholder for streaming assistant response
    final assistantPlaceholder = ChatMessage(
      id:          '${userMsg.id}_response',
      role:        MessageRole.assistant,
      content:     '',
      createdAt:   DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantPlaceholder],
      isTyping: true,
    );

    if (_channel != null && state.isConnected) {
      _channel!.sink.add(jsonEncode({
        'type':    'message',
        'content': text.trim(),
        'session_id': state.sessionId,
      }));
    } else {
      // Offline fallback
      await Future.delayed(const Duration(milliseconds: 1200));
      final msgs = [...state.messages];
      msgs.last
        ..content     = 'Φαίνεται ότι δεν υπάρχει σύνδεση. Προσπαθώ να επανασυνδεθώ...'
        ..isStreaming = false;
      state = state.copyWith(messages: msgs, isTyping: false);
    }
  }

  void _disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl     = TextEditingController();
  final _scrollCtrl   = ScrollController();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showCrisis = true);
      });
    }

    // Auto-scroll on new messages
    ref.listen(chatNotifierProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _AiAvatar(),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MindBridge AI', style: TextStyle(fontSize: 15)),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: chatState.isConnected
                          ? AppColors.statusGood
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatState.isConnected ? 'Online' : 'Αποσυνδεδεμένο',
                      style: TextStyle(
                        fontSize: 11,
                        color: chatState.isConnected
                            ? AppColors.statusGood
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: chatState.messages.length,
                  itemBuilder: (_, i) {
                    final msg = chatState.messages[i];
                    return _MessageBubble(message: msg);
                  },
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
                      _AiAvatar(size: 28),
                      const SizedBox(width: 8),
                      _TypingIndicator(),
                    ],
                  ),
                ),

              // Error banner (non-crisis)
              if (chatState.error != null && chatState.error != '__crisis__')
                Container(
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
                    chatState.error!,
                    style: const TextStyle(
                      color: AppColors.statusCritical,
                      fontSize: 12,
                    ),
                  ),
                ),

              // Input bar
              _InputBar(
                controller: _textCtrl,
                focusNode: _inputFocusNode,
                onSend: _send,
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
            _AiAvatar(size: 28),
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
                    horizontal: 13,
                    vertical: 10,
                  ),
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
        child: Icon(
          Icons.favorite,
          color: Colors.white,
          size: size * 0.45,
        ),
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
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.gridline),
          ),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Exercises shortcut
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
              color: AppColors.textMuted,
              tooltip: 'Ασκήσεις',
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Γράψε εδώ...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rFull),
                    borderSide: const BorderSide(color: AppColors.gridline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rFull),
                    borderSide: const BorderSide(color: AppColors.gridline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.rFull),
                    borderSide:
                        const BorderSide(color: AppColors.brand, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surface0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Send button
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, size: 18),
                color: Colors.white,
                onPressed: onSend,
                tooltip: 'Αποστολή',
              ),
            ),
          ],
        ),
      );
}
