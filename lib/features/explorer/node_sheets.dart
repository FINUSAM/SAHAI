import 'package:flutter/material.dart';

import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import 'explorer_rows.dart';
import 'node_icons.dart';

/// What the user picked in a node's actions sheet (frame 6).
enum NodeChoice {
  edit,
  add,
  markDone,
  reopen,
  move,
  moveUp,
  moveDown,
  reorder,
  delete,
}

/// The "⋮" menu for [node]. It only offers what the rules allow: no Mark done
/// on domains, streams or locked tasks (AT-003, E-007), and Add only for
/// types that can hold children (AT-002).
Future<NodeChoice?> showNodeActions(
  BuildContext context,
  Tree tree,
  TreeNode node,
) => showModalBottomSheet<NodeChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => _NodeActionsSheet(tree: tree, node: node),
);

class _NodeActionsSheet extends StatelessWidget {
  const _NodeActionsSheet({required this.tree, required this.node});

  final Tree tree;
  final TreeNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siblings = node.parentId == null
        ? tree.roots
        : tree.childrenOf(node.parentId!);
    final index = siblings.indexWhere((s) => s.id == node.id);
    final path = pathOf(tree, node);
    final mark = markOf(tree, node);
    final parentType = node.type.parentType;
    void pick(NodeChoice choice) => Navigator.of(context).pop(choice);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle(tree, node),
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  [
                    Strings.typeName(node.type),
                    if (path.isNotEmpty) path,
                  ].join(Strings.separator),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _item(Icons.edit_outlined, Strings.edit, () => pick(NodeChoice.edit)),
          if (node.type.allowedChildren.isNotEmpty)
            _item(
              Icons.add,
              Strings.addChild(node.type.allowedChildren),
              () => pick(NodeChoice.add),
            ),
          if (mark == RowMark.todo)
            _item(
              Icons.check_circle_outline,
              Strings.markDone,
              () => pick(NodeChoice.markDone),
            ),
          if (mark == RowMark.done)
            _item(Icons.undo, Strings.reopen, () => pick(NodeChoice.reopen)),
          if (parentType != null)
            _item(
              Icons.drive_file_move_outlined,
              Strings.moveToAnother(parentType),
              () => pick(NodeChoice.move),
            ),
          if (siblings.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text(Strings.moveUp),
                      onPressed: index > 0
                          ? () => pick(NodeChoice.moveUp)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text(Strings.moveDown),
                      onPressed: index < siblings.length - 1
                          ? () => pick(NodeChoice.moveDown)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            _item(
              Icons.reorder,
              Strings.reorderChildren(parentType),
              () => pick(NodeChoice.reorder),
            ),
          ],
          const Divider(height: 1),
          _item(
            Icons.delete_outline,
            Strings.delete,
            () => pick(NodeChoice.delete),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    onTap: onTap,
  );
}

/// Lets the user pick which kind of child to add to [parent], listing only
/// the valid types (frame 4, AT-002).
Future<NodeType?> showAddMenu(BuildContext context, TreeNode parent) =>
    showModalBottomSheet<NodeType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.addTo(parent.title),
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      Strings.typeName(parent.type),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              for (final type in parent.type.allowedChildren)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(child: Icon(iconForType(type))),
                  title: Text(Strings.typeName(type)),
                  subtitle: Text(Strings.typeDescription(type)),
                  onTap: () => Navigator.of(context).pop(type),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
