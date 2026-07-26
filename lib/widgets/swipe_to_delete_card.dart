import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

/// Wraps a card so it can be swiped left to reveal an iOS-style delete
/// button. The button is a small, soft-red rounded square set apart from the
/// card by a gap. Deletion always runs through [confirmDelete] first.
///
/// Use this for every deletable card so the gesture, spacing, and colour stay
/// consistent across the app.
class SwipeToDeleteCard extends StatelessWidget {
  const SwipeToDeleteCard({
    required this.itemKey,
    required this.confirmDelete,
    required this.onDeleted,
    required this.child,
    super.key,
  });

  /// Stable identity for the underlying slidable.
  final Key itemKey;

  /// Asks the user to confirm; resolves true to proceed with deletion.
  final Future<bool> Function() confirmDelete;

  /// Performs the deletion once confirmed.
  final VoidCallback onDeleted;

  /// The card to wrap.
  final Widget child;

  Future<void> _delete() async {
    if (await confirmDelete()) onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Slidable(
      key: itemKey,
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.26,
        children: [
          CustomSlidableAction(
            onPressed: (_) => unawaited(_delete()),
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            child: Padding(
              // Gap between the card and the button.
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: scheme.error,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
