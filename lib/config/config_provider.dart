import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/config/app_config.dart';

part 'config_provider.g.dart';

/// Exposes the resolved [AppConfig] to the provider tree.
///
/// Throws by default: `main.dart` MUST override it with the resolved config
/// via `ProviderScope(overrides: [appConfigProvider.overrideWithValue(...)])`.
/// This keeps config an explicit launch-time input rather than a global.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) {
  throw UnimplementedError(
    'appConfigProvider must be overridden in main() with AppConfig.resolve()',
  );
}
