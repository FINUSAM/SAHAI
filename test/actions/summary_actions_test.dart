import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/visibility.dart';

import '../helpers.dart';

/// The M2 core loop through the actions: what the Summary shows after each
/// change, what the activity log records, and Undo (PRD 6, 7, 9; E-001).
void main() {
  late TestApp app;
  late NodeActions actions;

  // Biztras › Website relaunch › 1. Write copy (1.1, 1.2), 2. Design pages
  // (2.1, 2.2); Client admin stream (A, B, C).
  late String biztras, relaunch, t1, s11, s12, t2, s21, s22, admin, a, b, c;

  setUp(() async {
    app = TestApp();
    actions = app.actions;
    biztras = await actions.create(type: NodeType.domain, title: 'Biztras');
    relaunch = await actions.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Website relaunch',
    );
    t1 = await actions.create(
      type: NodeType.task,
      parentId: relaunch,
      title: '1. Write copy',
    );
    s11 = await actions.create(
      type: NodeType.subtask,
      parentId: t1,
      title: 'Draft homepage',
    );
    s12 = await actions.create(
      type: NodeType.subtask,
      parentId: t1,
      title: 'Draft pricing page',
    );
    t2 = await actions.create(
      type: NodeType.task,
      parentId: relaunch,
      title: '2. Design pages',
    );
    s21 = await actions.create(
      type: NodeType.subtask,
      parentId: t2,
      title: 'Wireframes',
    );
    s22 = await actions.create(
      type: NodeType.subtask,
      parentId: t2,
      title: 'Visual design',
    );
    admin = await actions.create(
      type: NodeType.stream,
      parentId: biztras,
      title: 'Client admin',
    );
    a = await actions.create(
      type: NodeType.streamItem,
      parentId: admin,
      title: 'A',
    );
    b = await actions.create(
      type: NodeType.streamItem,
      parentId: admin,
      title: 'B',
    );
    c = await actions.create(
      type: NodeType.streamItem,
      parentId: admin,
      title: 'C',
    );
  });

  tearDown(() => app.close());

  Future<List<String>> visible() async {
    final tree = await actions.loadTree();
    return computeSummary(
      tree,
      now: app.clock.now,
    ).cards.map((c) => c.id).toList();
  }

  Future<List<SummaryVisibleRow>> visibleRows() => (app.db.select(
    app.db.summaryVisible,
  )..where((v) => v.isDeleted.equals(false))).get();

  Future<List<EventRow>> events([String? type]) async {
    // Insertion order: the fake clock gives many events the same time.
    final query = app.db.select(app.db.events)
      ..orderBy([(e) => OrderingTerm.asc(e.rowId)]);
    if (type != null) query.where((e) => e.eventType.equals(type));
    return query.get();
  }

  Future<List<String>> surfacedIds() async =>
      (await events(EventTypes.surfaced)).map((e) => e.nodeId!).toList();

  test('the visible table matches the Summary after setup', () async {
    expect(await visible(), [s11, a]);
    expect(
      (await visibleRows()).map((r) => r.nodeId),
      unorderedEquals([s11, a]),
    );
  });

  test('AT-015 the next subtask surfaces when the first is done', () async {
    await actions.markDone(s11);
    expect(await visible(), [s12, a]);
  });

  test('AT-016 the task surfaces for sign-off and stays TODO', () async {
    await actions.markDone(s11);
    await actions.markDone(s12);
    expect(await visible(), [t1, a]);
    expect((await actions.loadTree())[t1]!.isTodo, isTrue);
  });

  test('AT-017 the next task unlocks after sign-off', () async {
    await actions.markDone(s11);
    await actions.markDone(s12);
    await actions.markDone(t1);
    expect(await visible(), [s21, a]);
    expect(await visible(), isNot(contains(s22)));
  });

  test('AT-020 project sign-off, then nothing from it', () async {
    for (final id in [s11, s12, t1, s21, s22, t2]) {
      await actions.markDone(id);
    }
    expect(await visible(), [relaunch, a]);
    await actions.markDone(relaunch);
    expect(await visible(), [a]);
  });

  test('AT-022 one normal stream item at a time', () async {
    expect(await visible(), contains(a));
    await actions.markDone(a);
    final ids = await visible();
    expect(ids, contains(b));
    expect(ids, isNot(contains(c)));
  });

  test("AT-024 deleting the last TODO subtask readies the task", () async {
    await actions.markDone(s11);
    await actions.delete(s12);
    expect(await visible(), [t1, a]);
  });

  test(
    'a reorder that changes the first subtask updates the Summary',
    () async {
      await actions.moveUp(s12);
      expect(await visible(), [s12, a]);
      expect(await surfacedIds(), contains(s12));
    },
  );

  group('AT-025 undo a completion (E-001)', () {
    test(
      'the item is TODO and showing again; the next one is hidden',
      () async {
        final token = await actions.markDone(s11);
        expect(await visible(), [s12, a]);
        await actions.undoComplete(token);
        expect(await visible(), [s11, a]);
        expect((await actions.loadTree())[s11]!.isTodo, isTrue);
      },
    );

    test(
      'completion_undone points at the completed event, which stays',
      () async {
        final token = await actions.markDone(s11);
        await actions.undoComplete(token);
        final completed = await events(EventTypes.completed);
        expect(completed.single.eventId, token);
        final undone = (await events(EventTypes.completionUndone)).single;
        expect(undone.nodeId, s11);
        expect(jsonDecode(undone.payload), {'undoes_event_id': token});
      },
    );

    test(
      'the restored card gets no new surfaced event and keeps its time',
      () async {
        final before = await visibleRows();
        final originalTime = before
            .singleWhere((r) => r.nodeId == s11)
            .surfacedAt;
        final surfacedBefore = (await surfacedIds()).where((id) => id == s11);
        expect(surfacedBefore, hasLength(1));

        app.clock.advance(const Duration(seconds: 3));
        final token = await actions.markDone(s11);
        app.clock.advance(const Duration(seconds: 2));
        await actions.undoComplete(token);

        expect((await surfacedIds()).where((id) => id == s11), hasLength(1));
        final after = await visibleRows();
        expect(
          after.singleWhere((r) => r.nodeId == s11).surfacedAt,
          originalTime,
        );
      },
    );

    test(
      'the card that briefly replaced it keeps its own surfaced event',
      () async {
        final token = await actions.markDone(s11);
        await actions.undoComplete(token);
        expect((await surfacedIds()).where((id) => id == s12), hasLength(1));
        expect(
          (await visibleRows()).map((r) => r.nodeId),
          isNot(contains(s12)),
        );
      },
    );

    test('undo of a sign-off reopens an ancestor completed since', () async {
      await actions.markDone(s11);
      final token = await actions.markDone(s12);
      await actions.markDone(t1);
      await actions.undoComplete(token);
      final tree = await actions.loadTree();
      expect(tree[s12]!.isTodo, isTrue);
      expect(
        tree[t1]!.isTodo,
        isTrue,
        reason: 'no DONE parent of a TODO child',
      );
      expect(await visible(), [s12, a]);
    });

    test('a token that is not a completion is refused', () async {
      final deleteToken = await actions.delete(c);
      expect(
        () => actions.undoComplete(deleteToken),
        throwsA(isA<ActionRejected>()),
      );
    });
  });

  test('AT-027 reopening a child reopens its ancestors and it shows', () async {
    await actions.markDone(s11);
    await actions.markDone(s12);
    await actions.markDone(t1);
    await actions.reopen(s12);
    final tree = await actions.loadTree();
    expect(tree[s12]!.isTodo, isTrue);
    expect(tree[t1]!.isTodo, isTrue);
    expect(await visible(), [s12, a]);
  });

  test('AT-028 reopening an earlier task re-locks later ones', () async {
    await actions.markDone(s11);
    await actions.markDone(s12);
    await actions.markDone(t1);
    await actions.markDone(s21);
    expect(await visible(), [s22, a]);

    await actions.reopen(t1);
    expect(await visible(), [t1, a]);
    expect((await actions.loadTree()).isLocked(t2), isTrue);

    await actions.markDone(t1);
    expect(await visible(), [s22, a]);
    expect((await actions.loadTree())[s21]!.isDone, isTrue);
  });

  test('AT-030 completion is logged with every field', () async {
    final token = await actions.markDone(s11);
    final event = (await events(EventTypes.completed)).single;
    expect(event.eventId, token);
    expect(event.nodeId, s11);
    expect(event.nodeType, 'subtask');
    expect(event.domainId, biztras);
    expect(event.groupId, isNull);
    expect(event.occurredAt, app.clock.now.millisecondsSinceEpoch);
    expect(event.tzOffsetMinutes, app.clock.now.timeZoneOffset.inMinutes);
  });

  test('AT-031 surfacing is logged for the item that appears', () async {
    expect(await surfacedIds(), isNot(contains(s12)));
    await actions.markDone(s11);
    final surfaced = (await events(EventTypes.surfaced))
        .singleWhere((e) => e.nodeId == s12);
    expect(surfaced.nodeType, 'subtask');
    expect(surfaced.domainId, biztras);
    expect(surfaced.occurredAt, app.clock.now.millisecondsSinceEpoch);
  });

  test('surfaced and summary_visible are written in one transaction', () async {
    // Every surfaced event matches a row that was visible at some point.
    await actions.markDone(s11);
    await actions.markDone(a);
    final rows = await app.db.select(app.db.summaryVisible).get();
    final rowIds = rows.map((r) => r.nodeId).toSet();
    for (final id in await surfacedIds()) {
      expect(rowIds, contains(id));
    }
    expect(
      (await visibleRows()).map((r) => r.nodeId),
      unorderedEquals([s12, b]),
    );
  });

  test(
    'AT-032 create, delete, restore, complete and reopen are logged in order',
    () async {
      final fresh = TestApp();
      addTearDown(fresh.close);
      final d = await fresh.actions.create(type: NodeType.domain, title: 'D');
      final p = await fresh.actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      final task = await fresh.actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'T',
      );
      final deleteToken = await fresh.actions.delete(task);
      await fresh.actions.undoDelete(deleteToken);
      await fresh.actions.markDone(task);
      await fresh.actions.reopen(task);

      final log = await (fresh.db.select(
        fresh.db.events,
      )..orderBy([(e) => OrderingTerm.asc(e.rowId)])).get();
      final forTask = log
          .where((e) => e.nodeId == task && e.eventType != EventTypes.surfaced)
          .map((e) => e.eventType)
          .toList();
      expect(forTask, [
        EventTypes.created,
        EventTypes.deleted,
        EventTypes.restored,
        EventTypes.completed,
        EventTypes.reopened,
      ]);
    },
  );
}
