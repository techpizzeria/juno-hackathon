import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/utils/ids.dart';

void main() {
  test('fnv1a32 is deterministic and matches known vectors', () {
    // Standard FNV-1a test vectors.
    expect(fnv1a32(''), 0x811c9dc5);
    expect(fnv1a32('a'), 0xe40c292c);
    expect(fnv1a32('foobar'), 0xbf9cf968);
    expect(fnv1a32('creak'), fnv1a32('creak'));
  });

  test('notification ids are positive int32 and slot-distinct', () {
    final a = notificationId('program-1', 'slot-1');
    final b = notificationId('program-1', 'slot-2');
    final c = notificationId('program-2', 'slot-1');
    final snooze = snoozeNotificationId('program-1');

    for (final id in [a, b, c, snooze]) {
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    }
    expect({a, b, c, snooze}, hasLength(4));
    expect(notificationId('program-1', 'slot-1'), a);
  });
}
