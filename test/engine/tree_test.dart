import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/tree.dart';

TreeNode node(
  String id,
  NodeType type, {
  String? parent,
  NodeStatus? status,
  int order = 0,
  String? group,
}) => TreeNode(
  id: id,
  parentId: parent,
  type: type,
  title: id,
  status: status ?? (type.hasStatus ? NodeStatus.todo : null),
  sortOrder: order,
  groupId: group,
);

/// Biztras > Website (project) > Task 1 [1.1, 1.2], Task 2 [2.1], Task 3.
Tree sampleTree({NodeStatus task1 = NodeStatus.todo}) => Tree([
  node('biztras', NodeType.domain),
  node('website', NodeType.project, parent: 'biztras', group: 'laptop'),
  node('t1', NodeType.task, parent: 'website', order: 0, status: task1),
  node('s1.1', NodeType.subtask, parent: 't1', order: 0),
  node('s1.2', NodeType.subtask, parent: 't1', order: 1),
  node('t2', NodeType.task, parent: 'website', order: 1),
  node('s2.1', NodeType.subtask, parent: 't2', order: 0),
  node('t3', NodeType.task, parent: 'website', order: 2),
]);

void main() {
  group('AT-007 locked tasks are marked', () {
    test('Task 2 is locked while Task 1 is TODO; Task 1 is not', () {
      final tree = sampleTree();
      expect(tree.currentTaskOf('website')?.id, 't1');
      expect(tree.isLocked('t1'), isFalse);
      expect(tree.isLocked('t2'), isTrue);
      expect(tree.isLocked('t3'), isTrue);
    });

    test('Task 2 unlocks once Task 1 is DONE', () {
      final tree = sampleTree(task1: NodeStatus.done);
      expect(tree.currentTaskOf('website')?.id, 't2');
      expect(tree.isLocked('t2'), isFalse);
      expect(tree.isLocked('t3'), isTrue);
    });

    test('order, not creation, decides the current task', () {
      final tree = Tree([
        node('p', NodeType.project),
        node('late', NodeType.task, parent: 'p', order: 5),
        node('early', NodeType.task, parent: 'p', order: 1),
      ]);
      expect(tree.currentTaskOf('p')?.id, 'early');
      expect(tree.isLocked('late'), isTrue);
    });

    test('DONE tasks and non-tasks are never locked', () {
      final tree = sampleTree(task1: NodeStatus.done);
      expect(tree.isLocked('t1'), isFalse);
      expect(tree.isLocked('s2.1'), isFalse);
      expect(tree.isLocked('website'), isFalse);
    });
  });

  test('children come back in order', () {
    final tree = sampleTree();
    expect(tree.childrenOf('website').map((n) => n.id), ['t1', 't2', 't3']);
    expect(tree.childrenOf('t1').map((n) => n.id), ['s1.1', 's1.2']);
    expect(tree.roots.map((n) => n.id), ['biztras']);
  });

  test('ancestors, descendants and domain', () {
    final tree = sampleTree();
    expect(tree.ancestorsOf('s1.2').map((n) => n.id), [
      't1',
      'website',
      'biztras',
    ]);
    expect(tree.descendantsOf('website').map((n) => n.id), [
      't1',
      's1.1',
      's1.2',
      't2',
      's2.1',
      't3',
    ]);
    expect(tree.domainOf('s2.1')?.id, 'biztras');
    expect(tree.domainOf('biztras')?.id, 'biztras');
  });

  test('the nearest group wins', () {
    final tree = sampleTree();
    expect(tree.effectiveGroupOf('s1.1'), 'laptop');
    expect(tree.effectiveGroupOf('biztras'), isNull);
  });

  test('a node with TODO children blocks completion', () {
    final tree = sampleTree();
    expect(tree.hasTodoChildren('t1'), isTrue);
    expect(tree.hasTodoChildren('t3'), isFalse);
  });
}
