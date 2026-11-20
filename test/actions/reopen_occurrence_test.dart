import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/data/log_retention.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/visibility.dart';
import 'package:sahai/shared/time_format.dart';

import '../helpers.dart';

/// Reopen last completion and Reopen last skip on a repeating item
/// (PRD 7, 9; E-018). Local time, as the rules are: Pay HDFC card is due
/// on the 5th of each month and shows 3 days early.
void main() {
  late TestApp app;
  late NodeActions actions;
  late String hdfc;

  DateTime nov(int day, [int hour = 10]) => DateTime(2026, 11, day, hour);

  setUp(() async {
    app = TestApp(clock: TestClock(nov(4)));
    actions = app.actions;
    final personal = await actions.create(
      type: NodeType.domain,
      title: 'Personal',
    );
    final finance = await actions.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Finance & Bills',
    );
    hdfc = await actions.create(
      type: NodeType.streamItem,
      parentId: finance,
      title: 'Pay HDFC card',
      schedule: Schedule.monthly(day: 5),
      dueOn: DateTime(2026, 11, 5),
    );
  });

  tearDown(() => app.close());

  Future<void> goTo(DateTime at) async {
    app.clock.now = at;
    await actions.recompute();
  }

  Future<DateTime> dueOn() async => (await actions.loadTree())[hdfc]!.dueOn!;

  Future<List<EventRow>> events(String type) =>
      (app.db.select(app.db.events)
            ..where((e) => e.eventType.equals(type))
            ..orderBy([(e) => OrderingTerm.asc(e.rowId)]))
          .get();

  Map<String, Object?> payload(EventRow event) =>
      jsonDecode(event.payload) as Map<String, Object?>;

  Future<List<String>> summary() async => (computeSummary(
    await actions.loadTree(),
    now: app.clock.now,
  )).cards.map((c) => c.id).toList();

  test('AT-125 Reopen last completion brings back the old due date and '
      'logs a reopened event that cancels the completion', () async {
    await goTo(nov(7));
    await actions.markDone(hdfc);
    expect(await dueOn(), DateTime(2026, 12, 5));
    expect(await summary(), isEmpty);

    final offered = (await actions.reopenableOccurrences())[hdfc]!;
    expect(offered.skipped, isFalse);
    expect(offered.on, DateTime(2026, 11, 7));
    expect(offered.dueOn, DateTime(2026, 11, 5));

    await actions.reopenOccurrence(hdfc);
    expect(await dueOn(), DateTime(2026, 11, 5));
    expect(await summary(), [hdfc]);
    expect(dueLabel(await dueOn(), app.clock.now), '2 days overdue');

    final completed = (await events(EventTypes.completed)).single;
    final reopened = (await events(EventTypes.reopened)).single;
    expect(reopened.nodeId, hdfc);
    expect(payload(reopened), {
      'undoes_event_id': completed.eventId,
      'due_on': '2026-11-05',
    });
    // It came back on purpose, so it surfaces again (unlike Undo).
    expect((await events(EventTypes.surfaced)).last.nodeId, hdfc);

    // Finished again, the next date is worked out again: still Dec 5.
    await actions.markDone(hdfc);
    expect(await dueOn(), DateTime(2026, 12, 5));
  });

  test('AT-126 Reopen last skip brings the skipped occurrence back', () async {
    await goTo(nov(4));
    await actions.skipOccurrence(hdfc);
    expect(await dueOn(), DateTime(2026, 12, 5));
    final offered = (await actions.reopenableOccurrences())[hdfc]!;
    expect(offered.skipped, isTrue);

    await actions.reopenOccurrence(hdfc);
    expect(await dueOn(), DateTime(2026, 11, 5));
    expect(await summary(), [hdfc]);
    final skipped = (await events(EventTypes.skipped)).single;
    expect(
      payload((await events(EventTypes.reopened)).single)['undoes_event_id'],
      skipped.eventId,
    );
  });

  test('AT-127 only the latest can be reopened, and only once; a new '
      'completion after it can be reopened in turn', () async {
    await goTo(nov(7));
    await actions.markDone(hdfc);
    await goTo(DateTime(2026, 12, 5, 10));
    await actions.markDone(hdfc);
    expect(await dueOn(), DateTime(2027, 1, 5));

    final offered = (await actions.reopenableOccurrences())[hdfc]!;
    expect(offered.dueOn, DateTime(2026, 12, 5));

    await actions.reopenOccurrence(hdfc);
    expect(await dueOn(), DateTime(2026, 12, 5));
    // Nov 5's completion is never offered.
    expect(await actions.reopenableOccurrences(), isEmpty);
    await expectLater(
      actions.reopenOccurrence(hdfc),
      throwsA(
        isA<ActionRejected>().having(
          (e) => e.reason,
          'reason',
          RejectReason.nothingToReopen,
        ),
      ),
    );

    // Finished again, that new completion can be reopened (owner's choice C).
    await actions.markDone(hdfc);
    expect(
      (await actions.reopenableOccurrences())[hdfc]!.dueOn,
      DateTime(2026, 12, 5),
    );
  });

  test('nothing is offered after Undo, after Next due is changed, or once '
      'it stops repeating', () async {
    await goTo(nov(7));
    final token = await actions.markDone(hdfc);
    await actions.undoComplete(token);
    expect(await actions.reopenableOccurrences(), isEmpty);

    await actions.markDone(hdfc);
    await actions.setRecurrence(
      hdfc,
      Schedule.monthly(day: 5),
      dueOn: DateTime(2027, 1, 5),
    );
    expect(await actions.reopenableOccurrences(), isEmpty);

    // Changing it back doesn't revive a completion already cancelled by
    // Undo: the latest one is the second, which is offered again.
    await actions.setRecurrence(
      hdfc,
      Schedule.monthly(day: 5),
      dueOn: DateTime(2026, 12, 5),
    );
    expect((await actions.reopenableOccurrences())[hdfc], isNotNull);

    await actions.stopRepeating(hdfc);
    expect(await actions.reopenableOccurrences(), isEmpty);
  });

  test('a completion cancelled by Undo is never offered, even if the due '
      'date is put back by hand', () async {
    await goTo(nov(7));
    final token = await actions.markDone(hdfc);
    await actions.undoComplete(token);
    await actions.setRecurrence(
      hdfc,
      Schedule.monthly(day: 5),
      dueOn: DateTime(2026, 12, 5),
    );
    expect(await actions.reopenableOccurrences(), isEmpty);
  });

  test('reopening a completion made while set aside puts the set aside '
      'back too, as it was before the tick', () async {
    await goTo(nov(4));
    final until = nov(9, 8);
    await actions.setAside(hdfc, until);
    await actions.markDone(hdfc);
    await actions.reopenOccurrence(hdfc);
    final node = (await actions.loadTree())[hdfc]!;
    expect(node.dueOn, DateTime(2026, 11, 5));
    expect(node.snoozeUntil!.isAtSameMomentAs(until), isTrue);
  });

  test('a completion more than 12 months old can still be reopened, because '
      'compaction keeps it (decision 0009)', () async {
    await goTo(nov(7));
    await actions.markDone(hdfc);
    // Stop repeating would clear it, so the bill just goes unpaid for
    // 13 months.
    await goTo(DateTime(2027, 12, 10, 10));
    await compactEventLog(app.db, clock: app.clock.clock);
    expect(await events(EventTypes.completed), hasLength(1));
    await actions.reopenOccurrence(hdfc);
    expect(await dueOn(), DateTime(2026, 11, 5));
  });
}
