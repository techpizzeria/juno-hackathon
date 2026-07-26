import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';

void main() {
  test('bundled catalog parses and has unique, illustrated entries', () {
    final raw = File('assets/exercises.json').readAsStringSync();
    final list = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ExerciseModel.fromJson)
        .toList();

    expect(list.length, greaterThanOrEqualTo(60));
    expect(list.map((e) => e.id).toSet().length, list.length);
    for (final exercise in list) {
      expect(exercise.images, isNotEmpty, reason: exercise.id);
      expect(exercise.name, isNotEmpty);
      expect(
        exercise.imageUrl(0),
        startsWith('https://raw.githubusercontent.com/'),
      );
    }
  });
}
