// Times the visibility engine on a 10,000-item tree (PRD 13, AT-114).
//
// Usage, from the repo root:
//   dart run tool/benchmark.dart [items]
//
// This is the early warning the tech plan asks for from M2: it runs on the
// development machine, not a phone, so it's a trend, not the AT-114 check.
// The real check is a profile build on a mid-range phone in M7. The result
// is recorded in docs/plans/0004-m2-core-loop.md.
import 'dart:io';
import 'dart:math';

import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/tree.dart';
import 'package:sahai/engine/visibility.dart';

void main(List<String> args) {
  final target = args.isEmpty ? 10000 : int.parse(args.first);
  final nodes = generateTree(target);
  final buildWatch = Stopwatch()..start();
  final tree = Tree(nodes);
  buildWatch.stop();

  final now = DateTime.utc(2026, 11, 3, 15);
  // Warm up, then take the median of 25 runs.
  for (var i = 0; i < 5; i++) {
    computeSummary(tree, now: now);
  }
  final times = <int>[];
  late SummaryResult result;
  for (var i = 0; i < 25; i++) {
    final watch = Stopwatch()..start();
    result = computeSummary(tree, now: now);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  times.sort();
  stdout
    ..writeln('nodes: ${nodes.length}')
    ..writeln('cards: ${result.cards.length}')
    ..writeln('tree build: ${buildWatch.elapsedMilliseconds} ms')
    ..writeln('recompute median: ${times[times.length ~/ 2] / 1000} ms')
    ..writeln('recompute max: ${times.last / 1000} ms');
}

/// A realistic shape: domains holding projects of sequential tasks with
/// subtasks, plus streams of items, with about a third of items done.
List<TreeNode> generateTree(int target) {
  final random = Random(10000);
  final nodes = <TreeNode>[];
  var next = 0;
  String id() => 'n${next++}';

  TreeNode add(NodeType type, String? parent, int order, {bool done = false}) {
    final node = TreeNode(
      id: id(),
      parentId: parent,
      type: type,
      title: type.dbName,
      status: type.hasStatus
          ? (done ? NodeStatus.done : NodeStatus.todo)
          : null,
      sortOrder: order,
    );
    nodes.add(node);
    return node;
  }

  var domainOrder = 0;
  while (nodes.length < target) {
    final domain = add(NodeType.domain, null, domainOrder++);
    var childOrder = 0;
    for (var p = 0; p < 12 && nodes.length < target; p++) {
      final project = add(NodeType.project, domain.id, childOrder++);
      final taskCount = 3 + random.nextInt(5);
      // Earlier tasks are done, so the current task is somewhere inside.
      final doneTasks = random.nextInt(taskCount);
      for (var t = 0; t < taskCount; t++) {
        final taskDone = t < doneTasks;
        final task = add(NodeType.task, project.id, t, done: taskDone);
        final subtaskCount = random.nextInt(8);
        final doneSubtasks = taskDone
            ? subtaskCount
            : random.nextInt(subtaskCount + 1);
        for (var s = 0; s < subtaskCount; s++) {
          add(NodeType.subtask, task.id, s, done: s < doneSubtasks);
        }
      }
    }
    for (var s = 0; s < 4 && nodes.length < target; s++) {
      final stream = add(NodeType.stream, domain.id, childOrder++);
      final itemCount = 5 + random.nextInt(20);
      final doneItems = random.nextInt(itemCount);
      for (var i = 0; i < itemCount; i++) {
        add(NodeType.streamItem, stream.id, i, done: i < doneItems);
      }
    }
  }
  return nodes;
}
