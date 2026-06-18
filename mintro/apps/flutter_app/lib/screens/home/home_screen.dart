import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../animations/animated_streak_dot.dart';
import '../../animations/page_transitions.dart';
import '../../models/learning_path.dart';
import '../../providers/profile_provider.dart';
import '../../providers/learning_provider.dart';
import '../../screens/lesson_complete/lesson_complete_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/mintro_card.dart';
import '../../widgets/mintro_progress_bar.dart';
import '../../widgets/count_up_text.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final dailyProgressAsync = ref.watch(dailyXpProgressProvider);
    final activeDaysAsync = ref.watch(activeDaysThisWeekProvider);
    final todaysLessonsAsync = ref.watch(todaysLessonsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(dailyXpProgressProvider);
            ref.invalidate(activeDaysThisWeekProvider);
            ref.invalidate(todaysLessonsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              profileAsync.when(
                data: (profile) => _Header(
                  displayName: profile.displayName,
                  streak: profile.currentStreak,
                  coins: profile.coins,
                ),
                loading: () => const _HeaderSkeleton(),
                error: (e, _) => Text('Failed to load profile', style: AppTextStyles.body),
              ),
              const SizedBox(height: 20),
              activeDaysAsync.when(
                data: (activeDays) => profileAsync.maybeWhen(
                  data: (profile) => _StreakCard(
                    streak: profile.currentStreak,
                    activeWeekdays: activeDays,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                loading: () => const SizedBox(height: 180),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              profileAsync.maybeWhen(
                data: (profile) => dailyProgressAsync.when(
                  data: (progress) => _DailyXpGoalCard(
                    earned: progress.xpEarned,
                    goal: profile.dailyXpGoal,
                  ),
                  loading: () => const SizedBox(height: 120),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Lessons", style: AppTextStyles.headline),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: [
                        Text('All', style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryGreen)),
                        const Icon(Icons.chevron_right, color: AppColors.primaryGreen, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              todaysLessonsAsync.when(
                data: (lessons) => Column(
                  children: lessons
                      .map((lesson) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LessonRow(lesson: lesson),
                          ))
                      .toList(),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Failed to load lessons', style: AppTextStyles.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String displayName;
  final int streak;
  final int coins;

  const _Header({required this.displayName, required this.streak, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: AppTextStyles.body),
              const SizedBox(height: 2),
              Text(displayName, style: AppTextStyles.displayLarge),
            ],
          ),
        ),
        _Pill(
          icon: Icons.whatshot_rounded,
          iconColor: AppColors.streak,
          bgColor: AppColors.streakBg,
          child: CountUpText(
            value: streak,
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.streak),
          ),
        ),
        const SizedBox(width: 8),
        _Pill(
          icon: Icons.monetization_on_rounded,
          iconColor: AppColors.coin,
          bgColor: AppColors.coinBg,
          child: CountUpText(
            value: coins,
            formatter: (v) => v.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},',
                ),
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.coin),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Widget child;

  const _Pill({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          child,
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 56);
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final Set<int> activeWeekdays;

  const _StreakCard({required this.streak, required this.activeWeekdays});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;

    return MintroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVE STREAK', style: AppTextStyles.label),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$streak', style: AppTextStyles.displayLarge.copyWith(fontSize: 36)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('days', style: AppTextStyles.body),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.streakBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.whatshot_rounded, color: AppColors.streak),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final isActive = activeWeekdays.contains(weekday);
              final isToday = weekday == today;

              return Expanded(
                child: Column(
                  children: [
                    AnimatedStreakDot(isActive: isActive, isToday: isToday),
                    const SizedBox(height: 6),
                    Text(_weekdayLabels[index], style: AppTextStyles.caption),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DailyXpGoalCard extends StatelessWidget {
  final int earned;
  final int goal;

  const _DailyXpGoalCard({required this.earned, required this.goal});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal - earned).clamp(0, goal);

    return MintroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Daily XP Goal', style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                '$earned / $goal XP',
                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MintroProgressBar(progress: goal == 0 ? 0 : earned / goal),
          const SizedBox(height: 10),
          Text(
            remaining == 0 ? "You hit today's goal! 🎉" : '$remaining more XP to hit today\'s goal',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends ConsumerWidget {
  final Lesson lesson;

  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MintroCard(
      color: lesson.isCompleted ? AppColors.primaryGreenLight : AppColors.surface,
      padding: const EdgeInsets.all(16),
      onTap: lesson.isCompleted ? null : () => _startLesson(context, ref),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(lesson.icon), color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  lesson.description,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('+${lesson.xpReward} XP', style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primaryGreen)),
          const SizedBox(width: 8),
          Icon(
            lesson.isCompleted ? Icons.check_circle : Icons.chevron_right,
            color: lesson.isCompleted ? AppColors.primaryGreen : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  /// In the real quiz flow this would push a QuizScreen first and collect
  /// `answers` from user input; here the lesson is submitted directly with
  /// an empty answer set as a stand-in so the completion → animation
  /// pipeline (this Part) can be demonstrated end-to-end against Part C's
  /// scoring endpoint without depending on the unbuilt quiz UI.
  Future<void> _startLesson(BuildContext context, WidgetRef ref) async {
    await ref.read(lessonCompletionProvider.notifier).submit(
          lessonId: lesson.id,
          answers: const [],
          timeSpentSeconds: 0,
        );

    if (context.mounted) {
      Navigator.of(context).push(
        SlideUpRoute(page: const LessonCompleteScreen()),
      );
    }
  }

  IconData _iconFor(String? icon) {
    switch (icon) {
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'piggy_bank':
        return Icons.savings_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}
