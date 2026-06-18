import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A single weekday indicator in the streak row. When [isActive] flips from
/// false to true (i.e. the user just completed today's activity), it plays
/// a scale-bounce + color fill rather than snapping instantly — this is the
/// piece that makes completing a lesson feel like it "locked in" the day.
class AnimatedStreakDot extends StatefulWidget {
  final bool isActive;
  final bool isToday;

  const AnimatedStreakDot({super.key, required this.isActive, required this.isToday});

  @override
  State<AnimatedStreakDot> createState() => _AnimatedStreakDotState();
}

class _AnimatedStreakDotState extends State<AnimatedStreakDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    if (widget.isActive) _controller.value = 1;
  }

  @override
  void didUpdateWidget(AnimatedStreakDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.value = 0;
    }
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
        final t = Curves.easeOutBack.transform(_controller.value);
        final bounce = widget.isActive ? (1.0 + (1 - t).clamp(0.0, 0.3) * 0.3) : 1.0;

        return Transform.scale(
          scale: bounce,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Color.lerp(AppColors.surfaceMuted, AppColors.primaryGreenLight, _controller.value),
              borderRadius: BorderRadius.circular(18),
              border: widget.isToday ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: _controller.value > 0.5
                ? Icon(
                    Icons.check_circle,
                    color: AppColors.primaryGreen.withOpacity(_controller.value),
                    size: 18,
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
