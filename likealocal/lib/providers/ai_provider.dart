import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';

class AiProvider extends ChangeNotifier {
  final _service = AiService();

  final List<Map<String, String>> _chatHistory = [];
  List<Map<String, String>> get chatHistory => List.unmodifiable(_chatHistory);

  bool isThinking = false;
  String? error;

  String? _reviewSummary;
  bool isSummarizing = false;
  String? get reviewSummary => _reviewSummary;

  Future<String> sendMessage(String userMessage,
      {List<String> userPreferences = const []}) async {
    _chatHistory.add({'role': 'user', 'content': userMessage});
    isThinking = true;
    error = null;
    notifyListeners();

    try {
      final reply = await _service.chat(
        history: _chatHistory,
        userPreferences: userPreferences,
      );
      _chatHistory.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e) {
      error = e.toString();
      _chatHistory.removeLast(); // remove optimistic user message
      rethrow;
    } finally {
      isThinking = false;
      notifyListeners();
    }
  }

  Future<void> summarizeReviews({
    required String placeName,
    required List<String> reviews,
  }) async {
    isSummarizing = true;
    _reviewSummary = null;
    notifyListeners();

    try {
      _reviewSummary = await _service.summarizeReviews(
        placeName: placeName,
        reviews: reviews,
      );
    } catch (e) {
      _reviewSummary = null;
    } finally {
      isSummarizing = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _chatHistory.clear();
    notifyListeners();
  }
}