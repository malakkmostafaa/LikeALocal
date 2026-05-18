import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/trivia_question.dart';
import 'place_service.dart';

class TriviaService {
  TriviaService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PlaceService? placeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _placeService = placeService ?? PlaceService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PlaceService _placeService;

  static const int questionsPerSession = 5;
  static const int secondsPerQuestion = 10;

  // ── Test / demo mode ────────────────────────────────────────────────────────
  // Set kTestMode = true  → questions regenerate and play resets every 1 minute.
  // Set kTestMode = false → normal production behaviour (once per 24 hours).
  static const bool kTestMode = false ;
  static const Duration kTestCooldown = Duration(minutes: 1);
  // ────────────────────────────────────────────────────────────────────────────

  String _todayKey() {
    if (kTestMode) {
      // Bucket time into exact 1-minute windows from Unix epoch so the key
      // changes precisely every kTestCooldown, independent of wall-clock minute.
      final window =
          DateTime.now().millisecondsSinceEpoch ~/ kTestCooldown.inMilliseconds;
      return 'test-$window';
    }
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _monthKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  /// Returns today's questions, generating them via Gemini if no one has
  /// played yet today. Safe under concurrent first-opens.
  Future<List<TriviaQuestion>> getOrGenerateDaily() async {
    final dateKey = _todayKey();
    final ref = _firestore.collection('daily_trivia').doc(dateKey);

    final snap = await ref.get();
    if (snap.exists && snap.data() != null) {
      return _parseQuestions(snap.data()!);
    }

    final questions = await _generateWithGemini();

    try {
      // create() fails if the doc already exists — wins the race cleanly.
      await ref.set({
        'questions': questions.map((q) => q.toMap()).toList(),
        'generatedAt': FieldValue.serverTimestamp(),
        'generatedBy': _auth.currentUser?.uid,
      });
      return questions;
    } catch (_) {
      // Someone beat us to it. Read theirs so everyone today sees the same set.
      final fresh = await ref.get();
      if (fresh.exists && fresh.data() != null) {
        return _parseQuestions(fresh.data()!);
      }
      return questions;
    }
  }

  List<TriviaQuestion> _parseQuestions(Map<String, dynamic> data) {
    final raw = (data['questions'] as List?) ?? const [];
    return raw
        .map((q) => TriviaQuestion.fromMap(Map<String, dynamic>.from(q)))
        .toList();
  }

  Future<List<TriviaQuestion>> _generateWithGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    // Pull top places by rating to use as question fodder.
    final allPlaces = await _placeService.getPlacesOnce();
    allPlaces.sort((a, b) => b.rating.compareTo(a.rating));
    final topPlaces = allPlaces.take(30).toList();

    final placesContext = topPlaces.map((p) {
      return '- "${p.name}" (${p.category}, rating ${p.rating.toStringAsFixed(1)})';
    }).join('\n');

    final prompt = '''
Generate exactly $questionsPerSession multiple-choice trivia questions for a
mobile app about Cairo, Egypt called LikeALocal. The user has 10 seconds per
question.

Mix two question types roughly 50/50:
1. General Cairo knowledge (history, neighborhoods, food, culture, geography).
2. Questions referencing the actual places below — for example "Which place
   has the highest rating?", "Which of these is a café in Zamalek?",
   "What category is Garden Nook Café?".

PLACES AVAILABLE:
$placesContext

Rules:
- Each question has exactly 4 choices.
- correctIndex is 0-3.
- Questions should be answerable in 10 seconds — keep them short and clear.
- Avoid trick questions or anything ambiguous.
- Mix difficulty: 2 easy, 2 medium, 1 hard.
- Never reveal the answer in the question text.

Return ONLY valid JSON in this exact shape, no prose, no markdown fences:
{"questions":[{"text":"...","choices":["a","b","c","d"],"correctIndex":0}, ...]}
''';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      throw Exception('Empty response from Gemini.');
    }

    final decoded = jsonDecode(text);
    final list = (decoded['questions'] as List?) ?? const [];

    final questions = list
        .map((q) => TriviaQuestion.fromMap(Map<String, dynamic>.from(q)))
        .where((q) => q.choices.length == 4 &&
            q.correctIndex >= 0 &&
            q.correctIndex < 4 &&
            q.text.trim().isNotEmpty)
        .toList();

    if (questions.length < questionsPerSession) {
      throw Exception(
        'Gemini returned ${questions.length} valid questions, '
        'expected $questionsPerSession.',
      );
    }

    return questions.take(questionsPerSession).toList();
  }

  /// Whether the current user has already played today.
  Future<bool> hasPlayedToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final dateKey = _todayKey();
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('trivia_scores')
        .doc(dateKey)
        .get();
    return doc.exists;
  }

  /// Returns today's saved score, or null if not played yet.
  Future<int?> todaysScore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final dateKey = _todayKey();
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('trivia_scores')
        .doc(dateKey)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['score'] as num?)?.toInt();
  }

  /// Saves today's result, updates the monthly leaderboard entry, and
  /// updates the user's streak + streak badges — all atomically.
  Future<void> submitScore({
    required int score,
    required int correctCount,
    required List<bool> perQuestionResults,
    required String userName,
    required String profileImageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');

    final dateKey = _todayKey();
    final monthKey = _monthKey();

    final dailyRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('trivia_scores')
        .doc(dateKey);

    final leaderboardRef = _firestore
        .collection('leaderboards')
        .doc('trivia')
        .collection(monthKey)
        .doc(uid);

    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      // All reads first (Firestore transaction rule).
      final existingDaily = await tx.get(dailyRef);
      if (existingDaily.exists) {
        // Already played today — don't double-count.
        return;
      }
      final boardSnap = await tx.get(leaderboardRef);
      final userSnap = await tx.get(userRef);

      // ── Streak math ────────────────────────────────────────────
      final userData = userSnap.data() ?? {};
      final prevStreak = (userData['triviaStreak'] as num?)?.toInt() ?? 0;
      final lastDate = userData['lastTriviaDate']?.toString() ?? '';
      final yesterdayKey = _yesterdayKey();

      final newStreak = (lastDate == yesterdayKey) ? prevStreak + 1 : 1;
      final newBadges = _badgesForStreak(newStreak);

      // ── Writes ─────────────────────────────────────────────────
      tx.set(dailyRef, {
        'score': score,
        'correctCount': correctCount,
        'perQuestion': perQuestionResults,
        'completedAt': FieldValue.serverTimestamp(),
      });

      final prevTotal =
          (boardSnap.data()?['totalScore'] as num?)?.toInt() ?? 0;
      final prevBest = (boardSnap.data()?['bestDay'] as num?)?.toInt() ?? 0;
      final prevPlayed =
          (boardSnap.data()?['playedDays'] as num?)?.toInt() ?? 0;

      tx.set(leaderboardRef, {
        'totalScore': prevTotal + score,
        'bestDay': score > prevBest ? score : prevBest,
        'playedDays': prevPlayed + 1,
        'userName': userName,
        'profileImageUrl': profileImageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(userRef, {
        'triviaStreak': newStreak,
        'lastTriviaDate': dateKey,
        if (newBadges.isNotEmpty) 'badges': FieldValue.arrayUnion(newBadges),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String _yesterdayKey() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    final yy = y.year.toString().padLeft(4, '0');
    final mm = y.month.toString().padLeft(2, '0');
    final dd = y.day.toString().padLeft(2, '0');
    return '$yy-$mm-$dd';
  }

  /// Returns the badge ids unlocked at this streak count, or [] if none.
  /// arrayUnion is idempotent so re-awarding is harmless.
  List<String> _badgesForStreak(int streak) {
    final badges = <String>[];
    if (streak >= 3) badges.add('trivia_streak_3');
    if (streak >= 7) badges.add('trivia_streak_7');
    if (streak >= 30) badges.add('trivia_streak_30');
    return badges;
  }

  /// Streams the current month's leaderboard, ordered by totalScore desc.
  Stream<List<LeaderboardEntry>> monthlyLeaderboardStream({int limit = 50}) {
    return _firestore
        .collection('leaderboards')
        .doc('trivia')
        .collection(_monthKey())
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        return LeaderboardEntry(
          uid: doc.id,
          userName: (data['userName'] ?? '').toString(),
          profileImageUrl: (data['profileImageUrl'] ?? '').toString(),
          totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
          bestDay: (data['bestDay'] as num?)?.toInt() ?? 0,
          playedDays: (data['playedDays'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    });
  }
}

class LeaderboardEntry {
  LeaderboardEntry({
    required this.uid,
    required this.userName,
    required this.profileImageUrl,
    required this.totalScore,
    required this.bestDay,
    required this.playedDays,
  });

  final String uid;
  final String userName;
  final String profileImageUrl;
  final int totalScore;
  final int bestDay;
  final int playedDays;
}
