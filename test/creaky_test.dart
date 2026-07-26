import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/main.dart';
import 'package:flutter_template/utils/local_storage.dart';
import 'package:flutter_template/widgets/celebration_overlay.dart';
import 'package:flutter_template/widgets/mascot.dart';

Widget _testApp(Widget child, {bool reducedMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Iterable<String> _assetNames(WidgetTester tester, Finder scope) {
  return tester
      .widgetList<Image>(
        find.descendant(of: scope, matching: find.byType(Image)),
      )
      .map((image) => image.image)
      .whereType<AssetImage>()
      .map((image) => image.assetName);
}

void main() {
  group('Creaky assets', () {
    test('every home mood maps to the expected state', () {
      expect(
        CreakyAssets.homeStateFolder(CreakyHomeMood.sunny),
        'home_sunny',
      );
      expect(CreakyAssets.homeStateFolder(CreakyHomeMood.grey), 'home_grey');
      expect(
        CreakyAssets.homeStateFolder(CreakyHomeMood.rainy),
        'home_rainy',
      );
      expect(
        CreakyAssets.homeStateFolder(CreakyHomeMood.stormy),
        'home_stormy',
      );
    });

    test('every production mascot path stays below assets/creaky', () {
      expect(CreakyAssets.all, isNotEmpty);
      expect(
        CreakyAssets.all,
        everyElement(startsWith('assets/creaky/')),
      );
      expect(CreakyAssets.all, everyElement(endsWith('.png')));
      expect(CreakyAssets.all, everyElement(isNot(contains('2.0x'))));
      for (final path in CreakyAssets.all) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('production Dart does not reference preview animations', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        expect(source, isNot(contains('.gif')), reason: file.path);
        expect(source, isNot(contains('previews/animated')), reason: file.path);
      }
    });
  });

  group('Creaky motion lifecycle', () {
    testWidgets('reduced motion renders stable static composites', (
      tester,
    ) async {
      const mascotKey = ValueKey('mascot');
      await tester.pumpWidget(
        _testApp(
          const MascotWidget(
            key: mascotKey,
            mood: CreakyHomeMood.stormy,
          ),
          reducedMotion: true,
        ),
      );

      expect(
        _assetNames(tester, find.byKey(mascotKey)),
        [CreakyAssets.compositeForMood(CreakyHomeMood.stormy)],
      );
      expect(
        find.descendant(
          of: find.byKey(mascotKey),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );

      const celebrationKey = ValueKey('celebration');
      await tester.pumpWidget(
        _testApp(
          const CreakyCelebrationView(
            key: celebrationKey,
            celebration: CreakyCelebration.highFive,
          ),
          reducedMotion: true,
        ),
      );
      expect(
        _assetNames(tester, find.byKey(celebrationKey)),
        [
          CreakyAssets.compositeForCelebration(
            CreakyCelebration.highFive,
          ),
        ],
      );
    });

    testWidgets('eye and lightning controllers dispose safely', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          const MascotWidget(mood: CreakyHomeMood.stormy),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpWidget(_testApp(const SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('ordinary parent rebuild preserves lightning timeline', (
      tester,
    ) async {
      late VoidCallback rebuildParent;
      const mascotKey = ValueKey('storm');
      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = () => setState(() {});
              return const MascotWidget(
                key: mascotKey,
                mood: CreakyHomeMood.stormy,
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      Opacity lightningOpacity() {
        return tester
            .widgetList<Opacity>(
              find.descendant(
                of: find.byKey(mascotKey),
                matching: find.byType(Opacity),
              ),
            )
            .firstWhere((opacity) {
              final child = opacity.child;
              return child is Image &&
                  child.image is AssetImage &&
                  (child.image as AssetImage).assetName.endsWith(
                    '40_lightning.png',
                  );
            });
      }

      final before = lightningOpacity().opacity;
      expect(before, greaterThan(0));
      rebuildParent();
      await tester.pump();
      expect(lightningOpacity().opacity, before);
    });

    testWidgets('disposed celebration timer never invokes its callback', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        _testApp(
          CreakyCelebrationView(
            celebration: CreakyCelebration.ascent,
            onCompleted: () => completed++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(_testApp(const SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 2));

      expect(completed, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ordinary parent rebuild does not replay completion', (
      tester,
    ) async {
      var completed = 0;
      late VoidCallback rebuildParent;
      await tester.pumpWidget(
        _testApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = () => setState(() {});
              return CreakyCelebrationView(
                key: const ValueKey('event-1'),
                celebration: CreakyCelebration.heartEyes,
                onCompleted: () => completed++,
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));
      rebuildParent();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 699));
      expect(completed, 0);
      await tester.pump(const Duration(milliseconds: 2));
      expect(completed, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(completed, 1);
    });
  });

  group('Creaky celebration selection', () {
    test('leads with the heart-eyes cloud', () {
      // Independent of the RNG seed, the first celebration is heart eyes.
      for (final seed in [1, 42, 99, 1000]) {
        final selector = CreakyCelebrationSelector(random: Random(seed));
        expect(selector.next(), CreakyCelebration.heartEyes);
      }
    });

    test('returns only valid values and avoids immediate repeats', () {
      final selector = CreakyCelebrationSelector(random: Random(42));
      CreakyCelebration? previous;
      for (var i = 0; i < 200; i++) {
        final selected = selector.next();
        expect(CreakyCelebration.values, contains(selected));
        if (previous != null) expect(selected, isNot(previous));
        previous = selected;
      }
    });

    test('uses exactly 15 valid encouragements without immediate repeats', () {
      expect(creakyEncouragements, hasLength(15));
      expect(creakyEncouragements.toSet(), hasLength(15));
      final selector = CreakyEncouragementSelector(random: Random(42));
      String? previous;
      for (var i = 0; i < 200; i++) {
        final selected = selector.next();
        expect(creakyEncouragements, contains(selected));
        if (previous != null) expect(selected, isNot(previous));
        previous = selected;
      }
    });
  });

  testWidgets('dashboard does not overflow on a narrow phone', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      tester.view.reset();
    });

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
        child: const CreakApp(introSeen: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MascotWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
