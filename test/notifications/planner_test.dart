import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/notifications/planner.dart';

import '../engine/engine_helpers.dart';

/// Which reminders get scheduled (PRD 7, tech plan 7). The engine's trees
/// and the AT sheet's reference time: Tuesday, Nov 3, 3:00 PM UTC.
void main() {
  const on = AppSettings();
  final eightAm = now.add(const Duration(hours: 17));
  final nineAm = now.add(const Duration(hours: 18));
  final nextWeek = now.add(const Duration(days: 6));

  /// "2026-11-04T08:00:00.000Z: A, B", one per notification.
  String at(DateTime time, List<String> ids) =>
      '${time.toIso8601String()}: ${ids.join(', ')}';

  List<String> plan(TreeBuilder b, {AppSettings settings = on}) => [
    for (final n in planNotifications(b.build(), now: now, settings: settings))
      at(n.at, [for (final c in n.cards) c.id]),
  ];

  /// Personal › Home stream with one item, plus two more streams.
  TreeBuilder streams({
    Map<String, DateTime> setAside = const {},
    Set<String> quiet = const {},
  }) {
    final b = TreeBuilder();
    b.add(NodeType.domain, 'personal', snoozeUntil: setAside['personal']);
    for (final (stream, item) in [
      ('home', 'Call Rahul'),
      ('errands', 'Buy stamps'),
      ('health', 'Find a dentist'),
    ]) {
      b.add(NodeType.stream, stream, parent: 'personal');
      b.add(
        NodeType.streamItem,
        item,
        parent: stream,
        snoozeUntil: setAside[item],
        remind: !quiet.contains(item),
      );
    }
    return b;
  }

  test('nothing set aside, nothing planned', () {
    expect(plan(streams()), isEmpty);
  });

  test('AT-051 a single waking item is named on its own', () {
    final result = planNotifications(
      streams(setAside: {'Call Rahul': nineAm}).build(),
      now: now,
      settings: on,
    );
    expect(result.single.at, nineAm);
    expect(result.single.grouped, isFalse);
    expect(result.single.cards.single.node.title, 'Call Rahul');
    expect(result.single.cards.single.path.map((p) => p.id), [
      'personal',
      'home',
    ]);
  });

  test('AT-050 items waking at the same time share one notification', () {
    final result = plan(
      streams(
        setAside: {
          'Call Rahul': eightAm,
          'Buy stamps': eightAm,
          'Find a dentist': eightAm,
        },
      ),
    );
    expect(result, [
      at(eightAm, ['Call Rahul', 'Buy stamps', 'Find a dentist']),
    ]);
  });

  test('AT-052 different wake times notify separately', () {
    expect(
      plan(streams(setAside: {'Call Rahul': eightAm, 'Buy stamps': nineAm})),
      [
        at(eightAm, ['Call Rahul']),
        at(nineAm, ['Buy stamps']),
      ],
    );
  });

  test('AT-053 Remind me off wakes quietly', () {
    expect(
      plan(
        streams(
          setAside: {'Call Rahul': eightAm, 'Buy stamps': eightAm},
          quiet: {'Call Rahul'},
        ),
      ),
      [
        at(eightAm, ['Buy stamps']),
      ],
    );
  });

  test('AT-054 no notification while still hidden by a set-aside domain', () {
    final b = streams(setAside: {'Call Rahul': nineAm, 'personal': nextWeek});
    // Nothing at 9 AM; when the domain wakes, everything in it comes back
    // and notifies, as one group.
    expect(plan(b), [
      at(nextWeek, ['Call Rahul', 'Buy stamps', 'Find a dentist']),
    ]);
  });

  test('a quiet domain brings its items back quietly', () {
    final b = TreeBuilder()
      ..add(NodeType.domain, 'd', snoozeUntil: nextWeek, remind: false)
      ..add(NodeType.stream, 's', parent: 'd')
      ..add(NodeType.streamItem, 'i', parent: 's');
    expect(plan(b), isEmpty);
  });

  test('AT-056 nothing is planned with notifications off', () {
    expect(
      plan(
        streams(setAside: {'Call Rahul': eightAm}),
        settings: const AppSettings(notificationsEnabled: false),
      ),
      isEmpty,
    );
  });

  test('a waking subtask that replaces the visible one notifies (AT-034)', () {
    final b = sampleTree(setAside: {'s1.1': eightAm});
    expect(plan(b), [
      at(eightAm, ['s1.1']),
    ]);
  });

  test('a wake that changes nothing on the Summary is skipped', () {
    // 1.2 is behind 1.1, which is showing.
    expect(plan(sampleTree(setAside: {'s1.2': eightAm})), isEmpty);
  });

  test('the plan stops at 60 days', () {
    expect(
      plan(
        streams(
          setAside: {
            'Call Rahul': now.add(const Duration(days: 59)),
            'Buy stamps': now.add(const Duration(days: 61)),
          },
        ),
      ),
      [
        at(now.add(const Duration(days: 59)), ['Call Rahul']),
      ],
    );
  });

  test('the plan is capped at 100 notifications', () {
    final b = TreeBuilder()..add(NodeType.domain, 'd');
    for (var i = 0; i < 120; i++) {
      b.add(NodeType.stream, 's$i', parent: 'd');
      b.add(
        NodeType.streamItem,
        'i$i',
        parent: 's$i',
        snoozeUntil: now.add(Duration(hours: i + 1)),
      );
    }
    final result = plan(b);
    expect(result, hasLength(maxPlanned));
    expect(result.last, at(now.add(const Duration(hours: 100)), ['i99']));
  });
}
