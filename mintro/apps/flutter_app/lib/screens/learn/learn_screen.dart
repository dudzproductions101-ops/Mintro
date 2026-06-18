import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/learning_path.dart';
import '../../providers/learning_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/mintro_card.dart';
import '../../widgets/mintro_progress_bar.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(learningPathsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(learningPathsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Skill Tree', style: AppTextStyles.displayLarge),
              const SizedBox(height: 4),
              Text('Master financial concepts step by step', style: AppTextStyles.body),
              const SizedBox(height: 24),
              Text('Learning Paths', style: AppTextStyles.headline),
              const SizedBox(height: 12),
              pathsAsync.when(
                data: (paths) => _PathGrid(paths: paths),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Failed to load learning paths', style: AppTextStyles.body),
              ),
              const SizedBox(height: 28),
              Text('Skill Map', style: AppTextStyles.headline),
              const SizedBox(height: 12),
              pathsAsync.maybeWhen(
                data: (paths) => _SkillMap(paths: paths),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathGrid extends StatelessWidget {
  final List<LearningPath> paths;

  const _PathGrid({required this.paths});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paths.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) => _PathCard(path: paths[index]),
    );
  }
}

class _PathCard extends StatelessWidget {
  final LearningPath path;

  const _PathCard({required this.path});

  Color get _dotColor {
    switch (path.slug) {
      case 'credit-debt':
        return AppColors.pathCreditDebt;
      case 'investing':
        return AppColors.pathInvesting;
      case 'tax-strategy':
        return AppColors.pathTaxStrategy;
      case 'trust-funds':
        return AppColors.pathTrustFunds;
      default:
        return AppColors.pathFoundations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MintroCard(
      padding: const EdgeInsets.all(16),
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            path.description,
            style: AppTextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          MintroProgressBar(progress: path.progress, fillColor: _dotColor, height: 6),
          const SizedBox(height: 8),
          Text('${path.completedLessons}/${path.totalLessons} lessons', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Vertical node map: completed nodes show a filled green check badge,
/// matching the "Money Basics — 100 XP" style nodes in the mockup.
class _SkillMap extends StatelessWidget {
  final List<LearningPath> paths;

  const _SkillMap({required this.paths});

  @override
  Widget build(BuildContext context) {
    final nodes = paths.take(5).toList();

    return MintroCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < nodes.length; i++) ...[
            _SkillNode(path: nodes[i]),
            if (i != nodes.length - 1)
              Container(width: 2, height: 28, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _SkillNode extends StatelessWidget {
  final LearningPath path;

  const _SkillNode({required this.path});

  @override
  Widget build(BuildContext context) {
    final unlocked = path.completedLessons > 0 || path.sortOrder == 0;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: unlocked ? AppColors.primaryGreenLight : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: unlocked ? AppColors.primaryGreen : AppColors.divider,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.attach_money_rounded,
                size: 32,
                color: unlocked ? AppColors.primaryGreen : AppColors.textTertiary,
              ),
            ),
            if (path.isComplete)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(path.title, style: AppTextStyles.titleMedium),
        Text('${path.totalLessons * 25} XP', style: AppTextStyles.caption),
      ],
    );
  }
}
