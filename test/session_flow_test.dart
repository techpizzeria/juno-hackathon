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

/// Drives the core loop end-to-end: dashboard shows today's session, the
/// user logs one exercise, amends nothing, completes the session, sees the
/// celebration, and returns to a dashboard with a live streak.
void main() {
  testWidgets('complete a session from the dashboard', (tester) async {
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
        child: const CreakApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Dashboard shows today's pending session.
    expect(find.textContaining('Achilles rehab'), findsOneWidget);
    await tester.tap(find.text('Start today’s session'));
    await tester.pumpAndSettle();

    // Mark each exercise done via its bottom sheet (which scrolls).
    expect(find.text('Calf raise'), findsOneWidget);
    await tester.tap(find.text('Start').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mark done ✓'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark done ✓'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 logged'), findsOneWidget);
    expect(find.byType(CreakyCelebrationView), findsNothing);

    await tester.tap(find.text('Start').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mark done ✓'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark done ✓'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2 logged'), findsOneWidget);
    expect(find.byType(CreakyCelebrationView), findsNothing);

    // Finish the session; exactly one Creaky success screen appears.
    await tester.tap(find.text('Finish 🎉'));
    await tester.pumpAndSettle();
    expect(find.byType(CelebrationOverlay), findsOneWidget);
    expect(find.byType(CreakyCelebrationView), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && creakyEncouragements.contains(widget.data),
      ),
      findsOneWidget,
    );
    expect(find.text('Session complete!'), findsNothing);

    // Dismiss: back on the dashboard, all done, streak live.
    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();
    expect(find.text('All done today 🎉'), findsOneWidget);
    expect(find.textContaining('1-day streak'), findsOneWidget);
  });
}
