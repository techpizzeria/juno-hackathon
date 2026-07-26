import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/programs/domain/catalog_shortlist.dart';

ExerciseModel _exercise(
  String id, {
  List<String> primary = const [],
  List<String> secondary = const [],
}) =>
    ExerciseModel(
      id: id,
      name: id,
      level: 'beginner',
      category: 'strength',
      primaryMuscles: primary,
      secondaryMuscles: secondary,
    );

const _catalog = [
  ExerciseModel(
    id: 'squat',
    name: 'squat',
    level: 'beginner',
    category: 'strength',
    primaryMuscles: ['quadriceps'],
    secondaryMuscles: ['glutes'],
  ),
  ExerciseModel(
    id: 'ham_curl',
    name: 'ham_curl',
    level: 'beginner',
    category: 'strength',
    primaryMuscles: ['hamstrings'],
  ),
  ExerciseModel(
    id: 'calf_raise',
    name: 'calf_raise',
    level: 'beginner',
    category: 'strength',
    primaryMuscles: ['calves'],
  ),
  ExerciseModel(
    id: 'bench',
    name: 'bench',
    level: 'beginner',
    category: 'strength',
    primaryMuscles: ['chest'],
  ),
  ExerciseModel(
    id: 'curl',
    name: 'curl',
    level: 'beginner',
    category: 'strength',
    primaryMuscles: ['biceps'],
  ),
];

void main() {
  group('targetMusclesFor', () {
    test('maps body parts (including stems) to catalog muscles', () {
      expect(targetMusclesFor('my knee hurts'), contains('quadriceps'));
      expect(targetMusclesFor('my knee hurts'), contains('hamstrings'));
      expect(targetMusclesFor('sore lower back'), contains('lower back'));
    });

    test('is empty when nothing recognizable is mentioned', () {
      expect(targetMusclesFor('I just feel a bit off today'), isEmpty);
    });
  });

  group('shortlistForComplaint', () {
    test('keeps only exercises matching the complaint muscles', () {
      final result = shortlistForComplaint(
        'my knee has been aching',
        _catalog,
        minResults: 2,
      );
      final ids = [for (final e in result) e.id];
      expect(ids, containsAll(<String>['squat', 'ham_curl', 'calf_raise']));
      expect(ids, isNot(contains('bench')));
      expect(ids, isNot(contains('curl')));
    });

    test('returns the full catalog when no body part is recognized', () {
      final result = shortlistForComplaint('feeling low', _catalog);
      expect(result, hasLength(_catalog.length));
    });

    test('returns the full catalog when too few exercises match', () {
      // Knee matches 3 exercises; a min of 5 forces the safe fallback.
      final result = shortlistForComplaint(
        'knee pain',
        _catalog,
        minResults: 5,
      );
      expect(result, hasLength(_catalog.length));
    });

    test('caps the shortlist at the limit', () {
      final result = shortlistForComplaint(
        'knee pain',
        _catalog,
        limit: 2,
        minResults: 2,
      );
      expect(result, hasLength(2));
    });

    test('ranks primary-muscle matches above secondary-only matches', () {
      final catalog = [
        _exercise('secondary_only', secondary: ['quadriceps']),
        _exercise('primary_match', primary: ['quadriceps']),
      ];
      final result = shortlistForComplaint(
        'quad strain',
        catalog,
        minResults: 1,
      );
      expect(result.first.id, 'primary_match');
    });
  });
}
