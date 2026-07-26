import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/mascot.dart';

/// Session-lifetime selector for the supplied Creaky celebrations.
///
/// The first selection is uniform across all three values. Later selections
/// are uniform across the two values other than the immediately previous one.
class CreakyCelebrationSelector {
  /// Creates a selector, optionally with a deterministic [random] for tests.
  CreakyCelebrationSelector({Random? random}) : _random = random ?? Random();

  final Random _random;
  CreakyCelebration? _last;

  /// Selects the next valid celebration without an immediate repeat.
  CreakyCelebration next() {
    final available = CreakyCelebration.values
        .where((celebration) => celebration != _last)
        .toList(growable: false);
    final selected = available[_random.nextInt(available.length)];
    _last = selected;
    return selected;
  }
}

/// App-session selector shared by all exercise log routes.
final creakyCelebrationSelector = CreakyCelebrationSelector();

/// Short encouragements available on the task-success screen.
const creakyEncouragements = <String>[
  'Nice work!',
  'Well done!',
  'Strong finish!',
  'Great job!',
  'Keep it up!',
  'You nailed it!',
  'Excellent work!',
  'Way to go!',
  'Looking strong!',
  'Progress made!',
  'One step stronger!',
  'Momentum gained!',
  'Brilliant effort!',
  'That’s a win!',
  'Done and dusted!',
];

/// App-session selector for the success screen's encouragement.
class CreakyEncouragementSelector {
  /// Creates a selector, optionally with deterministic randomness for tests.
  CreakyEncouragementSelector({Random? random}) : _random = random ?? Random();

  final Random _random;
  String? _last;

  /// Selects uniformly without immediately repeating the previous message.
  String next() {
    final available = creakyEncouragements
        .where((message) => message != _last)
        .toList(growable: false);
    final selected = available[_random.nextInt(available.length)];
    _last = selected;
    return selected;
  }
}

/// Shared selector retaining repeat avoidance for the current app session.
final creakyEncouragementSelector = CreakyEncouragementSelector();

/// Duration of one non-looping [celebration].
Duration creakyCelebrationDuration(CreakyCelebration celebration) =>
    switch (celebration) {
      CreakyCelebration.heartEyes => const Duration(milliseconds: 1400),
      CreakyCelebration.ascent => const Duration(milliseconds: 1800),
      CreakyCelebration.highFive => const Duration(milliseconds: 1600),
    };

/// One supplied, non-looping Creaky exercise-completion animation.
///
/// [onCompleted] is called at most once. Ordinary parent rebuilds retain this
/// widget's controller-owned timeline and completion timer. In reduced-motion
/// mode only the settled composite is rendered.
class CreakyCelebrationView extends StatefulWidget {
  const CreakyCelebrationView({
    required this.celebration,
    this.size = 280,
    this.animate = true,
    this.onCompleted,
    super.key,
  });

  /// Celebration selected for this completion event.
  final CreakyCelebration celebration;

  /// Square artwork dimension in logical pixels.
  final double size;

  /// Whether motion is enabled in addition to the platform preference.
  final bool animate;

  /// Called once after this celebration's specified duration.
  final VoidCallback? onCompleted;

  @override
  State<CreakyCelebrationView> createState() => _CreakyCelebrationViewState();
}

class _CreakyCelebrationViewState extends State<CreakyCelebrationView> {
  Timer? _completionTimer;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _scheduleCompletion();
  }

  @override
  void didUpdateWidget(CreakyCelebrationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.celebration != widget.celebration) {
      _completed = false;
      _scheduleCompletion();
    }
  }

  void _scheduleCompletion() {
    _completionTimer?.cancel();
    _completionTimer = Timer(
      creakyCelebrationDuration(widget.celebration),
      () {
        if (!mounted || _completed) return;
        _completed = true;
        widget.onCompleted?.call();
      },
    );
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  Widget _image(String state, String layer) => Image.asset(
    CreakyAssets.layer(state, layer),
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
  );

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = widget.animate && AppMotion.isEnabledOf(context);
    final child = shouldAnimate
        ? _animatedCelebration()
        : Image.asset(
            CreakyAssets.compositeForCelebration(widget.celebration),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(dimension: widget.size, child: child),
      ),
    );
  }

  Widget _animatedCelebration() => switch (widget.celebration) {
    CreakyCelebration.heartEyes => Stack(
      children: [
        Positioned.fill(
          child: AppAnimate(
            effects: [
              ScaleEffect(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.08, 1.08),
                duration: 700.ms,
                curve: Curves.easeOutBack,
              ),
              const ThenEffect(),
              ScaleEffect(
                begin: const Offset(1.08, 1.08),
                end: const Offset(1, 1),
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
            ],
            child: _image('success_heart_eyes', '10_cloud'),
          ),
        ),
        Positioned.fill(
          child: AppAnimate(
            effects: [
              FadeEffect(duration: 160.ms),
              ScaleEffect(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
              MoveEffect(
                begin: const Offset(0, 12),
                end: const Offset(0, -22),
                duration: 1000.ms,
                curve: Curves.easeOut,
              ),
              FadeEffect(
                begin: 1,
                end: 0,
                delay: 850.ms,
                duration: 400.ms,
              ),
            ],
            child: _image('success_heart_eyes', '20_hearts'),
          ),
        ),
      ],
    ),
    CreakyCelebration.ascent => Stack(
      children: [
        Positioned.fill(
          child: AppAnimate(
            effects: [
              FadeEffect(
                begin: 0.65,
                duration: 900.ms,
                curve: Curves.easeInOut,
              ),
              MoveEffect(
                begin: const Offset(0, 42),
                end: const Offset(0, -30),
                duration: 1600.ms,
                curve: Curves.easeOutCubic,
              ),
            ],
            child: _image(
              'success_ascent',
              '00_ascent_effects',
            ),
          ),
        ),
        Positioned.fill(
          child: AppAnimate(
            effects: [
              MoveEffect(
                begin: const Offset(0, 42),
                end: const Offset(0, -34),
                duration: 1600.ms,
                curve: Curves.easeOutCubic,
              ),
              ScaleEffect(
                begin: const Offset(0.96, 0.96),
                duration: 900.ms,
                curve: Curves.easeOut,
              ),
            ],
            child: _image('success_ascent', '10_cloud'),
          ),
        ),
      ],
    ),
    CreakyCelebration.highFive => Stack(
      children: [
        Positioned.fill(
          child: AppAnimate(
            effects: [
              MoveEffect(
                begin: const Offset(-6, 6),
                duration: 880.ms,
                curve: Curves.easeOutBack,
              ),
            ],
            child: _image('success_high_five', '10_cloud'),
          ),
        ),
        Positioned.fill(
          child: AppAnimate(
            effects: [
              MoveEffect(
                begin: const Offset(6, -6),
                duration: 880.ms,
                curve: Curves.easeOutBack,
              ),
              ScaleEffect(
                begin: const Offset(1, 1),
                end: const Offset(1.04, 1.04),
                delay: 880.ms,
                duration: 120.ms,
                curve: Curves.easeOut,
              ),
              const ThenEffect(),
              ScaleEffect(
                begin: const Offset(1.04, 1.04),
                end: const Offset(1, 1),
                duration: 160.ms,
                curve: Curves.easeIn,
              ),
            ],
            child: _image(
              'success_high_five',
              '20_sun_and_impact',
            ),
          ),
        ),
      ],
    ),
  };
}

/// Full-screen success state containing one selected Creaky celebration.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({
    required this.celebration,
    required this.message,
    super.key,
  });

  /// Success state selected for this completed task.
  final CreakyCelebration celebration;

  /// Encouragement selected for this completed task.
  final String message;

  /// Presents exactly one success screen for [celebration].
  static Future<void> show(
    BuildContext context, {
    required CreakyCelebration celebration,
    required String message,
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: 'Task complete',
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => CelebrationOverlay(
        celebration: celebration,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight - 80;
          final size = min<double>(
            320,
            min(constraints.maxWidth, max(0, availableHeight)),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IgnorePointer(
                        child: CreakyCelebrationView(
                          celebration: celebration,
                          size: size,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nice!'),
              ),
            ],
          );
        },
      ),
    );
  }
}
