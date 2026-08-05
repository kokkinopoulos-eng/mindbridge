import 'dart:convert';

/// A stored message (persisted to Hive)
class StoredMessage {
  const StoredMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;      // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'role':      role,
    'content':   content,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory StoredMessage.fromJson(Map<String, dynamic> j) => StoredMessage(
    role:      j['role']    as String,
    content:   j['content'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
  );

  /// Convert to API format for sending to AI
  Map<String, String> toApiMessage() => {'role': role, 'content': content};
}

/// A full chat session
class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<StoredMessage> messages;

  /// Auto-generate title from first user message
  static String titleFrom(String firstUserMessage) {
    final t = firstUserMessage.trim();
    if (t.length <= 45) return t;
    return '${t.substring(0, 42)}...';
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'title':     title,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'messages':  messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
    id:        j['id']    as String,
    title:     j['title'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int),
    messages:  (j['messages'] as List<dynamic>)
        .map((e) => StoredMessage.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  String encode() => jsonEncode(toJson());
  static ChatSession decode(String s) =>
      ChatSession.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Messages formatted for AI API (no welcome message)
  List<Map<String, String>> get apiMessages =>
      messages.map((m) => m.toApiMessage()).toList();

  /// Session summary for display
  String get preview {
    final last = messages.lastOrNull;
    if (last == null) return '';
    final t = last.content.trim();
    if (t.length <= 60) return t;
    return '${t.substring(0, 57)}...';
  }
}
