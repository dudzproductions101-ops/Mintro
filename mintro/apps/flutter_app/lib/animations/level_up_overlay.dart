import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'confetti_burst.dart';

/// Shows a full-screen "Level Up!" celebration. Call via [show] rather than
/// constructing directly — it handles the overlay insertion/removal and
/// the entrance/exit transition.
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;
  final bool showConfetti;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
    this.showConfetti = true,
  });

  static void show(BuildContext context, {required int newLevel, bool showConfetti = true}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => LevelUpOverlay(
        newLevel: newLevel,
        showConfetti: showConfetti,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _backdropOpacity;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _badgeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.08).chain(CurveTween(curve: Curves.easeOutBack)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_controller);

    _backdropOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.3));

    _controller.forward();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    await _controller.reverse();
    widget.onDismiss();
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
        return Stack(
          children: [
            Opacity(
              opacity: _backdropOpacity.value,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),
            if (_controller.value > 0.3 && widget.showConfetti) ConfettiBurst(pieceCount: 80),
            Center(
              child: Transform.scale(
                scale: _badgeScale.value,
                child: _LevelBadge(level: widget.newLevel, onContinue: _dismiss),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final VoidCallback onContinue;

  const _LevelBadge({required this.level, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreenLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$level', style: AppTextStyles.displayLarge.copyWith(fontSize: 36, color: AppColors.primaryGreen)),
          ),
          const SizedBox(height: 20),
          Text('Level Up!', style: AppTextStyles.headline),
          const SizedBox(height: 6),
          Text(
            "You've reached level $level. Keep the momentum going.",
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onContinue, child: const Text('Continue')),
          ),
        ],
      ),
    );
  }
}
