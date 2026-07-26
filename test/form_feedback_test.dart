import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/features/logs/domain/form_feedback.dart';
import 'package:flutter_template/features/logs/domain/log_entry.dart';

void main() {
  final feedback = FormFeedbackModel(
    score: 8,
    summary: 'Solid squat depth, watch the knees.',
    cues: const ['Keep knees over toes', 'Slow the descent'],
    encouragement: 'Great control overall!',
    analyzedAt: DateTime(2026, 7, 26, 9, 30),
  );

  test('FormFeedbackModel round-trips through JSON', () {
    final restored = FormFeedbackModel.fromJson(feedback.toJson());
    expect(restored.score, feedback.score);
    expect(restored.summary, feedback.summary);
    expect(restored.cues, feedback.cues);
    expect(restored.encouragement, feedback.encouragement);
    expect(restored.analyzedAt, feedback.analyzedAt);
  });

  test('feedback nested in an ExerciseLogModel persists', () {
    final log = ExerciseLogModel(
      exerciseId: 'ex1',
      status: ExerciseLogStatus.done,
      repsPerSet: const [10, 10, 8],
      videoPath: '/tmp/clip.mp4',
      feedback: feedback,
    );

    final restored = ExerciseLogModel.fromJson(log.toJson());

    expect(restored.feedback, isNotNull);
    expect(restored.feedback!.score, 8);
    expect(restored.feedback!.cues, hasLength(2));
    expect(restored.videoPath, '/tmp/clip.mp4');
  });

  test('copyWith clearFeedback drops the feedback', () {
    final log = ExerciseLogModel(
      exerciseId: 'ex1',
      status: ExerciseLogStatus.done,
      feedback: feedback,
    );
    expect(log.copyWith(clearFeedback: true).feedback, isNull);
    // A plain copy keeps it.
    expect(log.copyWith(painNote: 'ouch').feedback, isNotNull);
  });
}
