import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_template/features/exercise_catalog/data/exercise_catalog.dart';
import 'package:flutter_template/features/exercise_catalog/domain/exercise.dart';
import 'package:flutter_template/features/exercise_catalog/presentation/exercise_motion_image.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/programs/presentation/program_edit_screen.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/features/schedule/domain/schedule.dart';
import 'package:flutter_template/features/schedule/presentation/schedule_editor_screen.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/utils/dates.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';

/// Read-only view of one program with its exercise prescriptions.
///
/// Watches the programs notifier so edits reflect immediately. Catalog-linked
/// exercises show their motion image and target muscles.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({required this.programId, super.key});

  /// Id of the program to show.
  final String programId;

  /// Pushes the detail screen for [programId].
  static Future<void> push(BuildContext context, String programId) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(programId: programId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(
      programsProvider.select(
        (programs) => programs.where((p) => p.id == programId).firstOrNull,
      ),
    );
    if (program == null) {
      // Deleted while open; nothing sensible to show.
      return const AppScaffold(body: SizedBox.shrink());
    }
    final catalog =
        ref.watch(exerciseCatalogByIdProvider).value ?? const {};
    final textTheme = Theme.of(context).textTheme;

    final schedule = ref.watch(
      schedulesProvider.select(
        (schedules) =>
            schedules.where((s) => s.programId == programId).firstOrNull,
      ),
    );
    final scheduleSummary = switch (schedule) {
      null => 'No reminders yet',
      ScheduleModel(enabled: false) => 'Reminders off',
      ScheduleModel(:final slots) when slots.isEmpty => 'No reminders yet',
      ScheduleModel(:final slots) =>
        (slots.map((s) => s.label).toList()..sort()).join(' · '),
    };

    return AppScaffold(
      title: program.name,
      actions: [
        IconButton(
          tooltip: 'Reminders',
          icon: const Icon(Icons.alarm),
          onPressed: () => ScheduleEditorScreen.push(context, programId),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => ProgramEditScreen.push(context, initial: program),
        ),
      ],
      body: ListView(
        children: AppAnimate.staggered(
          context,
          children: [
            if (program.description != null) ...[
              Text(program.description!, style: textTheme.bodyLarge),
              const SizedBox(height: 12),
            ],
            _ProgramCard(
              program: program,
              catalog: catalog,
              scheduleSummary: scheduleSummary,
              onReminders: () =>
                  ScheduleEditorScreen.push(context, programId),
            ),
          ],
        ),
      ),
    );
  }
}

/// One card holding the whole program: date-range progress, a tappable
/// reminders row, and every exercise — each a distinct element separated by
/// dividers.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.catalog,
    required this.scheduleSummary,
    required this.onReminders,
  });

  final ProgramModel program;
  final Map<String, ExerciseModel> catalog;
  final String scheduleSummary;
  final VoidCallback onReminders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget divider() =>
        Divider(height: 24, color: theme.colorScheme.outlineVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDuration(context),
            divider(),
            InkWell(
              onTap: onReminders,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.alarm, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reminders', style: theme.textTheme.titleSmall),
                          Text(
                            scheduleSummary,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
            divider(),
            Text('Exercises', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final (index, exercise) in program.exercises.indexed) ...[
              if (index > 0) divider(),
              _ExerciseSection(
                exercise: exercise,
                catalogEntry: exercise.catalogExerciseId == null
                    ? null
                    : catalog[exercise.catalogExerciseId],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDuration(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CreakColors>()!;
    final start = _dateOnly(program.startDate);
    final endDate = program.endDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (endDate == null) {
      return Row(
        children: [
          Icon(Icons.event_repeat, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ongoing program', style: theme.textTheme.titleSmall),
                Text(
                  'Started ${ymd(start)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final end = _dateOnly(endDate);
    final totalDays = end.difference(start).inDays + 1;
    final elapsed =
        (today.difference(start).inDays + 1).clamp(0, totalDays);
    final fraction = totalDays <= 0 ? 1.0 : elapsed / totalDays;
    final finished = today.isAfter(end);
    final notStarted = today.isBefore(start);
    final status = finished
        ? 'Completed 🎉'
        : notStarted
            ? 'Starts ${ymd(start)}'
            : 'Day $elapsed of $totalDays · ${(fraction * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(ymd(start), style: theme.textTheme.labelMedium),
            const Spacer(),
            Text(ymd(end), style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: finished ? colors.success : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(status, style: theme.textTheme.bodySmall),
      ],
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

/// One exercise as a distinct section inside [_ProgramCard].
class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({required this.exercise, required this.catalogEntry});

  final ProgramExercise exercise;
  final ExerciseModel? catalogEntry;

  Future<void> _openReference() async {
    final url = Uri.tryParse(exercise.referenceUrl ?? '');
    if (url != null) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = catalogEntry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry != null) ...[
            SizedBox(
              width: 72,
              height: 72,
              child: ExerciseMotionImage(exercise: entry),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: theme.textTheme.titleMedium),
                Text(
                  '${exercise.sets} sets × ${exercise.reps} reps',
                  style: theme.textTheme.bodyMedium,
                ),
                if (exercise.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise.description!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (entry != null && entry.primaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final muscle in entry.primaryMuscles)
                        Chip(
                          label: Text(muscle),
                          labelStyle: theme.textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (exercise.referenceUrl != null)
            IconButton(
              tooltip: 'Open reference',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: _openReference,
            ),
        ],
      ),
    );
  }
}
