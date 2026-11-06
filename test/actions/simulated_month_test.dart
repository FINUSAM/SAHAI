import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/visibility.dart';
import 'package:sahai/shared/time_format.dart';

import '../helpers.dart';

/// PRD 16's gate for M4: the four credit card bills in PRD 7 behave correctly
/// through a full month. The fake clock walks every day from Nov 1 to Jan 1 at
/// 10:00 AM, checks the whole Summary against a hand-written calendar, then
/// does what the script says for that day:
///
/// - HDFC, due the 5th: paid late on Nov 10, early on Dec 4.
/// - SBI, due the 12th: paid on the due date both months.
/// - ICICI, due the 18th: November skipped on the 16th, December paid on the
///   20th.
/// - Axis, due the 25th: November missed. Paid on Dec 27, which pays the
///   Nov 25 occurrence, so Dec 25's shows straight away, and that is paid on
///   Dec 28.
void main() {
  test('the four bills behave through a full simulated month', () async {
    final app = TestApp(clock: TestClock(DateTime(2026, 11, 1, 10)));
    addTearDown(app.close);
    final actions = app.actions;

    final personal = await actions.create(
      type: NodeType.domain,
      title: 'Personal',
    );
    final finance = await actions.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Finance & Bills',
    );
    Future<String> bill(String title, int day) async {
      final id = await actions.create(
        type: NodeType.streamItem,
        parentId: finance,
        title: title,
      );
      await actions.setRecurrence(
        id,
        Schedule.monthly(day: day),
        dueOn: DateTime(2026, 11, day),
      );
      return id;
    }

    final hdfc = await bill('Pay HDFC card', 5);
    final sbi = await bill('Pay SBI card', 12);
    final icici = await bill('Pay ICICI card', 18);
    final axis = await bill('Pay Axis card', 25);

    // First and last day each card is on the Summary at 10:00 AM. A card
    // still shows on the day it's paid, because the check comes first.
    final calendar = <String, List<(DateTime, DateTime)>>{
      hdfc: [
        (DateTime(2026, 11, 2), DateTime(2026, 11, 10)),
        (DateTime(2026, 12, 2), DateTime(2026, 12, 4)),
      ],
      sbi: [
        (DateTime(2026, 11, 9), DateTime(2026, 11, 12)),
        (DateTime(2026, 12, 9), DateTime(2026, 12, 12)),
      ],
      icici: [
        (DateTime(2026, 11, 15), DateTime(2026, 11, 16)),
        (DateTime(2026, 12, 15), DateTime(2026, 12, 20)),
      ],
      axis: [(DateTime(2026, 11, 22), DateTime(2026, 12, 28))],
    };

    final script = <DateTime, Future<void> Function()>{
      DateTime(2026, 11, 10): () => actions.markDone(hdfc),
      DateTime(2026, 11, 12): () => actions.markDone(sbi),
      DateTime(2026, 11, 16): () => actions.skipOccurrence(icici),
      DateTime(2026, 12, 4): () => actions.markDone(hdfc),
      DateTime(2026, 12, 12): () => actions.markDone(sbi),
      DateTime(2026, 12, 20): () => actions.markDone(icici),
      DateTime(2026, 12, 27): () => actions.markDone(axis),
      DateTime(2026, 12, 28): () => actions.markDone(axis),
    };

    // Labels at 10:00 AM on the days that show each rule.
    final labels = <(DateTime, String), String>{
      (DateTime(2026, 11, 2), hdfc): 'Due Nov 5',
      (DateTime(2026, 11, 5), hdfc): 'Due today',
      (DateTime(2026, 11, 6), hdfc): '1 day overdue',
      (DateTime(2026, 11, 9), hdfc): '4 days overdue',
      (DateTime(2026, 11, 9), sbi): 'Due Nov 12',
      (DateTime(2026, 11, 12), sbi): 'Due today',
      (DateTime(2026, 11, 25), axis): 'Due today',
      (DateTime(2026, 12, 2), hdfc): 'Due Dec 5',
      (DateTime(2026, 12, 15), icici): 'Due Dec 18',
      (DateTime(2026, 12, 26), axis): '31 days overdue',
      (DateTime(2026, 12, 28), axis): '3 days overdue',
    };

    bool shows(String id, DateTime day) => calendar[id]!.any(
      (range) => !day.isBefore(range.$1) && !day.isAfter(range.$2),
    );

    for (
      var day = DateTime(2026, 11, 1);
      !day.isAfter(DateTime(2027, 1, 1));
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      app.clock.now = DateTime(day.year, day.month, day.day, 10);
      await actions.recompute();
      final summary = computeSummary(
        await actions.loadTree(),
        now: app.clock.now,
      );
      expect(summary.visibleIds, {
        for (final id in [hdfc, sbi, icici, axis])
          if (shows(id, day)) id,
      }, reason: 'Summary on $day');
      for (final card in summary.cards) {
        final expected = labels[(day, card.id)];
        if (expected == null) continue;
        expect(
          dueLabel(card.node.dueOn!, app.clock.now),
          expected,
          reason: '${card.node.title} on $day',
        );
      }
      await script[day]?.call();
    }

    final tree = await actions.loadTree();
    expect(tree[hdfc]!.dueOn, DateTime(2027, 1, 5));
    expect(tree[sbi]!.dueOn, DateTime(2027, 1, 12));
    expect(tree[icici]!.dueOn, DateTime(2027, 1, 18));
    expect(tree[axis]!.dueOn, DateTime(2027, 1, 25));
    expect(tree[hdfc]!.isTodo, isTrue);

    final log = await app.db.select(app.db.events).get();
    List<String> dueDates(String type, String id) => [
      for (final e in log)
        if (e.eventType == type && e.nodeId == id)
          (jsonDecode(e.payload) as Map<String, Object?>)['due_on']! as String,
    ];
    // Only appearances once the month starts: each item also appears as a
    // normal card when it's created, before it gets its schedule.
    final start = DateTime(2026, 11, 1, 10).toUtc().millisecondsSinceEpoch;
    int surfaced(String id) => log
        .where(
          (e) =>
              e.eventType == EventTypes.surfaced &&
              e.nodeId == id &&
              e.occurredAt > start,
        )
        .length;

    expect(dueDates(EventTypes.completed, hdfc), ['2026-11-05', '2026-12-05']);
    expect(dueDates(EventTypes.completed, sbi), ['2026-11-12', '2026-12-12']);
    expect(dueDates(EventTypes.completed, icici), ['2026-12-18']);
    expect(dueDates(EventTypes.skipped, icici), ['2026-11-18']);
    expect(dueDates(EventTypes.completed, axis), ['2026-11-25', '2026-12-25']);
    expect(surfaced(hdfc), 2);
    expect(surfaced(sbi), 2);
    expect(surfaced(icici), 2);
    expect(surfaced(axis), 1);
  });
}
