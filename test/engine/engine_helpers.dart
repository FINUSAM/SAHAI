import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/tree.dart';

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
    bool remind = true,
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
        remindOnWake: remind,
        isRecurring: recurring,
      ),
    );
    return id;
  }

  Tree build() => Tree(_nodes);
}

/// The AT sheet's reference time: Tuesday, Nov 3, 2026, 3:00 PM UTC.
final now = DateTime.utc(2026, 11, 3, 15);

/// Biztras › Website relaunch › 1. Write copy (1.1, 1.2), 2. Design pages
/// (2.1, 2.2), 3. Launch; plus the Client admin stream (A, B, C).
TreeBuilder sampleTree({
  bool s11Done = false,
  bool s12Done = false,
  bool t1Done = false,
  bool aDone = false,
  Map<String, DateTime> setAside = const {},
}) {
  final b = TreeBuilder();
  void add(NodeType type, String id, {String? parent, bool done = false}) =>
      b.add(type, id, parent: parent, done: done, snoozeUntil: setAside[id]);
  add(NodeType.domain, 'biztras');
  add(NodeType.project, 'relaunch', parent: 'biztras');
  add(NodeType.task, 't1', parent: 'relaunch', done: t1Done);
  add(NodeType.subtask, 's1.1', parent: 't1', done: s11Done);
  add(NodeType.subtask, 's1.2', parent: 't1', done: s12Done);
  add(NodeType.task, 't2', parent: 'relaunch');
  add(NodeType.subtask, 's2.1', parent: 't2');
  add(NodeType.subtask, 's2.2', parent: 't2');
  add(NodeType.task, 't3', parent: 'relaunch');
  add(NodeType.stream, 'admin', parent: 'biztras');
  add(NodeType.streamItem, 'A', parent: 'admin', done: aDone);
  add(NodeType.streamItem, 'B', parent: 'admin');
  add(NodeType.streamItem, 'C', parent: 'admin');
  return b;
}
