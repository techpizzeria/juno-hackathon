// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseLogModel _$ExerciseLogModelFromJson(Map<String, dynamic> json) =>
    ExerciseLogModel(
      exerciseId: json['exerciseId'] as String,
      status: $enumDecode(_$ExerciseLogStatusEnumMap, json['status']),
      repsPerSet: (json['repsPerSet'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      painNote: json['painNote'] as String?,
      videoPath: json['videoPath'] as String?,
    );

Map<String, dynamic> _$ExerciseLogModelToJson(ExerciseLogModel instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'status': _$ExerciseLogStatusEnumMap[instance.status]!,
      'repsPerSet': instance.repsPerSet,
      'painNote': instance.painNote,
      'videoPath': instance.videoPath,
    };

const _$ExerciseLogStatusEnumMap = {
  ExerciseLogStatus.done: 'done',
  ExerciseLogStatus.skipped: 'skipped',
};

LogEntryModel _$LogEntryModelFromJson(Map<String, dynamic> json) =>
    LogEntryModel(
      id: json['id'] as String,
      programId: json['programId'] as String,
      date: json['date'] as String,
      exerciseLogs:
          (json['exerciseLogs'] as List<dynamic>?)
              ?.map((e) => ExerciseLogModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$LogEntryModelToJson(LogEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'programId': instance.programId,
      'date': instance.date,
      'exerciseLogs': instance.exerciseLogs.map((e) => e.toJson()).toList(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'note': instance.note,
    };
