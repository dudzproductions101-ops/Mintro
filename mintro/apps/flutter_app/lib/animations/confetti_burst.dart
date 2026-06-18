import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class _ConfettiPiece {
  final double startX; // 0-1, horizontal position
  final double delay; // 0-1, fraction of total duration before this piece starts
  final double fallDuration; // 0-1, fraction of total duration this piece takes to fall
  final double driftX; // horizontal drift in logical pixels
  final double rotationSpeed;
  final Color color;
  final double size;
  final bool isCircle;

  _ConfettiPiece({
    required this.startX,
    required this.delay,
    required this.fallDuration,
    required this.driftX,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    required this.isCircle,
  });
}

/// A short burst of falling confetti rectangles/circles, rendered with a
/// CustomPainter so no third-party package is required. Plays once and
/// calls [onComplete] when finished — callers typically pair this with an
/// AnimatedOpacity to fade the whole overlay out afterward.
class ConfettiBurst extends StatefulWidget {
  final VoidCallback? onComplete;
  final int pieceCount;
  final Duration duration;

  const ConfettiBurst({
    super.key,
    this.onComplete,
    this.pieceCount = 60,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  static const _palette = [
    AppColors.primaryGreen,
    AppColors.coin,
    AppColors.streak,
    AppColors.pathInvesting,
    AppColors.pathTaxStrategy,
    AppColors.leagueEmerald,
  ];

  @override
  void initState() {
    super.initState();
    final random = Random();

    _pieces = List.generate(widget.pieceCount, (_) {
      return _ConfettiPiece(
        startX: random.nextDouble(),
        delay: random.nextDouble() * 0.25,
        fallDuration: 0.55 + random.nextDouble() * 0.35,
        driftX: (random.nextDouble() - 0.5) * 120,
        rotationSpeed: (random.nextDouble() - 0.5) * 8,
        color: _palette[random.nextInt(_palette.length)],
        size: 6 + random.nextDouble() * 6,
        isCircle: random.nextBool(),
      );
    });

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(pieces: _pieces, progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final localProgress = ((progress - piece.delay) / piece.fallDuration).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      final opacity = localProgress > 0.8 ? (1 - localProgress) * 5 : 1.0;
      final x = piece.startX * size.width + piece.driftX * localProgress;
      final y = -20 + (size.height + 40) * Curves.easeIn.transform(localProgress);
      final rotation = piece.rotationSpeed * localProgress * 2 * pi;

      final paint = Paint()..color = piece.color.withOpacity(opacity.clamp(0, 1));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5),
            const Radius.circular(2),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
