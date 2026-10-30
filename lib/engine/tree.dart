import 'node_type.dart';

/// The engine's view of one node: only what the rules need.
class TreeNode {
  const TreeNode({
    required this.id,
    required this.parentId,
    required this.type,
    required this.title,
    required this.status,
    required this.sortOrder,
    this.groupId,
  });

  final String id;
  final String? parentId;
  final NodeType type;
  final String title;

  /// Null for domains and streams.
  final NodeStatus? status;
  final int sortOrder;
  final String? groupId;

  bool get isTodo => status == NodeStatus.todo;
  bool get isDone => status == NodeStatus.done;
}

/// An in-memory snapshot of the non-deleted tree (tech plan 4.1).
///
/// Deleted nodes are left out by the caller, so every rule here already
/// ignores them, as PRD 5 and 6 require.
class Tree {
  Tree(Iterable<TreeNode> nodes) {
    for (final node in nodes) {
      _byId[node.id] = node;
      (_children[node.parentId] ??= []).add(node);
    }
    for (final siblings in _children.values) {
      // Ties can only come from concurrent edits; the id keeps order stable.
      siblings.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    }
  }

  final Map<String, TreeNode> _byId = {};
  final Map<String?, List<TreeNode>> _children = {};

  TreeNode? operator [](String id) => _byId[id];

  bool contains(String id) => _byId.containsKey(id);

  /// Top-level nodes (domains), in order.
  List<TreeNode> get roots => List.unmodifiable(_children[null] ?? const []);

  /// Direct children of [parentId], in order.
  List<TreeNode> childrenOf(String parentId) =>
      List.unmodifiable(_children[parentId] ?? const []);

  /// Ancestors of [id], nearest first.
  List<TreeNode> ancestorsOf(String id) {
    final result = <TreeNode>[];
    var parentId = _byId[id]?.parentId;
    while (parentId != null) {
      final parent = _byId[parentId];
      if (parent == null) break;
      result.add(parent);
      parentId = parent.parentId;
    }
    return result;
  }

  /// Every node under [id], at any depth.
  List<TreeNode> descendantsOf(String id) {
    final result = <TreeNode>[];
    void walk(String parentId) {
      for (final child in childrenOf(parentId)) {
        result.add(child);
        walk(child.id);
      }
    }

    walk(id);
    return result;
  }

  /// The domain [id] belongs to (itself, if it is a domain).
  TreeNode? domainOf(String id) {
    final node = _byId[id];
    if (node == null) return null;
    if (node.type == NodeType.domain) return node;
    for (final ancestor in ancestorsOf(id)) {
      if (ancestor.type == NodeType.domain) return ancestor;
    }
    return null;
  }

  /// The context group that applies to [id]: its own, or its nearest
  /// ancestor's (PRD 8.2).
  String? effectiveGroupOf(String id) {
    final node = _byId[id];
    if (node == null) return null;
    if (node.groupId != null) return node.groupId;
    for (final ancestor in ancestorsOf(id)) {
      if (ancestor.groupId != null) return ancestor.groupId;
    }
    return null;
  }

  /// The project's current task: the first task in order that is TODO,
  /// whether set aside or not (PRD 5). Null when every task is done.
  TreeNode? currentTaskOf(String projectId) {
    for (final task in childrenOf(projectId)) {
      if (task.type == NodeType.task && task.isTodo) return task;
    }
    return null;
  }

  /// A task is locked when it is TODO and comes after its project's current
  /// task (PRD 4: Task N+1 stays locked until Task N is DONE).
  bool isLocked(String taskId) {
    final task = _byId[taskId];
    if (task == null || task.type != NodeType.task || !task.isTodo) {
      return false;
    }
    final projectId = task.parentId;
    if (projectId == null) return false;
    final current = currentTaskOf(projectId);
    return current != null && current.id != task.id;
  }

  /// Whether [id] has a TODO child, which blocks marking it done so that a
  /// DONE parent never holds a TODO child (PRD 7).
  bool hasTodoChildren(String id) => childrenOf(id).any((c) => c.isTodo);
}
