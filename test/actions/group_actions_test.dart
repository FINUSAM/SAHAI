import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/groups.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';

import '../helpers.dart';

/// Context groups and the Summary's order through the actions, and what
/// the activity log records (PRD 8.2, 9; E-013, E-014, E-015).
void main() {
  late TestApp app;
  late NodeActions actions;

  // Biztras › Website relaunch (P) › 1. Write copy (1.1, 1.2), 2. Design
  // pages (2.1); Brochure (Q) › Print it; Pricing (R) › Set prices; Client
  // admin stream (A, B).
  late String biztras, p, t1, s11, s12, t2, q, r, admin;
  late String laptop, errands, home;

  setUp(() async {
    app = TestApp();
    actions = app.actions;
    biztras = await actions.create(type: NodeType.domain, title: 'Biztras');
    p = await actions.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Website relaunch',
    );
    t1 = await actions.create(
      type: NodeType.task,
      parentId: p,
      title: '1. Write copy',
    );
    s11 = await actions.create(
      type: NodeType.subtask,
      parentId: t1,
      title: '1.1',
    );
    s12 = await actions.create(
      type: NodeType.subtask,
      parentId: t1,
      title: '1.2',
    );
    t2 = await actions.create(
      type: NodeType.task,
      parentId: p,
      title: '2. Design pages',
    );
    await actions.create(type: NodeType.subtask, parentId: t2, title: '2.1');
    q = await actions.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Brochure',
    );
    await actions.create(type: NodeType.task, parentId: q, title: 'Print it');
    r = await actions.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Pricing',
    );
    await actions.create(type: NodeType.task, parentId: r, title: 'Set prices');
    admin = await actions.create(
      type: NodeType.stream,
      parentId: biztras,
      title: 'Client admin',
    );
    await actions.create(
      type: NodeType.streamItem,
      parentId: admin,
      title: 'A',
    );
    await actions.create(
      type: NodeType.streamItem,
      parentId: admin,
      title: 'B',
    );
  });

  tearDown(() => app.close());

  Future<void> makeGroups() async {
    laptop = await actions.createGroup('At laptop', icon: 'laptop');
    errands = await actions.createGroup('Errands', icon: 'bag');
    home = await actions.createGroup('At home');
  }

  /// "At laptop: Print it, 1.1" per section; "No group" for the default list.
  Future<List<String>> layout() async => [
    for (final s in await actions.loadArrangedSummary())
      '${s.group?.name ?? 'No group'}: '
          '${s.cards.map((c) => c.node.title).join(', ')}',
  ];

  Future<List<EventRow>> events([String? type]) async {
    // Insertion order: the fake clock gives many events the same time.
    final query = app.db.select(app.db.events)
      ..orderBy([(e) => OrderingTerm.asc(e.rowId)]);
    if (type != null) query.where((e) => e.eventType.equals(type));
    return query.get();
  }

  Map<String, Object?> payload(EventRow e) =>
      jsonDecode(e.payload) as Map<String, Object?>;

  /// The task that is [project]'s card.
  Future<String> taskOf(String project) async =>
      (await actions.loadTree()).childrenOf(project).first.id;

  Future<String?> settingOf(String id) async =>
      (await actions.loadTree())[id]!.groupId;

  /// At laptop: Print it (Q), 1.1 (P), Set prices (R), in that order.
  Future<void> laptopWithThree() async {
    await actions.setGroup(q, laptop);
    await actions.setGroup(p, laptop);
    await actions.setGroup(r, laptop);
  }

  test('AT-083 ungrouped cards use the default list', () async {
    expect(await actions.loadGroups(), isEmpty);
    expect(await layout(), ['No group: 1.1, Print it, Set prices, A']);
  });

  test('AT-084 create a group', () async {
    final id = await actions.createGroup('  At laptop ', icon: 'laptop');
    final groups = await actions.loadGroups();
    expect(groups.single.id, id);
    expect(groups.single.name, 'At laptop');
    expect(groups.single.icon, 'laptop');
    // Available, but not on the Summary until it holds a card.
    expect(await layout(), ['No group: 1.1, Print it, Set prices, A']);
    await actions.setGroup(q, id);
    expect(await layout(), [
      'At laptop: Print it',
      'No group: 1.1, Set prices, A',
    ]);
  });

  test('AT-084 a group needs a name', () async {
    expect(
      () => actions.createGroup('  '),
      throwsA(
        isA<ActionRejected>().having(
          (e) => e.reason,
          'reason',
          RejectReason.emptyTitle,
        ),
      ),
    );
  });

  test('AT-085 groups are inherited', () async {
    await makeGroups();
    await actions.setGroup(p, laptop);
    expect(await layout(), [
      'At laptop: 1.1',
      'No group: Print it, Set prices, A',
    ]);
    expect(await settingOf(s11), isNull);
  });

  test('AT-086 the nearest group wins', () async {
    await makeGroups();
    await actions.setGroup(p, laptop);
    await actions.setGroup(s12, errands);
    await actions.markDone(s11);
    expect(await layout(), [
      'Errands: 1.2',
      'No group: Print it, Set prices, A',
    ]);
  });

  test('AT-087 dragging assigns that item only', () async {
    await makeGroups();
    await actions.setGroup(p, laptop);
    await actions.moveCardToGroup(s11, errands);
    expect(await layout(), [
      'Errands: 1.1',
      'No group: Print it, Set prices, A',
    ]);
    expect(await settingOf(s11), errands);
    expect(await settingOf(p), laptop);
    expect(await settingOf(s12), isNull);
    await actions.markDone(s11);
    expect(await layout(), [
      'At laptop: 1.2',
      'No group: Print it, Set prices, A',
    ]);
  });

  test('AT-088 the next card keeps the same position', () async {
    await makeGroups();
    await laptopWithThree();
    expect((await layout()).first, 'At laptop: Print it, 1.1, Set prices');
    await actions.markDone(s11);
    expect((await layout()).first, 'At laptop: Print it, 1.2, Set prices');
    // And again when the task is done and the next one's first subtask
    // shows: the arrangement survives completing items.
    await actions.markDone(s12);
    await actions.markDone(t1);
    expect((await layout()).first, 'At laptop: Print it, 2.1, Set prices');
  });

  test('AT-089 a card moving groups goes to the end', () async {
    await makeGroups();
    await actions.setGroup(admin, errands);
    await actions.setGroup(p, laptop);
    await actions.setGroup(s12, errands);
    expect(await layout(), [
      'At laptop: 1.1',
      'Errands: A',
      'No group: Print it, Set prices',
    ]);
    await actions.markDone(s11);
    expect(await layout(), [
      'Errands: A, 1.2',
      'No group: Print it, Set prices',
    ]);
  });

  test('AT-090 new slots go to the end', () async {
    await makeGroups();
    await laptopWithThree();
    await actions.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Newsletter',
      group: laptop,
    );
    expect(
      (await layout()).first,
      'At laptop: Print it, 1.1, Set prices, Newsletter',
    );
  });

  test('AT-091 recurring items keep their position', () async {
    await makeGroups();
    final bills = await actions.create(
      type: NodeType.stream,
      parentId: biztras,
      title: 'Bills',
    );
    final hdfc = await actions.create(
      type: NodeType.streamItem,
      parentId: bills,
      title: 'Pay HDFC card',
      schedule: Schedule.monthly(day: 5),
      dueOn: DateTime(2026, 11, 5),
      group: laptop,
    );
    await actions.setGroup(q, laptop);
    await actions.setGroup(r, laptop);
    // The user places HDFC second.
    await actions.reorderCard(hdfc, 1);
    expect(
      (await layout()).first,
      'At laptop: Print it, Pay HDFC card, '
      'Set prices',
    );
    await actions.markDone(hdfc);
    expect((await layout()).first, 'At laptop: Print it, Set prices');
    // Next month it shows again from Dec 2, three days before it's due.
    app.clock.now = DateTime(2026, 12, 3, 10);
    await actions.recompute();
    expect(
      (await layout()).first,
      'At laptop: Print it, Pay HDFC card, '
      'Set prices',
    );
  });

  test('AT-092 dragging never changes the tree', () async {
    await makeGroups();
    await laptopWithThree();
    Future<List<(String, int)>> order() async => [
      for (final n in (await actions.loadTree()).nodes) (n.id, n.sortOrder),
    ];
    final before = await order();
    await actions.reorderCard(await taskOf(r), 0);
    await actions.moveCardUp(s11);
    await actions.moveCardToGroup(await taskOf(q), errands);
    expect(await order(), before);
  });

  test('AT-094 reorders and group changes are logged', () async {
    await makeGroups();
    await laptopWithThree();
    final start = (await events()).length;
    // Within the group: Set prices from third to first.
    final rTask = await taskOf(r);
    await actions.reorderCard(rTask, 0);
    final within = (await events()).skip(start).single;
    expect(within.eventType, EventTypes.reordered);
    expect(within.nodeId, rTask);
    expect(within.groupId, laptop);
    expect(payload(within), {
      'view': 'summary',
      'owner_id': r,
      'old_position': 2,
      'new_position': 0,
      'old_group': laptop,
      'new_group': laptop,
    });
    // To another group: 1.1 from At laptop to Errands.
    final mid = (await events()).length;
    await actions.moveCardToGroup(s11, errands);
    final moved = (await events()).skip(mid).toList();
    expect(moved.map((e) => e.eventType), [
      EventTypes.groupChanged,
      EventTypes.reordered,
    ]);
    expect(payload(moved[0]), {
      'old_setting': null,
      'new_setting': errands,
      'old_group': laptop,
      'new_group': errands,
      'owner_id': p,
      'old_slot_group': laptop,
      'old_slot_position': 2,
    });
    expect(moved[0].groupId, errands);
    expect(payload(moved[1]), {
      'view': 'summary',
      'owner_id': p,
      'old_position': 2,
      'new_position': 0,
      'old_group': laptop,
      'new_group': errands,
    });
  });

  test('moving a card up and down', () async {
    await makeGroups();
    await laptopWithThree();
    final rTask = (await actions.loadTree()).childrenOf(r).single.id;
    await actions.moveCardUp(rTask);
    expect((await layout()).first, 'At laptop: Print it, Set prices, 1.1');
    await actions.moveCardDown(s11);
    final before = (await events()).length;
    // Already last: nothing changes and nothing is logged.
    await actions.moveCardDown(s11);
    expect((await layout()).first, 'At laptop: Print it, Set prices, 1.1');
    expect((await events()).length, before);
  });

  test('a card that is not on the Summary cannot be reordered', () async {
    expect(
      () => actions.reorderCard(s12, 0),
      throwsA(
        isA<ActionRejected>().having(
          (e) => e.reason,
          'reason',
          RejectReason.notOnSummary,
        ),
      ),
    );
  });

  test('a slot of a hidden owner keeps its order', () async {
    await makeGroups();
    await laptopWithThree();
    final printIt = (await actions.loadTree()).childrenOf(q).single.id;
    await actions.setAside(printIt, DateTime.utc(2026, 11, 4, 8));
    final rTask = (await actions.loadTree()).childrenOf(r).single.id;
    await actions.reorderCard(rTask, 0);
    expect((await layout()).first, 'At laptop: Set prices, 1.1');
    app.clock.now = DateTime.utc(2026, 11, 4, 9);
    await actions.recompute();
    expect((await layout()).first, 'At laptop: Print it, Set prices, 1.1');
  });

  group('Undo of a group change', () {
    test('puts the setting and the card back exactly', () async {
      await makeGroups();
      await laptopWithThree();
      final token = await actions.moveCardToGroup(s11, errands);
      expect((await layout()).take(2), [
        'At laptop: Print it, Set prices',
        'Errands: 1.1',
      ]);
      final before = (await events()).length;
      await actions.undoGroupChange(token!);
      expect((await layout()).first, 'At laptop: Print it, 1.1, Set prices');
      expect(await settingOf(s11), isNull);
      final undone = (await events()).skip(before).toList();
      expect(undone.map((e) => e.eventType), [
        EventTypes.groupChanged,
        EventTypes.reordered,
      ]);
      expect(payload(undone[0])['undoes_event_id'], token);
      expect(payload(undone[0])['new_setting'], isNull);
      expect(payload(undone[1]), {
        'view': 'summary',
        'owner_id': p,
        'old_position': 0,
        'new_position': 1,
        'old_group': errands,
        'new_group': laptop,
        'undoes_event_id': token,
      });
    });

    test('is refused once the setting has changed again', () async {
      await makeGroups();
      await laptopWithThree();
      final token = await actions.moveCardToGroup(s11, errands);
      await actions.setGroup(s11, home);
      expect(
        () => actions.undoGroupChange(token!),
        throwsA(
          isA<ActionRejected>().having(
            (e) => e.reason,
            'reason',
            RejectReason.staleUndo,
          ),
        ),
      );
    });

    test('a card already in the group gives no token', () async {
      await makeGroups();
      await actions.setGroup(p, laptop);
      expect(await actions.moveCardToGroup(s11, laptop), isNull);
      expect(await settingOf(s11), isNull);
    });
  });

  group('setting a group on a node', () {
    test(
      'logs group_changed only when the node has no card of its own',
      () async {
        await makeGroups();
        final before = (await events()).length;
        await actions.setGroup(p, laptop);
        final logged = (await events()).skip(before).toList();
        expect(logged.single.eventType, EventTypes.groupChanged);
        expect(logged.single.nodeId, p);
        expect(payload(logged.single), {
          'old_setting': null,
          'new_setting': laptop,
          'old_group': null,
          'new_group': laptop,
        });
      },
    );

    test('the same setting again changes nothing', () async {
      await makeGroups();
      await actions.setGroup(p, laptop);
      final before = (await events()).length;
      expect(await actions.setGroup(p, laptop), isNull);
      expect((await events()).length, before);
    });

    test('a group that does not exist is refused', () async {
      expect(
        () => actions.setGroup(p, 'missing'),
        throwsA(
          isA<ActionRejected>().having(
            (e) => e.reason,
            'reason',
            RejectReason.noSuchGroup,
          ),
        ),
      );
    });

    test('created nodes log their own group', () async {
      await makeGroups();
      final id = await actions.create(
        type: NodeType.project,
        parentId: biztras,
        title: 'Newsletter',
        group: errands,
      );
      final created = (await events(EventTypes.created)).last;
      expect(created.nodeId, id);
      expect(created.groupId, errands);
    });
  });

  group('E-013 No group overrides an inherited group', () {
    test('E-013 dragging to the default list sets No group', () async {
      await makeGroups();
      await actions.setGroup(p, laptop);
      await actions.moveCardToGroup(s11, null);
      expect(await settingOf(s11), noGroup);
      expect(await layout(), ['No group: Print it, Set prices, A, 1.1']);
      // The next subtask still follows the project.
      await actions.markDone(s11);
      expect(await layout(), [
        'At laptop: 1.2',
        'No group: Print it, Set prices, A',
      ]);
    });

    test('E-013 with no group to override, the setting is cleared', () async {
      await makeGroups();
      await actions.setGroup(s11, errands);
      await actions.moveCardToGroup(s11, null);
      expect(await settingOf(s11), isNull);
      await actions.setGroup(q, noGroup);
      expect(await settingOf(q), isNull);
    });

    test('E-013 No group on a project keeps its cards out of the '
        'domain\'s group', () async {
      await makeGroups();
      await actions.setGroup(biztras, home);
      await actions.setGroup(p, noGroup);
      expect(await settingOf(p), noGroup);
      expect(await layout(), [
        'At home: Print it, Set prices, A',
        'No group: 1.1',
      ]);
    });
  });

  group('E-014 deleting a group', () {
    test('E-014 items follow the next group up, at the end, with no log '
        'events', () async {
      await makeGroups();
      await actions.setGroup(biztras, home);
      await actions.setGroup(p, laptop);
      expect(await layout(), [
        'At laptop: 1.1',
        'At home: Print it, Set prices, A',
      ]);
      final before = (await events()).length;
      await actions.deleteGroup(laptop);
      expect(await layout(), ['At home: Print it, Set prices, A, 1.1']);
      expect((await events()).length, before);
      expect(await settingOf(p), laptop);
      expect((await actions.loadGroups()).map((g) => g.name), [
        'Errands',
        'At home',
      ]);
    });

    test('E-014 with no group above, items go to the default list', () async {
      await makeGroups();
      await laptopWithThree();
      await actions.deleteGroup(laptop);
      expect(await layout(), ['No group: A, 1.1, Print it, Set prices']);
    });

    test('E-014 Undo restores the group and every card\'s place', () async {
      await makeGroups();
      await laptopWithThree();
      await actions.reorderCard(s11, 0);
      final deletion = await actions.deleteGroup(laptop);
      await actions.undoDeleteGroup(deletion);
      expect(await layout(), [
        'At laptop: 1.1, Print it, Set prices',
        'No group: A',
      ]);
      expect(
        () => actions.undoDeleteGroup(deletion),
        throwsA(
          isA<ActionRejected>().having(
            (e) => e.reason,
            'reason',
            RejectReason.staleUndo,
          ),
        ),
      );
    });

    test('E-014 a deleted group can no longer be set', () async {
      await makeGroups();
      await actions.deleteGroup(errands);
      expect(
        () => actions.setGroup(p, errands),
        throwsA(
          isA<ActionRejected>().having(
            (e) => e.reason,
            'reason',
            RejectReason.noSuchGroup,
          ),
        ),
      );
    });
  });

  group('editing and ordering groups', () {
    test('rename and change the icon', () async {
      await makeGroups();
      await actions.editGroup(home, name: 'Home', icon: 'house');
      final edited = (await actions.loadGroups()).last;
      expect(edited.name, 'Home');
      expect(edited.icon, 'house');
      await actions.editGroup(home, name: 'Home');
      expect((await actions.loadGroups()).last.icon, isNull);
    });

    test('group order sets the order on the Summary', () async {
      await makeGroups();
      await actions.setGroup(q, laptop);
      await actions.setGroup(r, errands);
      expect((await layout()).take(2), [
        'At laptop: Print it',
        'Errands: Set prices',
      ]);
      await actions.moveGroupUp(errands);
      expect((await layout()).take(2), [
        'Errands: Set prices',
        'At laptop: Print it',
      ]);
      await actions.reorderGroup(errands, 5);
      expect((await actions.loadGroups()).map((g) => g.name), [
        'At laptop',
        'At home',
        'Errands',
      ]);
      await actions.moveGroupDown(errands);
      expect((await actions.loadGroups()).last.name, 'Errands');
    });

    test('watchGroups emits after a change', () async {
      final emitted = actions.watchGroups().map(
        (gs) => gs.map((g) => g.name).toList(),
      );
      expect(
        emitted,
        emitsInOrder([
          isEmpty,
          ['At laptop'],
        ]),
      );
      await actions.createGroup('At laptop');
    });
  });

  group('E-015 Explorer reorders are logged', () {
    test('E-015 reorder logs the old and new position', () async {
      await makeGroups();
      await actions.setGroup(p, laptop);
      await actions.reorder(t2, 0);
      final logged = (await events(EventTypes.reordered)).single;
      expect(logged.eventType, EventTypes.reordered);
      expect(logged.nodeId, t2);
      expect(payload(logged), {
        'view': 'explorer',
        'old_position': 1,
        'new_position': 0,
        'old_group': laptop,
        'new_group': laptop,
      });
    });

    test('E-015 move up and move down are logged', () async {
      await actions.moveDown(q);
      await actions.moveUp(admin);
      final logged = await events(EventTypes.reordered);
      expect(logged.map((e) => e.nodeId), [q, admin]);
      expect(logged.map((e) => payload(e)['old_position']), [1, 3]);
      expect(logged.map((e) => payload(e)['new_position']), [2, 2]);
    });

    test('E-015 a move that changes nothing is not logged', () async {
      await actions.moveUp(p);
      await actions.reorder(admin, 99);
      expect(await events(EventTypes.reordered), isEmpty);
    });

    test('E-015 the Reorder screen logs only the items moved', () async {
      await actions.setChildOrder(biztras, [admin, p, q, r]);
      final logged = await events(EventTypes.reordered);
      expect(logged.single.nodeId, admin);
      expect(payload(logged.single)['old_position'], 3);
      expect(payload(logged.single)['new_position'], 0);
    });
  });

  test('Explorer events record the group from a live group only', () async {
    await makeGroups();
    await actions.setGroup(p, laptop);
    await actions.deleteGroup(laptop);
    await actions.reorder(t2, 0);
    expect((await events(EventTypes.reordered)).single.groupId, isNull);
  });
}
