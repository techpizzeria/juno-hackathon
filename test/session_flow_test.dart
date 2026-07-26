import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/utils/local_storage.dart';
import 'package:flutter_template/widgets/celebration_overlay.dart';

/// Boots the app with one two-exercise program scheduled today and opens
/// today's session, ready for per-exercise interactions.
Future<void> _openTodaysSession(WidgetTester tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);

  final program = ProgramModel(
    id: 'p1',
    name: 'Achilles rehab',
    startDate: DateTime.now().subtract(const Duration(days: 7)),
    createdAt: DateTime.now(),
    exercises: const [
      ProgramExercise(id: 'e1', name: 'Calf raise', sets: 3, reps: 10),
      ProgramExercise(id: 'e2', name: 'Heel drop', sets: 3, reps: 8),
    ],
  );
  final schedule = ScheduleModel(
    programId: 'p1',
    slots: [
      ScheduleSlot(
        id: 's1',
        weekday: DateTime.now().weekday,
        hour: 7,
        minute: 0,
      ),
    ],
  );
  SharedPreferences.setMockInitialValues({
    'creak.programs.v1': jsonEncode([program.toJson()]),
    'creak.schedules.v1': jsonEncode([schedule.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            apiBaseUrl: 'https://example.com',
            llmProvider: '',
            llmApiKey: '',
            llmModel: '',
            geminiApiKey: '',
            geminiModel: '',
            showDebugTools: false,
          ),
        ),
        localStorageProvider.overrideWithValue(prefs),
      ],
      child: const CreakApp(introSeen: true),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start today’s session'));
  await tester.pumpAndSettle();
}

/// Opens the next pending exercise's sheet and taps [action] ('Mark done ✓'
/// or 'Skip').
Future<void> _logNext(WidgetTester tester, String action) async {
  await tester.tap(find.text('Start').first);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(action));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('completing every exercise shows the celebration', (
    tester,
  ) async {
    await _openTodaysSession(tester);

    expect(find.text('Calf raise'), findsOneWidget);
    await _logNext(tester, 'Mark done ✓');
    expect(find.text('1 of 2 logged'), findsOneWidget);
    expect(find.byType(CreakyCelebrationView), findsNothing);

    await _logNext(tester, 'Mark done ✓');
    expect(find.text('2 of 2 logged'), findsOneWidget);
    expect(find.byType(CreakyCelebrationView), findsNothing);

    await tester.tap(find.text('Finish 🎉'));
    await tester.pumpAndSettle();
    expect(find.byType(CelebrationOverlay), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && creakyEncouragements.contains(widget.data),
      ),
      findsOneWidget,
    );

    // Dismiss: back on the dashboard, all done, streak live.
    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();
    expect(find.text('All done today 🎉'), findsOneWidget);
    expect(find.textContaining('1-day streak'), findsOneWidget);
  });

  testWidgets('a partial session (one done, one skipped) still celebrates', (
    tester,
  ) async {
    await _openTodaysSession(tester);

    await _logNext(tester, 'Mark done ✓');
    await _logNext(tester, 'Skip');
    expect(find.text('2 of 2 logged'), findsOneWidget);

    await tester.tap(find.text('Finish 🎉'));
    await tester.pumpAndSettle();
    expect(find.byType(CelebrationOverlay), findsOneWidget);
  });

  testWidgets('a fully skipped session stays silent', (tester) async {
    await _openTodaysSession(tester);

    await _logNext(tester, 'Skip');
    await _logNext(tester, 'Skip');
    expect(find.text('2 of 2 logged'), findsOneWidget);

    await tester.tap(find.text('Finish 🎉'));
    await tester.pumpAndSettle();
    expect(find.byType(CelebrationOverlay), findsNothing);
  });
}
