import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../animations/reward_pop_chip.dart';
import '../../models/quest.dart';
import '../../providers/quest_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/mintro_card.dart';
import '../../widgets/mintro_progress_bar.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(activeQuestsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(activeQuestsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Quests', style: AppTextStyles.displayLarge),
              const SizedBox(height: 4),
              Text('Complete challenges, earn rewards', style: AppTextStyles.body),
              const SizedBox(height: 20),
              questsAsync.when(
                data: (quests) => _QuestsBody(quests: quests),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Failed to load quests', style: AppTextStyles.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestsBody extends ConsumerWidget {
  final List<Quest> quests;

  const _QuestsBody({required this.quests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = quests.where((q) => q.claimed).length;
    final active = quests.where((q) => !q.claimed).length;
    final coinsEarned = quests
        .where((q) => q.claimed)
        .fold<int>(0, (sum, q) => sum + q.coinReward);

    final featured = quests.where((q) => q.isFeatured && !q.claimed).toList();
    final regular = quests.where((q) => !q.isFeatured).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatChip(
                icon: Icons.check_circle,
                iconColor: AppColors.primaryGreen,
                bgColor: AppColors.primaryGreenLight,
                value: '$completed',
                label: 'Completed',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.coin,
                bgColor: AppColors.coinBg,
                value: '$active',
                label: 'Active',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                icon: Icons.paid_rounded,
                iconColor: AppColors.pathTaxStrategy,
                bgColor: const Color(0xFFEDE7FA),
                value: coinsEarned.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]},',
                    ),
                label: 'Coins Earned',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (featured.isNotEmpty) ...[
          _FeaturedQuestCard(quest: featured.first),
          const SizedBox(height: 24),
        ],
        Text('Active', style: AppTextStyles.headline),
        const SizedBox(height: 12),
        ...regular.map((quest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuestCard(quest: quest),
            )),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FeaturedQuestCard extends ConsumerWidget {
  final Quest quest;

  const _FeaturedQuestCard({required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.questFeaturedBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'FEATURED',
                        style: AppTextStyles.label.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quest.title,
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                '${quest.coinReward} coins',
                style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quest.description,
            style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quest.currentValue} of ${quest.targetValue} weeks complete',
                style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.85)),
              ),
              Text(
                '${(quest.progress * 100).round()}%',
                style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MintroProgressBar(
            progress: quest.progress,
            fillColor: Colors.white,
            trackColor: Colors.white.withOpacity(0.25),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  final Quest quest;

  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MintroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.savings_rounded, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(quest.title, style: AppTextStyles.titleMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _periodLabel(quest.period),
                            style: AppTextStyles.caption.copyWith(color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(quest.description, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
                  Text(_timeLabel(quest.timeRemaining), style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${quest.currentValue} / ${quest.targetValue}', style: AppTextStyles.caption),
              if (quest.completed && !quest.claimed)
                _ClaimButton(quest: quest)
              else
                Text(
                  '+${quest.coinReward} coins',
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.coin),
                ),
            ],
          ),
          const SizedBox(height: 8),
          MintroProgressBar(progress: quest.progress),
        ],
      ),
    );
  }

  String _periodLabel(QuestPeriod period) {
    switch (period) {
      case QuestPeriod.daily:
        return 'Daily';
      case QuestPeriod.weekly:
        return 'Weekly';
      case QuestPeriod.monthly:
        return 'Monthly';
    }
  }

  String _timeLabel(Duration remaining) {
    if (remaining.inDays >= 1) return '${remaining.inDays} days';
    if (remaining.inHours >= 1) return '${remaining.inHours} hrs';
    return '${remaining.inMinutes} min';
  }
}

class _ClaimButton extends ConsumerWidget {
  final Quest quest;

  const _ClaimButton({required this.quest});

  Future<void> _handleClaim(BuildContext context, WidgetRef ref) async {
    await ref.read(questClaimProvider.notifier).claim(quest);

    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final position = box?.localToGlobal(Offset.zero) ?? Offset.zero;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 80,
        top: position.dy - 56,
        child: RewardPopChip(
          icon: Icons.monetization_on_rounded,
          color: AppColors.coin,
          backgroundColor: AppColors.coinBg,
          label: '+${quest.coinReward} coins',
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1400), entry.remove);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimState = ref.watch(questClaimProvider);

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: claimState.isLoading ? null : () => _handleClaim(context, ref),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: claimState.isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Claim'),
      ),
    );
  }
}
