import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'local_storage.g.dart';

/// The app-wide key/value store for small local data.
///
/// Local-first repositories read this with `ref.read(localStorageProvider)`.
/// The instance is created during launch and injected via an override in
/// `main.dart` (SharedPreferences init is async, so it cannot be constructed
/// lazily inside the provider).
@Riverpod(keepAlive: true)
SharedPreferences localStorage(Ref ref) {
  throw UnimplementedError(
    'localStorageProvider must be overridden in main() with the instance',
  );
}
