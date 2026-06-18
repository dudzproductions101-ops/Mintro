import 'package:flutter/material.dart';

/// Slide-up-and-fade transition, used for the lesson → quiz → completion
/// flow so it reads as "stepping forward" rather than the default
/// right-to-left push (which implies lateral navigation, not progression).
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

            return SlideTransition(
              position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}

/// Simple cross-fade, used for modal-style screens (settings, achievement
/// detail) where a directional slide would feel out of place.
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}
