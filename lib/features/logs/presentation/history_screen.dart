import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:flutter_template/features/logs/data/today.dart';
import 'package:flutter_template/features/logs/domain/log_entry.dart';
import 'package:flutter_template/features/logs/domain/streak.dart';
import 'package:flutter_template/features/logs/presentation/form_feedback_dialog.dart';
import 'package:flutter_template/features/logs/presentation/session_video_view.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';

const Map<SessionOutcome, String> _outcomeBadges = {
  SessionOutcome.completed: '✅ Completed',
  SessionOutcome.partial: '🟡 Partial',
  SessionOutcome.skipped: '⚪ Skipped',
  SessionOutcome.missed: '⚪ Missed',
  SessionOutcome.pending: '⏳ Pending',
};

/// The true record of past sessions, grouped by program and expandable.
///
/// Each program lists its dated sessions; tapping one opens its full detail
/// (per-exercise status, amended actuals, comments, and any recorded video).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  /// Pushes the history screen.
  static Future<void> push(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(historyByProgramProvider);
    final streak = ref.watch(streakProvider);
    final textTheme = Theme.of(context).textTheme;
    return AppScaffold(
      title: 'History',
      body: programs.isEmpty
          ? Center(
              child: Text(
                'Nothing here yet.\nSchedule a program to start logging!',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              children: AppAnimate.staggered(
                context,
                children: [
                  Text(
                    '🔥 Current streak: $streak days',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final program in programs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProgramGroup(history: program),
                    ),
                ],
              ),
            ),
    );
  }
}

/// One program's expandable set of past sessions.
class _ProgramGroup extends StatelessWidget {
  const _ProgramGroup({required this.history});

  final ProgramHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        title: Text(history.program.name, style: theme.textTheme.titleMedium),
        subtitle: Text('${history.entries.length} sessions'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final entry in history.entries)
            _EntryRow(entry: entry),
        ],
      ),
    );
  }
}

/// A single dated session row, tappable to inspect.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final ProgramHistoryEntry entry;

  bool get _hasMetadata =>
      entry.session.entry?.exerciseLogs.any((log) => log.hasMetadata) ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Text(DateFormat.MMMEd().format(entry.date)),
      subtitle: Text(_outcomeBadges[entry.session.outcome]!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasMetadata)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _EntryDetailSheet(entry: entry),
      ),
    );
  }
}

/// Full detail for one session: each exercise's status, actuals, comment,
/// and any recorded video.
class _EntryDetailSheet extends StatelessWidget {
  const _EntryDetailSheet({required this.entry});

  final ProgramHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = entry.session;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          Text(session.program.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            '${DateFormat.yMMMMEEEEd().format(entry.date)} · '
            '${_outcomeBadges[session.outcome]!}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final exercise in session.program.exercises)
            _ExerciseDetail(
              name: exercise.name,
              planSets: exercise.sets,
              planReps: exercise.reps,
              log: session.entry?.logFor(exercise.id),
            ),
        ],
      ),
    );
  }
}

/// One exercise's logged detail inside the entry sheet.
class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({
    required this.name,
    required this.planSets,
    required this.planReps,
    required this.log,
  });

  final String name;
  final int planSets;
  final int planReps;
  final ExerciseLogModel? log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final log = this.log;
    final skipped = log?.status == ExerciseLogStatus.skipped;
    final fullyDone = log?.isFullyDone ?? false;
    // Marked done but a set was left at 0 reps: partial, not complete.
    final partial = log?.status == ExerciseLogStatus.done && !fullyDone;
    final marker = fullyDone
        ? '✓'
        : partial
            ? '~'
            : skipped
                ? '–'
                : '·';
    final reps = log?.repsPerSet;
    final hasReps = reps != null && reps.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$marker $name', style: theme.textTheme.titleSmall),
          Text(
            hasReps
                ? 'Did ${reps.join(', ')}  (plan $planSets × $planReps)'
                : 'Plan $planSets × $planReps',
            style: theme.textTheme.bodySmall,
          ),
          if (log?.painNote != null && log!.painNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '📝 ${log.painNote}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (log?.videoPath != null && log!.videoPath!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SessionVideoView(path: log.videoPath!, maxHeight: 140),
          ],
          if (log?.feedback != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () =>
                    showFormFeedback(context, log!.feedback!, name),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('View form feedback'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
