import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/trivia_provider.dart';
import 'game_screen.dart';

class TriviaResultScreen extends StatelessWidget {
  const TriviaResultScreen({super.key});

  String _emojiSummary(List<bool> results) {
    return results.map((r) => r ? '🟩' : '🟥').join(' ');
  }

  String _verdict(int correct, int total) {
    if (correct == total) return 'Perfect!';
    if (correct >= total - 1) return 'So close!';
    if (correct >= total ~/ 2) return 'Nice run.';
    return 'Keep practicing!';
  }

  void _share(BuildContext context, TriviaProvider trivia) {
    final today = DateTime.now();
    final dateStr = '${today.year}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final text = 'LikeALocal Trivia $dateStr\n'
        '${trivia.correctCount}/${trivia.totalQuestions}  •  ${trivia.score} pts\n'
        '${_emojiSummary(trivia.perQuestionResults)}';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Result copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exit(BuildContext context) {
    context.read<TriviaProvider>().resetToIdle();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit(context);
      },
      child: Scaffold(
        backgroundColor: GameScreen.bgColor,
        body: SafeArea(
          child: Consumer<TriviaProvider>(
            builder: (context, trivia, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      _verdict(trivia.correctCount, trivia.totalQuestions),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: GameScreen.textColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${trivia.correctCount} of ${trivia.totalQuestions} correct', //  'trivia.correct_count'.tr(namedArgs: {'correct': '${trivia.correctCount}', 'total': '${trivia.totalQuestions}'}),
                      style: const TextStyle(
                        color: GameScreen.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _ScoreHero(score: trivia.score),
                    const SizedBox(height: 24),
                    _EmojiStrip(results: trivia.perQuestionResults),
                    const SizedBox(height: 24),
                    if (trivia.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAE2E2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Score saved locally only: ${trivia.errorMessage ?? ''}', //'trivia.score_local_only'.tr(namedArgs: {'error': trivia.errorMessage ?? ''}),
                          style: const TextStyle(
                            color: Color(0xFFD64A4A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _share(context, trivia),
                        icon: const Icon(Icons.share_rounded),
                        label: Text('Share Result'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GameScreen.primaryColor,
                          side: const BorderSide(
                            color: GameScreen.primaryColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _exit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameScreen.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE26D45), Color(0xFFE88A66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: GameScreen.primaryColor.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Today\'s Score',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'points',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiStrip extends StatelessWidget {
  const _EmojiStrip({required this.results});
  final List<bool> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: results.map((r) {
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: r ? const Color(0xFF3DAA5A) : const Color(0xFFD64A4A),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            r ? Icons.check_rounded : Icons.close_rounded,
            color: Colors.white,
            size: 22,
          ),
        );
      }).toList(),
    );
  }
}
