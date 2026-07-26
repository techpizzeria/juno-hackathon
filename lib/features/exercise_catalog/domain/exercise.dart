import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

/// One exercise from the bundled free-exercise-db catalog.
///
/// Read-only reference data: parsed from `assets/exercises.json`, never
/// written back. [primaryMuscles] tells the user which muscles should be
/// working; [images] holds two photo frames (start/end position) that the
/// UI crossfades to suggest motion.
@JsonSerializable(createToJson: false)
class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.level,
    required this.category,
    this.force,
    this.mechanic,
    this.equipment,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.images = const [],
  });

  /// Decodes a catalog entry from the bundled JSON.
  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  /// Stable dataset id, e.g. `Calf_Raise_On_A_Dumbbell`.
  final String id;

  /// Display name.
  final String name;

  /// Difficulty: `beginner` or `intermediate` in the curated set.
  final String level;

  /// Dataset category: stretching, strength, or plyometrics.
  final String category;

  /// Push/pull/static, when known.
  final String? force;

  /// Compound or isolation, when known.
  final String? mechanic;

  /// Required equipment, null meaning none.
  final String? equipment;

  /// Muscles that should be doing the work.
  final List<String> primaryMuscles;

  /// Supporting muscles.
  final List<String> secondaryMuscles;

  /// Step-by-step how-to text.
  final List<String> instructions;

  /// Relative image paths (`<id>/0.jpg`, `<id>/1.jpg`).
  final List<String> images;

  /// Absolute URL of photo [frame] (0 = start, 1 = end position).
  String imageUrl(int frame) =>
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/'
      'exercises/${images[frame]}';
}
