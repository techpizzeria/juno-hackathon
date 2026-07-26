// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedules.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for stored reminder schedules.
///
/// Persists all schedules as one JSON array under `creak.schedules.v1`.

@ProviderFor(ScheduleRepository)
final scheduleRepositoryProvider = ScheduleRepositoryProvider._();

/// Single source of truth for stored reminder schedules.
///
/// Persists all schedules as one JSON array under `creak.schedules.v1`.
final class ScheduleRepositoryProvider
    extends $NotifierProvider<ScheduleRepository, ScheduleRepository> {
  /// Single source of truth for stored reminder schedules.
  ///
  /// Persists all schedules as one JSON array under `creak.schedules.v1`.
  ScheduleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleRepositoryHash();

  @$internal
  @override
  ScheduleRepository create() => ScheduleRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScheduleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScheduleRepository>(value),
    );
  }
}

String _$scheduleRepositoryHash() =>
    r'3e79f2b1788a90f582374b15686ddeab7dc2b004';

/// Single source of truth for stored reminder schedules.
///
/// Persists all schedules as one JSON array under `creak.schedules.v1`.

abstract class _$ScheduleRepository extends $Notifier<ScheduleRepository> {
  ScheduleRepository build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ScheduleRepository, ScheduleRepository>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScheduleRepository, ScheduleRepository>,
              ScheduleRepository,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Reactive reminder schedules, keyed by program.
///
/// Also owns keeping pending notifications in sync with the stored slots
/// (wired to the notification service in a later milestone).

@ProviderFor(Schedules)
final schedulesProvider = SchedulesProvider._();

/// Reactive reminder schedules, keyed by program.
///
/// Also owns keeping pending notifications in sync with the stored slots
/// (wired to the notification service in a later milestone).
final class SchedulesProvider
    extends $NotifierProvider<Schedules, List<ScheduleModel>> {
  /// Reactive reminder schedules, keyed by program.
  ///
  /// Also owns keeping pending notifications in sync with the stored slots
  /// (wired to the notification service in a later milestone).
  SchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schedulesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schedulesHash();

  @$internal
  @override
  Schedules create() => Schedules();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ScheduleModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ScheduleModel>>(value),
    );
  }
}

String _$schedulesHash() => r'e7a9d24cf64550fd914ad4e211c468a122e54aa9';

/// Reactive reminder schedules, keyed by program.
///
/// Also owns keeping pending notifications in sync with the stored slots
/// (wired to the notification service in a later milestone).

abstract class _$Schedules extends $Notifier<List<ScheduleModel>> {
  List<ScheduleModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ScheduleModel>, List<ScheduleModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ScheduleModel>, List<ScheduleModel>>,
              List<ScheduleModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
