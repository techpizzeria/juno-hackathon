import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/widgets/app_animations.dart';

/// Shows an exercise's position photos, optionally crossfading the two
/// start/end frames in a loop to suggest motion.
///
/// Motion is opt-in via [animate]; only the info bottom sheets use it, so
/// inline images (grid cards, session list) stay still. Also falls back to
/// the static first frame under reduced motion (via [AppAnimate]) or when
/// only one frame exists, and to a friendly icon when the network image
/// fails to load.
class ExerciseMotionImage extends StatelessWidget {
  const ExerciseMotionImage({
    required this.exercise,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.animate = false,
    super.key,
  });

  /// The catalog entry whose photos are shown.
  final ExerciseModel exercise;

  /// Corner rounding applied to the image.
  final BorderRadius borderRadius;

  /// Whether to loop the two position photos. Off by default so exercise
  /// images sit still inline (grids, session cards); on only inside an info
  /// bottom sheet, where the crossfade suggests motion. A single-frame entry
  /// never moves regardless.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (exercise.images.isEmpty) {
      return const _ImageFallback();
    }
    final baseFrame = _frame(context, 0);
    if (!animate || exercise.images.length < 2) {
      return ClipRRect(borderRadius: borderRadius, child: baseFrame);
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          baseFrame,
          Positioned.fill(
            // Hold each pose still, then cross-dissolve quickly between them.
            // The two photos are different positions, not motion frames, so a
            // continuous fade just ghosts them together and reads as flicker.
            // Dwelling on a clean frame and blending only briefly avoids that.
            // With reverse repeat, the Interval yields: hold frame 0 (~1.5s),
            // quick fade, hold frame 1 (~1.5s), quick fade back.
            child: AppAnimate(
              onPlay: (c) => c.repeat(reverse: true),
              effects: [
                FadeEffect(
                  begin: 0,
                  end: 1,
                  duration: 1950.ms,
                  curve: const Interval(0.385, 0.615, curve: Curves.easeInOut),
                ),
              ],
              child: _frame(context, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frame(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    return Image.network(
      exercise.imageUrl(index),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      // Decode lazily at a modest size; cards are small.
      cacheWidth: 480,
      // Fade each frame in once it decodes so it never pops from the
      // placeholder.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : ColoredBox(color: scheme.surfaceContainerHighest),
      errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.self_improvement, color: scheme.primary, size: 32),
      ),
    );
  }
}
