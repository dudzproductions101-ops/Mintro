import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A chip that animates in with a spring-like overshoot when a reward is
/// granted (e.g. "+15 XP", "+500 coins"). Intended to be staggered via
/// [delay] when multiple rewards appear together (XP then coins then streak).
class RewardPopChip extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String label;
  final Duration delay;

  const RewardPopChip({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.label,
    this.delay = Duration.zero,
  });

  @override
  State<RewardPopChip> createState() => _RewardPopChipState();
}

class _RewardPopChipState extends State<RewardPopChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    ]).animate(_controller);

    _opacity = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: AppTextStyles.titleMedium.copyWith(color: widget.color),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Convenience row that lays out XP / coin / streak chips with a natural
/// stagger (XP first, then coins, then streak) so rewards don't all pop at
/// once — this reads as "results revealing" rather than a static dump.
class StaggeredRewardRow extends StatelessWidget {
  final int xpEarned;
  final int coinsEarned;
  final bool showStreak;
  final int currentStreak;

  const StaggeredRewardRow({
    super.key,
    required this.xpEarned,
    required this.coinsEarned,
    this.showStreak = false,
    this.currentStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (xpEarned > 0)
          RewardPopChip(
            icon: Icons.bolt_rounded,
            color: AppColors.primaryGreen,
            backgroundColor: AppColors.primaryGreenLight,
            label: '+$xpEarned XP',
            delay: const Duration(milliseconds: 100),
          ),
        if (coinsEarned > 0)
          RewardPopChip(
            icon: Icons.monetization_on_rounded,
            color: AppColors.coin,
            backgroundColor: AppColors.coinBg,
            label: '+$coinsEarned coins',
            delay: const Duration(milliseconds: 280),
          ),
        if (showStreak)
          RewardPopChip(
            icon: Icons.whatshot_rounded,
            color: AppColors.streak,
            backgroundColor: AppColors.streakBg,
            label: '$currentStreak day streak',
            delay: const Duration(milliseconds: 460),
          ),
      ],
    );
  }
}
