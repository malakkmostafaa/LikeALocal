import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/trivia_service.dart';
import 'game_screen.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final TriviaService _service = TriviaService();

  String _monthLabel(BuildContext context) {
    const keys = [
      'months.january', 'months.february', 'months.march', 'months.april',
      'months.may', 'months.june', 'months.july', 'months.august',
      'months.september', 'months.october', 'months.november', 'months.december',
    ];
    final now = DateTime.now();
    return '${keys[now.month - 1].tr()} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: GameScreen.bgColor,
      appBar: AppBar(
        backgroundColor: GameScreen.bgColor,
        foregroundColor: GameScreen.textColor,
        elevation: 0,
        title: Text(
          'leaderboard.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(
                _monthLabel(context),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: GameScreen.textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<LeaderboardEntry>>(
                stream: _service.monthlyLeaderboardStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: GameScreen.primaryColor,
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return _ErrorState(message: snap.error.toString());
                  }
                  final allEntries = snap.data ?? [];
                  if (allEntries.isEmpty) {
                    return const _EmptyState();
                  }

                  // Top 10 shown in the list.
                  final top10 = allEntries.take(10).toList();

                  // Find current user outside top 10.
                  final myIndex = allEntries
                      .indexWhere((e) => e.uid == myUid);
                  final myEntry =
                      myIndex > 9 && myIndex != -1 ? allEntries[myIndex] : null;

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: top10.length + (myEntry != null ? 2 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      // Separator row between top 10 and user's own rank.
                      if (myEntry != null && index == top10.length) {
                        return const _RankDivider();
                      }
                      if (myEntry != null && index == top10.length + 1) {
                        return _LeaderboardRow(
                          rank: myIndex + 1,
                          entry: myEntry,
                          isMe: true,
                        );
                      }
                      final entry = top10[index];
                      return _LeaderboardRow(
                        rank: index + 1,
                        entry: entry,
                        isMe: entry.uid == myUid,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFE5A11A);
      case 2:
        return const Color(0xFF9AA3AD);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return GameScreen.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? GameScreen.softPrimary : GameScreen.cardColor;
    final borderColor =
        isMe ? GameScreen.primaryColor : GameScreen.borderColor;
    final hasImage = entry.profileImageUrl.isNotEmpty;
    final displayName =
        entry.userName.trim().isEmpty ? 'Player' : entry.userName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isMe ? 1.5 : 1),
      ),
      child: Row(
        children: [
          // Rank column
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rank <= 3)
                  Icon(Icons.emoji_events_rounded,
                      color: _rankColor(), size: 22)
                else
                  Text(
                    '#$rank',
                    style: const TextStyle(
                      color: GameScreen.mutedText,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                if (rank <= 3)
                  Text(
                    '$rank',
                    style: TextStyle(
                      color: _rankColor(),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: GameScreen.softPrimary,
            backgroundImage: hasImage
                ? CachedNetworkImageProvider(entry.profileImageUrl)
                : null,
            child: hasImage
                ? null
                : const Icon(
                    Icons.person_rounded,
                    color: GameScreen.primaryColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          // Name + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: GameScreen.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GameScreen.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'leaderboard.you'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.playedDays == 1
                      ? 'leaderboard.days_played_one'.tr(namedArgs: {'days': '${entry.playedDays}', 'best': '${entry.bestDay}'})
                      : 'leaderboard.days_played_other'.tr(namedArgs: {'days': '${entry.playedDays}', 'best': '${entry.bestDay}'}),
                  style: const TextStyle(
                    color: GameScreen.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Score
          Text(
            '${entry.totalScore}',
            style: const TextStyle(
              color: GameScreen.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank divider (shown between top 10 and user's own entry) ─────────────────

class _RankDivider extends StatelessWidget {
  const _RankDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(child: Divider(color: GameScreen.borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'leaderboard.your_ranking'.tr(),
              style: const TextStyle(
                color: GameScreen.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Expanded(child: Divider(color: GameScreen.borderColor)),
        ],
      ),
    );
  }
}

// ── Empty & error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: GameScreen.softPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: GameScreen.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'leaderboard.no_scores_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: GameScreen.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'leaderboard.no_scores_sub'.tr(),
              style: const TextStyle(color: GameScreen.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: GameScreen.primaryColor, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(color: GameScreen.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
