import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_template/features/logs/domain/form_feedback.dart';

part 'log_entry.g.dart';

/// A one-shot domain event emitted when an exercise transitions to fully done.
///
/// The event is created only after the updated log has persisted successfully.
/// Its identity lets presentation retain one selected celebration across
/// rebuilds for the event's entire lifetime.
class ExerciseCompletionEvent {
  const ExerciseCompletionEvent({
    required this.id,
    required this.entryId,
    required this.exerciseId,
    required this.completedAt,
  });

  /// Unique event identity.
  final String id;

  /// Session log entry that owns the completed exercise.
  final String entryId;

  /// Exercise that transitioned to fully done.
  final String exerciseId;

  /// Time the successful persistence completed.
  final DateTime completedAt;
}

/// Whether [current] is a new, successful exercise completion.
///
/// Null input represents a cancelled action. Skipped and zero-rep attempts
/// remain non-completions, while editing an already-complete exercise does not
/// emit a duplicate event.
bool isNewExerciseCompletion({
  required ExerciseLogModel? previous,
  required ExerciseLogModel? current,
}) {
  return (current?.isFullyDone ?? false) && !(previous?.isFullyDone ?? false);
}

/// What happened to one exercise within a day's session.
enum ExerciseLogStatus {
  /// The user performed the exercise (possibly amended).
  done,

  /// The user explicitly skipped it.
  skipped,
}

/// The user's record for one exercise on one day.
///
/// [repsPerSet] captures what was actually managed, one entry per set
/// performed (e.g. `[10, 10, 7]` against a 3×10 prescription). Null when the
/// exercise was skipped or logged without detail. Pending exercises have no
/// log at all.
@JsonSerializable(explicitToJson: true)
class ExerciseLogModel {
  const ExerciseLogModel({
    required this.exerciseId,
    required this.status,
    this.repsPerSet,
    this.painNote,
    this.videoPath,
    this.feedback,
  });

  /// Decodes from stored JSON.
  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseLogModelFromJson(json);

  /// The `ProgramExercise.id` this log refers to.
  final String exerciseId;

  /// Done or skipped.
  final ExerciseLogStatus status;

  /// Reps achieved in each set, e.g. `[10, 10, 7]`; its length is the number
  /// of sets actually performed. Null when there's no per-set detail.
  final List<int>? repsPerSet;

  /// Optional comment/pain note for the physio.
  final String? painNote;

  /// Absolute path to a self-recorded form-check video, when one was taken.
  final String? videoPath;

  /// AI feedback on [videoPath], when the user ran a form check.
  final FormFeedbackModel? feedback;

  /// Whether this exercise was fully completed: marked done with no set left
  /// at 0 reps. A done log with a 0-rep set counts as partial, not complete.
  bool get isFullyDone =>
      status == ExerciseLogStatus.done &&
      (repsPerSet == null || repsPerSet!.every((reps) => reps > 0));

  /// Whether the user attached a comment or video worth flagging in history.
  bool get hasMetadata =>
      (painNote != null && painNote!.isNotEmpty) ||
      (videoPath != null && videoPath!.isNotEmpty);

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$ExerciseLogModelToJson(this);

  /// Copy with selective overrides. Pass [clearFeedback] to drop feedback
  /// (e.g. after the video is retaken).
  ExerciseLogModel copyWith({
    ExerciseLogStatus? status,
    List<int>? repsPerSet,
    String? painNote,
    String? videoPath,
    FormFeedbackModel? feedback,
    bool clearFeedback = false,
  }) {
    return ExerciseLogModel(
      exerciseId: exerciseId,
      status: status ?? this.status,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      painNote: painNote ?? this.painNote,
      videoPath: videoPath ?? this.videoPath,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
    );
  }
}

/// One program's log for one local calendar day.
///
/// [date] is a `yyyy-MM-dd` string; comparing these strings sidesteps
/// timezone/midnight-boundary bugs. Exercises without an entry in
/// [exerciseLogs] are still pending.
@JsonSerializable(explicitToJson: true)
class LogEntryModel {
  const LogEntryModel({
    required this.id,
    required this.programId,
    required this.date,
    this.exerciseLogs = const [],
    this.completedAt,
    this.note,
  });

  /// Decodes from stored JSON.
  factory LogEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LogEntryModelFromJson(json);

  /// Entry identity.
  final String id;

  /// The program this session belongs to.
  final String programId;

  /// Local calendar day, `yyyy-MM-dd`.
  final String date;

  /// Per-exercise records, at most one per exercise id.
  final List<ExerciseLogModel> exerciseLogs;

  /// When the user closed out the whole session, if they did.
  final DateTime? completedAt;

  /// Optional session-level note.
  final String? note;

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$LogEntryModelToJson(this);

  /// The record for [exerciseId], if any.
  ExerciseLogModel? logFor(String exerciseId) =>
      exerciseLogs.where((log) => log.exerciseId == exerciseId).firstOrNull;

  /// Whether at least one exercise was done (partial credit counts).
  bool get hasAnyDone =>
      exerciseLogs.any((log) => log.status == ExerciseLogStatus.done);

  /// Copy with the record for `log.exerciseId` added or replaced.
  LogEntryModel withExerciseLog(ExerciseLogModel log) {
    final replaced = exerciseLogs.any((e) => e.exerciseId == log.exerciseId);
    return copyWith(
      exerciseLogs: [
        for (final e in exerciseLogs)
          if (e.exerciseId == log.exerciseId) log else e,
        if (!replaced) log,
      ],
    );
  }

  /// Copy with selective overrides.
  LogEntryModel copyWith({
    List<ExerciseLogModel>? exerciseLogs,
    DateTime? completedAt,
    String? note,
  }) {
    return LogEntryModel(
      id: id,
      programId: programId,
      date: date,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }
}
