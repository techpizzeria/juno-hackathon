import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive circular progress indicator.
///
/// Thin wrapper over [CircularProgressIndicator.adaptive] so call sites never
/// pick a platform variant themselves.
class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

/// Platform-adaptive switch.
///
/// Thin wrapper over [Switch.adaptive] so call sites never pick a platform
/// variant themselves.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value on toggle.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(value: value, onChanged: onChanged);
  }
}

/// Shows a platform-adaptive confirm dialog and returns true when confirmed.
///
/// Renders [AlertDialog.adaptive] with Cancel/[confirmLabel] actions; pass
/// [destructive] for delete-style confirmations so the confirm action is
/// styled accordingly on iOS.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final isCupertino =
          Theme.of(dialogContext).platform == TargetPlatform.iOS;
      Widget action({
        required String label,
        required bool result,
        bool isDestructive = false,
      }) {
        void submit() => Navigator.pop(dialogContext, result);
        if (isCupertino) {
          return CupertinoDialogAction(
            onPressed: submit,
            isDestructiveAction: isDestructive,
            child: Text(label),
          );
        }
        return TextButton(onPressed: submit, child: Text(label));
      }

      return AlertDialog.adaptive(
        title: Text(title),
        content: Text(message),
        actions: [
          action(label: 'Cancel', result: false),
          action(
            label: confirmLabel,
            result: true,
            isDestructive: destructive,
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
