import 'package:flutter/material.dart';

/// Dismisses the on-screen keyboard when the user taps outside a text field.
///
/// Wrap a screen or sheet body in this so tapping empty space unfocuses the
/// current field. Every screen gets it for free via `AppScaffold`.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({required this.child, super.key});

  /// The content to wrap.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
