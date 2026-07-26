/// Pure derivation logic for sessions, streaks, and the lazy
/// "skipped by midnight" rule.
///
/// Nothing here writes: a past scheduled day with no log simply *reads as*
/// missed at derivation time, so no background task is needed.
library;

import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/dates.dart';

/// How one program's scheduled session on one day turned out.
enum SessionOutcome {
  /// Every exercise logged done.
  completed,

  /// At least one exercise done, but not all.
  partial,

  /// The user explicitly skipped everything.
  skipped,

  /// The day passed with nothing logged (derived, never stored).
  missed,

  /// Still open today.
  pending,
}

/// Whether [program] has a reminder-scheduled session on [day].
bool isScheduledOn(
  ProgramModel program,
  ScheduleModel? schedule,
  DateTime day,
) {
  if (schedule == null) return false;
  return program.isActiveOn(day) && schedule.hasSlotOn(day.weekday);
}

/// Derives the outcome of [program]'s session on a day given its [entry]
/// (null when nothing was logged) and whether that day [isPast].
SessionOutcome sessionOutcome({
  required ProgramModel program,
  required LogEntryModel? entry,
  required bool isPast,
}) {
  if (entry == null || entry.exerciseLogs.isEmpty) {
    return isPast ? SessionOutcome.missed : SessionOutcome.pending;
  }
  final logged = {for (final log in entry.exerciseLogs) log.exerciseId};
  final allLogged =
      program.exercises.every((exercise) => logged.contains(exercise.id));
  final doneCount = entry.exerciseLogs
      .where((log) => log.status == ExerciseLogStatus.done)
      .length;
  if (doneCount == 0) {
    if (allLogged) return SessionOutcome.skipped;
    return isPast ? SessionOutcome.missed : SessionOutcome.pending;
  }
  if (allLogged && doneCount == entry.exerciseLogs.length) {
    // "Done" but with a set left at 0 reps is partial, not complete.
    final allFullyDone = entry.exerciseLogs.every((log) => log.isFullyDone);
    return allFullyDone ? SessionOutcome.completed : SessionOutcome.partial;
  }
  if (allLogged) return SessionOutcome.partial;
  return isPast ? SessionOutcome.partial : SessionOutcome.pending;
}

/// Whether the scheduled day [day] keeps a streak alive: every program
/// scheduled that day has at least one exercise done (showing up counts).
bool daySatisfied({
  required List<ProgramModel> programs,
  required List<ScheduleModel> schedules,
  required List<LogEntryModel> logs,
  required DateTime day,
}) {
  final key = ymd(day);
  final scheduled = _scheduledPrograms(programs, schedules, day);
  if (scheduled.isEmpty) return false;
  return scheduled.every((program) {
    final entry = logs
        .where((log) => log.programId == program.id && log.date == key)
        .firstOrNull;
    return entry?.hasAnyDone ?? false;
  });
}

/// Current streak in days, walking back from [today].
///
/// Unscheduled days are neutral. Today extends the streak once satisfied
/// but never breaks it while still pending. The first unsatisfied scheduled
/// past day breaks the walk. Capped at 365 days back.
int currentStreak({
  required List<ProgramModel> programs,
  required List<ScheduleModel> schedules,
  required List<LogEntryModel> logs,
  required DateTime today,
}) {
  var streak = 0;
  for (var back = 0; back <= 365; back++) {
    final day = DateTime(today.year, today.month, today.day - back);
    final scheduled = _scheduledPrograms(programs, schedules, day);
    if (scheduled.isEmpty) continue;
    final satisfied = daySatisfied(
      programs: programs,
      schedules: schedules,
      logs: logs,
      day: day,
    );
    if (satisfied) {
      streak++;
    } else if (back == 0) {
      continue; // Today still pending: neutral.
    } else {
      break;
    }
  }
  return streak;
}

List<ProgramModel> _scheduledPrograms(
  List<ProgramModel> programs,
  List<ScheduleModel> schedules,
  DateTime day,
) {
  return [
    for (final program in programs)
      if (isScheduledOn(
        program,
        schedules.where((s) => s.programId == program.id).firstOrNull,
        day,
      ))
        program,
  ];
}
