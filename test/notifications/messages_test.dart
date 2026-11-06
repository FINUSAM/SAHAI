import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/notifications/planner.dart';
import 'package:sahai/notifications/reminders.dart';

import '../engine/engine_helpers.dart';

/// How reminders read (PRD 7, frame 13).
void main() {
  final eightAm = now.add(const Duration(hours: 17));

  List<ReminderMessage> messages(Map<String, DateTime> setAside) {
    final tree = sampleTree(setAside: setAside).build();
    return messagesFor(
      tree,
      planNotifications(tree, now: now, settings: const AppSettings()),
    );
  }

  test('AT-051 one item is named, with its path, and opens that item', () {
    final m = messages({'s1.1': eightAm}).single;
    expect(m.title, 's1.1 is back');
    expect(m.body, 'biztras › relaunch › 1. t1');
    expect(m.lines, isEmpty);
    expect(m.nodeId, 's1.1');
    expect(m.at, eightAm);
  });

  test('AT-050 several at once are counted and listed, and open the '
      'Summary', () {
    final m = messages({'s1.1': eightAm, 'A': eightAm}).single;
    expect(m.title, '2 items are back');
    expect(m.body, 's1.1, A');
    expect(m.lines, ['s1.1', 'A']);
    expect(m.nodeId, isNull);
  });

  test('AT-052 each moment gets its own id', () {
    final ms = messages({
      's1.1': eightAm,
      'A': eightAm.add(const Duration(hours: 1)),
    });
    expect(ms.map((m) => m.id), [0, 1]);
  });
}
