import 'package:flutter/material.dart';

class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String Function(int)? formatter;

  const CountUpText({super.key, required this.value, this.style, this.formatter});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final text = formatter != null ? formatter!(animatedValue) : animatedValue.toString();
        return Text(text, style: style);
      },
    );
  }
}
