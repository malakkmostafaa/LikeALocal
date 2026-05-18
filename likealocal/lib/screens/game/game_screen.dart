import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/trivia_provider.dart';
import 'leaderboard_screen.dart';
import 'trivia_play_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const Color bgColor = Color(0xFFFAF7F2);
  static const Color cardColor = Color(0xFFFFFBF7);
  static const Color primaryColor = Color(0xFFE26D45);
  static const Color softPrimary = Color(0xFFFFEEE6);
  static const Color borderColor = Color(0xFFF0E4DC);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TriviaProvider>().refreshDailyStatus();
    });
    // Poll every 30 seconds so the button updates automatically when the
    // testing window (1 minute) rolls over without needing to restart.
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<TriviaProvider>().refreshDailyStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Also re-check when the app comes back from the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TriviaProvider>().refreshDailyStatus();
    }
  }

  void _openPlay() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TriviaPlayScreen()),
    );
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameScreen.bgColor,
      body: SafeArea(
        child: Consumer<TriviaProvider>(
          builder: (context, trivia, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'game.title'.tr(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: GameScreen.textColor,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'game.subtitle'.tr(),
                    style: const TextStyle(
                      color: GameScreen.mutedText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _HeroCard(
                    hasPlayedToday: trivia.hasPlayedToday,
                    todaysScore: trivia.todaysExistingScore,
                    onPlay: trivia.hasPlayedToday ? null : _openPlay,
                  ),
                  const SizedBox(height: 14),
                  _LeaderboardButton(onTap: _openLeaderboard),

                  const SizedBox(height: 18),
                  _HowItWorksCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.hasPlayedToday,
    required this.todaysScore,
    required this.onPlay,
  });

  final bool hasPlayedToday;
  final int? todaysScore;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE26D45), Color(0xFFE88A66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: GameScreen.primaryColor.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                hasPlayedToday ? 'game.todays_score'.tr() : 'game.todays_challenge'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasPlayedToday) ...[
            Text(
              '${todaysScore ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'game.see_tomorrow'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ] else ...[
            Text(
              'game.questions_timer'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'game.one_attempt'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: GameScreen.primaryColor,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                disabledForegroundColor: GameScreen.primaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                hasPlayedToday ? 'game.come_back'.tr() : 'game.play_today'.tr(),
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

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameScreen.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameScreen.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'game.how_it_works'.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: GameScreen.textColor,
            ),
          ),
          const SizedBox(height: 14),
          _Bullet(
            icon: Icons.help_outline_rounded,
            text: 'game.bullet_questions'.tr(),
          ),
          const SizedBox(height: 10),
          _Bullet(
            icon: Icons.timer_outlined,
            text: 'game.bullet_timer'.tr(),
          ),
          const SizedBox(height: 10),
          _Bullet(
            icon: Icons.emoji_events_outlined,
            text: 'game.bullet_leaderboard'.tr(),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: GameScreen.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: GameScreen.mutedText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}


class _LeaderboardButton extends StatelessWidget {
  const _LeaderboardButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: GameScreen.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: GameScreen.borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: GameScreen.primaryColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'game.leaderboard'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: GameScreen.textColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: GameScreen.mutedText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}