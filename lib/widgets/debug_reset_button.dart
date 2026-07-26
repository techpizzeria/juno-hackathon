import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/logs/data/logs.dart';
import 'package:flutter_template/features/programs/data/programs.dart';
import 'package:flutter_template/features/schedule/data/schedules.dart';
import 'package:flutter_template/widgets/adaptive.dart';

/// Demo helper: a small floating button that expands into a "clear all
/// data" action.
///
/// Collapsed it is an unobtrusive small FAB; tapping it reveals the reset
/// action, which (after confirmation) wipes programs, schedules, logs, and
/// pending notifications so a demo can restart from the empty state.
class DebugResetButton extends ConsumerStatefulWidget {
  const DebugResetButton({super.key});

  @override
  ConsumerState<DebugResetButton> createState() => _DebugResetButtonState();
}

class _DebugResetButtonState extends ConsumerState<DebugResetButton> {
  var _expanded = false;

  Future<void> _reset() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Clear all data?',
      message: 'Removes every program, schedule, log, and pending reminder '
          'on this device.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(schedulesProvider.notifier).clearAll();
    await ref.read(programsProvider.notifier).clearAll();
    await ref.read(logsProvider.notifier).clearAll();
    if (!mounted) return;
    setState(() => _expanded = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared — fresh start!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_expanded) ...[
          FloatingActionButton.extended(
            heroTag: 'debug-reset-action',
            onPressed: _reset,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear all data'),
          ),
          const SizedBox(width: 8),
        ],
        FloatingActionButton.small(
          heroTag: 'debug-reset-toggle',
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Icon(_expanded ? Icons.close : Icons.cleaning_services),
        ),
      ],
    );
  }
}
