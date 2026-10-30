import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/shared/ids.dart';

import '../helpers.dart';

Matcher rejectedWith(RejectReason reason) =>
    throwsA(isA<ActionRejected>().having((e) => e.reason, 'reason', reason));

void main() {
  late TestApp app;
  late NodeActions actions;

  setUp(() {
    app = TestApp();
    actions = app.actions;
  });

  tearDown(() => app.close());

  Future<List<String>> titlesUnder(String parentId) async =>
      (await actions.loadTree())
          .childrenOf(parentId)
          .map((n) => n.title)
          .toList();

  Future<NodeRow> row(String id) =>
      (app.db.select(app.db.nodes)..where((n) => n.id.equals(id))).getSingle();

  Future<List<EventRow>> events() =>
      (app.db.select(app.db.events)..orderBy([
            (e) => OrderingTerm.asc(e.createdAt),
            (e) => OrderingTerm.asc(e.eventId),
          ]))
          .get();

  group('AT-001 create every node type', () {
    test('each appears under its parent with the right type', () async {
      final domain = await actions.create(
        type: NodeType.domain,
        title: 'Biztras',
      );
      final stream = await actions.create(
        type: NodeType.stream,
        parentId: domain,
        title: 'Client admin',
      );
      final item = await actions.create(
        type: NodeType.streamItem,
        parentId: stream,
        title: 'Send invoice',
      );
      final project = await actions.create(
        type: NodeType.project,
        parentId: domain,
        title: 'Website',
      );
      final task = await actions.create(
        type: NodeType.task,
        parentId: project,
        title: 'Write copy',
      );
      final subtask = await actions.create(
        type: NodeType.subtask,
        parentId: task,
        title: 'Draft homepage',
      );

      final tree = await actions.loadTree();
      expect(tree.roots.single.type, NodeType.domain);
      expect(tree[stream]!.parentId, domain);
      expect(tree[item]!.type, NodeType.streamItem);
      expect(tree[project]!.parentId, domain);
      expect(tree[task]!.parentId, project);
      expect(tree[subtask]!.parentId, task);
      expect(tree[subtask]!.status, NodeStatus.todo);
      expect(tree[domain]!.status, isNull);
      expect(tree[stream]!.status, isNull);
    });

    test('nodes stay after closing and reopening the database', () async {
      final dir = await Directory.systemTemp.createTemp('sahai_at001');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/sahai.sqlite');

      final first = TestApp(executor: NativeDatabase(file));
      final domain = await first.actions.create(
        type: NodeType.domain,
        title: 'Personal',
      );
      await first.actions.create(
        type: NodeType.stream,
        parentId: domain,
        title: 'Errands',
      );
      await first.close();

      final second = TestApp(executor: NativeDatabase(file));
      addTearDown(second.close);
      final tree = await second.actions.loadTree();
      expect(tree.roots.single.title, 'Personal');
      expect(tree.childrenOf(domain).single.title, 'Errands');
    });

    test('a blank title is refused', () {
      expect(
        () => actions.create(type: NodeType.domain, title: '   '),
        rejectedWith(RejectReason.emptyTitle),
      );
    });
  });

  group('AT-002 only valid children can be added', () {
    test('invalid parent and child pairs are refused', () async {
      final domain = await actions.create(type: NodeType.domain, title: 'D');
      final stream = await actions.create(
        type: NodeType.stream,
        parentId: domain,
        title: 'S',
      );
      final project = await actions.create(
        type: NodeType.project,
        parentId: domain,
        title: 'P',
      );
      final task = await actions.create(
        type: NodeType.task,
        parentId: project,
        title: 'T',
      );
      final subtask = await actions.create(
        type: NodeType.subtask,
        parentId: task,
        title: 'ST',
      );
      final item = await actions.create(
        type: NodeType.streamItem,
        parentId: stream,
        title: 'I',
      );

      await expectLater(
        actions.create(type: NodeType.task, parentId: domain, title: 'x'),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.create(type: NodeType.task, parentId: stream, title: 'x'),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.create(type: NodeType.subtask, parentId: project, title: 'x'),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.create(type: NodeType.subtask, parentId: subtask, title: 'x'),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.create(type: NodeType.streamItem, parentId: item, title: 'x'),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.create(type: NodeType.project, title: 'no parent'),
        rejectedWith(RejectReason.invalidParent),
      );
    });
  });

  group('AT-004 reorder sequential tasks', () {
    test('moving Task 3 above Task 1 gives 3, 1, 2 and persists', () async {
      final dir = await Directory.systemTemp.createTemp('sahai_at004');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/sahai.sqlite');

      final first = TestApp(executor: NativeDatabase(file));
      final d = await first.actions.create(type: NodeType.domain, title: 'D');
      final p = await first.actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      await first.actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 1',
      );
      await first.actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 2',
      );
      final t3 = await first.actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 3',
      );
      await first.actions.reorder(t3, 0);
      await first.close();

      final second = TestApp(executor: NativeDatabase(file));
      addTearDown(second.close);
      final tree = await second.actions.loadTree();
      expect(tree.childrenOf(p).map((n) => n.title), [
        'Task 3',
        'Task 1',
        'Task 2',
      ]);
      // Order decides the current task, so Task 3 is now current.
      expect(tree.currentTaskOf(p)?.title, 'Task 3');
    });

    test('move up and move down shift by one and stop at the ends', () async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      final p = await actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      final t1 = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 1',
      );
      await actions.create(type: NodeType.task, parentId: p, title: 'Task 2');
      final t3 = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 3',
      );

      await actions.moveDown(t1);
      expect(await titlesUnder(p), ['Task 2', 'Task 1', 'Task 3']);
      await actions.moveUp(t3);
      expect(await titlesUnder(p), ['Task 2', 'Task 3', 'Task 1']);
      await actions.moveDown(t1);
      expect(await titlesUnder(p), ['Task 2', 'Task 3', 'Task 1']);
    });
  });

  test('AT-005 reorder subtasks and stream items', () async {
    final d = await actions.create(type: NodeType.domain, title: 'D');
    final p = await actions.create(
      type: NodeType.project,
      parentId: d,
      title: 'P',
    );
    final t = await actions.create(
      type: NodeType.task,
      parentId: p,
      title: 'T',
    );
    await actions.create(type: NodeType.subtask, parentId: t, title: 'A');
    await actions.create(type: NodeType.subtask, parentId: t, title: 'B');
    final c = await actions.create(
      type: NodeType.subtask,
      parentId: t,
      title: 'C',
    );
    final s = await actions.create(
      type: NodeType.stream,
      parentId: d,
      title: 'S',
    );
    await actions.create(type: NodeType.streamItem, parentId: s, title: 'X');
    await actions.create(type: NodeType.streamItem, parentId: s, title: 'Y');
    final z = await actions.create(
      type: NodeType.streamItem,
      parentId: s,
      title: 'Z',
    );

    await actions.reorder(c, 0);
    await actions.reorder(z, 0);

    expect(await titlesUnder(t), ['C', 'A', 'B']);
    expect(await titlesUnder(s), ['Z', 'X', 'Y']);
  });

  group('AT-006 move an item to another parent', () {
    test('subtask moves from Task A to Task B', () async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      final p = await actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      final a = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task A',
      );
      final b = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task B',
      );
      await actions.create(
        type: NodeType.subtask,
        parentId: b,
        title: 'Existing',
      );
      final s = await actions.create(
        type: NodeType.subtask,
        parentId: a,
        title: 'S',
      );

      await actions.move(s, b);

      expect(await titlesUnder(a), isEmpty);
      expect(await titlesUnder(b), ['Existing', 'S']);
    });

    test('a parent of the wrong type is refused', () async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      final p = await actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      final t = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'T',
      );
      final s = await actions.create(
        type: NodeType.subtask,
        parentId: t,
        title: 'S',
      );
      final stream = await actions.create(
        type: NodeType.stream,
        parentId: d,
        title: 'Stream',
      );

      await expectLater(
        actions.move(s, p),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.move(s, stream),
        rejectedWith(RejectReason.invalidParent),
      );
      await expectLater(
        actions.move(t, d),
        rejectedWith(RejectReason.invalidParent),
      );
    });
  });

  group('AT-008 delete with Undo', () {
    test('the project and its three tasks come back exactly', () async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      final p = await actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      for (final title in ['T1', 'T2', 'T3']) {
        await actions.create(type: NodeType.task, parentId: p, title: title);
      }
      final before = await titlesUnder(p);

      final deleteEvent = await actions.delete(p);
      expect((await actions.loadTree()).contains(p), isFalse);

      await actions.undoDelete(deleteEvent);
      expect((await actions.loadTree()).childrenOf(d).single.id, p);
      expect(await titlesUnder(p), before);
    });

    test(
      'E-003 Undo doesn\'t bring back a task deleted earlier on its own',
      () async {
        final d = await actions.create(type: NodeType.domain, title: 'D');
        final p = await actions.create(
          type: NodeType.project,
          parentId: d,
          title: 'P',
        );
        await actions.create(type: NodeType.task, parentId: p, title: 'Keep');
        final gone = await actions.create(
          type: NodeType.task,
          parentId: p,
          title: 'Deleted first',
        );
        await actions.delete(gone);

        final deleteEvent = await actions.delete(p);
        await actions.undoDelete(deleteEvent);

        expect(await titlesUnder(p), ['Keep']);
        expect((await row(gone)).isDeleted, isTrue);
      },
    );
  });

  test(
    'AT-009 deleted rows stay in the database with is_deleted = true',
    () async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      final p = await actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      final tasks = [
        for (final title in ['T1', 'T2', 'T3'])
          await actions.create(type: NodeType.task, parentId: p, title: title),
      ];

      final deleteEvent = await actions.delete(p);

      final tree = await actions.loadTree();
      for (final id in [p, ...tasks]) {
        expect(tree.contains(id), isFalse);
        final r = await row(id);
        expect(r.isDeleted, isTrue, reason: id);
        expect(r.deletedByEvent, deleteEvent);
      }
    },
  );

  group('AT-010 sync-ready fields are set', () {
    test('ids are UUIDs and updated_at is UTC and changes on edit', () async {
      final clock = TestClock();
      final uuidApp = TestApp(clock: clock, ids: newUuid);
      addTearDown(uuidApp.close);
      final id = await uuidApp.actions.create(
        type: NodeType.domain,
        title: 'Old',
      );
      final uuidV4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidV4.hasMatch(id), isTrue, reason: id);

      final created = await (uuidApp.db.select(
        uuidApp.db.nodes,
      )..where((n) => n.id.equals(id))).getSingle();
      expect(created.updatedAt, clock.now.millisecondsSinceEpoch);
      expect(created.createdAt, created.updatedAt);

      clock.advance(const Duration(minutes: 5));
      await uuidApp.actions.edit(id, title: 'New');

      final edited = await (uuidApp.db.select(
        uuidApp.db.nodes,
      )..where((n) => n.id.equals(id))).getSingle();
      expect(edited.title, 'New');
      expect(edited.updatedAt, clock.now.millisecondsSinceEpoch);
      expect(edited.createdAt, created.createdAt);
    });

    test('times are stored as UTC even when the clock is local', () async {
      final local = DateTime(2026, 11, 3, 20, 30);
      final localApp = TestApp(clock: TestClock(local));
      addTearDown(localApp.close);
      final id = await localApp.actions.create(
        type: NodeType.domain,
        title: 'D',
      );
      final created = await (localApp.db.select(
        localApp.db.nodes,
      )..where((n) => n.id.equals(id))).getSingle();
      expect(created.updatedAt, local.toUtc().millisecondsSinceEpoch);
    });
  });

  group('mark done and reopen (basic, M1)', () {
    late String p, t1, t2, s1;

    setUp(() async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      p = await actions.create(type: NodeType.project, parentId: d, title: 'P');
      t1 = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 1',
      );
      s1 = await actions.create(
        type: NodeType.subtask,
        parentId: t1,
        title: '1.1',
      );
      t2 = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'Task 2',
      );
    });

    test('E-007 a locked task offers no Mark done until the task before it is done', () async {
      await expectLater(
        actions.markDone(t2),
        rejectedWith(RejectReason.lockedTask),
      );
      await actions.markDone(s1);
      await actions.markDone(t1);
      await actions.markDone(t2);
      expect((await actions.loadTree())[t2]!.isDone, isTrue);
    });

    test('a node with TODO children can\'t be marked done', () async {
      await expectLater(
        actions.markDone(t1),
        rejectedWith(RejectReason.hasTodoChildren),
      );
      await expectLater(
        actions.markDone(p),
        rejectedWith(RejectReason.hasTodoChildren),
      );
    });

    test('domains and streams have no Mark done', () async {
      final tree = await actions.loadTree();
      final domain = tree.roots.single.id;
      await expectLater(
        actions.markDone(domain),
        rejectedWith(RejectReason.noStatus),
      );
    });

    test('reopening a subtask also reopens its DONE task', () async {
      await actions.markDone(s1);
      await actions.markDone(t1);

      await actions.reopen(s1);

      final tree = await actions.loadTree();
      expect(tree[s1]!.isTodo, isTrue);
      expect(tree[t1]!.isTodo, isTrue);
      expect((await row(t1)).completedAt, isNull);
    });

    test('reopening a TODO node is refused', () {
      expect(() => actions.reopen(s1), rejectedWith(RejectReason.notDone));
    });
  });

  test(
    'activity log records create, delete, restore, complete and reopen',
    () async {
      final d = await actions.create(type: NodeType.domain, title: 'D');
      final p = await actions.create(
        type: NodeType.project,
        parentId: d,
        title: 'P',
      );
      app.clock.advance(const Duration(seconds: 1));
      final t = await actions.create(
        type: NodeType.task,
        parentId: p,
        title: 'T',
      );
      app.clock.advance(const Duration(seconds: 1));
      final deleteEvent = await actions.delete(t);
      app.clock.advance(const Duration(seconds: 1));
      await actions.undoDelete(deleteEvent);
      app.clock.advance(const Duration(seconds: 1));
      await actions.markDone(t);
      app.clock.advance(const Duration(seconds: 1));
      await actions.reopen(t);

      final log = (await events()).where((e) => e.nodeId == t).toList();
      expect(log.map((e) => e.eventType), [
        'created',
        'deleted',
        'restored',
        'completed',
        'reopened',
      ]);
      for (final e in log) {
        expect(e.nodeType, 'task');
        expect(e.domainId, d);
        expect(e.tzOffsetMinutes, 0);
      }
      expect(log[1].eventId, deleteEvent);
      expect(jsonDecode(log[2].payload), {'undoes_event_id': deleteEvent});
    },
  );
}
