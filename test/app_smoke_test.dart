import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/utils/local_storage.dart';

void main() {
  testWidgets('app boots to the dashboard', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Reduced motion also verifies the AppAnimate accessibility gate:
    // with animations disabled no flutter_animate timers may be scheduled.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    SharedPreferences.setMockInitialValues({});
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
    await tester.pump();

    // Empty landing keeps the same three sections.
    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
