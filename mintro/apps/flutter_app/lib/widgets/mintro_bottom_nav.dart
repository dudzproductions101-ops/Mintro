import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MintroBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MintroBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.route_rounded, outlineIcon: Icons.route_outlined, label: 'Learn'),
    (icon: Icons.bolt_rounded, outlineIcon: Icons.bolt_outlined, label: 'Quests'),
    (icon: Icons.emoji_events_rounded, outlineIcon: Icons.emoji_events_outlined, label: 'Ranks'),
    (icon: Icons.person_rounded, outlineIcon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == currentIndex;
              final color = selected ? AppColors.primaryGreen : AppColors.textTertiary;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(selected ? item.icon : item.outlineIcon, color: color, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.navLabel.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
