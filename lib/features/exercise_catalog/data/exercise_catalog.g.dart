// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_catalog.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for the bundled exercise catalog.

@ProviderFor(ExerciseCatalogRepository)
final exerciseCatalogRepositoryProvider = ExerciseCatalogRepositoryProvider._();

/// Single source of truth for the bundled exercise catalog.
final class ExerciseCatalogRepositoryProvider
    extends
        $NotifierProvider<
          ExerciseCatalogRepository,
          ExerciseCatalogRepository
        > {
  /// Single source of truth for the bundled exercise catalog.
  ExerciseCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseCatalogRepositoryHash();

  @$internal
  @override
  ExerciseCatalogRepository create() => ExerciseCatalogRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseCatalogRepository>(value),
    );
  }
}

String _$exerciseCatalogRepositoryHash() =>
    r'4a9515fcd1bd6897765fad7fd5f6ed2577f16b8a';

/// Single source of truth for the bundled exercise catalog.

abstract class _$ExerciseCatalogRepository
    extends $Notifier<ExerciseCatalogRepository> {
  ExerciseCatalogRepository build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ExerciseCatalogRepository, ExerciseCatalogRepository>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExerciseCatalogRepository, ExerciseCatalogRepository>,
              ExerciseCatalogRepository,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The full curated exercise catalog, loaded once and kept for the app's
/// lifetime. Screens filter this list locally (search, muscle chips).

@ProviderFor(exerciseCatalog)
final exerciseCatalogProvider = ExerciseCatalogProvider._();

/// The full curated exercise catalog, loaded once and kept for the app's
/// lifetime. Screens filter this list locally (search, muscle chips).

final class ExerciseCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExerciseModel>>,
          List<ExerciseModel>,
          FutureOr<List<ExerciseModel>>
        >
    with
        $FutureModifier<List<ExerciseModel>>,
        $FutureProvider<List<ExerciseModel>> {
  /// The full curated exercise catalog, loaded once and kept for the app's
  /// lifetime. Screens filter this list locally (search, muscle chips).
  ExerciseCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseCatalogHash();

  @$internal
  @override
  $FutureProviderElement<List<ExerciseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ExerciseModel>> create(Ref ref) {
    return exerciseCatalog(ref);
  }
}

String _$exerciseCatalogHash() => r'39cab1e394ea706a6b61342bf357a3c0e1c1425b';

/// The catalog indexed by exercise id, for resolving program links to
/// images and instructions.

@ProviderFor(exerciseCatalogById)
final exerciseCatalogByIdProvider = ExerciseCatalogByIdProvider._();

/// The catalog indexed by exercise id, for resolving program links to
/// images and instructions.

final class ExerciseCatalogByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ExerciseModel>>,
          Map<String, ExerciseModel>,
          FutureOr<Map<String, ExerciseModel>>
        >
    with
        $FutureModifier<Map<String, ExerciseModel>>,
        $FutureProvider<Map<String, ExerciseModel>> {
  /// The catalog indexed by exercise id, for resolving program links to
  /// images and instructions.
  ExerciseCatalogByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseCatalogByIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseCatalogByIdHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, ExerciseModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, ExerciseModel>> create(Ref ref) {
    return exerciseCatalogById(ref);
  }
}

String _$exerciseCatalogByIdHash() =>
    r'34c8807dc41385815cbbf2742063cda8e5cdd81d';
