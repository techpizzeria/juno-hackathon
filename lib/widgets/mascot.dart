import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_template/widgets/app_animations.dart';

/// Creaky's four daily-goal moods.
enum CreakyHomeMood {
  /// Today's goal is complete.
  sunny,

  /// Today's goal is open and on track.
  grey,

  /// A previously scheduled goal was missed.
  rainy,

  /// The existing late-evening wind-down state.
  stormy,
}

/// The three supplied exercise-completion celebrations.
enum CreakyCelebration {
  /// Creaky pops in with heart eyes and rising hearts.
  heartEyes,

  /// Creaky rises on a bright ascent trail.
  ascent,

  /// Creaky's edge meets the sun at the supplied impact spark.
  highFive,
}

/// Production paths for the supplied Creaky artwork.
abstract final class CreakyAssets {
  static const _root = 'assets/creaky';

  /// Every base-resolution asset path referenced by production widgets.
  ///
  /// Flutter resolves the corresponding `2.0x` variant automatically.
  static const all = <String>[
    '$_root/home_sunny/composite.png',
    '$_root/home_sunny/layers/00_sun.png',
    '$_root/home_sunny/layers/10_body.png',
    '$_root/home_sunny/layers/20_eyes.png',
    '$_root/home_grey/composite.png',
    '$_root/home_grey/layers/10_body.png',
    '$_root/home_grey/layers/20_eyes.png',
    '$_root/home_rainy/composite.png',
    '$_root/home_rainy/layers/10_body.png',
    '$_root/home_rainy/layers/20_eyes.png',
    '$_root/home_rainy/layers/30_rain.png',
    '$_root/home_stormy/composite.png',
    '$_root/home_stormy/layers/10_body.png',
    '$_root/home_stormy/layers/20_eyes.png',
    '$_root/home_stormy/layers/30_rain.png',
    '$_root/home_stormy/layers/40_lightning.png',
    '$_root/success_heart_eyes/composite.png',
    '$_root/success_heart_eyes/layers/10_cloud.png',
    '$_root/success_heart_eyes/layers/20_hearts.png',
    '$_root/success_ascent/composite.png',
    '$_root/success_ascent/layers/00_ascent_effects.png',
    '$_root/success_ascent/layers/10_cloud.png',
    '$_root/success_high_five/composite.png',
    '$_root/success_high_five/layers/10_cloud.png',
    '$_root/success_high_five/layers/20_sun_and_impact.png',
  ];

  /// State folder corresponding to [mood].
  static String homeStateFolder(CreakyHomeMood mood) => switch (mood) {
    CreakyHomeMood.sunny => 'home_sunny',
    CreakyHomeMood.grey => 'home_grey',
    CreakyHomeMood.rainy => 'home_rainy',
    CreakyHomeMood.stormy => 'home_stormy',
  };

  /// Static settled artwork for [mood].
  static String compositeForMood(CreakyHomeMood mood) =>
      '$_root/${homeStateFolder(mood)}/composite.png';

  /// State folder corresponding to [celebration].
  static String celebrationStateFolder(CreakyCelebration celebration) =>
      switch (celebration) {
        CreakyCelebration.heartEyes => 'success_heart_eyes',
        CreakyCelebration.ascent => 'success_ascent',
        CreakyCelebration.highFive => 'success_high_five',
      };

  /// Static settled artwork for [celebration].
  static String compositeForCelebration(CreakyCelebration celebration) =>
      '$_root/${celebrationStateFolder(celebration)}/composite.png';

  /// Full-canvas layer path under a supplied [state] folder.
  static String layer(String state, String layer) =>
      '$_root/$state/layers/$layer.png';
}

/// The Creaky mascot rendered from supplied full-canvas PNG layers.
///
/// The artwork is always square and isolated in a [RepaintBoundary].
/// Decorative artwork is excluded from accessibility semantics. When reduced
/// motion is requested, the state-specific `composite.png` is rendered and no
/// controllers or looping effects are created.
class MascotWidget extends StatelessWidget {
  const MascotWidget({
    required this.mood,
    this.size = 180,
    this.animate = true,
    super.key,
  });

  /// Current daily-goal mood.
  final CreakyHomeMood mood;

  /// Square artwork dimension in logical pixels.
  final double size;

  /// Whether motion is enabled in addition to the platform preference.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = animate && AppMotion.isEnabledOf(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: shouldAnimate
              ? _AnimatedHomeMood(mood: mood)
              : Image.asset(
                  CreakyAssets.compositeForMood(mood),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
        ),
      ),
    );
  }
}

class _AnimatedHomeMood extends StatelessWidget {
  const _AnimatedHomeMood({required this.mood});

  final CreakyHomeMood mood;

  Widget _image(String state, String layer) => Image.asset(
    CreakyAssets.layer(state, layer),
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
  );

  Widget _eyes(
    String state, {
    Duration cycle = const Duration(milliseconds: 4200),
  }) {
    final path = CreakyAssets.layer(state, '20_eyes');
    return _BlinkingEyes(key: ValueKey(path), path: path, cycle: cycle);
  }

  @override
  Widget build(BuildContext context) => switch (mood) {
    CreakyHomeMood.sunny => Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: AppAnimate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              MoveEffect(
                begin: const Offset(0, 2),
                end: const Offset(0, -4),
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
              RotateEffect(
                begin: -0.008,
                end: 0.008,
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
            ],
            child: _image('home_sunny', '00_sun'),
          ),
        ),
        Positioned.fill(
          child: AppAnimate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              ScaleEffect(
                begin: const Offset(0.995, 0.995),
                end: const Offset(1.005, 1.005),
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
              MoveEffect(
                begin: const Offset(0, 1),
                end: const Offset(0, -2),
                duration: 1600.ms,
                curve: Curves.easeInOut,
              ),
            ],
            child: Stack(
              children: [
                Positioned.fill(
                  child: _image('home_sunny', '10_body'),
                ),
                Positioned.fill(child: _eyes('home_sunny')),
              ],
            ),
          ),
        ),
      ],
    ),
    CreakyHomeMood.grey => Stack(
      children: [
        Positioned.fill(
          child: AppAnimate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              ScaleEffect(
                begin: const Offset(0.998, 0.998),
                end: const Offset(1.002, 1.002),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
              MoveEffect(
                begin: const Offset(-1, 0),
                end: const Offset(1, 0),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
            ],
            child: Stack(
              children: [
                Positioned.fill(child: _image('home_grey', '10_body')),
                Positioned.fill(
                  child: _eyes(
                    'home_grey',
                    cycle: const Duration(milliseconds: 4600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    CreakyHomeMood.rainy => Stack(
      children: [
        Positioned.fill(
          child: AppAnimate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              MoveEffect(
                end: const Offset(0, 2),
                duration: 600.ms,
                curve: Curves.easeInOut,
              ),
              ScaleEffect(
                begin: const Offset(0.998, 0.998),
                end: const Offset(1.002, 1.002),
                duration: 600.ms,
                curve: Curves.easeInOut,
              ),
            ],
            child: Stack(
              children: [
                Positioned.fill(
                  child: _image('home_rainy', '10_body'),
                ),
                Positioned.fill(child: _eyes('home_rainy')),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: AppAnimate(
            onPlay: (controller) => controller.repeat(),
            effects: [
              MoveEffect(
                begin: const Offset(0, -24),
                end: const Offset(0, 28),
                duration: 1200.ms,
                curve: Curves.linear,
              ),
              FadeEffect(
                begin: 0.25,
                duration: 600.ms,
              ),
            ],
            child: _image('home_rainy', '30_rain'),
          ),
        ),
        Positioned.fill(
          child: AppAnimate(
            delay: 600.ms,
            onPlay: (controller) => controller.repeat(),
            effects: [
              MoveEffect(
                begin: const Offset(0, -24),
                end: const Offset(0, 28),
                duration: 1200.ms,
                curve: Curves.linear,
              ),
              FadeEffect(
                begin: 0.15,
                end: 0.75,
                duration: 600.ms,
              ),
            ],
            child: _image('home_rainy', '30_rain'),
          ),
        ),
      ],
    ),
    CreakyHomeMood.stormy => _StormBodyAndLightning(
      body: _image('home_stormy', '10_body'),
      eyes: _eyes(
        'home_stormy',
        cycle: const Duration(milliseconds: 3600),
      ),
      rain: AppAnimate(
        onPlay: (controller) => controller.repeat(),
        effects: [
          MoveEffect(
            begin: const Offset(0, -18),
            end: const Offset(0, 24),
            duration: 900.ms,
            curve: Curves.linear,
          ),
        ],
        child: _image('home_stormy', '30_rain'),
      ),
      lightning: _image('home_stormy', '40_lightning'),
    ),
  };
}

class _BlinkingEyes extends StatefulWidget {
  const _BlinkingEyes({
    required this.path,
    required this.cycle,
    super.key,
  });

  final String path;
  final Duration cycle;

  @override
  State<_BlinkingEyes> createState() => _BlinkingEyesState();
}

class _BlinkingEyesState extends State<_BlinkingEyes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.cycle,
  )..repeat();

  @override
  void didUpdateWidget(_BlinkingEyes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycle != widget.cycle) {
      _controller.duration = widget.cycle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _scaleY(double value) {
    if (value < 0.66) return 1;
    if (value < 0.69) return 1 - ((value - 0.66) / 0.03) * 0.92;
    if (value < 0.73) return 0.08 + ((value - 0.69) / 0.04) * 0.92;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          1,
          _scaleY(_controller.value),
          1,
        ),
        child: child,
      ),
      child: Image.asset(
        widget.path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

class _StormBodyAndLightning extends StatefulWidget {
  const _StormBodyAndLightning({
    required this.body,
    required this.eyes,
    required this.rain,
    required this.lightning,
  });

  final Widget body;
  final Widget eyes;
  final Widget rain;
  final Widget lightning;

  @override
  State<_StormBodyAndLightning> createState() => _StormBodyAndLightningState();
}

class _StormBodyAndLightningState extends State<_StormBodyAndLightning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isFirstFlash(double value) => value >= 0.18 && value <= 0.22;

  bool _isSecondFlash(double value) => value >= 0.28 && value <= 0.32;

  double _flashOpacity(double value) =>
      _isFirstFlash(value) || _isSecondFlash(value) ? 0.9 : 0;

  double _shakeX(double value) {
    if (!_isFirstFlash(value) && !_isSecondFlash(value)) return 0;
    return ((value * 180).floor().isEven ? -1 : 1) * 2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(_shakeX(_controller.value), 0),
              child: Stack(
                children: [
                  Positioned.fill(child: widget.body),
                  Positioned.fill(child: widget.eyes),
                ],
              ),
            ),
          ),
          Positioned.fill(child: widget.rain),
          Positioned.fill(
            child: Opacity(
              opacity: _flashOpacity(_controller.value),
              child: widget.lightning,
            ),
          ),
        ],
      ),
    );
  }
}
