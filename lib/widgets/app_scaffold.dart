import 'package:flutter/material.dart';

import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/widgets/dismiss_keyboard.dart';

/// Creak's standard screen shell.
///
/// Paints the warm brand gradient full-bleed behind a transparent [Scaffold]
/// and wraps [body] in a `SafeArea` with a 16px minimum inset. Every screen
/// in the app composes this instead of building its own [Scaffold], so inset
/// handling and background treatment stay in one place.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  /// Screen content, laid out inside the safe area.
  final Widget body;

  /// Optional app bar title. When null no app bar is shown.
  final String? title;

  /// Optional app bar actions, ignored when [title] is null.
  final List<Widget>? actions;

  /// Optional FAB forwarded to the underlying [Scaffold].
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CreakColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.backgroundGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null
            ? null
            : AppBar(
                title: Text(title!),
                scrolledUnderElevation: 0,
                actions: actions,
              ),
        floatingActionButton: floatingActionButton,
        body: DismissKeyboard(
          child: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: body,
          ),
        ),
      ),
    );
  }
}
