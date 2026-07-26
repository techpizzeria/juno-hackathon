// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide [Dio] instance.
///
/// Base URL and timeouts come from [appConfigProvider]. Repositories in the
/// data layer read this with `ref.read(dioProvider)`; nothing else should
/// construct a [Dio] directly. Add interceptors (auth, logging) here so every
/// request shares them.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// The app-wide [Dio] instance.
///
/// Base URL and timeouts come from [appConfigProvider]. Repositories in the
/// data layer read this with `ref.read(dioProvider)`; nothing else should
/// construct a [Dio] directly. Add interceptors (auth, logging) here so every
/// request shares them.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// The app-wide [Dio] instance.
  ///
  /// Base URL and timeouts come from [appConfigProvider]. Repositories in the
  /// data layer read this with `ref.read(dioProvider)`; nothing else should
  /// construct a [Dio] directly. Add interceptors (auth, logging) here so every
  /// request shares them.
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'c382a8bbab825ee1e7d77521acbe30bd825c059f';
