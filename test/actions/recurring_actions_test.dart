import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/set_aside_list.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/engine/tree.dart';
import 'package:sahai/engine/visibility.dart';
import 'package:sahai/shared/time_format.dart';

import '../helpers.dart';

/// Recurring items through the actions, and what the activity log records
/// (PRD 7, 9; E-001, E-005, E-011). Times are local, as the rules are.
void main() {
  late TestApp app;
  late NodeActions actions;
  late String personal, finance, home, hdfc;

  DateTime on(int day, [int hour = 10, int minute = 0]) =>
      DateTime(2026, 11, day, hour, minute);

  setUp(() async {
    // Nov 1, before HDFC appears on the 2nd.
    app = TestApp(clock: TestClock(on(1)));
    actions = app.actions;
    personal = await actions.create(type: NodeType.domain, title: 'Personal');
    finance = await actions.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Finance & Bills',
    );
    home = await actions.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Home',
    );
    hdfc = await actions.create(
      type: NodeType.streamItem,
      parentId: finance,
      title: 'Pay HDFC card',
    );
    await actions.setRecurrence(
      hdfc,
      Schedule.monthly(day: 5),
      dueOn: DateTime(2026, 11, 5),
    );
  });

  tearDown(() => app.close());

  Future<SummaryResult> summary() async =>
      computeSummary(await actions.loadTree(), now: app.clock.now);

  Future<List<String>> visible() async =>
      (await summary()).cards.map((c) => c.id).toList();

  Future<String> label(String id) async {
    final card = (await summary()).cards.singleWhere((c) => c.id == id);
    return dueLabel(card.node.dueOn!, app.clock.now);
  }

  Future<TreeNode> node(String id) async => (await actions.loadTree())[id]!;

  Future<List<EventRow>> events(String type) =>
      (app.db.select(app.db.events)
            ..where((e) => e.eventType.equals(type))
            ..orderBy([(e) => OrderingTerm.asc(e.rowId)]))
          .get();

  Map<String, Object?> payload(EventRow event) =>
      jsonDecode(event.payload) as Map<String, Object?>;

  Future<void> goTo(DateTime at) async {
    app.clock.now = at;
    await actions.recompute();
  }

  Future<String> bill(String title, int day, {String? stream}) async {
    final id = await actions.create(
      type: NodeType.streamItem,
      parentId: stream ?? finance,
      title: title,
    );
    await actions.setRecurrence(
      id,
      Schedule.monthly(day: day),
      dueOn: DateTime(2026, 11, day),
    );
    return id;
  }

  test(
    'AT-061 it appears at the start of the day, 3 days before due',
    () async {
      expect(await visible(), isEmpty);
      await goTo(on(2, 3, 59));
      expect(await visible(), isEmpty);
      await goTo(on(2, 4));
      expect(await visible(), [hdfc]);
      expect(await label(hdfc), 'Due Nov 5');
    },
  );

  test('AT-062 the card reads Due today all of the due day', () async {
    await goTo(on(5, 9));
    expect(await label(hdfc), 'Due today');
    await goTo(on(6, 3, 59));
    expect(await label(hdfc), 'Due today');
  });

  test('AT-063 overdue begins at the next day start', () async {
    await goTo(on(6, 4));
    expect(await label(hdfc), '1 day overdue');
    await goTo(on(9));
    expect(await label(hdfc), '4 days overdue');
  });

  test("AT-064 an unpaid bill doesn't hide the next", () async {
    final sbi = await bill('Pay SBI card', 12);
    await goTo(on(9));
    expect(await visible(), [hdfc, sbi]);
    expect(await label(hdfc), '4 days overdue');
    expect(await label(sbi), 'Due Nov 12');
  });

  test('AT-065 recurring items never block normal items', () async {
    final electricity = await bill('Electricity bill', 5, stream: home);
    final tap = await actions.create(
      type: NodeType.streamItem,
      parentId: home,
      title: 'Fix the tap',
    );
    final curtains = await actions.create(
      type: NodeType.streamItem,
      parentId: home,
      title: 'Buy curtains',
    );
    await goTo(on(5));
    final cards = await visible();
    expect(cards, containsAll([electricity, tap]));
    expect(cards, isNot(contains(curtains)));
  });

  test('AT-066 completing schedules the next occurrence', () async {
    await goTo(on(3));
    await actions.markDone(hdfc);
    expect(await visible(), isEmpty);
    expect((await node(hdfc)).isTodo, isTrue);
    expect((await node(hdfc)).dueOn, DateTime(2026, 12, 5));
    await goTo(DateTime(2026, 12, 2, 3, 59));
    expect(await visible(), isEmpty);
    await goTo(DateTime(2026, 12, 2, 4));
    expect(await visible(), [hdfc]);
  });

  test('AT-067 paying late keeps the schedule', () async {
    await goTo(on(7));
    await actions.markDone(hdfc);
    expect((await node(hdfc)).dueOn, DateTime(2026, 12, 5));
  });

  test('AT-068 a missed cycle shows straight away', () async {
    await goTo(DateTime(2026, 12, 10, 10));
    await actions.markDone(hdfc);
    expect(await visible(), [hdfc]);
    expect((await node(hdfc)).dueOn, DateTime(2026, 12, 5));
    expect(await label(hdfc), '5 days overdue');
  });

  test('AT-069 repeating from the completion date', () async {
    final haircut = await actions.create(
      type: NodeType.streamItem,
      parentId: home,
      title: 'Haircut',
    );
    await actions.setRecurrence(
      haircut,
      const Schedule.weekly(interval: 4, repeatFrom: RepeatFrom.completionDate),
      dueOn: on(9),
    );
    await goTo(on(10));
    await actions.markDone(haircut);
    expect((await node(haircut)).dueOn, DateTime(2026, 12, 8));
    await goTo(DateTime(2026, 12, 5, 3));
    expect(await visible(), isNot(contains(haircut)));
    await goTo(DateTime(2026, 12, 5, 4));
    expect(await visible(), contains(haircut));
  });

  test('repeating from completion uses the logical date', () async {
    final haircut = await actions.create(
      type: NodeType.streamItem,
      parentId: home,
      title: 'Haircut',
    );
    await actions.setRecurrence(
      haircut,
      const Schedule.weekly(interval: 4, repeatFrom: RepeatFrom.completionDate),
      dueOn: on(9),
    );
    // 1:30 AM on the 11th still counts as the 10th.
    await goTo(on(11, 1, 30));
    await actions.markDone(haircut);
    expect((await node(haircut)).dueOn, DateTime(2026, 12, 8));
  });

  test('AT-070 undo restores the occurrence', () async {
    await goTo(on(3));
    final surfacedBefore = (await events(EventTypes.surfaced)).length;
    final token = await actions.markDone(hdfc);
    await actions.undoComplete(token);
    expect(await visible(), [hdfc]);
    expect((await node(hdfc)).dueOn, DateTime(2026, 11, 5));
    // E-001: linked to the completion, with the due date it restored, and
    // no new `surfaced`.
    final undone = (await events(EventTypes.completionUndone)).single;
    expect(payload(undone)['undoes_event_id'], token);
    expect(payload(undone)['due_on'], '2026-11-05');
    expect(await events(EventTypes.completed), hasLength(1));
    expect(await events(EventTypes.surfaced), hasLength(surfacedBefore));
  });

  test('AT-071 skip moves on without logging a completion', () async {
    await goTo(on(3));
    await actions.skipOccurrence(hdfc);
    expect((await node(hdfc)).dueOn, DateTime(2026, 12, 5));
    expect(await visible(), isEmpty);
    expect(await events(EventTypes.completed), isEmpty);
    final skipped = (await events(EventTypes.skipped)).single;
    expect(payload(skipped)['due_on'], '2026-11-05');
  });

  test(
    'skipping follows the due date when repeating from completion',
    () async {
      final haircut = await actions.create(
        type: NodeType.streamItem,
        parentId: home,
        title: 'Haircut',
      );
      await actions.setRecurrence(
        haircut,
        const Schedule.weekly(
          interval: 4,
          repeatFrom: RepeatFrom.completionDate,
        ),
        dueOn: on(10),
      );
      await goTo(on(8));
      await actions.skipOccurrence(haircut);
      expect((await node(haircut)).dueOn, DateTime(2026, 12, 8));
    },
  );

  test('AT-072 setting aside keeps the schedule', () async {
    await goTo(on(2));
    await actions.setAside(hdfc, on(4, 8));
    await goTo(on(3));
    expect(await visible(), isEmpty);
    await goTo(on(4, 8));
    expect(await visible(), [hdfc]);
    expect(await label(hdfc), 'Due Nov 5');
    await actions.markDone(hdfc);
    expect((await node(hdfc)).dueOn, DateTime(2026, 12, 5));
  });

  test('AT-077 a completed recurring item is TODO, never DONE', () async {
    await goTo(on(3));
    await actions.markDone(hdfc);
    final row = await node(hdfc);
    expect(row.status, NodeStatus.todo);
    expect(row.isRecurring, isTrue);
    expect(row.dueOn, DateTime(2026, 12, 5));
  });

  test('AT-080 stop repeating makes it a normal stream item', () async {
    final tap = await actions.create(
      type: NodeType.streamItem,
      parentId: finance,
      title: 'Fix the tap',
    );
    await goTo(on(3));
    expect(await visible(), [hdfc, tap]);
    await actions.stopRepeating(hdfc);
    final row = await node(hdfc);
    expect(row.isRecurring, isFalse);
    expect(row.dueOn, isNull);
    expect(row.leadDays, isNull);
    // One card per stream again: the first item blocks the next.
    expect(await visible(), [hdfc]);
    await actions.markDone(hdfc);
    expect((await node(hdfc)).isDone, isTrue);
    expect(await visible(), [tap]);
  });

  test('AT-082 a recurring completion stores the due date', () async {
    await goTo(on(7));
    await actions.markDone(hdfc);
    final completed = (await events(EventTypes.completed)).single;
    expect(payload(completed)['due_on'], '2026-11-05');
  });

  group('E-001', () {
    test('undo after the occurrence moved on is refused', () async {
      await goTo(on(3));
      final first = await actions.markDone(hdfc);
      await goTo(DateTime(2026, 12, 3));
      await actions.markDone(hdfc);
      expect(
        () => actions.undoComplete(first),
        throwsA(
          isA<ActionRejected>().having(
            (e) => e.reason,
            'reason',
            RejectReason.staleUndo,
          ),
        ),
      );
    });

    test('undo puts a set aside and an override back', () async {
      await actions.wakeNow(hdfc);
      await actions.setAside(hdfc, on(1, 20));
      final until = (await node(hdfc)).snoozeUntil;
      final token = await actions.markDone(hdfc);
      expect((await node(hdfc)).snoozeUntil, isNull);
      expect((await node(hdfc)).snoozeOverridesShow, isFalse);
      await actions.undoComplete(token);
      expect((await node(hdfc)).snoozeUntil, until);
      expect((await node(hdfc)).snoozeOverridesShow, isTrue);
    });
  });

  group('E-005', () {
    Future<List<SetAsideEntry>> entries() async =>
        setAsideEntries(await actions.loadTree(), now: app.clock.now);

    test('a paid bill is listed until its show date', () async {
      await goTo(on(3));
      await actions.markDone(hdfc);
      final entry = (await entries()).single;
      expect(entry.node.id, hdfc);
      expect(entry.wakeAt, DateTime(2026, 12, 2, 4));
      await goTo(DateTime(2026, 12, 2, 4));
      expect(await entries(), isEmpty);
    });

    test('Wake now shows the real due label and keeps the schedule', () async {
      await goTo(on(3));
      await actions.markDone(hdfc);
      await actions.wakeNow(hdfc);
      expect(await visible(), [hdfc]);
      expect(await label(hdfc), 'Due Dec 5');
      expect(await entries(), isEmpty);
      final woke = (await events(EventTypes.woke)).single;
      expect(payload(woke)['cause'], WakeCause.wakeNow);
      await actions.markDone(hdfc);
      expect((await node(hdfc)).dueOn, DateTime(2027, 1, 5));
      expect(await visible(), isEmpty);
    });

    test('Change time moves only this occurrence, earlier or later', () async {
      await actions.changeWakeTime(hdfc, on(1, 20));
      expect((await entries()).single.wakeAt, on(1, 20).toUtc());
      await actions.changeWakeTime(hdfc, on(3, 9));
      expect((await entries()).single.wakeAt, on(3, 9).toUtc());
      await goTo(on(2, 4));
      expect(await visible(), isEmpty);
      await goTo(on(3, 9));
      expect(await visible(), [hdfc]);
      expect((await node(hdfc)).dueOn, DateTime(2026, 11, 5));
      // It stays awake once the new time passes, and the next occurrence
      // goes back to its own show date.
      await actions.markDone(hdfc);
      expect((await entries()).single.wakeAt, DateTime(2026, 12, 2, 4));
    });

    test('an earlier time keeps it showing before its show date', () async {
      await actions.changeWakeTime(hdfc, on(1, 20));
      await goTo(on(1, 20));
      expect(await visible(), [hdfc]);
      await goTo(on(1, 23));
      expect(await visible(), [hdfc]);
    });

    test('set aside as well, it is listed once at the later time', () async {
      await actions.setAside(hdfc, on(3, 8));
      expect((await entries()).single.wakeAt, on(3, 8).toUtc());
      await actions.setAside(hdfc, on(1, 20));
      expect((await entries()).single.wakeAt, DateTime(2026, 11, 2, 4));
    });

    test('under a set-aside stream it is listed under the stream', () async {
      await actions.setAside(finance, on(20, 8));
      final entry = (await entries()).single;
      expect(entry.node.id, finance);
      expect(entry.hidden.map((n) => n.id), [hdfc]);
    });

    test('Wake now and Change time still refuse what is awake', () async {
      await goTo(on(3));
      await expectLater(actions.wakeNow(hdfc), throwsA(isA<ActionRejected>()));
      await expectLater(
        actions.changeWakeTime(hdfc, on(4)),
        throwsA(isA<ActionRejected>()),
      );
    });
  });

  group('E-011', () {
    test(
      'undo of a skip restores the occurrence and links the event',
      () async {
        await goTo(on(3));
        final surfacedBefore = (await events(EventTypes.surfaced)).length;
        final token = await actions.skipOccurrence(hdfc);
        await actions.undoSkip(token);
        expect((await node(hdfc)).dueOn, DateTime(2026, 11, 5));
        expect(await visible(), [hdfc]);
        final undone = (await events(EventTypes.skipUndone)).single;
        expect(payload(undone)['undoes_event_id'], token);
        expect(payload(undone)['due_on'], '2026-11-05');
        expect(await events(EventTypes.skipped), hasLength(1));
        expect(await events(EventTypes.surfaced), hasLength(surfacedBefore));
      },
    );

    test('stopping logs what was cleared; undo puts it back', () async {
      await goTo(on(3));
      final before = await node(hdfc);
      final surfacedBefore = (await events(EventTypes.surfaced)).length;
      final token = await actions.stopRepeating(hdfc);
      final stopped = (await events(EventTypes.repeatStopped)).single;
      expect(payload(stopped)['due_on'], '2026-11-05');
      expect(payload(stopped)['lead_days'], 3);
      expect(payload(stopped)['recurrence'], before.schedule!.toJson());

      await actions.undoStopRepeating(token);
      final after = await node(hdfc);
      expect(after.isRecurring, isTrue);
      expect(after.dueOn, before.dueOn);
      expect(after.leadDays, before.leadDays);
      expect(after.schedule!.toJson(), before.schedule!.toJson());
      final restored = (await events(EventTypes.repeatRestored)).single;
      expect(payload(restored)['undoes_event_id'], token);
      expect(await events(EventTypes.surfaced), hasLength(surfacedBefore));
    });

    test('a stale undo is refused', () async {
      await goTo(on(3));
      final skip = await actions.skipOccurrence(hdfc);
      await actions.skipOccurrence(hdfc);
      await expectLater(actions.undoSkip(skip), throwsA(isA<ActionRejected>()));

      final stop = await actions.stopRepeating(hdfc);
      await actions.undoStopRepeating(stop);
      await expectLater(
        actions.undoStopRepeating(stop),
        throwsA(isA<ActionRejected>()),
      );
    });
  });

  test('a bill that appears while the app is closed is dated then', () async {
    await goTo(on(3));
    // The first is the item appearing as a normal card, before its schedule.
    final surfaced = (await events(EventTypes.surfaced)).last;
    expect(surfaced.nodeId, hdfc);
    expect(
      surfaced.occurredAt,
      DateTime(2026, 11, 2, 4).toUtc().millisecondsSinceEpoch,
    );
  });

  test('a card showing again is logged once per appearance', () async {
    await goTo(on(3));
    final before = (await events(EventTypes.surfaced)).length;
    await actions.recompute();
    expect(await events(EventTypes.surfaced), hasLength(before));
    await actions.markDone(hdfc);
    await goTo(DateTime(2026, 12, 3));
    expect(await events(EventTypes.surfaced), hasLength(before + 1));
  });

  group('nextChangeAt', () {
    test('includes the show time', () async {
      expect((await summary()).nextChangeAt, on(2, 4));
    });

    test('is the next day start while a due label shows', () async {
      await goTo(on(3));
      expect((await summary()).nextChangeAt, on(4, 4));
    });

    test('a set aside sooner than the day start comes first', () async {
      final tap = await actions.create(
        type: NodeType.streamItem,
        parentId: home,
        title: 'Fix the tap',
      );
      await goTo(on(3));
      await actions.setAside(tap, on(3, 20));
      expect((await summary()).nextChangeAt, on(3, 20).toUtc());
    });
  });

  test('settings move the show time', () async {
    final tree = await actions.loadTree();
    final sixAm = on(2, 5);
    expect(computeSummary(tree, now: sixAm).visibleIds, {hdfc});
    expect(
      computeSummary(
        tree,
        now: sixAm,
        settings: const AppSettings(dayStartMinutes: 6 * 60),
      ).visibleIds,
      isEmpty,
    );
  });

  group('setRecurrence', () {
    test('uses the default lead from Settings', () async {
      await (app.db.update(app.db.settingsTable))
          .write(const SettingsTableCompanion(defaultLeadDays: Value(5)));
      final id = await bill('Pay rent', 20);
      expect((await node(id)).leadDays, 5);
    });

    test('keeps a lead the user chose', () async {
      final id = await actions.create(
        type: NodeType.streamItem,
        parentId: home,
        title: 'Pay rent',
      );
      await actions.setRecurrence(
        id,
        Schedule.monthly(day: 3),
        dueOn: on(3),
        leadDays: 0,
      );
      expect((await node(id)).leadDays, 0);
      await goTo(on(3, 3, 59));
      expect(await visible(), isNot(contains(id)));
      await goTo(on(3, 4));
      expect(await visible(), contains(id));
    });

    test('only a TODO stream item can repeat', () async {
      await expectLater(
        actions.setRecurrence(finance, Schedule.monthly(day: 5), dueOn: on(5)),
        throwsA(
          isA<ActionRejected>().having(
            (e) => e.reason,
            'reason',
            RejectReason.cantRepeat,
          ),
        ),
      );
      final done = await actions.create(
        type: NodeType.streamItem,
        parentId: home,
        title: 'Old item',
      );
      await actions.markDone(done);
      await expectLater(
        actions.setRecurrence(done, Schedule.monthly(day: 5), dueOn: on(5)),
        throwsA(isA<ActionRejected>()),
      );
    });
  });

  test('Skip and Stop repeating refuse a normal item', () async {
    final tap = await actions.create(
      type: NodeType.streamItem,
      parentId: home,
      title: 'Fix the tap',
    );
    final refused = throwsA(
      isA<ActionRejected>().having(
        (e) => e.reason,
        'reason',
        RejectReason.notRecurring,
      ),
    );
    await expectLater(actions.skipOccurrence(tap), refused);
    await expectLater(actions.stopRepeating(tap), refused);
  });
}
