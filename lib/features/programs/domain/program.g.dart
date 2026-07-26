// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgramExercise _$ProgramExerciseFromJson(Map<String, dynamic> json) =>
    ProgramExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      catalogExerciseId: json['catalogExerciseId'] as String?,
      description: json['description'] as String?,
      referenceUrl: json['referenceUrl'] as String?,
    );

Map<String, dynamic> _$ProgramExerciseToJson(ProgramExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sets': instance.sets,
      'reps': instance.reps,
      'catalogExerciseId': instance.catalogExerciseId,
      'description': instance.description,
      'referenceUrl': instance.referenceUrl,
    };

ProgramModel _$ProgramModelFromJson(Map<String, dynamic> json) => ProgramModel(
  id: json['id'] as String,
  name: json['name'] as String,
  startDate: _dateFromJson(json['startDate'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  description: json['description'] as String?,
  endDate: _nullableDateFromJson(json['endDate'] as String?),
  exercises:
      (json['exercises'] as List<dynamic>?)
          ?.map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProgramModelToJson(ProgramModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'startDate': _dateToJson(instance.startDate),
      'endDate': _nullableDateToJson(instance.endDate),
      'description': instance.description,
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
