import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class AiService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt =
      '''You are an AI local guide for the LikeALocal app. 
You help users discover authentic local places like hidden cafés, restaurants, 
cultural spots and hidden gems. Keep responses short, friendly and specific. 
Always suggest 1-3 places with a brief reason why. If asked about a specific city, 
focus on that city. Default to Cairo, Egypt if no city is mentioned.''';

  Future<String> getRecommendation(
      String userMessage, List<Map<String, String>> history) async {
    final url = Uri.parse(_baseUrl);

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => {
            'role': m['role'] == 'model' ? 'assistant' : m['role']!,
            'content': m['text']!,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': messages,
        'max_tokens': 500,
      }),
    );
        

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> summarizeReviews(List<String> reviews) async {
    if (reviews.isEmpty) return 'No reviews yet.';

    final url = Uri.parse(_baseUrl);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {
            'role': 'system',
            'content': 'You summarize user reviews concisely.'
          },
          {
            'role': 'user',
            'content':
                'Summarize these reviews in 2-3 sentences. Highlight the most common points:\n- ${reviews.join('\n- ')}'
          },
        ],
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      return 'Could not generate summary.';
    }
  }
}
