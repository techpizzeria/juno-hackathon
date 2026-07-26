import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

/// Reusable animation vocabulary for the whole app.
///
/// Feature code must never call `.animate()` or check
/// `MediaQuery.disableAnimations` directly: compose these effect lists with
/// [AppAnimate] (or [AppAnimate.staggered]) so reduced-motion users get a
/// static app for free.
abstract final class AppAnimations {
  /// Stagger gap between siblings in list/grid entrances.
  static const staggerInterval = Duration(milliseconds: 60);

  /// Soft fade + rise used when cards and screens appear.
  static List<Effect<dynamic>> get cardEntrance => [
    FadeEffect(duration: 350.ms, curve: Curves.easeOut),
    SlideEffect(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
      duration: 350.ms,
      curve: Curves.easeOut,
    ),
  ];

  /// Overshoot pop with a shimmer sheen, for wins and completions.
  static List<Effect<dynamic>> get celebration => [
    ScaleEffect(
      begin: const Offset(0.6, 0.6),
      end: const Offset(1, 1),
      duration: 450.ms,
      curve: Curves.elasticOut,
    ),
    const ThenEffect(),
    ShimmerEffect(duration: 700.ms),
  ];

  /// Horizontal shake with a red flash, for failures.
  static List<Effect<dynamic>> get errorShake => [
    ShakeEffect(duration: 400.ms, hz: 5, offset: const Offset(8, 0)),
    TintEffect(color: Colors.red, end: 0.15, duration: 200.ms),
  ];

  /// Gentle looping scale pulse for a primary call-to-action.
  ///
  /// Use with `onPlay: (c) => c.repeat(reverse: true)`.
  static List<Effect<dynamic>> get pulse => [
    ScaleEffect(
      begin: const Offset(1, 1),
      end: const Offset(1.04, 1.04),
      duration: 900.ms,
      curve: Curves.easeInOut,
    ),
  ];
}

/// Central access to the platform's reduced-motion preference.
///
/// Presentation widgets that need to choose different static content, rather
/// than merely skip an effect, use this instead of reading [MediaQuery]
/// directly.
abstract final class AppMotion {
  /// Whether nonessential motion is enabled for [context].
  static bool isEnabledOf(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);
}

/// Motion-safe wrapper around `flutter_animate`.
///
/// Renders [child] animated with [effects], or completely static when the
/// platform requests reduced motion. This widget is the only sanctioned way
/// to animate in feature code.
///
/// ```dart
/// AppAnimate(
///   effects: AppAnimations.cardEntrance,
///   child: MyCard(),
/// )
/// ```
class AppAnimate extends StatelessWidget {
  const AppAnimate({
    required this.child,
    required this.effects,
    this.target,
    this.delay,
    this.onPlay,
    this.onComplete,
    super.key,
  });

  /// The widget to animate.
  final Widget child;

  /// Effects to apply, usually a list from [AppAnimations].
  final List<Effect<dynamic>> effects;

  /// Optional reactive drive: changing this between 0 and 1 plays the
  /// animation forward/backward (see `Animate.target`).
  final double? target;

  /// One-time delay before the whole sequence starts.
  final Duration? delay;

  /// Hook on the underlying controller, e.g. `(c) => c.repeat(reverse: true)`
  /// for loops.
  final void Function(AnimationController controller)? onPlay;

  /// Called when the sequence finishes.
  final void Function(AnimationController controller)? onComplete;

  @override
  Widget build(BuildContext context) {
    if (!AppMotion.isEnabledOf(context)) return child;
    return Animate(
      effects: effects,
      target: target,
      delay: delay,
      onPlay: onPlay,
      onComplete: onComplete,
      child: child,
    );
  }

  /// Applies [effects] to every child with a stagger of [interval],
  /// motion-gated like the single-child constructor.
  ///
  /// ```dart
  /// Column(
  ///   children: AppAnimate.staggered(context, children: cards),
  /// )
  /// ```
  static List<Widget> staggered(
    BuildContext context, {
    required List<Widget> children,
    List<Effect<dynamic>>? effects,
    Duration? interval,
  }) {
    if (!AppMotion.isEnabledOf(context)) return children;
    return children
        .animate(interval: interval ?? AppAnimations.staggerInterval)
        .addEffects(effects ?? AppAnimations.cardEntrance);
  }
}
