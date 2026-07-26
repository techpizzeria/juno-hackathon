import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter_template/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter_template/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/utils/local_storage.dart';

const _config = AppConfig(
  apiBaseUrl: 'https://example.com',
  llmProvider: '',
  llmApiKey: '',
  llmModel: '',
  geminiApiKey: '',
  geminiModel: '',
  showDebugTools: false,
);

Widget _app(SharedPreferences prefs, {required bool introSeen}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(_config),
      localStorageProvider.overrideWithValue(prefs),
    ],
    child: CreakApp(introSeen: introSeen),
  );
}

void main() {
  test('intro flag defaults to unseen and persists once marked', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = OnboardingRepository(prefs);

    expect(repo.hasCompletedIntro(), isFalse);
    await repo.markIntroSeen();
    expect(repo.hasCompletedIntro(), isTrue);
    // A fresh repository over the same store still sees it (survives relaunch).
    expect(OnboardingRepository(prefs).hasCompletedIntro(), isTrue);
  });

  testWidgets('first run shows the intro; the dashboard once seen', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_app(prefs, introSeen: false));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);

    await tester.pumpWidget(_app(prefs, introSeen: true));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Skip marks the intro seen so it never shows again', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(_app(prefs, introSeen: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    // Landed on the dashboard and recorded the flag, so the next launch
    // (which reads the flag) opens straight on the dashboard.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(OnboardingRepository(prefs).hasCompletedIntro(), isTrue);
  });
}
