import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Thin wrapper around the Gemini generative model, locked to the
/// LikeALocal assistant persona via a system prompt.
class ChatService {
  static const String _basePrompt = '''
You are LikeALocal's in-app assistant. LikeALocal is a mobile app that helps
users discover hidden gems in Cairo, Egypt — restaurants, cafés, art spots,
hangouts, neighborhoods, and similar local favorites — and save them as "pins".

Stay focused on:
- Recommending places, food, neighborhoods, and experiences in Cairo.
- Helping users use the app's features: pinning places, the 5-pin free
  tier limit, upgrading to Premium for unlimited pins, writing reviews,
  exploring the feed, and the map view.
- Travel etiquette, local tips, and short cultural context when useful.

Personalization rules:
- An APP CONTEXT block below may include the signed-in user's name, plan,
  preferences, pinned places, and a list of PLACES AVAILABLE IN THE APP.
- When recommending, prefer names from PLACES AVAILABLE IN THE APP. Quote
  the exact place name so the user can find it inside the app.
- Use the user's preferences and pinned places to tailor suggestions
  (e.g., "since you like Cafés and pinned Garden Nook, try ...").
- If no app place fits the question, say so plainly and suggest the user
  explore the Explore feed — don't invent places that aren't listed.

General rules:
- If a question is unrelated to travel, Cairo, or this app, politely say
  you can only help with LikeALocal topics and offer an example question.
- Keep replies short and friendly (2–4 sentences unless the user asks for
  detail). Use plain text, no markdown headers.
- Never invent specific business hours, prices, or addresses you are not
  sure about — say "check the place's page in the app" instead.
''';

  /// Sends [history] (oldest first) + the new user [message] and returns
  /// the assistant's reply text. [appContext], when non-empty, is appended
  /// to the system prompt so the model can personalize answers.
  Future<String> sendMessage({
    required List<({String role, String text})> history,
    required String message,
    String appContext = '',
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    final systemPrompt = appContext.trim().isEmpty
        ? _basePrompt
        : '$_basePrompt\n\n--- APP CONTEXT ---\n$appContext';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );

    final chat = model.startChat(
      history: history.map((m) {
        return m.role == 'user'
            ? Content.text(m.text)
            : Content.model([TextPart(m.text)]);
      }).toList(),
    );

    final response = await chat.sendMessage(Content.text(message));
    final reply = response.text?.trim();

    if (reply == null || reply.isEmpty) {
      throw Exception('Empty response from Gemini.');
    }
    return reply;
  }
}
