import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import 'action_feedback.dart';

/// Reorders one parent's children (frame 7, AT-004, AT-005). Changes are
/// saved together on Done, and Close leaves the order as it was. The arrows
/// are the accessible alternative to dragging (PRD 13).
class ReorderScreen extends ConsumerStatefulWidget {
  const ReorderScreen({super.key, this.parentId});

  /// Null reorders the domains.
  final String? parentId;

  @override
  ConsumerState<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends ConsumerState<ReorderScreen> {
  List<String>? _order;
  List<String> _original = const [];

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider).value;
    final parent = widget.parentId == null ? null : tree?[widget.parentId!];
    if (tree != null && _order == null) {
      final children = widget.parentId == null
          ? tree.roots
          : tree.childrenOf(widget.parentId!);
      _original = [for (final c in children) c.id];
      _order = [..._original];
    }
    final order = _order;
    final theme = Theme.of(context);
    final isTasks = parent?.type == NodeType.project;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: Strings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(Strings.reorderChildren(parent?.type)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: order == null ? null : _save,
              child: const Text(Strings.doneButton),
            ),
          ),
        ],
      ),
      body: tree == null || order == null
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (parent != null)
                      Text(parent.title, style: theme.textTheme.titleMedium),
                    Text(
                      isTasks ? Strings.reorderTasksHint : Strings.reorderHint,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              footer: isTasks
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        Strings.reorderTasksNote,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : null,
              itemCount: order.length,
              onReorderItem: (from, to) => setState(() {
                final id = order.removeAt(from);
                order.insert(to, id);
              }),
              itemBuilder: (context, i) {
                final node = tree[order[i]]!;
                final title = isTasks ? '${i + 1}. ${node.title}' : node.title;
                return Material(
                  key: ValueKey(node.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.drag_indicator,
                              semanticLabel: Strings.dragHandle(node.title),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: theme.textTheme.titleMedium),
                                Text(
                                  _status(tree, order, node),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          tooltip: Strings.moveUpTooltip(node.title),
                          onPressed: i == 0 ? null : () => _shift(i, -1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          tooltip: Strings.moveDownTooltip(node.title),
                          onPressed: i == order.length - 1
                              ? null
                              : () => _shift(i, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// The status each child will have in the new order, so moving a task
  /// above the current one shows it becoming current.
  String _status(Tree tree, List<String> order, TreeNode node) {
    if (node.isDone) return Strings.done;
    if (node.type != NodeType.task) return Strings.typeName(node.type);
    final firstTodo = order.firstWhere((id) => tree[id]!.isTodo);
    return firstTodo == node.id ? Strings.currentTask : Strings.locked;
  }

  void _shift(int index, int by) => setState(() {
    final order = _order!;
    final id = order.removeAt(index);
    order.insert(index + by, id);
  });

  Future<void> _save() async {
    final order = _order!;
    var saved = true;
    if (!listEquals(order, _original)) {
      final actions = ref.read(nodeActionsProvider);
      saved =
          await runAction(context, () async {
            await actions.setChildOrder(widget.parentId, order);
            return true;
          }) ??
          false;
    }
    if (saved && mounted) Navigator.of(context).pop();
  }
}
