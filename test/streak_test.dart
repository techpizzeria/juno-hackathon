import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/features/logs/domain/streak.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/dates.dart';

// Fixed reference day: Friday 2026-07-24.
final _today = DateTime(2026, 7, 24);

ProgramModel _program({DateTime? start}) {
  return ProgramModel(
    id: 'p1',
    name: 'Rehab',
    startDate: start ?? DateTime(2026),
    createdAt: DateTime(2026),
    exercises: const [
      ProgramExercise(id: 'e1', name: 'Calf raise', sets: 3, reps: 10),
      ProgramExercise(id: 'e2', name: 'Bridge', sets: 3, reps: 12),
    ],
  );
}

/// Schedule on every weekday in [weekdays].
ScheduleModel _schedule(Set<int> weekdays, {bool enabled = true}) {
  return ScheduleModel(
    programId: 'p1',
    enabled: enabled,
    slots: [
      for (final day in weekdays)
        ScheduleSlot(id: 's$day', weekday: day, hour: 7, minute: 0),
    ],
  );
}

LogEntryModel _log(
  DateTime day, {
  List<ExerciseLogModel> logs = const [],
}) {
  return LogEntryModel(
    id: 'l${ymd(day)}',
    programId: 'p1',
    date: ymd(day),
    exerciseLogs: logs,
  );
}

const _done1 = ExerciseLogModel(
  exerciseId: 'e1',
  status: ExerciseLogStatus.done,
);
const _done2 = ExerciseLogModel(
  exerciseId: 'e2',
  status: ExerciseLogStatus.done,
);
const _skip1 = ExerciseLogModel(
  exerciseId: 'e1',
  status: ExerciseLogStatus.skipped,
);
const _skip2 = ExerciseLogModel(
  exerciseId: 'e2',
  status: ExerciseLogStatus.skipped,
);

int _streak(List<LogEntryModel> logs, {Set<int>? weekdays}) {
  return currentStreak(
    programs: [_program()],
    schedules: [_schedule(weekdays ?? {1, 2, 3, 4, 5, 6, 7})],
    logs: logs,
    today: _today,
  );
}

DateTime _daysAgo(int n) =>
    DateTime(_today.year, _today.month, _today.day - n);

void main() {
  group('currentStreak', () {
    test('empty history is zero', () {
      expect(_streak([]), 0);
    });

    test('today pending is neutral, past days count', () {
      final logs = [
        _log(_daysAgo(1), logs: [_done1, _done2]),
        _log(_daysAgo(2), logs: [_done1]),
      ];
      expect(_streak(logs), 2);
    });

    test('today completed extends the streak', () {
      final logs = [
        _log(_daysAgo(0), logs: [_done1, _done2]),
        _log(_daysAgo(1), logs: [_done1, _done2]),
      ];
      expect(_streak(logs), 2);
    });

    test('partial credit keeps the streak (one done, one skipped)', () {
      final logs = [
        _log(_daysAgo(1), logs: [_done1, _skip2]),
      ];
      expect(_streak(logs), 1);
    });

    test('a fully skipped past day breaks the streak', () {
      final logs = [
        _log(_daysAgo(1), logs: [_done1, _done2]),
        _log(_daysAgo(2), logs: [_skip1, _skip2]),
        _log(_daysAgo(3), logs: [_done1, _done2]),
      ];
      expect(_streak(logs), 1);
    });

    test('an unlogged past scheduled day breaks the streak (lazy skip)', () {
      final logs = [
        _log(_daysAgo(1), logs: [_done1]),
        // _daysAgo(2): scheduled, no entry at all.
        _log(_daysAgo(3), logs: [_done1]),
      ];
      expect(_streak(logs), 1);
    });

    test('unscheduled days are neutral', () {
      // Friday today; scheduled Mon(1)/Wed(3)/Fri(5) only.
      final logs = [
        _log(_daysAgo(2), logs: [_done1]), // Wed
        _log(_daysAgo(4), logs: [_done1]), // Mon
      ];
      expect(_streak(logs, weekdays: {1, 3, 5}), 2);
    });

    test('disabled schedule means nothing is scheduled', () {
      final streak = currentStreak(
        programs: [_program()],
        schedules: [_schedule({1, 2, 3, 4, 5, 6, 7}, enabled: false)],
        logs: [
          _log(_daysAgo(1), logs: [_done1]),
        ],
        today: _today,
      );
      expect(streak, 0);
    });

    test('days before the program start are neutral', () {
      final streak = currentStreak(
        programs: [_program(start: _daysAgo(1))],
        schedules: [
          _schedule({1, 2, 3, 4, 5, 6, 7}),
        ],
        logs: [
          _log(_daysAgo(1), logs: [_done1]),
        ],
        today: _today,
      );
      expect(streak, 1);
    });
  });

  group('sessionOutcome', () {
    final program = _program();

    test('no entry: pending today, missed in the past', () {
      expect(
        sessionOutcome(program: program, entry: null, isPast: false),
        SessionOutcome.pending,
      );
      expect(
        sessionOutcome(program: program, entry: null, isPast: true),
        SessionOutcome.missed,
      );
    });

    test('all done is completed', () {
      final entry = _log(_today, logs: [_done1, _done2]);
      expect(
        sessionOutcome(program: program, entry: entry, isPast: false),
        SessionOutcome.completed,
      );
    });

    test('mixed done/skipped is partial', () {
      final entry = _log(_today, logs: [_done1, _skip2]);
      expect(
        sessionOutcome(program: program, entry: entry, isPast: true),
        SessionOutcome.partial,
      );
    });

    test('all skipped is skipped', () {
      final entry = _log(_today, logs: [_skip1, _skip2]);
      expect(
        sessionOutcome(program: program, entry: entry, isPast: true),
        SessionOutcome.skipped,
      );
    });

    test('done with a 0-rep set is partial, not completed', () {
      final entry = _log(
        _today,
        logs: const [
          ExerciseLogModel(
            exerciseId: 'e1',
            status: ExerciseLogStatus.done,
            repsPerSet: [10, 10, 0],
          ),
          _done2,
        ],
      );
      expect(
        sessionOutcome(program: program, entry: entry, isPast: true),
        SessionOutcome.partial,
      );
    });
  });
}
