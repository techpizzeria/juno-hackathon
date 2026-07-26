// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedProgramModel _$GeneratedProgramModelFromJson(
  Map<String, dynamic> json,
) => GeneratedProgramModel(
  name: json['name'] as String,
  summary: json['summary'] as String,
  disclaimer: json['disclaimer'] as String,
  durationWeeks: (json['durationWeeks'] as num).toInt(),
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => GeneratedExerciseModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  suggestedSchedule: GeneratedScheduleModel.fromJson(
    json['suggestedSchedule'] as Map<String, dynamic>,
  ),
);

GeneratedExerciseModel _$GeneratedExerciseModelFromJson(
  Map<String, dynamic> json,
) => GeneratedExerciseModel(
  name: json['name'] as String,
  sets: (json['sets'] as num).toInt(),
  reps: (json['reps'] as num).toInt(),
  catalogExerciseId: json['catalogExerciseId'] as String?,
  description: json['description'] as String?,
);

GeneratedScheduleModel _$GeneratedScheduleModelFromJson(
  Map<String, dynamic> json,
) => GeneratedScheduleModel(
  weekdays: (json['weekdays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  hour: (json['hour'] as num).toInt(),
  minute: (json['minute'] as num).toInt(),
);
