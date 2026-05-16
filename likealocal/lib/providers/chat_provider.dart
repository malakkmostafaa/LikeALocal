import 'package:flutter/foundation.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final _service = ChatService();

  bool isLoading = false;
  String? error;

  Stream<List<ChatConversation>> getConversations() =>
      _service.getMyConversations();

  Stream<List<ChatMessage>> getMessages(String chatId) =>
      _service.getMessages(chatId);

  Future<String> openChat({
    required String otherUserId,
    required String placeId,
    required String placeName,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      return await _service.getOrCreateChat(
        otherUserId: otherUserId,
        placeId: placeId,
        placeName: placeName,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String receiverId,
  }) async {
    await _service.sendMessage(
      chatId: chatId,
      text: text,
      receiverId: receiverId,
    );
  }
}