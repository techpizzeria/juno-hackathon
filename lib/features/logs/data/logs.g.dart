// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for stored session logs.
///
/// Persists all log entries as one JSON array under `creak.logs.v1`.

@ProviderFor(LogRepository)
final logRepositoryProvider = LogRepositoryProvider._();

/// Single source of truth for stored session logs.
///
/// Persists all log entries as one JSON array under `creak.logs.v1`.
final class LogRepositoryProvider
    extends $NotifierProvider<LogRepository, LogRepository> {
  /// Single source of truth for stored session logs.
  ///
  /// Persists all log entries as one JSON array under `creak.logs.v1`.
  LogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logRepositoryHash();

  @$internal
  @override
  LogRepository create() => LogRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogRepository>(value),
    );
  }
}

String _$logRepositoryHash() => r'c195b649c0e54a029dd16c5279b029877123e19e';

/// Single source of truth for stored session logs.
///
/// Persists all log entries as one JSON array under `creak.logs.v1`.

abstract class _$LogRepository extends $Notifier<LogRepository> {
  LogRepository build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LogRepository, LogRepository>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LogRepository, LogRepository>,
              LogRepository,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Reactive session logs; the UI's entry point for logging mutations.

@ProviderFor(Logs)
final logsProvider = LogsProvider._();

/// Reactive session logs; the UI's entry point for logging mutations.
final class LogsProvider extends $NotifierProvider<Logs, List<LogEntryModel>> {
  /// Reactive session logs; the UI's entry point for logging mutations.
  LogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logsHash();

  @$internal
  @override
  Logs create() => Logs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LogEntryModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LogEntryModel>>(value),
    );
  }
}

String _$logsHash() => r'9853a203a12213d66aae0e58ccc2d29fc9a1e9ec';

/// Reactive session logs; the UI's entry point for logging mutations.

abstract class _$Logs extends $Notifier<List<LogEntryModel>> {
  List<LogEntryModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<LogEntryModel>, List<LogEntryModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LogEntryModel>, List<LogEntryModel>>,
              List<LogEntryModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
