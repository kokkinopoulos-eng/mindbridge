import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/ai/ai_provider_settings.dart';
import '../../../core/ai/ai_chat_service.dart';
import '../../profile/data/profile_notifier.dart';
import '../data/sessions_notifier.dart';
import '../domain/chat_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/crisis_banner.dart';
import 'sessions_bottom_sheet.dart';

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
    this.messages       = const [],
    this.isTyping       = false,
    this.error,
    this.needsKey       = false,
    this.sessionId,
    this.sessionTitle   = 'Νέα Συνεδρία',
    this.lastUserText,
    this.sessionEnded   = false,
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;
  final bool needsKey;
  final String? sessionId;
  final String sessionTitle;
  /// Last user text sent — for retry on error
  final String? lastUserText;
  /// True after "Τέλος Συνεδρίας" pressed
  final bool sessionEnded;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    bool? needsKey,
    String? sessionId,
    String? sessionTitle,
    String? lastUserText,
    bool? sessionEnded,
  }) =>
      ChatState(
        messages:      messages      ?? this.messages,
        isTyping:      isTyping      ?? this.isTyping,
        error:         error,
        needsKey:      needsKey      ?? this.needsKey,
        sessionId:     sessionId     ?? this.sessionId,
        sessionTitle:  sessionTitle  ?? this.sessionTitle,
        lastUserText:  lastUserText  ?? this.lastUserText,
        sessionEnded:  sessionEnded  ?? this.sessionEnded,
      );
}

// ── Service provider ───────────────────────────────────────────────────────
@riverpod
AiChatService? aiChatService(Ref ref) {
  final settingsAsync = ref.watch(aiSettingsNotifierProvider);
  final profileAsync  = ref.watch(profileNotifierProvider);
  final profile = profileAsync.valueOrNull;
  return settingsAsync.when(
    data:    (s) => s.isConfigured ? AiChatService(s, profile: profile) : null,
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

    _loadCurrentSession();
    return const ChatState();
  }

  // ── Session loading ─────────────────────────────────────────────────────
  Future<void> _loadCurrentSession() async {
    final sessionsNotifier = ref.read(sessionsNotifierProvider.notifier);
    final sessionsAsync    = ref.read(sessionsNotifierProvider);
    SessionsState sessState;
    try {
      sessState = await sessionsAsync.when(
        data:    (s) async => s,
        loading: () => ref.read(sessionsNotifierProvider.future),
        error:   (_, __) async => const SessionsState(),
      );
    } catch (_) {
      sessState = const SessionsState();
    }

    ChatSession session;
    if (sessState.current != null) {
      session = sessState.current!;
    } else {
      session = await sessionsNotifier.newSession();
    }

    final uiMessages = [
      _buildWelcome(),
      ...session.messages.map(_storedToUi),
    ];

    final service = ref.read(aiChatServiceProvider);
    state = ChatState(
      messages:     uiMessages,
      sessionId:    session.id,
      sessionTitle: session.title,
      needsKey:     service == null,
    );
  }

  /// Switch to (or reload) a specific session
  Future<void> loadSession(String sessionId) async {
    await ref.read(sessionsNotifierProvider.notifier).switchTo(sessionId);
    final sessState = await ref.read(sessionsNotifierProvider.future);
    final session   = sessState.sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) return;

    final uiMessages = [
      _buildWelcome(),
      ...session.messages.map(_storedToUi),
    ];

    final service = ref.read(aiChatServiceProvider);
    state = ChatState(
      messages:     uiMessages,
      sessionId:    session.id,
      sessionTitle: session.title,
      needsKey:     service == null,
    );
  }

  /// Start a brand-new session
  Future<void> newSession() async {
    await _sub?.cancel();
    final session = await ref.read(sessionsNotifierProvider.notifier).newSession();
    final service = ref.read(aiChatServiceProvider);
    state = ChatState(
      messages:     [_buildWelcome()],
      sessionId:    session.id,
      sessionTitle: session.title,
      needsKey:     service == null,
    );
  }

  // ── Message sending ─────────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.sessionEnded) return;

    final service = ref.read(aiChatServiceProvider);
    if (service == null) {
      state = state.copyWith(needsKey: true);
      return;
    }

    final sessionId = state.sessionId;

    // Build history in API format (skip welcome placeholder)
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
      messages:     [...state.messages, userMsg, placeholder],
      isTyping:     true,
      error:        null,
      lastUserText: text.trim(),
    );

    // Persist user message
    if (sessionId != null) {
      await ref.read(sessionsNotifierProvider.notifier).appendMessage(
        sessionId,
        StoredMessage(
          role:      'user',
          content:   text.trim(),
          createdAt: userMsg.createdAt,
        ),
      );
      // Update title in state if session got auto-titled
      final sessState = ref.read(sessionsNotifierProvider).valueOrNull;
      final session   = sessState?.sessions.where((s) => s.id == sessionId).firstOrNull;
      if (session != null && session.title != state.sessionTitle) {
        state = state.copyWith(sessionTitle: session.title);
      }
    }

    await _sub?.cancel();
    bool hasCrisis    = false;
    String assistantContent = '';

    _sub = service.sendMessage(history).listen(
      (chunk) {
        if (chunk.isDone) {
          final msgs = [...state.messages];
          if (msgs.isNotEmpty) msgs.last.isStreaming = false;
          state = state.copyWith(messages: msgs, isTyping: false);

          // Persist assistant message
          if (sessionId != null && assistantContent.isNotEmpty) {
            ref.read(sessionsNotifierProvider.notifier).appendMessage(
              sessionId,
              StoredMessage(
                role:      'assistant',
                content:   assistantContent,
                createdAt: DateTime.now(),
              ),
            );
          }

          // Extract insight every 5 user messages
          final userCount = state.messages
              .where((m) => m.role == MessageRole.user).length;
          if (userCount % 5 == 0 && assistantContent.isNotEmpty) {
            _extractAndSaveInsight(history, assistantContent);
          }
          return;
        }
        if (chunk.isCrisis) hasCrisis = true;
        assistantContent += chunk.text;

        final msgs = [...state.messages];
        if (msgs.isNotEmpty && msgs.last.isStreaming) {
          msgs.last.content = assistantContent;
        }
        state = state.copyWith(
          messages: msgs,
          error:    hasCrisis ? '__crisis__' : null,
        );
      },
      onError: (e) {
        final msgs = [...state.messages];
        if (msgs.isNotEmpty && msgs.last.isStreaming) {
          msgs.remove(msgs.last); // Remove empty placeholder
        }
        state = state.copyWith(
          messages: msgs,
          isTyping: false,
          error:    e.toString(),
        );
      },
    );
  }

  /// Retry the last failed message
  Future<void> retryLastMessage() async {
    final text = state.lastUserText;
    if (text == null || text.isEmpty) return;
    state = state.copyWith(error: null);
    await sendMessage(text);
  }

  /// End the current session — AI delivers a wrap-up, then insight is saved
  Future<void> endSession() async {
    if (state.sessionEnded || state.isTyping) return;
    const prompt =
        '[ΤΕΛΟΣ ΣΥΝΕΔΡΙΑΣ] Ο χρήστης ολοκλήρωσε τη συνεδρία. '
        'Κάνε ένα σύντομο therapeutic wrap-up (2-4 προτάσεις): '
        'αναγνώρισε αυτό που μοιράστηκε, δώσε ένα σαφές takeaway ή βήμα για τη μέρα, '
        'και αποχαιρέτησέ τον θερμά.';
    await sendMessage(prompt);
    state = state.copyWith(sessionEnded: true);
    // Force insight extraction at session close regardless of count
    final service = ref.read(aiChatServiceProvider);
    if (service != null) {
      final history = state.messages
          .where((m) => m.id != 'welcome')
          .map((m) => {
                'role':    m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();
      _extractAndSaveInsight(history, '');
    }
  }

  /// Fire-and-forget: extract 1 insight, save to profile keypoints
  Future<void> _extractAndSaveInsight(
      List<Map<String, String>> history, String lastAssistant) async {
    final service = ref.read(aiChatServiceProvider);
    if (service == null) return;

    final trimmed = history.length > 14 ? history.sublist(history.length - 14) : history;
    final fullHistory = lastAssistant.isNotEmpty
        ? [...trimmed, {'role': 'assistant', 'content': lastAssistant}]
        : trimmed;
    if (fullHistory.isEmpty) return;

    final insight = await service.extractInsight(fullHistory);
    if (insight == null || insight.trim().isEmpty) return;

    final profile = ref.read(profileNotifierProvider).valueOrNull;
    if (profile == null) return;
    await ref.read(profileNotifierProvider.notifier)
        .save(profile.withNewKeypoint(insight.trim()));
  }

  void clearError() => state = state.copyWith(error: null);

  // ── Helpers ─────────────────────────────────────────────────────────────
  static ChatMessage _buildWelcome() => ChatMessage(
        id:        'welcome',
        role:      MessageRole.assistant,
        content:   _welcomeMsg,
        createdAt: DateTime.now(),
      );

  static ChatMessage _storedToUi(StoredMessage m) => ChatMessage(
        id:        '${m.createdAt.millisecondsSinceEpoch}',
        role:      m.role == 'user' ? MessageRole.user : MessageRole.assistant,
        content:   m.content,
        createdAt: m.createdAt,
      );
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

  void _confirmEndSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Τέλος συνεδρίας;'),
        content: const Text(
          'Ο AI θα κάνει ένα σύντομο wrap-up και θα κλείσει τη συνεδρία. '
          'Δεν θα μπορείς να συνεχίσεις — ξεκίνα νέα για νέα συνομιλία.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Άκυρο'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatNotifierProvider.notifier).endSession();
            },
            child: const Text('Τέλος'),
          ),
        ],
      ),
    );
  }

  void _showSessions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionsBottomSheet(
        onSessionSelected: (id) {
          ref.read(chatNotifierProvider.notifier).loadSession(id);
          _scrollToBottom();
        },
        onNewSession: () {
          ref.read(chatNotifierProvider.notifier).newSession();
        },
      ),
    );
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

    // Auto-scroll on new messages
    ref.listen(chatNotifierProvider, (_, __) => _scrollToBottom());

    final settingsAsync  = ref.watch(aiSettingsNotifierProvider);
    final providerLabel  = settingsAsync.valueOrNull?.provider.label ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const _AiAvatar(),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.sessionTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            ),
          ],
        ),
        actions: [
          // End session
          if (!chatState.sessionEnded && chatState.messages.length > 1)
            IconButton(
              icon: const Icon(Icons.meeting_room_outlined),
              tooltip: 'Τέλος συνεδρίας',
              onPressed: chatState.isTyping
                  ? null
                  : () => _confirmEndSession(context),
            ),
          // Sessions list
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Ιστορικό συνεδριών',
            onPressed: _showSessions,
          ),
          // New session
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Νέα συνεδρία',
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).newSession();
              context.go(AppRoutes.chat);
            },
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

              // Session ended banner
              if (chatState.sessionEnded)
                _SessionEndedBanner(onNew: () {
                  ref.read(chatNotifierProvider.notifier).newSession();
                  context.go(AppRoutes.chat);
                }),

              // Error banner (non-crisis, non-key)
              if (chatState.error != null &&
                  chatState.error != '__crisis__' &&
                  !chatState.needsKey &&
                  !chatState.sessionEnded)
                _ErrorBanner(
                  message: chatState.error!,
                  onRetry: () =>
                      ref.read(chatNotifierProvider.notifier).retryLastMessage(),
                ),

              // Input bar
              _InputBar(
                controller: _textCtrl,
                focusNode:  _inputFocusNode,
                onSend:     _send,
                enabled:    !chatState.needsKey && !chatState.sessionEnded,
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
  const _ErrorBanner({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.statusCritical.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Σφάλμα σύνδεσης — έλεγξε το δίκτυό σου.',
                style: const TextStyle(
                  color: AppColors.statusCritical,
                  fontSize: 12,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Ξανά', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.statusCritical,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      );
}

// ── Session ended banner ───────────────────────────────────────────────────
class _SessionEndedBanner extends StatelessWidget {
  const _SessionEndedBanner({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        color: AppColors.brandLight,
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.brand, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Η συνεδρία ολοκληρώθηκε',
                style: TextStyle(
                  color: AppColors.brandDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onNew,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Νέα συνεδρία →',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
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
                      : isUser
                          ? Text(
                              message.content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : MarkdownBody(
                              data: message.content,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                                strong: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                em: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                  fontStyle: FontStyle.italic,
                                ),
                                listBullet: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                                blockquote: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                code: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.brandDark,
                                  backgroundColor: AppColors.brandLight,
                                ),
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
