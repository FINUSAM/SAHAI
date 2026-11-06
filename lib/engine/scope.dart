import 'node_type.dart';
import 'tree.dart';

/// How far a set aside from a card reaches (PRD 7): the item itself or one
/// of its ancestors. Stored in the `set_aside` event (AT-059).
enum SetAsideLevel { item, task, project, stream, domain }

/// One choice in the scope dropdown: the node that gets the wake time.
class ScopeOption {
  const ScopeOption(this.node, this.level);

  final TreeNode node;
  final SetAsideLevel level;
}

/// What a card for [id] can set aside, the item itself first (the
/// default), then its ancestors nearest first (AT-036): a subtask offers its
/// task, project and domain; a task, its project and domain; a project, its
/// domain; a stream item, its stream and domain. Only the chosen node gets
/// the wake time, and visibility check 5 hides everything under it.
List<ScopeOption> setAsideScopes(Tree tree, String id) {
  final node = tree[id];
  if (node == null) return const [];
  return [
    ScopeOption(node, SetAsideLevel.item),
    for (final ancestor in tree.ancestorsOf(id))
      if (_levelOf(ancestor.type) case final level?)
        ScopeOption(ancestor, level),
  ];
}

SetAsideLevel? _levelOf(NodeType type) => switch (type) {
  NodeType.task => SetAsideLevel.task,
  NodeType.project => SetAsideLevel.project,
  NodeType.stream => SetAsideLevel.stream,
  NodeType.domain => SetAsideLevel.domain,
  // Never an ancestor (PRD 4).
  NodeType.subtask || NodeType.streamItem => null,
};
