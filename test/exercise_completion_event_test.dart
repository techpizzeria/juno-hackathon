import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/logs/data/logs.dart';
import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/utils/local_storage.dart';

class _FailingLogRepository extends LogRepository {
  _FailingLogRepository(this.initial);

  final List<LogEntryModel> initial;

  @override
  List<LogEntryModel> loadAll() => initial;

  @override
  Future<void> saveAll(List<LogEntryModel> logs) {
    throw Exception('storage failed');
  }
}

void main() {
  group('exercise completion transition', () {
    const complete = ExerciseLogModel(
      exerciseId: 'exercise',
      status: ExerciseLogStatus.done,
      repsPerSet: [10, 10, 10],
    );

    test('successful completion triggers exactly once', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final logs = container.read(logsProvider.notifier);
      final entry = await logs.ensureToday('program');

      final first = await logs.logExercise(entry.id, complete);
      final repeated = await logs.logExercise(entry.id, complete);

      expect(first, isA<ExerciseCompletionEvent>());
      expect(first!.exerciseId, 'exercise');
      expect(repeated, isNull);
    });

    test('cancelled, skipped, and partial attempts trigger zero events', () {
      const skipped = ExerciseLogModel(
        exerciseId: 'exercise',
        status: ExerciseLogStatus.skipped,
      );
      const partial = ExerciseLogModel(
        exerciseId: 'exercise',
        status: ExerciseLogStatus.done,
        repsPerSet: [10, 0, 10],
      );

      expect(
        isNewExerciseCompletion(previous: null, current: null),
        isFalse,
      );
      expect(
        isNewExerciseCompletion(previous: null, current: skipped),
        isFalse,
      );
      expect(
        isNewExerciseCompletion(previous: null, current: partial),
        isFalse,
      );
      expect(
        isNewExerciseCompletion(previous: null, current: complete),
        isTrue,
      );
      expect(
        isNewExerciseCompletion(previous: complete, current: complete),
        isFalse,
      );
    });

    test('failed persistence emits no event and rolls state back', () async {
      const entry = LogEntryModel(
        id: 'entry',
        programId: 'program',
        date: '2026-07-25',
      );
      final container = ProviderContainer(
        overrides: [
          logRepositoryProvider.overrideWithValue(
            _FailingLogRepository([entry]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final logs = container.read(logsProvider.notifier);
      ExerciseCompletionEvent? event;

      try {
        event = await logs.logExercise('entry', complete);
      } on Exception {
        // Expected: a failed domain mutation must not produce an event.
      }

      expect(event, isNull);
      expect(container.read(logsProvider).single.exerciseLogs, isEmpty);
    });
  });
}
