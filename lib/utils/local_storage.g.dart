// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app-wide key/value store for small local data.
///
/// Local-first repositories read this with `ref.read(localStorageProvider)`.
/// The instance is created during launch and injected via an override in
/// `main.dart` (SharedPreferences init is async, so it cannot be constructed
/// lazily inside the provider).

@ProviderFor(localStorage)
final localStorageProvider = LocalStorageProvider._();

/// The app-wide key/value store for small local data.
///
/// Local-first repositories read this with `ref.read(localStorageProvider)`.
/// The instance is created during launch and injected via an override in
/// `main.dart` (SharedPreferences init is async, so it cannot be constructed
/// lazily inside the provider).

final class LocalStorageProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  /// The app-wide key/value store for small local data.
  ///
  /// Local-first repositories read this with `ref.read(localStorageProvider)`.
  /// The instance is created during launch and injected via an override in
  /// `main.dart` (SharedPreferences init is async, so it cannot be constructed
  /// lazily inside the provider).
  LocalStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localStorageHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return localStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$localStorageHash() => r'ad67c0ce4fefe4eac1ec80addbc37f5590a7a9ab';
