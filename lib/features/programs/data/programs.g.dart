// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'programs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for stored programs.
///
/// Persists the full program list as one JSON array under
/// `creak.programs.v1`. Reads are synchronous (shared_preferences is an
/// in-memory cache); every mutation writes through.

@ProviderFor(ProgramRepository)
final programRepositoryProvider = ProgramRepositoryProvider._();

/// Single source of truth for stored programs.
///
/// Persists the full program list as one JSON array under
/// `creak.programs.v1`. Reads are synchronous (shared_preferences is an
/// in-memory cache); every mutation writes through.
final class ProgramRepositoryProvider
    extends $NotifierProvider<ProgramRepository, ProgramRepository> {
  /// Single source of truth for stored programs.
  ///
  /// Persists the full program list as one JSON array under
  /// `creak.programs.v1`. Reads are synchronous (shared_preferences is an
  /// in-memory cache); every mutation writes through.
  ProgramRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programRepositoryHash();

  @$internal
  @override
  ProgramRepository create() => ProgramRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgramRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgramRepository>(value),
    );
  }
}

String _$programRepositoryHash() => r'c54b2dafe26d63a5cca4d26f0090a3df2d5a8270';

/// Single source of truth for stored programs.
///
/// Persists the full program list as one JSON array under
/// `creak.programs.v1`. Reads are synchronous (shared_preferences is an
/// in-memory cache); every mutation writes through.

abstract class _$ProgramRepository extends $Notifier<ProgramRepository> {
  ProgramRepository build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProgramRepository, ProgramRepository>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgramRepository, ProgramRepository>,
              ProgramRepository,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Reactive list of the user's programs; the UI's entry point for program
/// state and mutations.

@ProviderFor(Programs)
final programsProvider = ProgramsProvider._();

/// Reactive list of the user's programs; the UI's entry point for program
/// state and mutations.
final class ProgramsProvider
    extends $NotifierProvider<Programs, List<ProgramModel>> {
  /// Reactive list of the user's programs; the UI's entry point for program
  /// state and mutations.
  ProgramsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programsHash();

  @$internal
  @override
  Programs create() => Programs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProgramModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ProgramModel>>(value),
    );
  }
}

String _$programsHash() => r'ded6a8b56438a00a2de43c08111cc6f733b7370c';

/// Reactive list of the user's programs; the UI's entry point for program
/// state and mutations.

abstract class _$Programs extends $Notifier<List<ProgramModel>> {
  List<ProgramModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ProgramModel>, List<ProgramModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ProgramModel>, List<ProgramModel>>,
              List<ProgramModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
