import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_config.dart';

class AiService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> _buildContext({
    List<String> userPreferences = const [],
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .orderBy('rating', descending: true)
          .limit(30)
          .get();

      final buffer = StringBuffer();
      buffer.writeln('=== LikeALocal places database (top 30 by rating) ===');

      for (final doc in snapshot.docs) {
        final d = doc.data();
        buffer.writeln(
          '• ${d['name']} | Category: ${d['category']} | '
          'Rating: ${d['rating']} | ${d['description'] ?? ''}',
        );
        if (d['tips'] is List && (d['tips'] as List).isNotEmpty) {
          final tips = (d['tips'] as List).take(2);
          buffer.writeln('  Tips: ${tips.map((t) => t['text']).join('; ')}');
        }
      }

      if (userPreferences.isNotEmpty) {
        buffer.writeln('\n=== User preferences: ${userPreferences.join(', ')} ===');
      }

      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  Future<String> chat({
    required List<Map<String, String>> history,
    List<String> userPreferences = const [],
  }) async {
    final context = await _buildContext(userPreferences: userPreferences);

    final systemPrompt = '''
You are an AI local guide for the LikeALocal app — a platform where locals share hidden gems, restaurants, and authentic experiences.

$context

Rules:
- Recommend only places from the database above. If nothing matches, say so honestly.
- Be warm, concise, and conversational.
- When recommending, always mention the place name and category.
- Never make up places, ratings, or details not in the database.
''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 512,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }
  }

  Future<String> summarizeReviews({
    required String placeName,
    required List<String> reviews,
  }) async {
    if (reviews.isEmpty) return 'No reviews yet to summarize.';

    final prompt = '''
Summarize these user reviews for "$placeName" in 2-3 sentences.
Focus on what visitors love, what to watch out for, and the overall vibe.
Keep it conversational and helpful.

Reviews:
${reviews.take(10).map((r) => '- $r').join('\n')}
''';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 200,
        'temperature': 0.5,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('Groq error ${response.statusCode}');
    }
  }
}