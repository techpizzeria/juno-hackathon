import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/logs/data/today.dart';
import 'package:flutter_template/features/logs/domain/streak.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/utils/ids.dart';
import 'package:flutter_template/utils/local_storage.dart';

ProgramModel _activeTodayProgram() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return ProgramModel(
    id: newId(),
    name: 'AI plan',
    startDate: start,
    createdAt: now,
    exercises: [
      ProgramExercise(id: newId(), name: 'Calf raise', sets: 3, reps: 10),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(ProgramModel program) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container.read(programsProvider.notifier).upsert(program);
    return container;
  }

  test('an active program with no schedule is trainable today', () async {
    final container = await containerWith(_activeTodayProgram());

    final sessions = container.read(todaysSessionsProvider);

    expect(sessions, hasLength(1));
    expect(sessions.single.outcome, SessionOutcome.pending);
    expect(sessions.single.slots, isEmpty);
  });

  test('an unscheduled program still shows no history days', () async {
    final container = await containerWith(_activeTodayProgram());

    // History is limited to genuinely scheduled days, so an unscheduled
    // program contributes nothing there even while it is trainable today.
    expect(container.read(historyProvider), isEmpty);
  });
}
