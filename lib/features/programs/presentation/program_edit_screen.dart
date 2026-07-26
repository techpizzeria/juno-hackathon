import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/exercise_catalog/presentation/exercise_picker_screen.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/generated_program.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/schedule/presentation/schedule_editor_screen.dart';
import 'package:flutter_template/utils/ids.dart';
import 'package:flutter_template/widgets/adaptive.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/dismiss_keyboard.dart';
import 'package:flutter_template/widgets/form_fields.dart';
import 'package:flutter_template/widgets/swipe_to_delete_card.dart';

/// Create/edit form for a program.
///
/// Pass [initial] to edit an existing program; omit it to create a new one.
/// Retained exercises keep their ids on save so log history stays linked.
/// Set [advanceToReminders] to jump into the reminder editor after saving
/// (defaults to true when creating). The form and Save action stay pinned;
/// only the exercise list scrolls.
class ProgramEditScreen extends ConsumerStatefulWidget {
  const ProgramEditScreen({
    this.initial,
    this.advanceToReminders,
    this.suggestedSchedule,
    super.key,
  });

  /// The program being edited, or a pre-filled draft when creating.
  final ProgramModel? initial;

  /// Whether to open the reminder editor after saving. When null, defaults
  /// to true for new programs and false when editing an existing one.
  final bool? advanceToReminders;

  /// AI-suggested reminder pattern to pre-fill the reminder editor with,
  /// used when this is a fresh program from the AI flow.
  final GeneratedScheduleModel? suggestedSchedule;

  /// Pushes the editor; resolves with the saved program, if any.
  static Future<ProgramModel?> push(
    BuildContext context, {
    ProgramModel? initial,
    bool? advanceToReminders,
  }) {
    return Navigator.push<ProgramModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramEditScreen(
          initial: initial,
          advanceToReminders: advanceToReminders,
        ),
      ),
    );
  }

  @override
  ConsumerState<ProgramEditScreen> createState() => _ProgramEditScreenState();
}

class _ProgramEditScreenState extends ConsumerState<ProgramEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late DateTime _startDate;
  DateTime? _endDate;
  late List<ProgramExercise> _exercises;

  /// True when this program did not exist before this screen (new or an AI
  /// draft not yet saved), which drives the "then set reminders" flow.
  bool get _isNew =>
      widget.initial == null ||
      !ref
          .read(programsProvider)
          .any((p) => p.id == widget.initial!.id);

  bool get _advanceToReminders => widget.advanceToReminders ?? _isNew;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name);
    _description = TextEditingController(text: initial?.description);
    _startDate = initial?.startDate ?? DateTime.now();
    _endDate = initial?.endDate;
    _exercises = [...?initial?.exercises];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _editExercise([ProgramExercise? exercise]) async {
    // Drop the keyboard from the name/notes fields before the sheet appears.
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<_ExerciseSheetResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseEditSheet(initial: exercise),
    );
    if (result == null || !mounted) return;
    if (result.deleted) {
      _removeExercise(exercise!);
      return;
    }
    final edited = result.exercise!;
    setState(() {
      final index = _exercises.indexWhere((e) => e.id == edited.id);
      if (index == -1) {
        _exercises = [..._exercises, edited];
      } else {
        _exercises = [
          for (final e in _exercises)
            if (e.id == edited.id) edited else e,
        ];
      }
    });
  }

  Future<bool> _confirmDelete(ProgramExercise exercise) {
    return showAppConfirmDialog(
      context,
      title: 'Remove "${exercise.name}"?',
      message: 'It will be taken out of this program.',
      confirmLabel: 'Remove',
      destructive: true,
    );
  }

  void _removeExercise(ProgramExercise exercise) {
    setState(() {
      _exercises = [
        for (final e in _exercises)
          if (e.id != exercise.id) e,
      ];
    });
  }

  bool get _canSave => _name.text.trim().isNotEmpty && _exercises.isNotEmpty;

  Future<void> _save() async {
    final base = widget.initial;
    // Guard against an end date that predates the start (e.g. after the
    // start was moved later): drop it rather than store an invalid range.
    final endDate =
        _endDate != null && _endDate!.isBefore(_startDate) ? null : _endDate;
    final program = ProgramModel(
      id: base?.id ?? newId(),
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      startDate: _startDate,
      endDate: endDate,
      exercises: _exercises,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    final advance = _advanceToReminders;
    await ref.read(programsProvider.notifier).upsert(program);
    if (!mounted) return;
    if (advance) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ScheduleEditorScreen(
            programId: program.id,
            suggested: widget.suggestedSchedule,
          ),
        ),
      );
    } else {
      Navigator.pop(context, program);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppScaffold(
      title: _isNew ? 'New program' : 'Edit program',
      // Form and exercise list share one scroll view so nothing is clipped
      // when the keyboard opens; only the Save action stays pinned.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          hint: 'Program name',
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        AppTextField(
                          controller: _description,
                          hint: "What's it for? (optional)",
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        FormFieldRow(
                          minChildWidth: 150,
                          children: [
                            DateField(
                              placeholder: 'Start date',
                              value: _startDate,
                              onChanged: (date) =>
                                  setState(() => _startDate = date),
                            ),
                            DateField(
                              placeholder: 'End date (optional)',
                              value: _endDate,
                              firstDate: _startDate,
                              onChanged: (date) =>
                                  setState(() => _endDate = date),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Exercises', style: textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _editExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_exercises.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No exercises yet.\nTap Add to build your program.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final exercise in _exercises)
                    _ExerciseTile(
                      key: ValueKey(exercise.id),
                      exercise: exercise,
                      onEdit: () => _editExercise(exercise),
                      confirmDelete: () => _confirmDelete(exercise),
                      onDeleted: () => _removeExercise(exercise),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save program'),
          ),
        ],
      ),
    );
  }
}

/// An exercise row: swipe left to delete, tap to edit.
class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onEdit,
    required this.confirmDelete,
    required this.onDeleted,
    super.key,
  });

  /// The exercise shown.
  final ProgramExercise exercise;

  /// Opens the edit sheet.
  final VoidCallback onEdit;

  /// Asks the user to confirm deletion; resolves true to proceed.
  final Future<bool> Function() confirmDelete;

  /// Removes the exercise from the program.
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwipeToDeleteCard(
        itemKey: ValueKey('slide-${exercise.id}'),
        confirmDelete: confirmDelete,
        onDeleted: onDeleted,
        child: Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Text(exercise.name, style: theme.textTheme.titleMedium),
            subtitle: Text('${exercise.sets} × ${exercise.reps}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onEdit,
          ),
        ),
      ),
    );
  }
}

/// What an [_ExerciseEditSheet] resolves to: a saved exercise or a deletion.
class _ExerciseSheetResult {
  const _ExerciseSheetResult.saved(this.exercise) : deleted = false;
  const _ExerciseSheetResult.deleted()
      : exercise = null,
        deleted = true;

  final ProgramExercise? exercise;
  final bool deleted;
}

/// Bottom-sheet editor for one exercise prescription.
class _ExerciseEditSheet extends StatefulWidget {
  const _ExerciseEditSheet({this.initial});

  final ProgramExercise? initial;

  @override
  State<_ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<_ExerciseEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _referenceUrl;
  String? _catalogExerciseId;
  late int _sets;
  late int _reps;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name);
    _referenceUrl = TextEditingController(text: initial?.referenceUrl);
    _catalogExerciseId = initial?.catalogExerciseId;
    _sets = initial?.sets ?? 3;
    _reps = initial?.reps ?? 10;
  }

  @override
  void dispose() {
    _name.dispose();
    _referenceUrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromCatalog() async {
    final picked = await ExercisePickerScreen.pick(context);
    if (picked == null) return;
    setState(() {
      _name.text = picked.name;
      _catalogExerciseId = picked.id;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Remove "${_name.text.trim()}"?',
      message: 'It will be taken out of this program.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (confirmed && mounted) {
      Navigator.pop(context, const _ExerciseSheetResult.deleted());
    }
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final url = _referenceUrl.text.trim();
    Navigator.pop(
      context,
      _ExerciseSheetResult.saved(
        ProgramExercise(
          id: widget.initial?.id ?? newId(),
          name: name,
          sets: _sets,
          reps: _reps,
          catalogExerciseId: _catalogExerciseId,
          description: widget.initial?.description,
          referenceUrl: url.isEmpty ? null : url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
            controller: _name,
            decoration: InputDecoration(
              hintText: 'Exercise name',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                tooltip: 'Pick from catalog',
                icon: const Icon(Icons.grid_view),
                onPressed: _pickFromCatalog,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FormFieldRow(
            children: [
              NumberStepper(
                label: 'Sets',
                value: _sets,
                max: 10,
                onChanged: (value) => setState(() => _sets = value),
              ),
              NumberStepper(
                label: 'Reps',
                value: _reps,
                onChanged: (value) => setState(() => _reps = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceUrl,
            decoration: const InputDecoration(
              hintText: 'Reference link (optional)',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _name.text.trim().isEmpty ? null : _submit,
            child: Text(_isEditing ? 'Update' : 'Add'),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _delete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Delete exercise',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}
