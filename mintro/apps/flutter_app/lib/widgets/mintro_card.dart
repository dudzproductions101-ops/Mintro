import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MintroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Border? border;
  final VoidCallback? onTap;

  const MintroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}
