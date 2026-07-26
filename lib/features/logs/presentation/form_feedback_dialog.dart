import 'package:flutter/material.dart';

import 'package:flutter_template/features/logs/domain/form_feedback.dart';

/// Shows [feedback] for [exerciseName] in a dialog.
Future<void> showFormFeedback(
  BuildContext context,
  FormFeedbackModel feedback,
  String exerciseName,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _FormFeedbackDialog(
      feedback: feedback,
      exerciseName: exerciseName,
    ),
  );
}

/// The form-check feedback dialog: score, summary, cues, and encouragement.
class _FormFeedbackDialog extends StatelessWidget {
  const _FormFeedbackDialog({
    required this.feedback,
    required this.exerciseName,
  });

  final FormFeedbackModel feedback;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Text('✨ '),
          Expanded(
            child: Text('Form check', style: theme.textTheme.titleLarge),
          ),
          _ScoreBadge(score: feedback.score),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              exerciseName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (feedback.summary.isNotEmpty)
              Text(feedback.summary, style: theme.textTheme.bodyLarge),
            if (feedback.cues.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Try this next time', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              for (final cue in feedback.cues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(cue, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
            if (feedback.encouragement.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                feedback.encouragement,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'General movement guidance, not medical advice.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// The rounded "N/10" score chip in the dialog title.
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score/10',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
