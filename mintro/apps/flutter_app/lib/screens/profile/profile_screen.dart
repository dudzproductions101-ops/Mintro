import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/achievement.dart';
import '../../models/goal.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/mintro_card.dart';
import '../../widgets/mintro_progress_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.displayLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(goalsProvider);
            ref.invalidate(achievementsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              profileAsync.when(
                data: (profile) => _ProfileCard(profile: profile),
                loading: () => const SizedBox(height: 140),
                error: (e, _) => Text('Failed to load profile', style: AppTextStyles.body),
              ),
              const SizedBox(height: 16),
              profileAsync.maybeWhen(
                data: (profile) => _StatsRow(profile: profile),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              goalsAsync.when(
                data: (goals) => goals.isNotEmpty
                    ? _PrimaryGoalCard(goal: goals.first)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox(height: 140),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              achievementsAsync.when(
                data: (achievements) => _AchievementsSection(achievements: achievements),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Failed to load achievements', style: AppTextStyles.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final leagueName = '${profile.league[0].toUpperCase()}${profile.league.substring(1)} League';

    return MintroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreenLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryGreen, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(profile.displayName),
                      style: AppTextStyles.titleLarge.copyWith(color: AppColors.primaryGreen),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreenDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'LV ${profile.level}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName, style: AppTextStyles.titleLarge),
                    Text(
                      '@${profile.username} · $leagueName',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${profile.currentStreak}-day streak', style: AppTextStyles.caption),
                        const SizedBox(width: 10),
                        const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.coin),
                        const SizedBox(width: 4),
                        Text('${profile.coins}', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${profile.level} → ${profile.level + 1}', style: AppTextStyles.caption),
              Text(
                '${profile.xpIntoCurrentLevel} / ${profile.xpNeededForLevel} XP',
                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MintroProgressBar(progress: profile.levelProgress),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _StatsRow extends StatelessWidget {
  final Profile profile;

  const _StatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(value: '${profile.totalXp}', label: 'Total XP', color: AppColors.primaryGreen, bg: AppColors.primaryGreenLight)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(value: '${profile.coins}', label: 'Coins', color: AppColors.coin, bg: AppColors.coinBg)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(value: '—', label: 'Lessons', color: AppColors.pathInvesting, bg: const Color(0xFFE3EAFB))),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(value: '—', label: 'Days Active', color: AppColors.pathTaxStrategy, bg: const Color(0xFFEDE7FA))),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _StatTile({required this.value, required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statValue.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PrimaryGoalCard extends StatelessWidget {
  final Goal goal;

  const _PrimaryGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return MintroCard(
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 22,
                sections: [
                  PieChartSectionData(
                    value: goal.progress * 100,
                    color: AppColors.goalRing,
                    radius: 10,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: (1 - goal.progress) * 100,
                    color: AppColors.progressTrack,
                    radius: 10,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name.toUpperCase(), style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  '${goal.currency} ${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${goal.progressPercent}% toward goal',
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryGreen),
                ),
                Text(
                  '${goal.currency} ${goal.remaining.toStringAsFixed(0)} remaining',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final earnedCount = achievements.where((a) => a.isEarned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Achievements', style: AppTextStyles.headline),
            Text(
              '$earnedCount of ${achievements.length} earned',
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) => _AchievementTile(achievement: achievements[index]),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return MintroCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: achievement.isEarned ? AppColors.primaryGreenLight : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: achievement.isEarned ? AppColors.primaryGreen : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: achievement.isEarned ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
