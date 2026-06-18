import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A toast-like card that slides up from the bottom edge to announce a
/// newly unlocked achievement, then auto-dismisses. Unlike [LevelUpOverlay]
/// this doesn't block interaction — multiple achievements unlocked at once
/// queue and show one after another rather than stacking visually.
class AchievementUnlockToast extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onDismiss;

  const AchievementUnlockToast({
    super.key,
    required this.title,
    required this.description,
    required this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: 100,
        child: AchievementUnlockToast(
          title: title,
          description: description,
          onDismiss: () => entry.remove(),
        ),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<AchievementUnlockToast> createState() => _AchievementUnlockToastState();
}

class _AchievementUnlockToastState extends State<AchievementUnlockToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    _slide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.coin, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement unlocked',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70),
                      ),
                      Text(
                        widget.title,
                        style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
