import 'groups.dart';
import 'node_type.dart';
import 'recurrence.dart';
import 'settings.dart';

/// The engine's view of one node: only what the rules need.
class TreeNode {
  const TreeNode({
    required this.id,
    required this.parentId,
    required this.type,
    required this.title,
    this.notes = '',
    required this.status,
    required this.sortOrder,
    this.groupId,
    this.snoozeUntil,
    this.remindOnWake = true,
    this.isRecurring = false,
    this.schedule,
    this.dueOn,
    this.leadDays,
    this.snoozeOverridesShow = false,
  });

  final String id;
  final String? parentId;
  final NodeType type;
  final String title;
  final String notes;

  /// Null for domains and streams.
  final NodeStatus? status;
  final int sortOrder;
  final String? groupId;

  /// Set aside until this moment (UTC); null or past means awake (PRD 5).
  final DateTime? snoozeUntil;

  /// The set-aside picker's Remind me switch: whether waking notifies
  /// (PRD 7, AT-053).
  final bool remindOnWake;

  /// A stream item with a repeat schedule (PRD 7).
  final bool isRecurring;
  final Schedule? schedule;

  /// The current occurrence's due date, as local midnight (AT-081).
  final DateTime? dueOn;

  /// How many days early it shows; null means the Settings default.
  final int? leadDays;

  /// Wake now or Change time on this occurrence: [snoozeUntil] replaces the
  /// computed show time until the occurrence ends (E-005).
  final bool snoozeOverridesShow;

  bool get isTodo => status == NodeStatus.todo;
  bool get isDone => status == NodeStatus.done;

  /// The moment this node comes back, which may already have passed, or
  /// null when nothing holds it. A recurring item waits for the later of
  /// its show time and any set aside (AT-072).
  DateTime? wakeAt(AppSettings settings) {
    final due = dueOn;
    if (due == null || snoozeOverridesShow) return snoozeUntil;
    final show = showTime(
      due,
      leadDays: leadDays ?? settings.defaultLeadDays,
      dayStartMinutes: settings.dayStartMinutes,
    );
    final until = snoozeUntil;
    return until != null && until.isAfter(show) ? until : show;
  }
}

/// An in-memory snapshot of the non-deleted tree (tech plan 4.1).
///
/// Deleted nodes are left out by the caller, so every rule here already
/// ignores them, as PRD 5 and 6 require.
class Tree {
  /// [groupIds] are the context groups that still exist. A node set to a
  /// deleted group counts as unset (E-014). Null trusts every group id, for
  /// trees built by hand in tests.
  Tree(Iterable<TreeNode> nodes, {this.groupIds}) {
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

  /// The groups that still exist; null trusts every group id.
  final Set<String>? groupIds;

  TreeNode? operator [](String id) => _byId[id];

  bool contains(String id) => _byId.containsKey(id);

  /// Every node, in no particular order.
  Iterable<TreeNode> get nodes => _byId.values;

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
  /// ancestor's (PRD 8.2). Null means the default list.
  String? effectiveGroupOf(String id) => groupSourceOf(id)?.groupId;

  /// The group [id] would follow with no setting of its own: its parent's
  /// effective group. The picker offers "Same as `parent`" and "No group"
  /// only when this isn't null (E-013).
  String? inheritedGroupOf(String id) {
    final parentId = _byId[id]?.parentId;
    return parentId == null ? null : effectiveGroupOf(parentId);
  }

  /// The node whose setting decides [id]'s group: itself or its nearest
  /// ancestor with a live group, or null when it's in the default list.
  /// "No group" stops the search (E-013), and a deleted group is skipped,
  /// so its items follow the next group up (E-014).
  TreeNode? groupSourceOf(String id) {
    final node = _byId[id];
    if (node == null) return null;
    for (final n in [node, ...ancestorsOf(id)]) {
      final group = n.groupId;
      if (group == null || !hasGroup(group)) continue;
      return group == noGroup ? null : n;
    }
    return null;
  }

  /// Whether [setting] is "No group" or a group that still exists.
  bool hasGroup(String setting) =>
      setting == noGroup || (groupIds?.contains(setting) ?? true);

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
