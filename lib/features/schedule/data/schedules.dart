import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/schedule/application/notification_service.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/local_storage.dart';

part 'schedules.g.dart';

/// Single source of truth for stored reminder schedules.
///
/// Persists all schedules as one JSON array under `creak.schedules.v1`.
@Riverpod(keepAlive: true)
class ScheduleRepository extends _$ScheduleRepository {
  static const _storageKey = 'creak.schedules.v1';

  @override
  ScheduleRepository build() => this;

  SharedPreferences get _prefs => ref.read(localStorageProvider);

  /// Loads every stored schedule, empty when none saved yet.
  List<ScheduleModel> loadAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in list.cast<Map<String, dynamic>>())
        ScheduleModel.fromJson(entry),
    ];
  }

  /// Replaces the stored schedule list.
  Future<void> saveAll(List<ScheduleModel> schedules) async {
    await _prefs.setString(
      _storageKey,
      jsonEncode([for (final schedule in schedules) schedule.toJson()]),
    );
  }
}

/// Reactive reminder schedules, keyed by program.
///
/// Also owns keeping pending notifications in sync with the stored slots
/// (wired to the notification service in a later milestone).
@Riverpod(keepAlive: true)
class Schedules extends _$Schedules {
  @override
  List<ScheduleModel> build() =>
      ref.read(scheduleRepositoryProvider).loadAll();

  /// The schedule for [programId], if one was ever saved.
  ScheduleModel? forProgram(String programId) =>
      state.where((s) => s.programId == programId).firstOrNull;

  /// Creates or replaces the schedule for `schedule.programId` and re-syncs
  /// its notifications.
  Future<void> upsertForProgram(ScheduleModel schedule) async {
    final exists = state.any((s) => s.programId == schedule.programId);
    state = [
      for (final s in state)
        if (s.programId == schedule.programId) schedule else s,
      if (!exists) schedule,
    ];
    await ref.read(scheduleRepositoryProvider).saveAll(state);
    await _resyncNotifications(schedule);
  }

  /// Drops the schedule for [programId] and cancels its notifications.
  Future<void> removeForProgram(String programId) async {
    state = [
      for (final s in state)
        if (s.programId != programId) s,
    ];
    await ref.read(scheduleRepositoryProvider).saveAll(state);
    await _cancelNotifications(programId);
  }

  /// Removes every schedule and pending notification (demo data reset).
  Future<void> clearAll() async {
    state = const [];
    await ref.read(scheduleRepositoryProvider).saveAll(state);
    await ref.read(notificationServiceProvider).cancelAll();
  }

  /// Cancel-then-re-add keeps pending notifications exactly in sync with
  /// the stored slots.
  Future<void> _resyncNotifications(ScheduleModel schedule) async {
    final service = ref.read(notificationServiceProvider);
    await service.cancelForProgram(schedule.programId);
    if (!schedule.enabled) return;
    final program = ref
        .read(programsProvider)
        .where((p) => p.id == schedule.programId)
        .firstOrNull;
    if (program == null) return;
    for (final slot in schedule.slots) {
      await service.scheduleWeekly(
        programId: program.id,
        programName: program.name,
        slot: slot,
      );
    }
  }

  Future<void> _cancelNotifications(String programId) async {
    await ref.read(notificationServiceProvider).cancelForProgram(programId);
  }
}
