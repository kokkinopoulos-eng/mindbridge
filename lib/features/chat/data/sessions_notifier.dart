import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/chat_session.dart';

part 'sessions_notifier.g.dart';

const _kBoxSessions = 'chat_sessions';
const _kBoxConfig   = 'chat_config';
const _kCurrentId   = 'current_session_id';

class SessionsState {
  const SessionsState({
    this.sessions      = const [],
    this.currentId,
  });

  final List<ChatSession> sessions;
  final String? currentId;

  ChatSession? get current =>
      currentId == null
          ? null
          : sessions.where((s) => s.id == currentId).firstOrNull;

  SessionsState copyWith({
    List<ChatSession>? sessions,
    String? currentId,
    bool clearCurrentId = false,
  }) => SessionsState(
    sessions:  sessions  ?? this.sessions,
    currentId: clearCurrentId ? null : (currentId ?? this.currentId),
  );
}

@riverpod
class SessionsNotifier extends _$SessionsNotifier {
  late Box<String> _boxSessions;
  late Box<String> _boxConfig;

  @override
  Future<SessionsState> build() async {
    _boxSessions = await Hive.openBox<String>(_kBoxSessions);
    _boxConfig   = await Hive.openBox<String>(_kBoxConfig);
    return _load();
  }

  SessionsState _load() {
    final sessions = _boxSessions.values
        .map((raw) {
          try { return ChatSession.decode(raw); }
          catch (_) { return null; }
        })
        .whereType<ChatSession>()
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final currentId = _boxConfig.get(_kCurrentId);
    return SessionsState(sessions: sessions, currentId: currentId);
  }

  /// Create a new empty session and make it current
  Future<ChatSession> newSession() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final session = ChatSession(
      id:        id,
      title:     'Νέα Συνεδρία',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages:  [],
    );
    await _boxSessions.put(id, session.encode());
    await _boxConfig.put(_kCurrentId, id);

    final current = state.valueOrNull ?? const SessionsState();
    state = AsyncValue.data(current.copyWith(
      sessions:  [session, ...current.sessions],
      currentId: id,
    ));
    return session;
  }

  /// Switch to an existing session
  Future<void> switchTo(String sessionId) async {
    await _boxConfig.put(_kCurrentId, sessionId);
    final current = state.valueOrNull ?? const SessionsState();
    state = AsyncValue.data(current.copyWith(currentId: sessionId));
  }

  /// Append a message to the current session
  Future<void> appendMessage(String sessionId, StoredMessage msg) async {
    final current = state.valueOrNull ?? const SessionsState();
    final idx = current.sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return;

    final session = current.sessions[idx];
    session.messages.add(msg);
    session.updatedAt = DateTime.now();

    // Auto-title from first user message
    if (session.title == 'Νέα Συνεδρία' && msg.role == 'user') {
      session.title = ChatSession.titleFrom(msg.content);
    }

    await _boxSessions.put(sessionId, session.encode());

    final updated = List<ChatSession>.from(current.sessions)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncValue.data(current.copyWith(sessions: updated));
  }

  /// Update the last assistant message (streaming append)
  Future<void> updateLastAssistant(
      String sessionId, String fullContent) async {
    final current = state.valueOrNull ?? const SessionsState();
    final idx = current.sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return;

    final session = current.sessions[idx];
    if (session.messages.isNotEmpty &&
        session.messages.last.role == 'assistant') {
      final old = session.messages.last;
      session.messages[session.messages.length - 1] = StoredMessage(
        role:      old.role,
        content:   fullContent,
        createdAt: old.createdAt,
      );
      session.updatedAt = DateTime.now();
      await _boxSessions.put(sessionId, session.encode());
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _boxSessions.delete(sessionId);
    final current = state.valueOrNull ?? const SessionsState();
    final updated = current.sessions.where((s) => s.id != sessionId).toList();

    String? newCurrentId = current.currentId;
    if (current.currentId == sessionId) {
      newCurrentId = updated.firstOrNull?.id;
      await _boxConfig.put(_kCurrentId, newCurrentId ?? '');
    }
    state = AsyncValue.data(SessionsState(
      sessions:  updated,
      currentId: newCurrentId,
    ));
  }
}
