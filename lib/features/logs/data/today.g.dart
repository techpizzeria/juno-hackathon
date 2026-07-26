// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's scheduled sessions, pending first.

@ProviderFor(todaysSessions)
final todaysSessionsProvider = TodaysSessionsProvider._();

/// Today's scheduled sessions, pending first.

final class TodaysSessionsProvider
    extends
        $FunctionalProvider<
          List<SessionView>,
          List<SessionView>,
          List<SessionView>
        >
    with $Provider<List<SessionView>> {
  /// Today's scheduled sessions, pending first.
  TodaysSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaysSessionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaysSessionsHash();

  @$internal
  @override
  $ProviderElement<List<SessionView>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SessionView> create(Ref ref) {
    return todaysSessions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SessionView> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SessionView>>(value),
    );
  }
}

String _$todaysSessionsHash() => r'f48da89afbc1ecb8a57fe212cf0e5bf9f96e9ff5';

/// Current streak in days.

@ProviderFor(streak)
final streakProvider = StreakProvider._();

/// Current streak in days.

final class StreakProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Current streak in days.
  StreakProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return streak(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$streakHash() => r'396aaa41877afde145660b99037aec8e7deca366';

/// 1–7 weekday numbers of this week (Mon–Sun) whose scheduled sessions
/// were all satisfied, for the dashboard's week dots.

@ProviderFor(weekDoneDays)
final weekDoneDaysProvider = WeekDoneDaysProvider._();

/// 1–7 weekday numbers of this week (Mon–Sun) whose scheduled sessions
/// were all satisfied, for the dashboard's week dots.

final class WeekDoneDaysProvider
    extends $FunctionalProvider<Set<int>, Set<int>, Set<int>>
    with $Provider<Set<int>> {
  /// 1–7 weekday numbers of this week (Mon–Sun) whose scheduled sessions
  /// were all satisfied, for the dashboard's week dots.
  WeekDoneDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekDoneDaysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekDoneDaysHash();

  @$internal
  @override
  $ProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<int> create(Ref ref) {
    return weekDoneDays(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$weekDoneDaysHash() => r'2d356815072b6298bf5cb446a2434e740850958d';

/// History grouped by program (each program's sessions, newest first), for
/// the expandable history view. Programs with no history are omitted.

@ProviderFor(historyByProgram)
final historyByProgramProvider = HistoryByProgramProvider._();

/// History grouped by program (each program's sessions, newest first), for
/// the expandable history view. Programs with no history are omitted.

final class HistoryByProgramProvider
    extends
        $FunctionalProvider<
          List<ProgramHistory>,
          List<ProgramHistory>,
          List<ProgramHistory>
        >
    with $Provider<List<ProgramHistory>> {
  /// History grouped by program (each program's sessions, newest first), for
  /// the expandable history view. Programs with no history are omitted.
  HistoryByProgramProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyByProgramProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyByProgramHash();

  @$internal
  @override
  $ProviderElement<List<ProgramHistory>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ProgramHistory> create(Ref ref) {
    return historyByProgram(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProgramHistory> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ProgramHistory>>(value),
    );
  }
}

String _$historyByProgramHash() => r'311ea849a15585b72794487817d1475cfd3e2a5b';

/// Past scheduled days (newest first, up to 60 days back), for history.

@ProviderFor(history)
final historyProvider = HistoryProvider._();

/// Past scheduled days (newest first, up to 60 days back), for history.

final class HistoryProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// Past scheduled days (newest first, up to 60 days back), for history.
  HistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyHash();

  @$internal
  @override
  $ProviderElement<List<HistoryDay>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<HistoryDay> create(Ref ref) {
    return history(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HistoryDay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HistoryDay>>(value),
    );
  }
}

String _$historyHash() => r'9b85ce0982a0dc50b08191c312216f9ed4e4feef';
