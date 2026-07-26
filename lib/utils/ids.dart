import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Returns a fresh v4 UUID for domain object identity.
String newId() => _uuid.v4();

/// FNV-1a 32-bit hash of [input].
///
/// Used for deterministic notification ids; implemented in-repo because
/// `String.hashCode` is not guaranteed stable across Dart SDK versions.
int fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Deterministic notification id for a program's schedule slot.
///
/// Masked to a positive int32 as required by the notifications plugin. The
/// same (program, slot) pair always maps to the same id, so re-scheduling
/// replaces rather than duplicates.
int notificationId(String programId, String slotId) =>
    fnv1a32('$programId|$slotId') & 0x7FFFFFFF;

/// Deterministic notification id for a program's snoozed one-off reminder.
int snoozeNotificationId(String programId) =>
    fnv1a32('$programId|snooze') & 0x7FFFFFFF;
