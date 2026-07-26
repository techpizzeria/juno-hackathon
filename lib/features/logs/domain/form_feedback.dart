import 'package:json_annotation/json_annotation.dart';

part 'form_feedback.g.dart';

/// Thrown when the form-check analysis fails or returns an unusable payload.
class FormCheckException implements Exception {
  const FormCheckException(this.message);

  /// Human-readable failure description shown to the user.
  final String message;

  @override
  String toString() => 'FormCheckException: $message';
}

/// AI feedback on a recorded form-check video.
///
/// Produced by the form-check service from one clip and stored on the
/// exercise log so it can be reopened later (in the session and in history).
/// [score] is a rough 1-10 self-check, not a medical assessment.
@JsonSerializable()
class FormFeedbackModel {
  const FormFeedbackModel({
    required this.score,
    required this.summary,
    required this.cues,
    required this.encouragement,
    required this.analyzedAt,
  });

  /// Decodes from stored JSON.
  factory FormFeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FormFeedbackModelFromJson(json);

  /// Rough overall form score, 1 (poor) to 10 (great).
  final int score;

  /// One-sentence overall read on the movement.
  final String summary;

  /// Specific, actionable things to improve next time.
  final List<String> cues;

  /// A short encouraging note.
  final String encouragement;

  /// When the analysis was produced.
  final DateTime analyzedAt;

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$FormFeedbackModelToJson(this);
}
