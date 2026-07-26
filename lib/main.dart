import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_template/config/app_config.dart';
import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter_template/features/logs/data/logs.dart';
import 'package:flutter_template/features/logs/presentation/today_log_screen.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/schedule/application/notification_service.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/utils/local_storage.dart';
import 'package:flutter_template/utils/navigation.dart';

/// Composition root.
///
/// Does async launch-time init (config, local storage, timezone database,
/// notification plugin), then exposes those singletons through a manually
/// created [ProviderContainer] so notification callbacks can reach app
/// state without a widget context. Features wire in lazily as their
/// screens are navigated to.
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load .env before resolving config; optional so a missing file (AI simply
  // stays disabled) never blocks launch.
  await dotenv.load(isOptional: true);
  final config = AppConfig.resolve();
  final prefs = await SharedPreferences.getInstance();

  // Timezones must be ready before any zonedSchedule call; without
  // setLocalLocation notifications silently schedule in UTC.
  tz_data.initializeTimeZones();
  try {
    tz.setLocalLocation(
      tz.getLocation(await FlutterTimezone.getLocalTimezone()),
    );
  } on Object {
    // Unknown identifier: fall back to the timezone package default (UTC).
  }

  late final ProviderContainer container;
  final notificationService = NotificationService(
    callbacks: NotificationCallbacks(
      openProgramLog: _openProgramLog,
      markProgramDone: (programId) =>
          _logProgramToday(container, programId, done: true),
      markProgramSkipped: (programId) =>
          _logProgramToday(container, programId, done: false),
    ),
  );

  container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      localStorageProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );

  await notificationService.init();
  final launchProgramId = await notificationService.launchPayloadProgramId();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CreakApp(),
    ),
  );
  FlutterNativeSplash.remove();

  if (launchProgramId != null) {
    // Cold start from a notification tap: deep-open today's log once the
    // first frame (and the navigator) exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openProgramLog(launchProgramId);
    });
  }
}

void _openProgramLog(String programId) {
  unawaited(
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => TodayLogScreen(programId: programId),
      ),
    ),
  );
}

/// Handles the Done/Skip notification action buttons: logs the whole
/// session for today without opening any UI.
Future<void> _logProgramToday(
  ProviderContainer container,
  String programId, {
  required bool done,
}) async {
  final program = container
      .read(programsProvider)
      .where((p) => p.id == programId)
      .firstOrNull;
  if (program == null) return;
  final logs = container.read(logsProvider.notifier);
  final entry = await logs.ensureToday(programId);
  final exerciseIds = [for (final e in program.exercises) e.id];
  if (done) {
    await logs.completeAll(entry.id, exerciseIds);
  } else {
    await logs.skipAll(entry.id, exerciseIds);
  }
}

/// The Creak application widget.
///
/// Installs the peach-coral Material 3 themes (system-driven light/dark) and
/// the [rootNavigatorKey] used by notification handlers to deep-open screens.
class CreakApp extends StatelessWidget {
  const CreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Creak',
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
