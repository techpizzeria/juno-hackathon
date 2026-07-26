import 'package:json_annotation/json_annotation.dart';

part 'generated_program.g.dart';

/// Thrown when the LLM call fails or returns an unusable payload.
class LlmException implements Exception {
  const LlmException(this.message);

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'LlmException: $message';
}

/// The wire shape the LLM is forced to produce for a generated program.
///
/// Read-only: converted into a `ProgramModel` (with fresh ids and clamped
/// values) by the generated-program converter, never stored as-is.
@JsonSerializable(createToJson: false)
class GeneratedProgramModel {
  const GeneratedProgramModel({
    required this.name,
    required this.summary,
    required this.disclaimer,
    required this.durationWeeks,
    required this.exercises,
    required this.suggestedSchedule,
  });

  /// Decodes the LLM's JSON output.
  factory GeneratedProgramModel.fromJson(Map<String, dynamic> json) =>
      _$GeneratedProgramModelFromJson(json);

  /// Program display name.
  final String name;

  /// One-paragraph summary of the plan and its rationale.
  final String summary;

  /// See-a-professional note shown to the user.
  final String disclaimer;

  /// How many weeks the program should run, chosen to fit the condition.
  /// The converter clamps this and derives the program's end date from it.
  final int durationWeeks;

  /// The proposed exercises.
  final List<GeneratedExerciseModel> exercises;

  /// The proposed reminder pattern (pre-fills the schedule editor).
  final GeneratedScheduleModel suggestedSchedule;
}

/// One LLM-proposed exercise.
@JsonSerializable(createToJson: false)
class GeneratedExerciseModel {
  const GeneratedExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    this.catalogExerciseId,
    this.description,
  });

  /// Decodes from the LLM's JSON output.
  factory GeneratedExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$GeneratedExerciseModelFromJson(json);

  /// Exercise name.
  final String name;

  /// Proposed sets (clamped by the converter).
  final int sets;

  /// Proposed reps (clamped by the converter).
  final int reps;

  /// Exact catalog id when the LLM picked from the provided catalog.
  final String? catalogExerciseId;

  /// One-line how/why note.
  final String? description;
}

/// The LLM's proposed weekly reminder pattern.
@JsonSerializable(createToJson: false)
class GeneratedScheduleModel {
  const GeneratedScheduleModel({
    required this.weekdays,
    required this.hour,
    required this.minute,
  });

  /// Decodes from the LLM's JSON output.
  factory GeneratedScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$GeneratedScheduleModelFromJson(json);

  /// 1=Monday..7=Sunday.
  final List<int> weekdays;

  /// Hour of day, 0-23.
  final int hour;

  /// Minute, 0-59.
  final int minute;
}
