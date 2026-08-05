import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider_settings.dart';

/// A single chunk emitted during streaming
class ChatChunk {
  const ChatChunk({required this.text, this.isDone = false, this.isCrisis = false});
  final String text;
  final bool isDone;
  final bool isCrisis;
}

/// Streaming AI chat service — supports OpenAI, Claude, Gemini
class AiChatService {
  AiChatService(this._settings);
  final AiSettings _settings;

  static const _systemPrompt = '''
Είσαι ο MindBridge AI, ένας συμπαθητικός βοηθός ψυχικής υγείας.
Μιλάς ελληνικά ή αγγλικά ανάλογα με τον χρήστη.
Χρησιμοποιείς CBT τεχνικές, ακούς ενεργητικά, είσαι ζεστός και μη κριτικός.
ΚΡΙΣΙΜΟ: Αν ο χρήστης αναφέρει αυτοτραυματισμό ή αυτοκτονία, ΠΑΝΤΑ απάντα με:
"ΚΡΙΣΗ:" στην αρχή και δώσε άμεσα τον αριθμό 10306 (ΕΨΥΠΕ).
Δεν είσαι γιατρός — το αναφέρεις όταν χρειάζεται.
''';

  Stream<ChatChunk> sendMessage(List<Map<String, String>> history) {
    return switch (_settings.provider) {
      AiProvider.openai => _openaiStream(history),
      AiProvider.claude => _claudeStream(history),
      AiProvider.gemini => _geminiStream(history),
    };
  }

  // ── OpenAI ────────────────────────────────────────────────────────────────
  Stream<ChatChunk> _openaiStream(List<Map<String, String>> history) async* {
    final dio = Dio();
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history,
    ];

    final response = await dio.post<ResponseBody>(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-4o',
        'messages': messages,
        'stream': true,
        'max_tokens': 1024,
        'temperature': 0.7,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_settings.openaiKey}',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(chunk);
      final lines = buffer.toString().split('\n');
      buffer.clear();

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') { yield const ChatChunk(text: '', isDone: true); return; }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final content = (json['choices'] as List?)
              ?.firstOrNull
              ?['delta']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            final isCrisis = content.contains('ΚΡΙΣΗ:');
            yield ChatChunk(text: content, isCrisis: isCrisis);
          }
        } catch (_) {}
      }
      if (lines.last.isNotEmpty) buffer.write(lines.last);
    }
    yield const ChatChunk(text: '', isDone: true);
  }

  // ── Claude ────────────────────────────────────────────────────────────────
  Stream<ChatChunk> _claudeStream(List<Map<String, String>> history) async* {
    final dio = Dio();

    // Validate key before sending
    final key = _settings.claudeKey.trim();
    if (key.isEmpty) {
      throw Exception('Δεν έχεις βάλει Claude API key');
    }

    Response<ResponseBody> response;
    try {
      response = await dio.post<ResponseBody>(
        'https://api.anthropic.com/v1/messages',
        data: {
          'model': 'claude-sonnet-5',
          'max_tokens': 1024,
          'system': _systemPrompt,
          'messages': history,
          'stream': true,
        },
        options: Options(
          headers: {
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
          validateStatus: (s) => true, // don't throw, handle manually
        ),
      );
    } on DioException catch (e) {
      throw Exception('Σφάλμα σύνδεσης: ${e.message}');
    }

    if (response.statusCode != 200) {
      // Read body for exact error message
      String body = '';
      try {
        final bytes = <int>[];
        await for (final chunk in response.data!.stream) {
          bytes.addAll(chunk);
        }
        body = utf8.decode(bytes);
      } catch (_) {}
      throw Exception('Claude API ${response.statusCode}: $body');
    }

    final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(chunk);
      final lines = buffer.toString().split('\n');
      buffer.clear();

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('data: ')) continue;
        try {
          final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
          if (json['type'] == 'content_block_delta') {
            final text = json['delta']?['text'] as String? ?? '';
            if (text.isNotEmpty) {
              yield ChatChunk(text: text, isCrisis: text.contains('ΚΡΙΣΗ:'));
            }
          } else if (json['type'] == 'message_stop') {
            yield const ChatChunk(text: '', isDone: true);
            return;
          }
        } catch (_) {}
      }
      if (lines.last.isNotEmpty) buffer.write(lines.last);
    }
    yield const ChatChunk(text: '', isDone: true);
  }

  // ── Gemini ────────────────────────────────────────────────────────────────
  Stream<ChatChunk> _geminiStream(List<Map<String, String>> history) async* {
    final dio = Dio();
    final contents = [
      {'role': 'user', 'parts': [{'text': _systemPrompt}]},
      {'role': 'model', 'parts': [{'text': 'Κατανοητό. Είμαι εδώ για να βοηθήσω.'}]},
      ...history.map((m) => {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}],
      }),
    ];

    final response = await dio.post<ResponseBody>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent?alt=sse&key=${_settings.geminiKey}',
      data: {'contents': contents},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        responseType: ResponseType.stream,
      ),
    );

    final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(chunk);
      final lines = buffer.toString().split('\n');
      buffer.clear();

      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('data: ')) continue;
        try {
          final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
          final text = ((json['candidates'] as List?)
                  ?.firstOrNull?['content']?['parts'] as List?)
              ?.firstOrNull?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield ChatChunk(text: text, isCrisis: text.contains('ΚΡΙΣΗ:'));
          }
        } catch (_) {}
      }
      if (lines.last.isNotEmpty) buffer.write(lines.last);
    }
    yield const ChatChunk(text: '', isDone: true);
  }
}
