import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MintroProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final Color fillColor;
  final Color trackColor;
  final double height;

  const MintroProgressBar({
    super.key,
    required this.progress,
    this.fillColor = AppColors.primaryGreen,
    this.trackColor = AppColors.progressTrack,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: trackColor,
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  width: constraints.maxWidth * value,
                  height: height,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(height),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
