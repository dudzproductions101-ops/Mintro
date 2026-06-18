import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../animations/confetti_burst.dart';
import '../../animations/level_up_overlay.dart';
import '../../animations/reward_pop_chip.dart';
import '../../providers/learning_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Shown immediately after a lesson's quiz is submitted. Reads the result
/// from [lessonCompletionProvider] (already populated by the time this
/// screen is pushed) and choreographs the celebration:
///
/// 1. Score ring scales in.
/// 2. ~250ms later, confetti fires if passed.
/// 3. ~400ms later, XP/coin/streak chips pop in with their own stagger.
/// 4. If the lesson completion caused a level-up, that overlay is shown on
///    top once the chip sequence finishes, so it doesn't compete for
///    attention with the in-flight reward animations.
class LessonCompleteScreen extends ConsumerStatefulWidget {
  const LessonCompleteScreen({super.key});

  @override
  ConsumerState<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends ConsumerState<LessonCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  bool _showConfetti = false;
  bool _showChips = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _ringController.forward();

    final result = ref.read(lessonCompletionProvider).value;
    final animationsEnabled = ref.read(settingsProvider).animationsEnabled;

    if (result != null && result.passed && animationsEnabled) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _showConfetti = true);
      });
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showChips = true);
    });

    if (result != null && result.leveledUp) {
      Future.delayed(const Duration(milliseconds: 1700), () {
        if (mounted) {
          final profile = ref.read(profileProvider).value;
          LevelUpOverlay.show(
            context,
            newLevel: profile?.level ?? 0,
            showConfetti: animationsEnabled,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(lessonCompletionProvider).value;

    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: result.passed ? AppColors.primaryGreenLight : AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, _) {
                    final scale = Curves.easeOutBack.transform(_ringController.value);
                    return Transform.scale(
                      scale: scale,
                      child: _ScoreRing(score: result.score, passed: result.passed),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  result.passed ? 'Lesson Complete!' : 'Almost there',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 6),
                Text(
                  result.passed
                      ? 'Great work — here\'s what you earned'
                      : 'Review the material and try again',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 28),
                AnimatedOpacity(
                  opacity: _showChips ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: result.passed
                      ? StaggeredRewardRow(
                          xpEarned: result.xpEarned,
                          coinsEarned: result.coinsEarned,
                          showStreak: result.streakExtended,
                        )
                      : const SizedBox.shrink(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(result.passed ? 'Continue' : 'Try Again'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showConfetti) ConfettiBurst(pieceCount: 50),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final bool passed;

  const _ScoreRing({required this.score, required this.passed});

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.primaryGreen : AppColors.streak;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: const Size(140, 140),
                painter: _RingPainter(progress: value, color: color),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_circle_rounded : Icons.refresh_rounded,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text('$score%', style: AppTextStyles.headline.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = AppColors.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (3.14159 / 180),
      progress * 2 * 3.14159,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
