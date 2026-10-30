import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/tree.dart';
import 'package:sahai/features/explorer/explorer_rows.dart';

TreeNode node(
  String id,
  NodeType type, {
  String? parent,
  int order = 0,
  NodeStatus? status,
}) => TreeNode(
  id: id,
  parentId: parent,
  type: type,
  title: id,
  status: type.hasStatus ? (status ?? NodeStatus.todo) : null,
  sortOrder: order,
);

void main() {
  // D > P > T1 (S1, S2), T2, T3; D > St > I1, I2 (done)
  Tree sample({NodeStatus t2 = NodeStatus.todo}) => Tree([
    node('D', NodeType.domain),
    node('P', NodeType.project, parent: 'D'),
    node('T1', NodeType.task, parent: 'P'),
    node('S1', NodeType.subtask, parent: 'T1'),
    node('S2', NodeType.subtask, parent: 'T1', order: 1),
    node('T2', NodeType.task, parent: 'P', order: 1, status: t2),
    node('T3', NodeType.task, parent: 'P', order: 2),
    node('St', NodeType.stream, parent: 'D', order: 1),
    node('I1', NodeType.streamItem, parent: 'St'),
    node(
      'I2',
      NodeType.streamItem,
      parent: 'St',
      order: 1,
      status: NodeStatus.done,
    ),
  ]);

  test('collapsed rows hide their children', () {
    final rows = explorerRows(sample(), {});
    expect(rows.map((r) => (r as NodeLine).node.id), ['D']);
  });

  test('expanded rows show children one level deeper, in order', () {
    final rows = explorerRows(sample(), {'D', 'P', 'T1', 'St'});
    expect(rows.map((r) => '${(r as NodeLine).node.id}@${r.depth}'), [
      'D@0',
      'P@1',
      'T1@2',
      'S1@3',
      'S2@3',
      'T2@2',
      'T3@2',
      'St@1',
      'I1@2',
      'I2@2',
    ]);
  });

  test('an open empty project or stream gets an Add line, a task does not', () {
    final tree = Tree([
      node('D', NodeType.domain),
      node('P', NodeType.project, parent: 'D'),
      node('St', NodeType.stream, parent: 'D', order: 1),
      node('P2', NodeType.project, parent: 'D', order: 2),
      node('T', NodeType.task, parent: 'P2'),
    ]);
    final rows = explorerRows(tree, {'D', 'P', 'St', 'P2', 'T'});
    final adds = rows.whereType<AddLine>().map((r) => r.parent.id);
    expect(adds, ['P', 'St']);
  });

  test('AT-007 marks: none for containers, lock for later tasks', () {
    final tree = sample();
    expect(markOf(tree, tree['D']!), RowMark.none);
    expect(markOf(tree, tree['St']!), RowMark.none);
    expect(markOf(tree, tree['T1']!), RowMark.todo);
    expect(markOf(tree, tree['T2']!), RowMark.locked);
    expect(markOf(tree, tree['I2']!), RowMark.done);
  });

  test('tasks are numbered by their place in the project', () {
    final tree = sample();
    expect(displayTitle(tree, tree['T3']!), '3. T3');
    expect(displayTitle(tree, tree['S1']!), 'S1');
  });

  test('subtitles show type, status and what is inside', () {
    final tree = sample();
    expect(subtitleOf(tree, tree['D']!), 'Domain · 1 project, 1 stream');
    expect(subtitleOf(tree, tree['P']!), 'Project · 3 tasks');
    expect(subtitleOf(tree, tree['T1']!), 'Current task · 2 subtasks');
    expect(subtitleOf(tree, tree['T2']!), 'Locked until 1 is done');
    expect(subtitleOf(tree, tree['T3']!), 'Locked until 2 is done');
    expect(subtitleOf(tree, tree['St']!), 'Stream · 2 items');
    expect(subtitleOf(tree, tree['I1']!), 'Stream item');
    expect(subtitleOf(tree, tree['I2']!), 'Done');
  });

  test('a locked task waits for the nearest TODO task above it', () {
    final tree = sample(t2: NodeStatus.done);
    expect(subtitleOf(tree, tree['T2']!), 'Done');
    expect(subtitleOf(tree, tree['T3']!), 'Locked until 1 is done');
  });

  test('paths list ancestors from the top', () {
    final tree = sample();
    expect(pathOf(tree, tree['S1']!), 'D › P › 1. T1');
    expect(pathOf(tree, tree['D']!), '');
  });

  test('inTreeOrder lists parents before children', () {
    expect(inTreeOrder(sample()).map((n) => n.id), [
      'D',
      'P',
      'T1',
      'S1',
      'S2',
      'T2',
      'T3',
      'St',
      'I1',
      'I2',
    ]);
  });
}
