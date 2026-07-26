import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/programs/data/generated_program_converter.dart';
import 'package:flutter_template/features/programs/domain/generated_program.dart';

const _catalog = [
  ExerciseModel(
    id: 'Calf_Raise_On_A_Dumbbell',
    name: 'Calf Raise On A Dumbbell',
    level: 'beginner',
    category: 'strength',
  ),
  ExerciseModel(
    id: '90_90_Hamstring',
    name: '90/90 Hamstring',
    level: 'beginner',
    category: 'stretching',
  ),
];

/// A canned LLM response, as both providers would return it.
const _cannedResponse = '''
{
  "name": "Achilles comeback plan",
  "summary": "Gentle loading for the achilles tendon.",
  "disclaimer": "See a physio if pain persists.",
  "exercises": [
    {"name": "Calf Raise On A Dumbbell", "catalogExerciseId": "Calf_Raise_On_A_Dumbbell", "sets": 3, "reps": 12, "description": null},
    {"name": "calf raise on a dumbbell", "catalogExerciseId": "Calf_Raise_Dumbbell_WRONG", "sets": 30, "reps": 100, "description": "slow tempo"},
    {"name": "Towel scrunches", "catalogExerciseId": null, "sets": 2, "reps": 15, "description": "grab a towel with your toes"}
  ],
  "suggestedSchedule": {"weekdays": [1, 3, 5], "hour": 18, "minute": 0}
}
''';

void main() {
  test('canned response parses and converts with clamping and matching', () {
    final generated = GeneratedProgramModel.fromJson(
      jsonDecode(_cannedResponse) as Map<String, dynamic>,
    );
    final program = convertGeneratedProgram(
      generated,
      _catalog,
      today: DateTime(2026, 7, 25),
    );

    expect(program.name, 'Achilles comeback plan');
    expect(program.startDate, DateTime(2026, 7, 25));
    expect(program.endDate, DateTime(2026, 9, 5));
    expect(program.exercises, hasLength(3));

    // Exact catalog id kept.
    expect(
      program.exercises[0].catalogExerciseId,
      'Calf_Raise_On_A_Dumbbell',
    );
    // Wrong id resolved via normalized name; out-of-range values clamped.
    expect(
      program.exercises[1].catalogExerciseId,
      'Calf_Raise_On_A_Dumbbell',
    );
    expect(program.exercises[1].sets, 10);
    expect(program.exercises[1].reps, 50);
    // Free text stays unlinked.
    expect(program.exercises[2].catalogExerciseId, isNull);
    // Fresh unique ids are minted.
    expect(
      program.exercises.map((e) => e.id).toSet(),
      hasLength(3),
    );
  });

  test('resolveCatalogId falls back to contains matching', () {
    const exercise = GeneratedExerciseModel(
      name: '90/90 hamstring stretch hold',
      sets: 2,
      reps: 5,
    );
    // "90/90 hamstring stretch hold" is not an exact match, but the catalog
    // name "90/90 Hamstring" is contained in it after normalization? No —
    // containment is checked the other way, so this stays free text.
    expect(resolveCatalogId(exercise, _catalog), isNull);

    const partial = GeneratedExerciseModel(
      name: 'Calf Raise',
      sets: 2,
      reps: 5,
    );
    expect(resolveCatalogId(partial, _catalog), 'Calf_Raise_On_A_Dumbbell');
  });
}
