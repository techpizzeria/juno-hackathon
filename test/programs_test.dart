import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/utils/ids.dart';
import 'package:flutter_template/utils/local_storage.dart';

ProgramModel _program(String name) {
  return ProgramModel(
    id: newId(),
    name: name,
    startDate: DateTime(2026, 7, 25),
    createdAt: DateTime(2026, 7, 25, 12),
    exercises: [
      ProgramExercise(id: newId(), name: 'Calf raise', sets: 3, reps: 10),
      ProgramExercise(
        id: newId(),
        name: 'Glute bridge',
        sets: 3,
        reps: 12,
        referenceUrl: 'https://example.com/video',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('programs persist across container relaunches', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final program = _program('Achilles rehab');
    await container.read(programsProvider.notifier).upsert(program);

    // Fresh container over the same prefs simulates an app relaunch.
    final relaunched = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(prefs)],
    );
    addTearDown(relaunched.dispose);

    final loaded = relaunched.read(programsProvider);
    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Achilles rehab');
    expect(loaded.single.exercises, hasLength(2));
    expect(loaded.single.exercises.last.referenceUrl, isNotNull);
    expect(loaded.single.startDate, DateTime(2026, 7, 25));
  });

  test('upsert replaces and delete removes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(programsProvider.notifier);

    final a = _program('A');
    final b = _program('B');
    await notifier.upsert(a);
    await notifier.upsert(b);
    await notifier.upsert(a.copyWith(name: 'A2'));

    expect(
      container.read(programsProvider).map((p) => p.name),
      ['A2', 'B'],
    );

    await notifier.delete(b.id);
    expect(container.read(programsProvider).map((p) => p.name), ['A2']);
  });
}
