// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleSlot _$ScheduleSlotFromJson(Map<String, dynamic> json) => ScheduleSlot(
  id: json['id'] as String,
  weekday: (json['weekday'] as num).toInt(),
  hour: (json['hour'] as num).toInt(),
  minute: (json['minute'] as num).toInt(),
);

Map<String, dynamic> _$ScheduleSlotToJson(ScheduleSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weekday': instance.weekday,
      'hour': instance.hour,
      'minute': instance.minute,
    };

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    ScheduleModel(
      programId: json['programId'] as String,
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$ScheduleModelToJson(ScheduleModel instance) =>
    <String, dynamic>{
      'programId': instance.programId,
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'enabled': instance.enabled,
    };
