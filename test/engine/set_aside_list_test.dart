import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/set_aside_list.dart';

import 'engine_helpers.dart';

/// What the Set-Aside page lists (PRD 8.3).
void main() {
  final tonight = now.add(const Duration(hours: 5));
  final tomorrow = now.add(const Duration(hours: 17));
  final nextWeek = now.add(const Duration(days: 6));

  List<(String, DateTime)> listed(Map<String, DateTime> setAside) => [
    for (final e in setAsideEntries(
      sampleTree(setAside: setAside).build(),
      now: now,
    ))
      (e.node.id, e.wakeAt),
  ];

  test('AT-046 every item set aside, soonest first', () {
    expect(listed({'admin': nextWeek, 's1.1': tonight, 't2': tomorrow}), [
      ('s1.1', tonight),
      ('t2', tomorrow),
      ('admin', nextWeek),
    ]);
  });

  test('AT-047 something under a set-aside ancestor is listed under it', () {
    expect(listed({'relaunch': nextWeek, 's1.1': tonight, 't1': tomorrow}), [
      ('relaunch', nextWeek),
    ]);
    expect(listed({'biztras': nextWeek, 'admin': tonight}), [
      ('biztras', nextWeek),
    ]);
  });

  test('a passed wake time is not listed', () {
    expect(
      listed({'s1.1': now, 'A': now.subtract(const Duration(hours: 1))}),
      isEmpty,
    );
  });

  test('an entry hides its TODO children and any containers', () {
    final tree = sampleTree(
      aDone: true,
      setAside: {'admin': nextWeek, 'biztras': nextWeek},
    ).build();
    final domain = setAsideEntries(tree, now: now).single;
    expect(domain.hidden.map((n) => n.id), ['relaunch', 'admin']);
    final b = TreeBuilder()
      ..add(NodeType.domain, 'd')
      ..add(NodeType.stream, 's', parent: 'd', snoozeUntil: nextWeek)
      ..add(NodeType.streamItem, 'done', parent: 's', done: true)
      ..add(NodeType.streamItem, 'todo', parent: 's');
    final stream = setAsideEntries(b.build(), now: now).single;
    expect(stream.hidden.map((n) => n.id), ['todo']);
  });

  test('wakeTimeOf and setAsideAncestor', () {
    final tree = sampleTree(setAside: {'t1': tomorrow}).build();
    expect(wakeTimeOf(tree['t1']!, now), tomorrow);
    expect(wakeTimeOf(tree['t1']!, tomorrow), isNull);
    expect(setAsideAncestor(tree, 's1.1', now)?.id, 't1');
    expect(setAsideAncestor(tree, 't1', now), isNull);
  });
}
