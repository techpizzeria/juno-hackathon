import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

/// Inline, tap-to-play player for a recorded form-check video.
///
/// Caps the clip at [maxHeight] and centers it, so a portrait phone video
/// stays a small box instead of filling the screen. Tapping toggles
/// play/pause and replays from the start once the clip has finished.
class SessionVideoView extends StatefulWidget {
  const SessionVideoView({required this.path, this.maxHeight = 200, super.key});

  /// Absolute path to the stored `.mp4`.
  final String path;

  /// Largest height the player may occupy; width follows the video's aspect
  /// ratio within it.
  final double maxHeight;

  @override
  State<SessionVideoView> createState() => _SessionVideoViewState();
}

class _SessionVideoViewState extends State<SessionVideoView> {
  VideoPlayerController? _controller;
  var _missing = false;
  var _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SessionVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A retake swaps in a new file: tear down and reload.
    if (oldWidget.path != widget.path) {
      unawaited(_controller?.dispose());
      _controller = null;
      _missing = false;
      _wasPlaying = false;
      _load();
    }
  }

  void _load() {
    final file = File(widget.path);
    if (!file.existsSync()) {
      _missing = true;
      return;
    }
    final controller = VideoPlayerController.file(file);
    _controller = controller;
    controller.addListener(_onValueChanged);
    unawaited(
      controller.initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {
        if (mounted) setState(() => _missing = true);
      }),
    );
  }

  /// Rebuilds only when playback starts or stops, so the play overlay
  /// reappears when the clip ends without a rebuild every frame.
  void _onValueChanged() {
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _wasPlaying) {
      _wasPlaying = playing;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onValueChanged);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  void _toggle() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.isPlaying) {
      unawaited(controller.pause());
      return;
    }
    // Restart from the beginning once the clip has run to the end.
    if (value.position >= value.duration) {
      unawaited(controller.seekTo(Duration.zero));
    }
    unawaited(controller.play());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_missing) {
      return Text('🎥 Video unavailable', style: theme.textTheme.bodySmall);
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(
        height: widget.maxHeight,
        child: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return SizedBox(
      height: widget.maxHeight,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: GestureDetector(
              onTap: _toggle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  if (!controller.value.isPlaying)
                    Icon(
                      Icons.play_circle_fill,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
