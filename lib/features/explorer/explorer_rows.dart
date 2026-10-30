import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';

/// What sits at the left of a row: nothing for domains and streams (they
/// have no status, AT-003), a circle to mark done, a check to reopen, or a
/// lock that replaces the check on locked tasks (AT-007, E-007).
enum RowMark { none, todo, done, locked }

/// One visible line of the Explorer.
sealed class ExplorerRow {
  const ExplorerRow(this.depth);

  final int depth;
}

class NodeLine extends ExplorerRow {
  const NodeLine({
    required int depth,
    required this.node,
    required this.title,
    required this.subtitle,
    required this.mark,
    required this.hasChildren,
    required this.expanded,
  }) : super(depth);

  final TreeNode node;
  final String title;
  final String subtitle;
  final RowMark mark;
  final bool hasChildren;
  final bool expanded;
}

/// "+ Add task" under an open, empty container, so its first child can be
/// added straight away (frame 5).
class AddLine extends ExplorerRow {
  const AddLine({required int depth, required this.parent}) : super(depth);

  final TreeNode parent;
}

/// The visible rows: every root, and the children of each expanded node.
List<ExplorerRow> explorerRows(Tree tree, Set<String> expanded) {
  final rows = <ExplorerRow>[];
  void walk(List<TreeNode> nodes, int depth) {
    for (final node in nodes) {
      final children = tree.childrenOf(node.id);
      final isOpen = expanded.contains(node.id);
      rows.add(
        NodeLine(
          depth: depth,
          node: node,
          title: displayTitle(tree, node),
          subtitle: subtitleOf(tree, node),
          mark: markOf(tree, node),
          hasChildren: children.isNotEmpty,
          expanded: isOpen,
        ),
      );
      if (!isOpen) continue;
      if (children.isEmpty) {
        // Tasks often have no subtasks, so they don't get an Add line.
        if (node.type != NodeType.task &&
            node.type.allowedChildren.isNotEmpty) {
          rows.add(AddLine(depth: depth + 1, parent: node));
        }
      } else {
        walk(children, depth + 1);
      }
    }
  }

  walk(tree.roots, 0);
  return rows;
}

/// Every node, parents before children, in the Explorer's order.
List<TreeNode> inTreeOrder(Tree tree) {
  final result = <TreeNode>[];
  void walk(List<TreeNode> nodes) {
    for (final node in nodes) {
      result.add(node);
      walk(tree.childrenOf(node.id));
    }
  }

  walk(tree.roots);
  return result;
}

/// Tasks are numbered by their place in the project, because they run in
/// that order: "1. Write copy".
String displayTitle(Tree tree, TreeNode node) {
  final number = taskNumber(tree, node);
  return number == null ? node.title : '$number. ${node.title}';
}

int? taskNumber(Tree tree, TreeNode node) {
  if (node.type != NodeType.task || node.parentId == null) return null;
  return tree.childrenOf(node.parentId!).indexWhere((t) => t.id == node.id) + 1;
}

RowMark markOf(Tree tree, TreeNode node) {
  if (!node.type.hasStatus) return RowMark.none;
  if (node.isDone) return RowMark.done;
  return tree.isLocked(node.id) ? RowMark.locked : RowMark.todo;
}

/// The grey line under a title, e.g. "Current task · 2 subtasks" or
/// "Locked until 1 is done".
String subtitleOf(Tree tree, TreeNode node) {
  final parts = <String>[];
  if (node.isDone) {
    parts.add(Strings.done);
  } else if (node.type == NodeType.task) {
    parts.add(
      tree.isLocked(node.id) ? _lockedUntil(tree, node) : Strings.currentTask,
    );
  } else {
    parts.add(Strings.typeName(node.type));
  }
  final counts = _childCounts(tree, node);
  if (counts.isNotEmpty) parts.add(counts);
  return parts.join(Strings.separator);
}

/// "Biztras › Website relaunch": the ancestors of [node], top first.
String pathOf(Tree tree, TreeNode node) => tree
    .ancestorsOf(node.id)
    .reversed
    .map((a) => displayTitle(tree, a))
    .join(Strings.pathSeparator);

/// A locked task waits for the nearest TODO task above it.
String _lockedUntil(Tree tree, TreeNode task) {
  final siblings = tree.childrenOf(task.parentId!);
  final index = siblings.indexWhere((t) => t.id == task.id);
  for (var i = index - 1; i >= 0; i--) {
    if (siblings[i].isTodo) return Strings.lockedUntil(i + 1);
  }
  return Strings.locked;
}

/// "1 project, 2 streams", "3 tasks". Empty when there are no children.
String _childCounts(Tree tree, TreeNode node) {
  final children = tree.childrenOf(node.id);
  return [
    for (final type in node.type.allowedChildren)
      if (children.where((c) => c.type == type).length case final n when n > 0)
        Strings.count(type, n),
  ].join(', ');
}
