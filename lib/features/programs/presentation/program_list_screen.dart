import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/programs/domain/program.dart';
import 'package:flutter_template/features/programs/presentation/create_program_screen.dart';
import 'package:flutter_template/features/programs/presentation/program_detail_screen.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/utils/dates.dart';
import 'package:flutter_template/widgets/adaptive.dart';
import 'package:flutter_template/widgets/app_animations.dart';
import 'package:flutter_template/widgets/app_scaffold.dart';
import 'package:flutter_template/widgets/swipe_to_delete_card.dart';

/// All of the user's programs. Active programs sit up top; finished ones
/// (their end date has passed) are dimmed and grouped below. Swipe a card to
/// delete it; add via the app-bar action.
class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  /// Pushes the program list.
  static Future<void> push(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramListScreen()),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) {
    return showAppConfirmDialog(
      context,
      title: 'Delete "$name"?',
      message: 'Reminders stop; your log history is kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  Future<void> _performDelete(WidgetRef ref, String programId) async {
    await ref.read(schedulesProvider.notifier).removeForProgram(programId);
    await ref.read(programsProvider.notifier).delete(programId);
  }

  static bool _isFinished(ProgramModel program, DateTime today) {
    final end = program.endDate;
    if (end == null) return false;
    return DateTime(end.year, end.month, end.day).isBefore(today);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = [
      for (final p in programs)
        if (!_isFinished(p, today)) p,
    ];
    final finished = [
      for (final p in programs)
        if (_isFinished(p, today)) p,
    ];

    return AppScaffold(
      title: 'Programs',
      actions: [
        IconButton(
          tooltip: 'New program',
          onPressed: () => CreateProgramScreen.push(context),
          icon: const Icon(Icons.add),
        ),
      ],
      body: programs.isEmpty
          ? Center(
              child: Text(
                'No programs yet.\nTap + to create one.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              children: AppAnimate.staggered(
                context,
                children: [
                  for (final program in active)
                    _ProgramCard(
                      program: program,
                      finished: false,
                      onTap: () =>
                          ProgramDetailScreen.push(context, program.id),
                      confirmDelete: () =>
                          _confirmDelete(context, program.name),
                      onDeleted: () => _performDelete(ref, program.id),
                    ),
                  if (finished.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      child: Text(
                        'Finished',
                        style: textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    for (final program in finished)
                      _ProgramCard(
                        program: program,
                        finished: true,
                        onTap: () =>
                            ProgramDetailScreen.push(context, program.id),
                        confirmDelete: () =>
                            _confirmDelete(context, program.name),
                        onDeleted: () => _performDelete(ref, program.id),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// One program row, swipe-deletable; dimmed with a badge when finished.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.finished,
    required this.onTap,
    required this.confirmDelete,
    required this.onDeleted,
  });

  final ProgramModel program;
  final bool finished;
  final VoidCallback onTap;
  final Future<bool> Function() confirmDelete;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Opacity(
      opacity: finished ? 0.6 : 1,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          title: Text(program.name, style: theme.textTheme.titleMedium),
          subtitle: Text(
            '${program.exercises.length} exercises · '
            'from ${ymd(program.startDate)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (finished) ...[
                const _FinishedBadge(),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeToDeleteCard(
        itemKey: ValueKey(program.id),
        confirmDelete: confirmDelete,
        onDeleted: onDeleted,
        child: card,
      ),
    );
  }
}

/// Small "Finished" pill shown on past programs.
class _FinishedBadge extends StatelessWidget {
  const _FinishedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '✓ Finished',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
