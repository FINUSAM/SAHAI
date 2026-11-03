import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/surfaced.dart';
import 'package:sahai/engine/tree.dart';
import 'package:sahai/engine/visibility.dart';

/// Builds trees by hand for the engine tests: no database, no clock.
class TreeBuilder {
  final List<TreeNode> _nodes = [];
  final Map<String?, int> _nextOrder = {};

  String add(
    NodeType type,
    String id, {
    String? parent,
    bool done = false,
    DateTime? snoozeUntil,
    bool recurring = false,
  }) {
    final order = _nextOrder[parent] ?? 0;
    _nextOrder[parent] = order + 1;
    _nodes.add(
      TreeNode(
        id: id,
        parentId: parent,
        type: type,
        title: id,
        status: type.hasStatus
            ? (done ? NodeStatus.done : NodeStatus.todo)
            : null,
        sortOrder: order,
        snoozeUntil: snoozeUntil,
        isRecurring: recurring,
      ),
    );
    return id;
  }

  Tree build() => Tree(_nodes);
}

final now = DateTime.utc(2026, 11, 3, 15);

List<String> visible(Tree tree) =>
    computeSummary(tree, now: now).cards.map((c) => c.id).toList();

SummaryCard cardFor(Tree tree, String id) =>
    computeSummary(tree, now: now).cards.singleWhere((c) => c.id == id);

/// Biztras › Website relaunch › 1. Write copy (1.1, 1.2), 2. Design pages
/// (2.1, 2.2), 3. Launch; plus the Client admin stream (A, B, C).
TreeBuilder sampleTree({
  bool s11Done = false,
  bool s12Done = false,
  bool t1Done = false,
  bool aDone = false,
}) {
  final b = TreeBuilder();
  b.add(NodeType.domain, 'biztras');
  b.add(NodeType.project, 'relaunch', parent: 'biztras');
  b.add(NodeType.task, 't1', parent: 'relaunch', done: t1Done);
  b.add(NodeType.subtask, 's1.1', parent: 't1', done: s11Done);
  b.add(NodeType.subtask, 's1.2', parent: 't1', done: s12Done);
  b.add(NodeType.task, 't2', parent: 'relaunch');
  b.add(NodeType.subtask, 's2.1', parent: 't2');
  b.add(NodeType.subtask, 's2.2', parent: 't2');
  b.add(NodeType.task, 't3', parent: 'relaunch');
  b.add(NodeType.stream, 'admin', parent: 'biztras');
  b.add(NodeType.streamItem, 'A', parent: 'admin', done: aDone);
  b.add(NodeType.streamItem, 'B', parent: 'admin');
  b.add(NodeType.streamItem, 'C', parent: 'admin');
  return b;
}

void main() {
  test('AT-013 only the first subtask shows', () {
    final tree = sampleTree().build();
    expect(visible(tree), ['s1.1', 'A']);
    final card = cardFor(tree, 's1.1');
    expect(card.kind, CardKind.subtask);
    expect(card.reason, CardReason.next);
    expect(card.path.map((n) => n.id), ['biztras', 'relaunch', 't1']);
    expect(card.ownerId, 'relaunch');
  });

  test('AT-014 a task with no subtasks shows directly', () {
    final b = TreeBuilder();
    b.add(NodeType.domain, 'd');
    b.add(NodeType.project, 'p', parent: 'd');
    b.add(NodeType.task, 't1', parent: 'p');
    b.add(NodeType.task, 't2', parent: 'p');
    final tree = b.build();
    expect(visible(tree), ['t1']);
    final card = cardFor(tree, 't1');
    expect(card.kind, CardKind.task);
    expect(card.reason, CardReason.next);
    expect(card.path.map((n) => n.id), ['d', 'p']);
  });

  test('AT-015 the next subtask surfaces when the first is done', () {
    expect(visible(sampleTree(s11Done: true).build()), ['s1.2', 'A']);
  });

  test('AT-016 a task surfaces for sign-off once its subtasks are done', () {
    final tree = sampleTree(s11Done: true, s12Done: true).build();
    expect(visible(tree), ['t1', 'A']);
    final card = cardFor(tree, 't1');
    expect(card.kind, CardKind.task);
    expect(card.reason, CardReason.taskSignOff);
    expect(card.doneChildren, 2);
    expect(card.unlocks?.id, 't2');
    expect(tree['t1']!.isTodo, isTrue, reason: 'still TODO until signed off');
  });

  test('AT-017 the next task unlocks after sign-off', () {
    final tree = sampleTree(s11Done: true, s12Done: true, t1Done: true).build();
    expect(visible(tree), ['s2.1', 'A']);
  });

  test('AT-018 locked tasks never show', () {
    final cards = computeSummary(sampleTree().build(), now: now).cards;
    final ids = cards.map((c) => c.id);
    expect(ids, isNot(contains('t2')));
    expect(ids, isNot(contains('s2.1')));
    expect(ids, isNot(contains('s2.2')));
    expect(ids, isNot(contains('t3')));
  });

  test('AT-019 an empty project prompts for tasks', () {
    final b = TreeBuilder();
    b.add(NodeType.domain, 'freelance');
    b.add(NodeType.project, 'portfolio', parent: 'freelance');
    final tree = b.build();
    expect(visible(tree), ['portfolio']);
    final card = cardFor(tree, 'portfolio');
    expect(card.kind, CardKind.project);
    expect(card.reason, CardReason.emptyProject);
    expect(card.path.map((n) => n.id), ['freelance']);
  });

  test('AT-020 project sign-off, then nothing once it is done', () {
    final b = TreeBuilder();
    b.add(NodeType.domain, 'd');
    b.add(NodeType.project, 'p', parent: 'd');
    b.add(NodeType.task, 't1', parent: 'p', done: true);
    b.add(NodeType.task, 't2', parent: 'p', done: true);
    final tree = b.build();
    expect(visible(tree), ['p']);
    final card = cardFor(tree, 'p');
    expect(card.reason, CardReason.projectSignOff);
    expect(card.doneChildren, 2);

    final signedOff = TreeBuilder();
    signedOff.add(NodeType.domain, 'd');
    signedOff.add(NodeType.project, 'p', parent: 'd', done: true);
    signedOff.add(NodeType.task, 't1', parent: 'p', done: true);
    expect(visible(signedOff.build()), isEmpty);
  });

  test('AT-021 domains and streams never appear', () {
    final b = TreeBuilder();
    b.add(NodeType.domain, 'empty-domain');
    b.add(NodeType.domain, 'd');
    b.add(NodeType.stream, 'empty-stream', parent: 'd');
    expect(visible(b.build()), isEmpty);
  });

  test('AT-022 one normal stream item at a time, in order', () {
    expect(visible(sampleTree().build()), contains('A'));
    final afterA = sampleTree(aDone: true).build();
    final ids = visible(afterA);
    expect(ids, contains('B'));
    expect(ids, isNot(contains('A')));
    expect(ids, isNot(contains('C')));
    expect(cardFor(afterA, 'B').ownerId, 'admin');
  });

  test('AT-023 at most one card per project over random sequences', () {
    // Three tasks with subtasks; mark random visible items done, reopen
    // random done items, and check the invariant after every step.
    final random = Random(23);
    for (var run = 0; run < 50; run++) {
      final status = <String, bool>{}; // id -> done
      final ids = ['t1', 's1a', 's1b', 't2', 's2a', 't3', 's3a', 's3b'];
      for (final id in ids) {
        status[id] = false;
      }
      Tree build() {
        final b = TreeBuilder();
        b.add(NodeType.domain, 'd');
        b.add(NodeType.project, 'p', parent: 'd', done: false);
        b.add(NodeType.task, 't1', parent: 'p', done: status['t1']!);
        b.add(NodeType.subtask, 's1a', parent: 't1', done: status['s1a']!);
        b.add(NodeType.subtask, 's1b', parent: 't1', done: status['s1b']!);
        b.add(NodeType.task, 't2', parent: 'p', done: status['t2']!);
        b.add(NodeType.subtask, 's2a', parent: 't2', done: status['s2a']!);
        b.add(NodeType.task, 't3', parent: 'p', done: status['t3']!);
        b.add(NodeType.subtask, 's3a', parent: 't3', done: status['s3a']!);
        b.add(NodeType.subtask, 's3b', parent: 't3', done: status['s3b']!);
        return b.build();
      }

      for (var step = 0; step < 30; step++) {
        final cards = computeSummary(build(), now: now).cards;
        final fromProject = cards.where((c) => c.ownerId == 'p');
        expect(fromProject.length, lessThanOrEqualTo(1), reason: 'run $run');
        if (cards.isNotEmpty && random.nextBool()) {
          final pick = cards[random.nextInt(cards.length)].id;
          if (pick != 'p') status[pick] = true;
        } else {
          final done = status.entries.where((e) => e.value).toList();
          if (done.isNotEmpty) {
            status[done[random.nextInt(done.length)].key] = false;
          }
        }
      }
    }
  });

  test("AT-024 deleted children don't block the parent", () {
    // Deleted nodes never reach the Tree (the caller filters them), so a
    // task whose only remaining subtask is done is ready for sign-off.
    final b = TreeBuilder();
    b.add(NodeType.domain, 'd');
    b.add(NodeType.project, 'p', parent: 'd');
    b.add(NodeType.task, 't1', parent: 'p');
    b.add(NodeType.subtask, 's1.1', parent: 't1', done: true);
    // s1.2 was deleted: it isn't in the tree at all.
    final tree = b.build();
    expect(visible(tree), ['t1']);
    expect(cardFor(tree, 't1').reason, CardReason.taskSignOff);
  });

  group('set aside (always false in M2, ready for M3)', () {
    test('a set-aside subtask is skipped and the next one shows', () {
      final b = TreeBuilder();
      b.add(NodeType.domain, 'd');
      b.add(NodeType.project, 'p', parent: 'd');
      b.add(NodeType.task, 't1', parent: 'p');
      b.add(
        NodeType.subtask,
        's1',
        parent: 't1',
        snoozeUntil: now.add(const Duration(hours: 2)),
      );
      b.add(NodeType.subtask, 's2', parent: 't1');
      final result = computeSummary(b.build(), now: now);
      expect(result.cards.map((c) => c.id), ['s2']);
      expect(result.nextChangeAt, now.add(const Duration(hours: 2)));
    });

    test('a set-aside domain hides everything and nothing is pending', () {
      final b = TreeBuilder();
      b.add(
        NodeType.domain,
        'd',
        snoozeUntil: now.add(const Duration(days: 7)),
      );
      b.add(NodeType.project, 'p', parent: 'd');
      b.add(NodeType.task, 't1', parent: 'p');
      final result = computeSummary(b.build(), now: now);
      expect(result.cards, isEmpty);
      expect(result.nextChangeAt, now.add(const Duration(days: 7)));
    });

    test('a past snooze time means awake', () {
      final b = TreeBuilder();
      b.add(NodeType.domain, 'd');
      b.add(NodeType.stream, 's', parent: 'd');
      b.add(
        NodeType.streamItem,
        'i',
        parent: 's',
        snoozeUntil: now.subtract(const Duration(minutes: 1)),
      );
      final result = computeSummary(b.build(), now: now);
      expect(result.cards.map((c) => c.id), ['i']);
      expect(result.nextChangeAt, isNull);
    });
  });

  group('surfaced diff (PRD 9, E-001)', () {
    test('newly visible items appear in Summary order', () {
      final diff = diffVisible(previous: {'a', 'x'}, current: ['b', 'a', 'c']);
      expect(diff.appeared, ['b', 'c']);
      expect(diff.disappeared, ['x']);
    });

    test('a suppressed id gets no surfaced entry (E-001 undo)', () {
      final diff = diffVisible(
        previous: {'s1.2'},
        current: ['s1.1'],
        suppress: {'s1.1'},
      );
      expect(diff.appeared, isEmpty);
      expect(diff.disappeared, ['s1.2']);
    });

    test('no change is empty', () {
      expect(diffVisible(previous: {'a'}, current: ['a']).isEmpty, isTrue);
    });
  });
}
