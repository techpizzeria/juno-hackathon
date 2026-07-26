import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A semicircular progress gauge, drawn as an arch over the top.
///
/// Used behind the dashboard mascot as the daily tracker: the track is the
/// faint full arch, and [progress] (0..1) fills it with the accent colour
/// from the left round to the right.
class DailyProgressArc extends StatelessWidget {
  const DailyProgressArc({
    required this.progress,
    this.size = 184,
    this.strokeWidth = 12,
    super.key,
  });

  /// Completion fraction, clamped to 0..1.
  final double progress;

  /// Width and height of the (square) gauge box; only the top arch is drawn.
  final double size;

  /// Thickness of the arch stroke.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress.clamp(0, 1),
          strokeWidth: strokeWidth,
          trackColor: scheme.primary.withValues(alpha: 0.15),
          progressColor: scheme.primary,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - strokeWidth) / 2,
    );
    // Top semicircle: left (pi) sweeping clockwise over the top to right.
    const start = math.pi;
    const sweep = math.pi;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, start, sweep, false, track);
    if (progress > 0) {
      final fill = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(rect, start, sweep * progress, false, fill);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
