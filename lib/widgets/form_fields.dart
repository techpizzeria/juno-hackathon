import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';

/// A label-less, iOS-style text field.
///
/// Uses a placeholder ([hint]) instead of a floating label, matching the
/// app's rounded filled input treatment. Prefer this over a raw [TextField]
/// in forms so every field reads the same.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  /// Backing text controller.
  final TextEditingController controller;

  /// Placeholder shown while empty.
  final String hint;

  /// Maximum visible lines; grows for multi-line notes.
  final int maxLines;

  /// Keyboard variant, e.g. [TextInputType.url].
  final TextInputType? keyboardType;

  /// Action button shown on the keyboard.
  final TextInputAction? textInputAction;

  /// Auto-capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field grabs focus on mount.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// A tappable, label-less date value with a platform-adaptive picker.
///
/// Shows [placeholder] while unset and the formatted date once chosen, in the
/// same filled pill as [AppTextField]. iOS gets a bottom-sheet
/// [CupertinoDatePicker]; other platforms get the Material [showDatePicker].
class DateField extends StatelessWidget {
  const DateField({
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  /// Placeholder shown while no date is set.
  final String placeholder;

  /// Currently selected date, or null when unset.
  final DateTime? value;

  /// Called with the newly picked date.
  final ValueChanged<DateTime> onChanged;

  /// Earliest selectable date, defaults to one year ago.
  final DateTime? firstDate;

  /// Latest selectable date, defaults to two years ahead.
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now;
    final first = firstDate ?? now.subtract(const Duration(days: 365));
    final last = lastDate ?? now.add(const Duration(days: 730));
    if (_isCupertino(context)) {
      await _showCupertinoSheet(
        context,
        CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: initial,
          minimumDate: first,
          maximumDate: last,
          onDateTimeChanged: onChanged,
        ),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return _PickerTile(
      placeholder: placeholder,
      valueText: value == null ? null : DateFormat.yMMMd().format(value!),
      icon: Icons.calendar_today_outlined,
      onTap: () => _pick(context),
    );
  }
}

/// A tappable, label-less time value with a platform-adaptive picker.
///
/// Shows [placeholder] while unset and the formatted time once chosen. iOS
/// gets a bottom-sheet [CupertinoDatePicker] in time mode; other platforms
/// get the Material [showTimePicker].
class TimeField extends StatelessWidget {
  const TimeField({
    required this.placeholder,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Placeholder shown while no time is set.
  final String placeholder;

  /// Currently selected time, or null when unset.
  final TimeOfDay? value;

  /// Called with the newly picked time.
  final ValueChanged<TimeOfDay> onChanged;

  Future<void> _pick(BuildContext context) async {
    final initial = value ?? TimeOfDay.now();
    if (_isCupertino(context)) {
      final now = DateTime.now();
      await _showCupertinoSheet(
        context,
        CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: DateTime(
            now.year,
            now.month,
            now.day,
            initial.hour,
            initial.minute,
          ),
          onDateTimeChanged: (dt) =>
              onChanged(TimeOfDay(hour: dt.hour, minute: dt.minute)),
        ),
      );
      return;
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return _PickerTile(
      placeholder: placeholder,
      valueText: value?.format(context),
      icon: Icons.schedule_outlined,
      onTap: () => _pick(context),
    );
  }
}

/// Lays children out in a row, collapsing to a column when narrow.
///
/// Uses a [LayoutBuilder]: children sit in a `Row` of `Expanded`s only when
/// each would get at least [minChildWidth] logical pixels; otherwise they
/// stack vertically. Use ~160 for short fields (numbers) and ~220 for
/// date/time pairs.
class FormFieldRow extends StatelessWidget {
  const FormFieldRow({
    required this.children,
    this.minChildWidth = 160,
    this.spacing = 12,
    super.key,
  });

  /// The fields to lay out.
  final List<Widget> children;

  /// Minimum width each child needs before the row collapses.
  final double minChildWidth;

  /// Gap between children in either direction.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits =
            constraints.maxWidth >= children.length * minChildWidth;
        if (fits) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing,
            children: [
              for (final child in children) Expanded(child: child),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing,
          children: children,
        );
      },
    );
  }
}

/// An outlined integer stepper: -/+ buttons plus a tappable value the user
/// can type into (clamped to [min]..[max], always under 100). The optional
/// [label] renders as text beside the controls, not as a floating label.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.value,
    required this.onChanged,
    this.label,
    this.min = 1,
    this.max = 99,
    super.key,
  });

  /// Text shown to the left of the controls; omitted for a bare stepper.
  final String? label;

  /// Current value.
  final int value;

  /// Called with the clamped new value.
  final ValueChanged<int> onChanged;

  /// Lower bound, inclusive.
  final int min;

  /// Upper bound, inclusive (kept under 100).
  final int max;

  Future<void> _edit(BuildContext context) async {
    final entered = await showDialog<int>(
      context: context,
      builder: (_) => _NumberInputDialog(
        title: label ?? 'Enter a number',
        initial: value,
        min: min,
        max: max,
      ),
    );
    if (entered != null) onChanged(entered.clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (label != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(label!, style: theme.textTheme.bodyMedium),
              ),
            )
          else
            const Spacer(),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            visualDensity: VisualDensity.compact,
          ),
          InkWell(
            onTap: () => _edit(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text('$value', style: theme.textTheme.titleMedium),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Numeric entry dialog for [NumberStepper]: digits only, at most two so the
/// value stays under 100, clamped to the stepper's range on submit.
class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
  });

  final String title;
  final int initial;
  final int min;
  final int max;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final _controller =
      TextEditingController(text: widget.initial.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    Navigator.pop(
      context,
      parsed?.clamp(widget.min, widget.max),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(hintText: '${widget.min}–${widget.max}'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}

/// Whether the current theme platform wants Cupertino-style pickers.
///
/// Branches on `Theme.of(context).platform` (testable, honors overrides) —
/// never on `dart:io Platform`. This file is the only place in the app that
/// makes this decision.
bool _isCupertino(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS;

/// Shared label-less pill for [DateField]/[TimeField].
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.placeholder,
    required this.valueText,
    required this.icon,
    required this.onTap,
  });

  final String placeholder;
  final String? valueText;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = valueText != null;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? valueText! : placeholder,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: hasValue
                        ? theme.colorScheme.onSurface
                        : theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showCupertinoSheet(BuildContext context, Widget picker) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: theme.brightness,
                ),
                child: picker,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
