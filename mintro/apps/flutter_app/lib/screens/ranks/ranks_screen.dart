import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/leaderboard.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/mintro_card.dart';

class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(leaderboardProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Leaderboard', style: AppTextStyles.displayLarge),
              const SizedBox(height: 4),
              Text("This week's top learners", style: AppTextStyles.body),
              const SizedBox(height: 20),
              leaderboardAsync.when(
                data: (result) => _LeaderboardBody(result: result),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Failed to load leaderboard', style: AppTextStyles.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  final LeaderboardResult result;

  const _LeaderboardBody({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CurrentLeagueCard(result: result),
        const SizedBox(height: 24),
        Text("This Week's Podium", style: AppTextStyles.headline),
        const SizedBox(height: 12),
        if (result.podium.length >= 3) _PodiumCard(podium: result.podium),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Full Rankings', style: AppTextStyles.headline),
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${result.totalInLeague} in league', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...result.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RankRow(entry: entry),
            )),
      ],
    );
  }
}

class _CurrentLeagueCard extends StatelessWidget {
  final LeaderboardResult result;

  const _CurrentLeagueCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final leagueName = '${result.league[0].toUpperCase()}${result.league.substring(1)} League';

    return MintroCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.leagueEmeraldBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.military_tech_rounded, color: AppColors.leagueEmerald),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT LEAGUE', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(leagueName, style: AppTextStyles.titleLarge),
                const SizedBox(height: 2),
                Text('Top 10 advance next week', style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.currentUserRank != null ? '#${result.currentUserRank}' : '—',
                style: AppTextStyles.headline.copyWith(color: AppColors.primaryGreen),
              ),
              Text('Your rank', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final List<LeaderboardEntry> podium;

  const _PodiumCard({required this.podium});

  @override
  Widget build(BuildContext context) {
    final first = podium[0];
    final second = podium[1];
    final third = podium[2];

    return MintroCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumSlot(entry: second, place: 2, bgColor: AppColors.podiumSilver, textColor: AppColors.rank2Text, height: 64)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumSlot(entry: first, place: 1, bgColor: AppColors.podiumGold, textColor: AppColors.rank1Text, height: 88, highlight: true)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumSlot(entry: third, place: 3, bgColor: AppColors.podiumBronze, textColor: AppColors.rank3Text, height: 52)),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place;
  final Color bgColor;
  final Color textColor;
  final double height;
  final bool highlight;

  const _PodiumSlot({
    required this.entry,
    required this.place,
    required this.bgColor,
    required this.textColor,
    required this.height,
    this.highlight = false,
  });

  String get _ordinal {
    switch (place) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      default:
        return '3rd';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: highlight ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            entry.initials,
            style: AppTextStyles.titleMedium.copyWith(
              color: highlight ? AppColors.primaryGreen : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(entry.displayName.split(' ').first, style: AppTextStyles.bodyStrong),
        Text(
          entry.weeklyXp.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]} ',
              ),
          style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(
            _ordinal,
            style: AppTextStyles.titleLarge.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return MintroCard(
      color: entry.isCurrentUser ? AppColors.highlightRow : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.bodyStrong.copyWith(
                color: entry.isCurrentUser ? AppColors.coin : AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(entry.initials, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName, style: AppTextStyles.bodyStrong),
                Row(
                  children: [
                    Text('${entry.weeklyXp} XP', style: AppTextStyles.caption),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.currentStreak}d streak',
                      style: AppTextStyles.caption.copyWith(color: AppColors.coin),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
