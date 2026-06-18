import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Wraps any async provider result and renders a consistent error state
/// with a retry button rather than letting individual screens each
/// implement their own error UI (which was the previous ad-hoc approach
/// of just showing a Text widget on error).
///
/// Usage:
/// ```dart
/// asyncValue.when(
///   data: (data) => MyWidget(data: data),
///   loading: () => const MintroLoadingState(),
///   error: (e, st) => AsyncErrorState(error: e, onRetry: () => ref.invalidate(myProvider)),
/// )
/// ```
class AsyncErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? message;

  const AsyncErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              message ?? 'Something went wrong',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent loading shimmer used while async data is fetching.
class MintroLoadingState extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const MintroLoadingState({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<MintroLoadingState> createState() => _MintroLoadingStateState();
}

class _MintroLoadingStateState extends State<MintroLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: Color.lerp(AppColors.progressTrack, AppColors.surfaceMuted, _shimmer.value),
          ),
        );
      },
    );
  }
}
