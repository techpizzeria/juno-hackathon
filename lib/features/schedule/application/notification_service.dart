import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/ids.dart';

part 'notification_service.g.dart';

/// The notification service instance, constructed and wired in `main()`.
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main()',
  );
}

/// What the composition root does when a notification interaction happens.
///
/// The service itself stays free of navigation and state concerns; `main()`
/// wires these callbacks to the root navigator and the log notifier.
class NotificationCallbacks {
  const NotificationCallbacks({
    required this.openProgramLog,
    required this.markProgramDone,
    required this.markProgramSkipped,
  });

  /// Open today's log screen for the program (notification body tap).
  final void Function(String programId) openProgramLog;

  /// Log the whole session done ("Done" action button).
  final Future<void> Function(String programId) markProgramDone;

  /// Log the whole session skipped ("Skip" action button).
  final Future<void> Function(String programId) markProgramSkipped;
}

/// Wraps `flutter_local_notifications` + `timezone` so no plugin types leak
/// into the rest of the app.
///
/// Timezones must be initialized (in `main()`) before any scheduling call.
/// Reminder ids are deterministic ([notificationId]) so re-scheduling
/// replaces rather than duplicates; cancellation matches on the payload's
/// program id, which survives any id-scheme drift.
class NotificationService {
  NotificationService({required NotificationCallbacks callbacks})
      : _callbacks = callbacks;

  static const _categoryId = 'CREAK_SESSION';
  static const _channelId = 'creak_reminders';

  final NotificationCallbacks _callbacks;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the plugin with the action category. Does NOT request
  /// permissions; call [requestPermissions] when the user first saves a
  /// schedule.
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _categoryId,
          actions: [
            DarwinNotificationAction.plain('done', 'Done ✓'),
            DarwinNotificationAction.plain('snooze', 'Snooze 1h'),
            DarwinNotificationAction.plain('skip', 'Skip today'),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _handleResponse,
    );
  }

  /// Asks the OS for notification permission (iOS prompt, Android 13+
  /// runtime permission). Returns whether notifications are allowed.
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Schedules the weekly recurring reminder for one slot of [programName].
  Future<void> scheduleWeekly({
    required String programId,
    required String programName,
    required ScheduleSlot slot,
  }) async {
    await _plugin.zonedSchedule(
      notificationId(programId, slot.id),
      'Time to creak 🦴',
      '$programName — 5 minutes, you got this!',
      _nextInstanceOf(slot),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: _payload(programId),
    );
  }

  /// Schedules a one-off reminder for [programName] one hour from now.
  Future<void> snoozeOneHour({
    required String programId,
    required String programName,
  }) async {
    await _plugin.zonedSchedule(
      snoozeNotificationId(programId),
      'Snoozed reminder ⏰',
      '$programName — ready when you are!',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _payload(programId),
    );
  }

  /// Fires a test reminder in ten seconds (debug tooling).
  Future<void> scheduleTestInTenSeconds({
    required String programId,
    required String programName,
  }) async {
    await _plugin.zonedSchedule(
      fnv1a32('$programId|test') & 0x7FFFFFFF,
      'Time to creak 🦴',
      '$programName — 5 minutes, you got this!',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _payload(programId),
    );
  }

  /// Cancels every pending notification whose payload references
  /// [programId].
  Future<void> cancelForProgram(String programId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload != null && _programIdFrom(payload) == programId) {
        await _plugin.cancel(request.id);
      }
    }
  }

  /// Number of currently pending reminders (debug tooling).
  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;

  /// Cancels every pending notification (demo data reset).
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Program id from the notification that cold-launched the app, if any.
  Future<String?> launchPayloadProgramId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final payload = details.notificationResponse?.payload;
    return payload == null ? null : _programIdFrom(payload);
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final programId = _programIdFrom(payload);
    if (programId == null) return;
    switch (response.actionId) {
      case 'done':
        unawaited(_callbacks.markProgramDone(programId));
      case 'skip':
        unawaited(_callbacks.markProgramSkipped(programId));
      case 'snooze':
        // Body text is not available here; a generic snooze title is fine.
        unawaited(
          snoozeOneHour(programId: programId, programName: 'Your session'),
        );
      default:
        _callbacks.openProgramLog(programId);
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Reminders',
        channelDescription: 'Physio session reminders',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction('done', 'Done ✓'),
          AndroidNotificationAction('snooze', 'Snooze 1h'),
          AndroidNotificationAction('skip', 'Skip today'),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: _categoryId),
    );
  }

  static String _payload(String programId) =>
      jsonEncode({'programId': programId});

  static String? _programIdFrom(String payload) {
    final decoded = jsonDecode(payload);
    return decoded is Map<String, dynamic>
        ? decoded['programId'] as String?
        : null;
  }

  tz.TZDateTime _nextInstanceOf(ScheduleSlot slot) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      slot.hour,
      slot.minute,
    );
    while (scheduled.weekday != slot.weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
