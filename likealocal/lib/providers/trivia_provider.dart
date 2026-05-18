import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/trivia_question.dart';
import '../services/trivia_service.dart';

enum TriviaPhase { idle, loading, playing, finished }

class TriviaProvider extends ChangeNotifier {
  TriviaProvider({TriviaService? service})
      : _service = service ?? TriviaService() {
    // Reset session state whenever the signed-in user changes so one user's
    // "played today" flag never bleeds into another user's session.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _hasPlayedToday = false;
      _todaysExistingScore = null;
      _phase = TriviaPhase.idle;
      _questions = [];
      _perQuestionResults.clear();
      _currentIndex = 0;
      _selectedChoice = null;
      _answerLocked = false;
      _secondsRemaining = TriviaService.secondsPerQuestion;
      _score = 0;
      _correctCount = 0;
      _ticker?.cancel();
      _errorMessage = null;
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _authSub;

  final TriviaService _service;

  // ── Session state ─────────────────────────────────────────────
  TriviaPhase _phase = TriviaPhase.idle;
  String? _errorMessage;

  List<TriviaQuestion> _questions = [];
  int _currentIndex = 0;

  int? _selectedChoice;
  bool _answerLocked = false;
  int _secondsRemaining = TriviaService.secondsPerQuestion;
  Timer? _ticker;

  int _score = 0;
  int _correctCount = 0;
  final List<bool> _perQuestionResults = [];

  bool _hasPlayedToday = false;
  int? _todaysExistingScore;

  // ── Getters ───────────────────────────────────────────────────
  TriviaPhase get phase => _phase;
  String? get errorMessage => _errorMessage;

  List<TriviaQuestion> get questions => List.unmodifiable(_questions);
  int get currentIndex => _currentIndex;
  TriviaQuestion? get currentQuestion =>
      (_currentIndex >= 0 && _currentIndex < _questions.length)
          ? _questions[_currentIndex]
          : null;
  int get totalQuestions => _questions.length;

  int? get selectedChoice => _selectedChoice;
  bool get answerLocked => _answerLocked;
  int get secondsRemaining => _secondsRemaining;

  int get score => _score;
  int get correctCount => _correctCount;
  List<bool> get perQuestionResults => List.unmodifiable(_perQuestionResults);

  bool get hasPlayedToday => _hasPlayedToday;
  int? get todaysExistingScore => _todaysExistingScore;

  // ── Lifecycle ─────────────────────────────────────────────────
  Future<void> refreshDailyStatus() async {
    try {
      _hasPlayedToday = await _service.hasPlayedToday();
      _todaysExistingScore = await _service.todaysScore();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Loads today's questions and starts the gameplay loop.
  Future<void> startDaily() async {
    if (_hasPlayedToday) return;
    _phase = TriviaPhase.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _questions = await _service.getOrGenerateDaily();
      _resetRoundState();
      _phase = TriviaPhase.playing;
      _startTimer();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _phase = TriviaPhase.idle;
      notifyListeners();
    }
  }

  void _resetRoundState() {
    _currentIndex = 0;
    _selectedChoice = null;
    _answerLocked = false;
    _secondsRemaining = TriviaService.secondsPerQuestion;
    _score = 0;
    _correctCount = 0;
    _perQuestionResults.clear();
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_answerLocked) return;
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        _lockAnswer(null);
      } else {
        notifyListeners();
      }
    });
  }

  void selectChoice(int index) {
    if (_answerLocked) return;
    _selectedChoice = index;
    _lockAnswer(index);
  }

  void _lockAnswer(int? chosen) {
    _answerLocked = true;
    final question = currentQuestion;
    final wasCorrect = chosen != null && question != null &&
        chosen == question.correctIndex;

    _perQuestionResults.add(wasCorrect);

    if (wasCorrect) {
      _correctCount++;
      final base = 100;
      final timeBonus = _secondsRemaining * 5; // up to +50 at instant answer
      _score += base + timeBonus;
    }

    notifyListeners();
  }

  /// Advances to the next question or finishes the session.
  Future<void> next({
    required String userName,
    required String profileImageUrl,
  }) async {
    if (!_answerLocked) return;

    if (_currentIndex >= _questions.length - 1) {
      // Last question — finalize.
      _ticker?.cancel();

      // Perfect-session bonus.
      if (_correctCount == _questions.length) {
        _score += 200;
      }

      _phase = TriviaPhase.finished;
      notifyListeners();

      try {
        await _service.submitScore(
          score: _score,
          correctCount: _correctCount,
          perQuestionResults: _perQuestionResults,
          userName: userName,
          profileImageUrl: profileImageUrl,
        );
        _hasPlayedToday = true;
        _todaysExistingScore = _score;
      } catch (e) {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return;
    }

    _currentIndex++;
    _selectedChoice = null;
    _answerLocked = false;
    _secondsRemaining = TriviaService.secondsPerQuestion;
    notifyListeners();
  }

  /// Returns to the hub after viewing results.
  void resetToIdle() {
    _ticker?.cancel();
    _phase = TriviaPhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _authSub.cancel();
    super.dispose();
  }
}
