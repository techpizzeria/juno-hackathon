import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_template/utils/dates.dart';

part 'schedule.g.dart';

/// One weekly reminder occurrence: a weekday at a time of day.
///
/// Slots are pure notification config. Replacing them (new ids included)
/// never touches log history, which references only program ids and dates.
@JsonSerializable()
class ScheduleSlot {
  const ScheduleSlot({
    required this.id,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  /// Decodes from stored JSON.
  factory ScheduleSlot.fromJson(Map<String, dynamic> json) =>
      _$ScheduleSlotFromJson(json);

  /// Slot identity; feeds the deterministic notification id hash.
  final String id;

  /// 1 = Monday .. 7 = Sunday (matches `DateTime.weekday`).
  final int weekday;

  /// Hour of day, 0–23.
  final int hour;

  /// Minute, 0–59.
  final int minute;

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$ScheduleSlotToJson(this);

  /// Human label like `Mon 18:00`.
  String get label {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '${weekdayShortLabel(weekday)} $hh:$mm';
  }
}

/// A program's reminder schedule: its weekly slots and on/off state.
@JsonSerializable(explicitToJson: true)
class ScheduleModel {
  const ScheduleModel({
    required this.programId,
    this.slots = const [],
    this.enabled = true,
  });

  /// Decodes from stored JSON.
  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  /// The program these reminders belong to (one schedule per program).
  final String programId;

  /// Weekly occurrences, unordered.
  final List<ScheduleSlot> slots;

  /// Whether reminders currently fire.
  final bool enabled;

  /// Encodes to stored JSON.
  Map<String, dynamic> toJson() => _$ScheduleModelToJson(this);

  /// Whether any slot lands on the 1–7 [weekday].
  bool hasSlotOn(int weekday) =>
      enabled && slots.any((slot) => slot.weekday == weekday);
}
