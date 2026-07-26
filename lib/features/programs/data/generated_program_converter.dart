import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/programs/domain/generated_program.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/utils/ids.dart';

/// Converts an LLM-generated program into a storable [ProgramModel].
///
/// Pure: mints fresh ids, clamps prescriptions to sane ranges, defaults the
/// date range to six weeks from today, and resolves catalog links the model
/// may have fudged (exact id → normalized name → contains → free text).
ProgramModel convertGeneratedProgram(
  GeneratedProgramModel generated,
  List<ExerciseModel> catalog, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return ProgramModel(
    id: newId(),
    name: generated.name.trim().isEmpty ? 'My program' : generated.name.trim(),
    description: generated.summary,
    startDate: start,
    endDate: start.add(const Duration(days: 42)),
    createdAt: now,
    exercises: [
      for (final exercise in generated.exercises)
        ProgramExercise(
          id: newId(),
          name: exercise.name,
          sets: exercise.sets.clamp(1, 10),
          reps: exercise.reps.clamp(1, 50),
          catalogExerciseId: resolveCatalogId(exercise, catalog),
          description: exercise.description,
        ),
    ],
  );
}

/// Resolves the catalog entry the model meant, or null for free text.
String? resolveCatalogId(
  GeneratedExerciseModel exercise,
  List<ExerciseModel> catalog,
) {
  final claimed = exercise.catalogExerciseId;
  if (claimed != null && catalog.any((e) => e.id == claimed)) return claimed;

  // The claimed id was wrong or absent: try the id then the name.
  for (final candidate in [claimed, exercise.name]) {
    final wanted = _normalize(candidate ?? '');
    if (wanted.isEmpty) continue;
    for (final entry in catalog) {
      if (_normalize(entry.name) == wanted ||
          _normalize(entry.id) == wanted) {
        return entry.id;
      }
    }
    for (final entry in catalog) {
      if (_normalize(entry.name).contains(wanted)) return entry.id;
    }
  }
  return null;
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[_-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
