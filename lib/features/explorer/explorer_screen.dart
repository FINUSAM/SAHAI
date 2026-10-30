import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import 'action_feedback.dart';
import 'explorer_rows.dart';
import 'explorer_state.dart';
import 'node_icons.dart';
import 'node_sheets.dart';

/// The whole tree (PRD 8.4, frames 2, 3 and 9).
class ExplorerScreen extends ConsumerWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(treeProvider);
    final hasRoots = tree.value?.roots.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.explorer),
        actions: const [SettingsButton()],
      ),
      body: switch (tree) {
        AsyncData(:final value) when value.roots.isEmpty => const _EmptyTree(),
        AsyncData(:final value) => _TreeList(tree: value),
        AsyncError() => const Center(child: Text(Strings.loadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: hasRoots
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text(Strings.addDomainButton),
              tooltip: Strings.addADomain,
              onPressed: () =>
                  context.push(Routes.newNode(NodeType.domain, null)),
            )
          : null,
    );
  }
}

class _EmptyTree extends StatelessWidget {
  const _EmptyTree();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              child: Icon(iconForType(NodeType.domain), size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              Strings.emptyTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              Strings.emptyBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text(Strings.addADomain),
              onPressed: () =>
                  context.push(Routes.newNode(NodeType.domain, null)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeList extends ConsumerWidget {
  const _TreeList({required this.tree});

  final Tree tree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = explorerRows(tree, ref.watch(expandedProvider));
    return ListView.separated(
      // Room for the floating button over the last row.
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      separatorBuilder: (context, i) => const Divider(height: 1),
      itemBuilder: (context, i) => switch (rows[i]) {
        final NodeLine line => _NodeTile(tree: tree, line: line),
        final AddLine line => _AddTile(line: line),
      },
    );
  }
}

/// Width of one level of indentation.
const _indent = 16.0;

class _NodeTile extends ConsumerWidget {
  const _NodeTile({required this.tree, required this.line});

  final Tree tree;
  final NodeLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final node = line.node;
    final isContainer = !node.type.hasStatus;
    final actions = ref.read(nodeActionsProvider);
    return InkWell(
      onTap: () => _openActions(context, ref, tree, node),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: EdgeInsets.only(left: line.depth * _indent),
          child: Row(
            children: [
              if (line.hasChildren)
                IconButton(
                  icon: Icon(
                    line.expanded ? Icons.expand_more : Icons.chevron_right,
                  ),
                  tooltip: line.expanded
                      ? Strings.collapse(line.title)
                      : Strings.expand(line.title),
                  onPressed: () =>
                      ref.read(expandedProvider.notifier).toggle(node.id),
                )
              else
                const SizedBox(width: 48),
              switch (line.mark) {
                RowMark.none => SizedBox(
                  width: 48,
                  child: Icon(iconForType(node.type)),
                ),
                RowMark.todo => IconButton(
                  icon: const Icon(Icons.radio_button_unchecked),
                  tooltip: Strings.markDoneTooltip(node.title),
                  onPressed: () =>
                      runAction(context, () => actions.markDone(node.id)),
                ),
                RowMark.done => IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: Strings.reopenTooltip(node.title),
                  onPressed: () =>
                      runAction(context, () => actions.reopen(node.id)),
                ),
                RowMark.locked => SizedBox(
                  width: 48,
                  child: Icon(
                    Icons.lock_outline,
                    semanticLabel: Strings.lockedLabel(node.title),
                  ),
                ),
              },
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isContainer ? FontWeight.bold : null,
                          decoration: node.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(line.subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: Strings.actionsFor(line.title),
                onPressed: () => _openActions(context, ref, tree, node),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends ConsumerWidget {
  const _AddTile({required this.line});

  final AddLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = line.parent.type.allowedChildren;
    return InkWell(
      onTap: () => _add(context, line.parent),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.only(left: line.depth * _indent + 48),
          child: Row(
            children: [
              const SizedBox(width: 48, child: Icon(Icons.add)),
              const SizedBox(width: 8),
              Expanded(child: Text(Strings.addChild(types))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adds a child to [parent]: straight to the form when only one type fits,
/// or through the Add menu for a domain (frame 4).
Future<void> _add(BuildContext context, TreeNode parent) async {
  final types = parent.type.allowedChildren;
  final type = types.length == 1
      ? types.single
      : await showAddMenu(context, parent);
  if (type == null || !context.mounted) return;
  await context.push(Routes.newNode(type, parent.id));
}

Future<void> _openActions(
  BuildContext context,
  WidgetRef ref,
  Tree tree,
  TreeNode node,
) async {
  final choice = await showNodeActions(context, tree, node);
  if (choice == null || !context.mounted) return;
  final actions = ref.read(nodeActionsProvider);
  switch (choice) {
    case NodeChoice.edit:
      await context.push(Routes.editNode(node.id));
    case NodeChoice.add:
      await _add(context, node);
    case NodeChoice.markDone:
      await runAction(context, () => actions.markDone(node.id));
    case NodeChoice.reopen:
      await runAction(context, () => actions.reopen(node.id));
    case NodeChoice.move:
      await context.push(Routes.moveNode(node.id));
    case NodeChoice.moveUp:
      await runAction(context, () => actions.moveUp(node.id));
    case NodeChoice.moveDown:
      await runAction(context, () => actions.moveDown(node.id));
    case NodeChoice.reorder:
      await context.push(Routes.reorder(node.parentId));
    case NodeChoice.delete:
      await _delete(context, ref, tree, node);
  }
}

/// Deletes without asking first; the Undo snackbar is the safety net
/// (PRD 7, AT-008).
Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Tree tree,
  TreeNode node,
) async {
  final actions = ref.read(nodeActionsProvider);
  final under = tree.descendantsOf(node.id).length;
  final eventId = await runAction(context, () => actions.delete(node.id));
  if (eventId == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(Strings.deleted(node.title, under)),
        duration: const Duration(seconds: 5),
        // Snackbars with an action stay until dismissed unless told not to.
        persist: false,
        action: SnackBarAction(
          label: Strings.undo,
          onPressed: () =>
              runAction(context, () => actions.undoDelete(eventId)),
        ),
      ),
    );
}
