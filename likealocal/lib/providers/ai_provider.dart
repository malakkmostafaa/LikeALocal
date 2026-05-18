import 'package:flutter/foundation.dart';

import '../models/place.dart';
import '../services/ai_service.dart';
import '../services/pin_service.dart';
import '../services/place_service.dart';
import '../services/user_service.dart';

enum ChatRole { user, bot }

class ChatMessage {
  ChatMessage({required this.role, required this.text});
  final ChatRole role;
  final String text;
}

class AiChatProvider extends ChangeNotifier {
  final GeminiAssistantService _assistant = GeminiAssistantService();
  final UserService _userService = UserService();
  final PinService _pinService = PinService();
  final PlaceService _placeService = PlaceService();

  static const int _maxPlacesInContext = 30;

  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _messages.add(ChatMessage(role: ChatRole.user, text: trimmed));
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final appContext = await _buildAppContext();

      final history = _messages
          .take(_messages.length - 1)
          .map((m) => (
                role: m.role == ChatRole.user ? 'user' : 'model',
                text: m.text,
              ))
          .toList();

      final reply = await _assistant.sendMessage(
        history: history,
        message: trimmed,
        appContext: appContext,
      );

      _messages.add(ChatMessage(role: ChatRole.bot, text: reply));
    } catch (e) {
      _errorMessage = e.toString();
      _messages.add(ChatMessage(
        role: ChatRole.bot,
        text: "Sorry, I couldn't reach the assistant.\n\nError: $e",
      ));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<String> _buildAppContext() async {
    final user = await _userService.getCurrentUserOnce();
    if (user == null) return '';

    final pinIds = await _pinService.pinnedPlaceIdsStream(user.uid).first;
    final allPlaces = await _placeService.getPlacesOnce();

    final pinnedPlaces =
        allPlaces.where((p) => pinIds.contains(p.id)).toList();

    final topPlaces = [...allPlaces]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final placesForContext = topPlaces.take(_maxPlacesInContext).toList();

    final buffer = StringBuffer();

    buffer.writeln('CURRENT USER:');
    buffer.writeln('- Name: ${user.name.isEmpty ? "Unknown" : user.name}');
    buffer.writeln(
      '- Plan: ${user.isPremium ? "Premium (unlimited pins)" : "Free (5-pin limit)"}',
    );
    buffer.writeln(
      '- Pins used: ${user.pinsCount}${user.isPremium ? "" : " / 5"}',
    );
    if (user.preferences.isNotEmpty) {
      buffer.writeln(
        '- Preferred categories: ${user.preferences.join(", ")}',
      );
    }
    if (user.bio.trim().isNotEmpty) {
      buffer.writeln('- Bio: ${user.bio.trim()}');
    }

    if (pinnedPlaces.isNotEmpty) {
      buffer.writeln();
      buffer.writeln("USER'S PINNED PLACES:");
      for (final p in pinnedPlaces) {
        buffer.writeln('- ${p.name} (${p.category})');
      }
    }

    if (placesForContext.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'PLACES AVAILABLE IN THE APP '
        '(recommend by exact name from this list when possible):',
      );
      for (final p in placesForContext) {
        buffer.writeln('- ${_formatPlaceLine(p)}');
      }
    }

    return buffer.toString();
  }

  String _formatPlaceLine(Place p) {
    final desc = p.description.trim();
    final shortDesc = desc.length > 120 ? '${desc.substring(0, 120)}…' : desc;
    final ratingPart =
        p.rating > 0 ? ', rating ${p.rating.toStringAsFixed(1)}' : '';
    return shortDesc.isEmpty
        ? '"${p.name}" — ${p.category}$ratingPart'
        : '"${p.name}" — ${p.category}$ratingPart. $shortDesc';
  }
}