// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide [VideoService].

@ProviderFor(videoService)
final videoServiceProvider = VideoServiceProvider._();

/// App-wide [VideoService].

final class VideoServiceProvider
    extends $FunctionalProvider<VideoService, VideoService, VideoService>
    with $Provider<VideoService> {
  /// App-wide [VideoService].
  VideoServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoServiceHash();

  @$internal
  @override
  $ProviderElement<VideoService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VideoService create(Ref ref) {
    return videoService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoService>(value),
    );
  }
}

String _$videoServiceHash() => r'3396ca86d81e6e88bf7f44af9cf53c6d061c988c';
