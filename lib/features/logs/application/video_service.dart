import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/utils/ids.dart';

part 'video_service.g.dart';

/// Records short form-check videos and keeps them in app storage.
///
/// Wraps `image_picker` (camera capture) and `path_provider` so the rest of
/// the app deals only in stable file paths. Capture needs a real device; the
/// iOS Simulator has no camera and returns null.
class VideoService {
  VideoService(this._picker);

  final ImagePicker _picker;

  /// Opens the camera to record a clip, copies it into the app's documents
  /// directory, and returns the stored absolute path. Returns null if the
  /// user cancels or no camera is available.
  Future<String?> recordAndStore() async {
    final captured = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );
    if (captured == null) return null;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/session_videos');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final destination = '${dir.path}/${newId()}.mp4';
    await File(captured.path).copy(destination);
    return destination;
  }
}

/// App-wide [VideoService].
@Riverpod(keepAlive: true)
VideoService videoService(Ref ref) => VideoService(ImagePicker());
