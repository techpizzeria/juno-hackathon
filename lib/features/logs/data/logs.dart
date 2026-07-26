import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/utils/dates.dart';
import 'package:flutter_template/utils/ids.dart';
import 'package:flutter_template/utils/local_storage.dart';

part 'logs.g.dart';

/// Single source of truth for stored session logs.
///
/// Persists all log entries as one JSON array under `creak.logs.v1`.
@Riverpod(keepAlive: true)
class LogRepository extends _$LogRepository {
  static const _storageKey = 'creak.logs.v1';

  @override
  LogRepository build() => this;

  SharedPreferences get _prefs => ref.read(localStorageProvider);

  /// Loads every stored log entry, empty when none saved yet.
  List<LogEntryModel> loadAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in list.cast<Map<String, dynamic>>())
        LogEntryModel.fromJson(entry),
    ];
  }

  /// Replaces the stored log list.
  Future<void> saveAll(List<LogEntryModel> logs) async {
    await _prefs.setString(
      _storageKey,
      jsonEncode([for (final log in logs) log.toJson()]),
    );
  }
}

/// Reactive session logs; the UI's entry point for logging mutations.
@Riverpod(keepAlive: true)
class Logs extends _$Logs {
  @override
  List<LogEntryModel> build() => ref.read(logRepositoryProvider).loadAll();

  /// Returns today's entry for [programId], creating an empty pending one
  /// on first access.
  Future<LogEntryModel> ensureToday(String programId) async {
    final date = todayYmd();
    final existing = state
        .where((log) => log.programId == programId && log.date == date)
        .firstOrNull;
    if (existing != null) return existing;
    final entry = LogEntryModel(
      id: newId(),
      programId: programId,
      date: date,
    );
    state = [...state, entry];
    await ref.read(logRepositoryProvider).saveAll(state);
    return entry;
  }

  /// Adds or replaces one exercise's record on entry [entryId].
  ///
  /// Returns one [ExerciseCompletionEvent] only when this mutation transitions
  /// the exercise from incomplete to fully done. Skips, partial attempts, and
  /// edits to an already-complete exercise return null.
  Future<ExerciseCompletionEvent?> logExercise(
    String entryId,
    ExerciseLogModel log,
  ) async {
    final entry = state.where((item) => item.id == entryId).firstOrNull;
    if (entry == null) return null;
    final previous = entry.logFor(log.exerciseId);
    await _update(entryId, (entry) => entry.withExerciseLog(log));
    if (!isNewExerciseCompletion(previous: previous, current: log)) {
      return null;
    }
    return ExerciseCompletionEvent(
      id: newId(),
      entryId: entryId,
      exerciseId: log.exerciseId,
      completedAt: DateTime.now(),
    );
  }

  /// Marks every exercise in [exerciseIds] done and closes the session.
  Future<void> completeAll(String entryId, List<String> exerciseIds) async {
    await _update(entryId, (entry) {
      var updated = entry;
      for (final exerciseId in exerciseIds) {
        final existing = entry.logFor(exerciseId);
        if (existing == null || existing.status != ExerciseLogStatus.done) {
          updated = updated.withExerciseLog(
            ExerciseLogModel(
              exerciseId: exerciseId,
              status: ExerciseLogStatus.done,
            ),
          );
        }
      }
      return updated.copyWith(completedAt: DateTime.now());
    });
  }

  /// Stamps the session closed without changing any exercise status; used
  /// when every exercise has already been logged individually.
  Future<void> markSessionComplete(String entryId) async {
    await _update(
      entryId,
      (entry) => entry.copyWith(completedAt: DateTime.now()),
    );
  }

  /// Marks every not-yet-logged exercise in [exerciseIds] skipped.
  Future<void> skipAll(String entryId, List<String> exerciseIds) async {
    await _update(entryId, (entry) {
      var updated = entry;
      for (final exerciseId in exerciseIds) {
        if (entry.logFor(exerciseId) == null) {
          updated = updated.withExerciseLog(
            ExerciseLogModel(
              exerciseId: exerciseId,
              status: ExerciseLogStatus.skipped,
            ),
          );
        }
      }
      return updated;
    });
  }

  /// Removes every log entry (demo data reset).
  Future<void> clearAll() async {
    state = const [];
    await ref.read(logRepositoryProvider).saveAll(state);
  }

  Future<void> _update(
    String entryId,
    LogEntryModel Function(LogEntryModel entry) transform,
  ) async {
    final previous = state;
    state = [
      for (final entry in state)
        if (entry.id == entryId) transform(entry) else entry,
    ];
    try {
      await ref.read(logRepositoryProvider).saveAll(state);
    } on Object {
      state = previous;
      rethrow;
    }
  }
}
