import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trivia_question.dart';
import '../../providers/trivia_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/trivia_service.dart';
import 'game_screen.dart';
import 'trivia_result_screen.dart';

class TriviaPlayScreen extends StatefulWidget {
  const TriviaPlayScreen({super.key});

  @override
  State<TriviaPlayScreen> createState() => _TriviaPlayScreenState();
}

class _TriviaPlayScreenState extends State<TriviaPlayScreen> {
  bool _resultPushed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TriviaProvider>().startDaily();
    });
  }

  Future<void> _handleNext() async {
    final user = context.read<UserProvider>().user;
    await context.read<TriviaProvider>().next(
          userName: user?.name ?? 'Player',
          profileImageUrl: user?.profileImageUrl ?? '',
        );
  }

  void _maybePushResult(TriviaProvider trivia) {
    if (_resultPushed) return;
    if (trivia.phase != TriviaPhase.finished) return;
    _resultPushed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TriviaResultScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameScreen.bgColor,
      appBar: AppBar(
        backgroundColor: GameScreen.bgColor,
        foregroundColor: GameScreen.textColor,
        elevation: 0,
        title: Text(
          'Daily Trivia',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Consumer<TriviaProvider>(
          builder: (context, trivia, _) {
            if (trivia.phase == TriviaPhase.loading ||
                trivia.phase == TriviaPhase.idle) {
              return _LoadingState(error: trivia.errorMessage);
            }

            _maybePushResult(trivia);

            final question = trivia.currentQuestion;
            if (question == null) {
              return const Center(
                child:
                    CircularProgressIndicator(color: GameScreen.primaryColor),
              );
            }

            return _GameView(
              question: question,
              questionIndex: trivia.currentIndex,
              totalQuestions: trivia.totalQuestions,
              secondsRemaining: trivia.secondsRemaining,
              selectedChoice: trivia.selectedChoice,
              answerLocked: trivia.answerLocked,
              score: trivia.score,
              onChoiceTap: trivia.selectChoice,
              onNext: _handleNext,
              isLastQuestion: trivia.currentIndex >= trivia.totalQuestions - 1,
            );
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: GameScreen.primaryColor, size: 56),
              const SizedBox(height: 16),
              Text(
                'Could not load today/n' 's questions',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GameScreen.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GameScreen.mutedText),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameScreen.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: GameScreen.primaryColor),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.secondsRemaining,
    required this.selectedChoice,
    required this.answerLocked,
    required this.score,
    required this.onChoiceTap,
    required this.onNext,
    required this.isLastQuestion,
  });

  final TriviaQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final int secondsRemaining;
  final int? selectedChoice;
  final bool answerLocked;
  final int score;
  final ValueChanged<int> onChoiceTap;
  final VoidCallback onNext;
  final bool isLastQuestion;

  @override
  Widget build(BuildContext context) {
    final timeFraction =
        (secondsRemaining / TriviaService.secondsPerQuestion).clamp(0.0, 1.0);
    final timeLow = secondsRemaining <= 3 && !answerLocked;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${questionIndex + 1} of ${totalQuestions}',
                style: const TextStyle(
                  color: GameScreen.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: GameScreen.softPrimary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'points $score',
                  style: const TextStyle(
                    color: GameScreen.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: timeFraction,
              minHeight: 8,
              backgroundColor: GameScreen.softPrimary,
              valueColor: AlwaysStoppedAnimation(
                timeLow ? Colors.red.shade400 : GameScreen.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${secondsRemaining}s',
              style: TextStyle(
                color: timeLow ? Colors.red.shade400 : GameScreen.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GameScreen.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GameScreen.borderColor),
            ),
            child: Text(
              question.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GameScreen.textColor,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: question.choices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ChoiceTile(
                  text: question.choices[index],
                  index: index,
                  selected: selectedChoice == index,
                  locked: answerLocked,
                  isCorrect: index == question.correctIndex,
                  onTap: answerLocked ? null : () => onChoiceTap(index),
                );
              },
            ),
          ),
          if (answerLocked)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameScreen.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isLastQuestion ? 'See Results' : 'Next Question',
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
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.text,
    required this.index,
    required this.selected,
    required this.locked,
    required this.isCorrect,
    required this.onTap,
  });

  final String text;
  final int index;
  final bool selected;
  final bool locked;
  final bool isCorrect;
  final VoidCallback? onTap;

  Color _backgroundColor() {
    if (!locked) return Colors.white;
    if (isCorrect) return const Color(0xFFE0F5E5);
    if (selected) return const Color(0xFFFAE2E2);
    return Colors.white;
  }

  Color _borderColor() {
    if (!locked) {
      return selected ? GameScreen.primaryColor : GameScreen.borderColor;
    }
    if (isCorrect) return const Color(0xFF3DAA5A);
    if (selected) return const Color(0xFFD64A4A);
    return GameScreen.borderColor;
  }

  IconData? _trailingIcon() {
    if (!locked) return null;
    if (isCorrect) return Icons.check_circle_rounded;
    if (selected) return Icons.cancel_rounded;
    return null;
  }

  Color _trailingColor() {
    if (isCorrect) return const Color(0xFF3DAA5A);
    return const Color(0xFFD64A4A);
  }

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode('A'.codeUnitAt(0) + index);

    return Material(
      color: _backgroundColor(),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor(), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GameScreen.softPrimary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: GameScreen.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: GameScreen.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_trailingIcon() != null) ...[
                const SizedBox(width: 8),
                Icon(_trailingIcon(), color: _trailingColor()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
