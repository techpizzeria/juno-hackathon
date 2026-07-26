import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/features/logs/data/logs.dart';
import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/features/logs/domain/streak.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/dates.dart';

part 'today.g.dart';

/// One program's session as seen from the dashboard/history: the program,
/// its reminder slots that day, the log entry (if any), and the derived
/// outcome.
class SessionView {
  const SessionView({
    required this.program,
    required this.slots,
    required this.entry,
    required this.outcome,
  });

  /// The program the session belongs to.
  final ProgramModel program;

  /// That day's reminder slots, earliest first.
  final List<ScheduleSlot> slots;

  /// The log entry, when one exists.
  final LogEntryModel? entry;

  /// Derived outcome (pending while the day is still open).
  final SessionOutcome outcome;
}

/// One past or present day in the history view.
class HistoryDay {
  const HistoryDay({required this.date, required this.sessions});

  /// The local calendar day.
  final DateTime date;

  /// That day's scheduled sessions with outcomes.
  final List<SessionView> sessions;
}

List<SessionView> _sessionsOn(
  DateTime day, {
  required List<ProgramModel> programs,
  required List<ScheduleModel> schedules,
  required List<LogEntryModel> logs,
  required bool isPast,
  bool includeUnscheduledActive = false,
}) {
  final key = ymd(day);
  final views = <SessionView>[];
  for (final program in programs) {
    final schedule =
        schedules.where((s) => s.programId == program.id).firstOrNull;
    // A program is trainable on any day it is active; reminders only decide
    // whether a notification fires and whether the day counts toward the
    // streak. So today includes active programs even without a schedule,
    // while history stays limited to genuinely scheduled days.
    final include = includeUnscheduledActive
        ? program.isActiveOn(day)
        : isScheduledOn(program, schedule, day);
    if (!include) continue;
    final slots = (schedule?.slots ?? const <ScheduleSlot>[])
        .where((slot) => slot.weekday == day.weekday)
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    final entry = logs
        .where((log) => log.programId == program.id && log.date == key)
        .firstOrNull;
    views.add(
      SessionView(
        program: program,
        slots: slots,
        entry: entry,
        outcome:
            sessionOutcome(program: program, entry: entry, isPast: isPast),
      ),
    );
  }
  return views;
}

/// Today's trainable sessions (every program active today, reminders or
/// not), pending first.
@Riverpod(keepAlive: true)
List<SessionView> todaysSessions(Ref ref) {
  final sessions = _sessionsOn(
    DateTime.now(),
    programs: ref.watch(programsProvider),
    schedules: ref.watch(schedulesProvider),
    logs: ref.watch(logsProvider),
    isPast: false,
    includeUnscheduledActive: true,
  )..sort((a, b) {
      int rank(SessionOutcome o) => o == SessionOutcome.pending ? 0 : 1;
      return rank(a.outcome) - rank(b.outcome);
    });
  return sessions;
}

/// Current streak in days.
@Riverpod(keepAlive: true)
int streak(Ref ref) {
  return currentStreak(
    programs: ref.watch(programsProvider),
    schedules: ref.watch(schedulesProvider),
    logs: ref.watch(logsProvider),
    today: DateTime.now(),
  );
}

/// 1–7 weekday numbers of this week (Mon–Sun) whose scheduled sessions
/// were all satisfied, for the dashboard's week dots.
@Riverpod(keepAlive: true)
Set<int> weekDoneDays(Ref ref) {
  final programs = ref.watch(programsProvider);
  final schedules = ref.watch(schedulesProvider);
  final logs = ref.watch(logsProvider);
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final done = <int>{};
  for (var offset = 0; offset < 7; offset++) {
    final day = DateTime(monday.year, monday.month, monday.day + offset);
    if (day.isAfter(now)) break;
    if (daySatisfied(
      programs: programs,
      schedules: schedules,
      logs: logs,
      day: day,
    )) {
      done.add(day.weekday);
    }
  }
  return done;
}

/// One dated session under a program in the grouped history view.
class ProgramHistoryEntry {
  const ProgramHistoryEntry({required this.date, required this.session});

  /// The local calendar day of the session.
  final DateTime date;

  /// That day's session for the program, with its outcome and logs.
  final SessionView session;
}

/// A program with its past sessions, newest first.
class ProgramHistory {
  const ProgramHistory({required this.program, required this.entries});

  /// The program these entries belong to.
  final ProgramModel program;

  /// Its dated sessions, newest first.
  final List<ProgramHistoryEntry> entries;
}

/// History grouped by program (each program's sessions, newest first), for
/// the expandable history view. Programs with no history are omitted.
@Riverpod(keepAlive: true)
List<ProgramHistory> historyByProgram(Ref ref) {
  final days = ref.watch(historyProvider);
  final byProgram = <String, List<ProgramHistoryEntry>>{};
  final programs = <String, ProgramModel>{};
  for (final day in days) {
    for (final session in day.sessions) {
      programs[session.program.id] = session.program;
      byProgram
          .putIfAbsent(session.program.id, () => [])
          .add(ProgramHistoryEntry(date: day.date, session: session));
    }
  }
  return [
    for (final entry in byProgram.entries)
      ProgramHistory(program: programs[entry.key]!, entries: entry.value),
  ];
}

/// Past scheduled days (newest first, up to 60 days back), for history.
@Riverpod(keepAlive: true)
List<HistoryDay> history(Ref ref) {
  final programs = ref.watch(programsProvider);
  final schedules = ref.watch(schedulesProvider);
  final logs = ref.watch(logsProvider);
  final now = DateTime.now();
  final days = <HistoryDay>[];
  for (var back = 0; back <= 60; back++) {
    final day = DateTime(now.year, now.month, now.day - back);
    final sessions = _sessionsOn(
      day,
      programs: programs,
      schedules: schedules,
      logs: logs,
      isPast: back > 0,
    );
    if (sessions.isNotEmpty) {
      days.add(HistoryDay(date: day, sessions: sessions));
    }
  }
  return days;
}
