import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/schedule/application/notification_service.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/ids.dart';
import 'package:flutter_template/utils/local_storage.dart';

/// No-op service so schedule mutations never touch the real notification
/// plugin (which has no platform channel in unit tests).
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService()
      : super(
          callbacks: NotificationCallbacks(
            openProgramLog: (_) {},
            markProgramDone: (_) async {},
            markProgramSkipped: (_) async {},
          ),
        );

  @override
  Future<void> scheduleWeekly({
    required String programId,
    required String programName,
    required ScheduleSlot slot,
  }) async {}

  @override
  Future<void> cancelForProgram(String programId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(SharedPreferences prefs) async {
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(prefs),
        notificationServiceProvider
            .overrideWithValue(_FakeNotificationService()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('schedule edits persist and never touch the logs key', () async {
    SharedPreferences.setMockInitialValues({
      'creak.logs.v1': '[{"sentinel":true}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = await containerWith(prefs);
    final notifier = container.read(schedulesProvider.notifier);

    await notifier.upsertForProgram(
      ScheduleModel(
        programId: 'p1',
        slots: [
          ScheduleSlot(id: newId(), weekday: 1, hour: 7, minute: 0),
          ScheduleSlot(id: newId(), weekday: 3, hour: 7, minute: 0),
        ],
      ),
    );
    // Edit: different pattern entirely.
    await notifier.upsertForProgram(
      ScheduleModel(
        programId: 'p1',
        slots: [
          ScheduleSlot(id: newId(), weekday: 4, hour: 12, minute: 30),
        ],
      ),
    );

    final relaunched = await containerWith(prefs);
    final loaded =
        relaunched.read(schedulesProvider.notifier).forProgram('p1');
    expect(loaded, isNotNull);
    expect(loaded!.slots.single.weekday, 4);
    expect(loaded.slots.single.label, 'Thu 12:30');

    expect(prefs.getString('creak.logs.v1'), '[{"sentinel":true}]');
  });

  test('removeForProgram drops only that program', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = await containerWith(prefs);
    final notifier = container.read(schedulesProvider.notifier);

    await notifier.upsertForProgram(
      ScheduleModel(
        programId: 'p1',
        slots: [ScheduleSlot(id: newId(), weekday: 1, hour: 7, minute: 0)],
      ),
    );
    await notifier.upsertForProgram(
      ScheduleModel(
        programId: 'p2',
        slots: [ScheduleSlot(id: newId(), weekday: 2, hour: 8, minute: 0)],
      ),
    );

    await notifier.removeForProgram('p1');
    expect(notifier.forProgram('p1'), isNull);
    expect(notifier.forProgram('p2'), isNotNull);
  });
}
