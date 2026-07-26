// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes the resolved [AppConfig] to the provider tree.
///
/// Throws by default: `main.dart` MUST override it with the resolved config
/// via `ProviderScope(overrides: [appConfigProvider.overrideWithValue(...)])`.
/// This keeps config an explicit launch-time input rather than a global.

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// Exposes the resolved [AppConfig] to the provider tree.
///
/// Throws by default: `main.dart` MUST override it with the resolved config
/// via `ProviderScope(overrides: [appConfigProvider.overrideWithValue(...)])`.
/// This keeps config an explicit launch-time input rather than a global.

final class AppConfigProvider
    extends $FunctionalProvider<AppConfig, AppConfig, AppConfig>
    with $Provider<AppConfig> {
  /// Exposes the resolved [AppConfig] to the provider tree.
  ///
  /// Throws by default: `main.dart` MUST override it with the resolved config
  /// via `ProviderScope(overrides: [appConfigProvider.overrideWithValue(...)])`.
  /// This keeps config an explicit launch-time input rather than a global.
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $ProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppConfig create(Ref ref) {
    return appConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfig>(value),
    );
  }
}

String _$appConfigHash() => r'eafb12088a6ecefa586b1fe171b2a92e3bcca01f';
