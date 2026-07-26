import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/config/config_provider.dart';
import 'package:flutter_template/features/programs/domain/generated_program.dart';
import 'package:flutter_template/features/schedule/application/notification_service.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/utils/dates.dart';
import 'package:flutter_template/utils/ids.dart';
import 'package:flutter_template/widgets/adaptive.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/form_fields.dart';

/// The two ways a user can express a weekly reminder pattern. Both compile
/// to the same flat slot list on save.
enum _EditorMode { sameTime, perDay }

/// Editor for a program's reminder schedule.
///
/// Supports "same time on selected weekdays" and "custom time per day".
/// Saving replaces the program's slots wholesale; log history is untouched
/// because logs never reference slots.
class ScheduleEditorScreen extends ConsumerStatefulWidget {
  const ScheduleEditorScreen({
    required this.programId,
    this.suggested,
    super.key,
  });

  /// The program whose reminders are being edited.
  final String programId;

  /// An AI-suggested pattern used to pre-fill a brand-new schedule; ignored
  /// when the program already has a saved schedule.
  final GeneratedScheduleModel? suggested;

  /// Pushes the editor for [programId].
  static Future<void> push(BuildContext context, String programId) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleEditorScreen(programId: programId),
      ),
    );
  }

  @override
  ConsumerState<ScheduleEditorScreen> createState() =>
      _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends ConsumerState<ScheduleEditorScreen> {
  var _enabled = true;
  _EditorMode _mode = _EditorMode.sameTime;

  /// sameTime state: chosen weekdays + one shared time.
  final Set<int> _sameTimeDays = {};
  TimeOfDay _sameTime = const TimeOfDay(hour: 18, minute: 0);

  /// perDay state: weekday -> time, absent meaning off.
  final Map<int, TimeOfDay> _perDayTimes = {};

  @override
  void initState() {
    super.initState();
    final existing =
        ref.read(schedulesProvider.notifier).forProgram(widget.programId);
    if (existing == null) {
      final suggested = widget.suggested;
      if (suggested != null && suggested.weekdays.isNotEmpty) {
        // Pre-fill from the AI's suggestion.
        _sameTimeDays.addAll(
          suggested.weekdays.where((day) => day >= 1 && day <= 7),
        );
        _sameTime = TimeOfDay(
          hour: suggested.hour.clamp(0, 23),
          minute: suggested.minute.clamp(0, 59),
        );
      } else {
        // Fresh schedule: pre-select every day so reminders are on by default.
        _sameTimeDays.addAll([
          for (var day = DateTime.monday; day <= DateTime.sunday; day++) day,
        ]);
      }
      return;
    }
    _enabled = existing.enabled;
    final byDay = <int, TimeOfDay>{
      for (final slot in existing.slots)
        slot.weekday: TimeOfDay(hour: slot.hour, minute: slot.minute),
    };
    _perDayTimes.addAll(byDay);
    final distinctTimes = byDay.values.map((t) => '${t.hour}:${t.minute}');
    if (distinctTimes.toSet().length <= 1) {
      _mode = _EditorMode.sameTime;
      _sameTimeDays.addAll(byDay.keys);
      if (byDay.isNotEmpty) _sameTime = byDay.values.first;
    } else {
      _mode = _EditorMode.perDay;
    }
  }

  /// Switches editor mode, translating the current selection so nothing is
  /// silently lost: shared days fan out to per-day times and vice versa.
  void _switchMode(_EditorMode next) {
    if (next == _mode) return;
    setState(() {
      if (next == _EditorMode.perDay) {
        _perDayTimes
          ..clear()
          ..addEntries(_sameTimeDays.map((day) => MapEntry(day, _sameTime)));
      } else {
        _sameTimeDays
          ..clear()
          ..addAll(_perDayTimes.keys);
        if (_perDayTimes.isNotEmpty) _sameTime = _perDayTimes.values.first;
      }
      _mode = next;
    });
  }

  List<ScheduleSlot> _compileSlots() {
    switch (_mode) {
      case _EditorMode.sameTime:
        return [
          for (final weekday in _sameTimeDays)
            ScheduleSlot(
              id: newId(),
              weekday: weekday,
              hour: _sameTime.hour,
              minute: _sameTime.minute,
            ),
        ];
      case _EditorMode.perDay:
        return [
          for (final MapEntry(key: weekday, value: time)
              in _perDayTimes.entries)
            ScheduleSlot(
              id: newId(),
              weekday: weekday,
              hour: time.hour,
              minute: time.minute,
            ),
        ];
    }
  }

  Future<void> _save() async {
    final slots = _compileSlots();
    if (_enabled && slots.isNotEmpty) {
      // First-time permission prompt happens here, tied to user intent.
      await ref.read(notificationServiceProvider).requestPermissions();
    }
    await ref.read(schedulesProvider.notifier).upsertForProgram(
          ScheduleModel(
            programId: widget.programId,
            slots: slots,
            enabled: _enabled,
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _fireTestNotification() async {
    final service = ref.read(notificationServiceProvider);
    await service.requestPermissions();
    await service.scheduleTestInTenSeconds(
      programId: widget.programId,
      programName: 'Test program',
    );
    final pending = await service.pendingCount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Firing in 10s — background the app! ($pending pending)',
        ),
      ),
    );
  }

  bool get _canSave => !_enabled || _compileSlots().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final showDebugTools =
        ref.watch(appConfigProvider.select((c) => c.showDebugTools));
    return AppScaffold(
      title: 'Reminders',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              title: const Text('Remind me'),
              subtitle: const Text('Turn all reminders on or off'),
              trailing: AppSwitch(
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_EditorMode>(
            segments: const [
              ButtonSegment(
                value: _EditorMode.sameTime,
                label: Text('Same time'),
              ),
              ButtonSegment(
                value: _EditorMode.perDay,
                label: Text('Custom per day'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => _switchMode(selection.first),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _mode == _EditorMode.sameTime
                  ? _buildSameTime(context)
                  : _buildPerDay(context),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save reminders'),
          ),
          if (showDebugTools) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _fireTestNotification,
              child: const Text('Test notification in 10s'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSameTime(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('On these days', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = DateTime.monday; day <= DateTime.sunday; day++)
              FilterChip(
                label: Text(weekdayShortLabel(day)),
                selected: _sameTimeDays.contains(day),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _sameTimeDays.add(day);
                  } else {
                    _sameTimeDays.remove(day);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('At', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        TimeField(
          placeholder: 'Reminder time',
          value: _sameTime,
          onChanged: (time) => setState(() => _sameTime = time),
        ),
      ],
    );
  }

  Widget _buildPerDay(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    weekdayShortLabel(day),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _perDayTimes.containsKey(day)
                      ? TimeField(
                          placeholder: 'Reminder time',
                          value: _perDayTimes[day],
                          onChanged: (time) =>
                              setState(() => _perDayTimes[day] = time),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => setState(
                            () => _perDayTimes[day] =
                                const TimeOfDay(hour: 18, minute: 0),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add reminder'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ),
                if (_perDayTimes.containsKey(day))
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _perDayTimes.remove(day)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
