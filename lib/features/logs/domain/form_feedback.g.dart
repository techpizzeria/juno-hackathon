// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormFeedbackModel _$FormFeedbackModelFromJson(Map<String, dynamic> json) =>
    FormFeedbackModel(
      score: (json['score'] as num).toInt(),
      summary: json['summary'] as String,
      cues: (json['cues'] as List<dynamic>).map((e) => e as String).toList(),
      encouragement: json['encouragement'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );

Map<String, dynamic> _$FormFeedbackModelToJson(FormFeedbackModel instance) =>
    <String, dynamic>{
      'score': instance.score,
      'summary': instance.summary,
      'cues': instance.cues,
      'encouragement': instance.encouragement,
      'analyzedAt': instance.analyzedAt.toIso8601String(),
    };
