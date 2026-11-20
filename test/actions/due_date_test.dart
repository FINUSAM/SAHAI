import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/due.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/engine/visibility.dart';

import '../helpers.dart';

/// Due dates on one-off items through the actions (E-019). Local time, as
/// the rules are: Monday, Nov 9, 2026, 10:00 AM.
void main() {
  late TestApp app;
  late NodeActions actions;
  late String biztras, website, writeCopy, errands;

  setUp(() async {
    app = TestApp(clock: TestClock(DateTime(2026, 11, 9, 10)));
    actions = app.actions;
    biztras = await actions.create(type: NodeType.domain, title: 'Biztras');
    website = await actions.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Website relaunch',
    );
    writeCopy = await actions.create(
      type: NodeType.task,
      parentId: website,
      title: 'Write the copy',
    );
    errands = await actions.create(
      type: NodeType.stream,
      parentId: biztras,
      title: 'Errands',
    );
  });

  tearDown(() => app.close());

  Future<List<EventRow>> dueEvents() =>
      (app.db.select(app.db.events)
            ..where((e) => e.eventType.equals(EventTypes.dueChanged))
            ..orderBy([(e) => OrderingTerm.asc(e.rowId)]))
          .get();

  Map<String, Object?> payload(EventRow e) =>
      jsonDecode(e.payload) as Map<String, Object?>;

  Matcher rejectedWith(RejectReason reason) =>
      throwsA(isA<ActionRejected>().having((e) => e.reason, 'reason', reason));

  Future<List<String>> summary() async => computeSummary(
    await actions.loadTree(),
    now: app.clock.now,
  ).cards.map((c) => c.id).toList();

  test('AT-128 a task gets a due date, On the day by default, and loses it '
      'with clear', () async {
    await actions.setDueDate(writeCopy, DateTime(2026, 11, 20));
    var node = (await actions.loadTree())[writeCopy]!;
    expect(node.dueOn, DateTime(2026, 11, 20));
    expect(node.dueReminder, DueReminder.onTheDay);
    expect(node.hasOneOffDue, isTrue);

    await actions.setDueDate(writeCopy, null);
    node = (await actions.loadTree())[writeCopy]!;
    expect(node.dueOn, isNull);
    expect(node.hasOneOffDue, isFalse);
  });

  test('AT-128 days before today cannot be picked; today can', () async {
    await expectLater(
      actions.setDueDate(writeCopy, DateTime(2026, 11, 8)),
      rejectedWith(RejectReason.pastDueDate),
    );
    await actions.setDueDate(writeCopy, DateTime(2026, 11, 9));
    expect((await actions.loadTree())[writeCopy]!.dueOn, DateTime(2026, 11, 9));
  });

  test('an overdue date can be kept while Remind me changes', () async {
    await actions.setDueDate(writeCopy, DateTime(2026, 11, 10));
    app.clock.now = DateTime(2026, 11, 12, 10);
    await actions.setDueDate(
      writeCopy,
      DateTime(2026, 11, 10),
      reminder: DueReminder.none,
    );
    final node = (await actions.loadTree())[writeCopy]!;
    expect(node.dueOn, DateTime(2026, 11, 10));
    expect(node.dueReminder, DueReminder.none);
  });

  test('AT-128 domains, streams and repeating items have no one-off due '
      'date', () async {
    final bill = await actions.create(
      type: NodeType.streamItem,
      parentId: errands,
      title: 'Pay rent',
      schedule: Schedule.monthly(day: 1),
      dueOn: DateTime(2026, 12, 1),
    );
    for (final id in [biztras, errands, bill]) {
      await expectLater(
        actions.setDueDate(id, DateTime(2026, 11, 20)),
        rejectedWith(RejectReason.cantHaveDueDate),
      );
    }
    await expectLater(
      actions.create(
        type: NodeType.stream,
        parentId: biztras,
        title: 'Clients',
        dueOn: DateTime(2026, 11, 20),
      ),
      rejectedWith(RejectReason.cantHaveDueDate),
    );
  });

  test(
    'projects, tasks, subtasks and one-off stream items can have one',
    () async {
      final subtask = await actions.create(
        type: NodeType.subtask,
        parentId: writeCopy,
        title: 'Draft homepage',
      );
      final item = await actions.create(
        type: NodeType.streamItem,
        parentId: errands,
        title: 'Renew passport',
        dueOn: DateTime(2026, 12, 14),
        dueReminder: DueReminder.weekBefore,
      );
      for (final id in [website, writeCopy, subtask]) {
        await actions.setDueDate(id, DateTime(2026, 11, 20));
      }
      final tree = await actions.loadTree();
      for (final id in [website, writeCopy, subtask, item]) {
        expect(tree[id]!.hasOneOffDue, isTrue, reason: tree[id]!.title);
      }
      expect(tree[item]!.dueReminder, DueReminder.weekBefore);
      expect(tree[item]!.isRecurring, isFalse);
    },
  );

  test('AT-133 each change logs due_changed with the old and new dates and '
      'the reminder, never the text', () async {
    await actions.setDueDate(writeCopy, DateTime(2026, 11, 20));
    await actions.setDueDate(
      writeCopy,
      DateTime(2026, 11, 24),
      reminder: DueReminder.dayBefore,
    );
    await actions.setDueDate(writeCopy, null);
    // Nothing changed, so nothing is logged.
    await actions.setDueDate(writeCopy, null);

    final events = await dueEvents();
    expect(events.map(payload), [
      {
        'old_due_on': null,
        'due_on': '2026-11-20',
        'old_reminder': null,
        'reminder': 'on_the_day',
      },
      {
        'old_due_on': '2026-11-20',
        'due_on': '2026-11-24',
        'old_reminder': 'on_the_day',
        'reminder': '1_day',
      },
      {
        'old_due_on': '2026-11-24',
        'due_on': null,
        'old_reminder': '1_day',
        'reminder': null,
      },
    ]);
    for (final e in events) {
      expect(e.nodeId, writeCopy);
      expect(e.nodeType, 'task');
      expect(e.domainId, biztras);
      expect(e.payload, isNot(contains('Write the copy')));
    }
  });

  test(
    'creating an item with a due date logs due_changed too (choice C)',
    () async {
      final item = await actions.create(
        type: NodeType.streamItem,
        parentId: errands,
        title: 'Renew passport',
        dueOn: DateTime(2026, 12, 14),
        dueReminder: DueReminder.weekBefore,
      );
      final event = (await dueEvents()).single;
      expect(event.nodeId, item);
      expect(payload(event), {
        'old_due_on': null,
        'due_on': '2026-12-14',
        'old_reminder': null,
        'reminder': '1_week',
      });
      // A repeating item's first due date isn't a one-off due date.
      await actions.create(
        type: NodeType.streamItem,
        parentId: errands,
        title: 'Pay rent',
        schedule: Schedule.monthly(day: 1),
        dueOn: DateTime(2026, 12, 1),
      );
      expect(await dueEvents(), hasLength(1));
    },
  );

  test(
    'a due date doesn\'t hide an item or bring one onto the Summary',
    () async {
      // Due in 10 days: a bill would wait for its show date; this doesn't.
      await actions.setDueDate(writeCopy, DateTime(2026, 11, 19));
      expect(await summary(), [writeCopy]);
      expect(
        (await actions.loadTree())[writeCopy]!.wakeAt(const AppSettings()),
        isNull,
      );

      // A later task due today still waits its turn.
      final later = await actions.create(
        type: NodeType.task,
        parentId: website,
        title: 'Launch',
      );
      await actions.setDueDate(later, DateTime(2026, 11, 9));
      expect(await summary(), [writeCopy]);
    },
  );

  test(
    'completing keeps the due date, so Undo brings the label back',
    () async {
      await actions.setDueDate(
        writeCopy,
        DateTime(2026, 11, 20),
        reminder: DueReminder.threeDaysBefore,
      );
      final token = await actions.markDone(writeCopy);
      var node = (await actions.loadTree())[writeCopy]!;
      expect(node.isDone, isTrue);
      expect(node.dueOn, DateTime(2026, 11, 20));
      await actions.undoComplete(token);
      node = (await actions.loadTree())[writeCopy]!;
      expect(node.isTodo, isTrue);
      expect(node.dueOn, DateTime(2026, 11, 20));
      expect(node.dueReminder, DueReminder.threeDaysBefore);
    },
  );
}
