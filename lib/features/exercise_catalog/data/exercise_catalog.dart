import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';

part 'exercise_catalog.g.dart';

/// Single source of truth for the bundled exercise catalog.
@Riverpod(keepAlive: true)
class ExerciseCatalogRepository extends _$ExerciseCatalogRepository {
  @override
  ExerciseCatalogRepository build() => this;

  /// Loads and parses the bundled catalog off the main isolate.
  Future<List<ExerciseModel>> loadCatalog() async {
    final raw = await rootBundle.loadString('assets/exercises.json');
    return compute(_parseCatalog, raw);
  }
}

List<ExerciseModel> _parseCatalog(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return [
    for (final entry in list.cast<Map<String, dynamic>>())
      ExerciseModel.fromJson(entry),
  ];
}

/// The full curated exercise catalog, loaded once and kept for the app's
/// lifetime. Screens filter this list locally (search, muscle chips).
@Riverpod(keepAlive: true)
Future<List<ExerciseModel>> exerciseCatalog(Ref ref) =>
    ref.read(exerciseCatalogRepositoryProvider).loadCatalog();

/// The catalog indexed by exercise id, for resolving program links to
/// images and instructions.
@Riverpod(keepAlive: true)
Future<Map<String, ExerciseModel>> exerciseCatalogById(Ref ref) async {
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  return {for (final exercise in catalog) exercise.id: exercise};
}
