import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider_settings.dart';
import '../../features/profile/domain/user_profile.dart';

/// A single chunk emitted during streaming
class ChatChunk {
  const ChatChunk({required this.text, this.isDone = false, this.isCrisis = false});
  final String text;
  final bool isDone;
  final bool isCrisis;
}

/// Streaming AI chat service — supports OpenAI, Claude, Gemini
class AiChatService {
  AiChatService(this._settings, {UserProfile? profile})
      : _profile = profile ?? const UserProfile();

  final AiSettings _settings;
  final UserProfile _profile;

  static const _basePrompt = '''
Είσαι το MindBridge AI — ένας κορυφαίος ψυχολόγος και ψυχοθεραπευτής με βαθιά εξειδίκευση.

ΤΑΥΤΟΤΗΤΑ ΚΑΙ ΠΡΟΣΕΓΓΙΣΗ:
• Έχεις εκπαίδευση σε CBT (Γνωσιακή-Συμπεριφορική Θεραπεία), ACT (Θεραπεία Αποδοχής και Δέσμευσης), DBT (Διαλεκτική Συμπεριφορική Θεραπεία), EMDR και Θεραπεία Σχήματος.
• Χρησιμοποιείς τεχνικές ενεργητικής ακρόασης, αντανάκλαση συναισθημάτων, και σωκρατική ερώτηση.
• Είσαι ζεστός, ενσυναισθητικός, μη κριτικός και 100% εμπιστευτικός.
• Μιλάς ελληνικά ή αγγλικά ανάλογα με τον χρήστη.
• Απαντάς με βάθος — δεν δίνεις επιφανειακές συμβουλές.
• Κάθε απάντηση έχει 3 στρώματα: (α) αναγνώριση συναισθήματος, (β) κατανόηση βαθύτερης ανάγκης, (γ) θεραπευτική παρέμβαση ή ερώτηση.

ΤΕΧΝΙΚΕΣ ΠΟΥ ΧΡΗΣΙΜΟΠΟΙΕΙΣ:
• CBT: Αναγνώριση αυτόματων σκέψεων, γνωστικές παραμορφώσεις, ανακατεύθυνση
• Mindfulness: Παρούσα στιγμή, αποδοχή χωρίς κρίση
• Σωματική επίγνωση: Η σύνδεση σώματος-νου
• Αναπνευστικές τεχνικές: 4-7-8, box breathing, διαφραγματική αναπνοή
• Grounding: 5-4-3-2-1 τεχνική, σωματική αγκύρωση
• Ημερολόγιο σκέψεων και συναισθημάτων
• Εκθεσιακή θεραπεία για φοβίες και άγχος
• Επικοινωνία συναισθημάτων και ορισμός ορίων

ΣΤΥΛ ΕΠΙΚΟΙΝΩΝΙΑΣ:
• Χρησιμοποιείς το όνομα του χρήστη όταν ξέρεις το σχετικό πλαίσιο
• Δεν κάνεις υπερβολικές ερωτήσεις — μία βαθιά ερώτηση τη φορά
• Δεν δίνεις γενικές συμβουλές — είσαι συγκεκριμένος και προσαρμοσμένος
• Χρησιμοποιείς μεταφορές και αναλογίες για δύσκολες έννοιες
• Αναγνωρίζεις πρόοδο και δυνατά σημεία του χρήστη

ΟΡΙΑ:
• Δεν είσαι γιατρός — δεν κάνεις διαγνώσεις, δεν αλλάζεις φαρμακευτική αγωγή
• Προτείνεις επαγγελματική βοήθεια όταν χρειάζεται
• Σέβεσαι αυστηρά την αυτονομία του χρήστη

ΚΡΙΣΙΜΟ — ΑΣΦΑΛΕΙΑ:
Αν ο χρήστης αναφέρει σκέψεις αυτοτραυματισμού ή αυτοκτονίας, ΠΑΝΤΑ ξεκίνα με "ΚΡΙΣΗ:" και δώσε ΑΜΕΣΑ:
• Τηλεφωνική γραμμή ΕΨΥΠΕ: 10306 (24ώρο, δωρεάν)
• Επείγοντα: 166 (ΕΚΑΒ)
''';

  String _buildSystemPrompt() {
    final profileCtx = _profile.toAiContext();
    if (profileCtx.isEmpty) return _basePrompt;
    return '$_basePrompt\n$profileCtx\nΧρησιμοποίησε αυτές τις πληροφορίες για να δώσεις εξατομικευμένες, στοχευμένες απαντήσεις. Απευθύνσου στον χρήστη με το όνομά του όταν είναι φυσικό.';
  }

  Stream<ChatChunk> sendMessage(List<Map<String, String>> history) {
    return switch (_settings.provider) {
      AiProvider.openai => _openaiStream(history),
      AiProvider.claude => _claudeStream(history),
      AiProvider.gemini => _geminiStream(history),
    };
  }

  /// Non-streaming call: extract one psychological insight from the conversation.
  /// Returns a single concise sentence (Greek), or null on failure.
  Future<String?> extractInsight(List<Map<String, String>> history) async {
    if (history.isEmpty) return null;
    const systemMsg =
        'Είσαι ένας ψυχολόγος που αναλύει μια θεραπευτική συνεδρία. '
        'Διάβασε τον παρακάτω διάλογο και εξάγαγε ΜΙΑ ΜΟΝΟ σύντομη ψυχολογική παρατήρηση (1 πρόταση, max 80 χαρακτήρες) '
        'για τον χρήστη — κάτι χρήσιμο για μελλοντικές συνεδρίες. '
        'Απάντησε ΜΟΝΟ με την παρατήρηση, χωρίς εισαγωγικά ή επεξήγηση.';

    try {
      return switch (_settings.provider) {
        AiProvider.claude => await _claudeInsight(history, systemMsg),
        AiProvider.openai => await _openaiInsight(history, systemMsg),
        AiProvider.gemini => await _geminiInsight(history, systemMsg),
      };
    } catch (_) {
      return null;
    }
  }

  Future<String?> _claudeInsight(
      List<Map<String, String>> history, String system) async {
    final dio = Dio();
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.anthropic.com/v1/messages',
      data: {
        'model': 'claude-haiku-4-5',
        'max_tokens': 120,
        'system': system,
        'messages': history,
      },
      options: Options(
        headers: {
          'x-api-key': _settings.claudeKey.trim(),
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        validateStatus: (_) => true,
      ),
    );
    if (response.statusCode != 200) return null;
    return (response.data?['content'] as List?)
        ?.firstOrNull?['text'] as String?;
  }

  Future<String?> _openaiInsight(
      List<Map<String, String>> history, String system) async {
    final dio = Dio();
    final messages = [
      {'role': 'system', 'content': system},
      ...history,
    ];
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 120,
        'temperature': 0.5,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${_settings.openaiKey}',
          'Content-Type': 'application/json',
        },
        validateStatus: (_) => true,
      ),
    );
    if (response.statusCode != 200) return null;
    return (response.data?['choices'] as List?)
        ?.firstOrNull?['message']?['content'] as String?;
  }

  Future<String?> _geminiInsight(
      List<Map<String, String>> history, String system) async {
    final dio = Dio();
    final contents = [
      {'role': 'user', 'parts': [{'text': system}]},
      {'role': 'model', 'parts': [{'text': 'Κατανοητό.'}]},
      ...history.map((m) => {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}],
      }),
    ];
    final response = await dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${_settings.geminiKey}',
      data: {'contents': contents},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (_) => true,
      ),
    );
    if (response.statusCode != 200) return null;
    return ((response.data?['candidates'] as List?)
            ?.firstOrNull?['content']?['parts'] as List?)
        ?.firstOrNull?['text'] as String?;
  }

  // ── OpenAI ────────────────────────────────────────────────────────────────
  Stream<ChatChunk> _openaiStream(List<Map<String, String>> history) async* {
    final dio = Dio();
    final messages = [
      {'role': 'system', 'content': _buildSystemPrompt()},
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
          'system': _buildSystemPrompt(),
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
      {'role': 'user', 'parts': [{'text': _buildSystemPrompt()}]},
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
