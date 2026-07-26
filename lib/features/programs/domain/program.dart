import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_template/utils/dates.dart';

part 'program.g.dart';

/// One exercise inside a program, with its prescription.
///
/// [id] is minted once and stays stable across program edits, because log
/// entries reference it; editing a program must reuse ids for retained
/// exercises.
@JsonSerializable()
class ProgramExercise {
  const ProgramExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    this.catalogExerciseId,
    this.description,
    this.referenceUrl,
  });

  /// Decodes from stored JSON.
  factory ProgramExercise.fromJson(Map<String, dynamic> json) =>
      _$ProgramExerciseFromJson(json);

  /// Stable identity referenced by exercise logs.
  final String id;

  /// Display name (catalog name or free text).
  final String name;

  /// Prescribed number of sets.
  final int sets;

  /// Prescribed repetitions per set.
  final int reps;

  /// Links to an `ExerciseModel` in the bundled catalog, when picked from
  /// it; null for free-text exercises.
  final String? catalogExerciseId;

  /// Optional how/why note.
  final String? description;

  /// Optional reference link, e.g. a YouTube video.
  final String? referenceUrl;

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$ProgramExerciseToJson(this);

  /// Copy with selective overrides; pass `clear*` to null a field out.
  ProgramExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    String? catalogExerciseId,
    String? description,
    String? referenceUrl,
  }) {
    return ProgramExercise(
      id: id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      catalogExerciseId: catalogExerciseId ?? this.catalogExerciseId,
      description: description ?? this.description,
      referenceUrl: referenceUrl ?? this.referenceUrl,
    );
  }
}

/// A physio program: a named set of prescribed exercises with a date range.
@JsonSerializable(explicitToJson: true)
class ProgramModel {
  const ProgramModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.createdAt,
    this.description,
    this.endDate,
    this.exercises = const [],
  });

  /// Decodes from stored JSON.
  factory ProgramModel.fromJson(Map<String, dynamic> json) =>
      _$ProgramModelFromJson(json);

  /// Stable identity referenced by schedules and logs.
  final String id;

  /// Display name, e.g. "Achilles rehab".
  final String name;

  /// First day the program is active (stored as `yyyy-MM-dd`).
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime startDate;

  /// Last active day inclusive, or null for open-ended.
  @JsonKey(fromJson: _nullableDateFromJson, toJson: _nullableDateToJson)
  final DateTime? endDate;

  /// Optional context: the complaint or an AI summary.
  final String? description;

  /// The prescribed exercises, in display order.
  final List<ProgramExercise> exercises;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$ProgramModelToJson(this);

  /// Whether the program is active on [date] (inclusive range).
  bool isActiveOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ))) {
      return false;
    }
    final end = endDate;
    return end == null || !day.isAfter(DateTime(end.year, end.month, end.day));
  }

  /// Copy with selective overrides.
  ProgramModel copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<ProgramExercise>? exercises,
  }) {
    return ProgramModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt,
    );
  }
}

DateTime _dateFromJson(String value) => parseYmd(value);
String _dateToJson(DateTime value) => ymd(value);
DateTime? _nullableDateFromJson(String? value) =>
    value == null ? null : parseYmd(value);
String? _nullableDateToJson(DateTime? value) =>
    value == null ? null : ymd(value);
