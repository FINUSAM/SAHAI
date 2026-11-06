import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../engine/node_type.dart';
import '../../engine/set_aside_list.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../set_aside/set_aside_flow.dart';
import 'action_feedback.dart';
import 'explorer_rows.dart';
import 'explorer_state.dart';
import 'node_icons.dart';
import 'node_sheets.dart';

/// How long an "Open in tree" highlight stays before fading (frame 8).
const highlightDuration = Duration(seconds: 3);

/// The whole tree (PRD 8.4, frames 2, 3 and 9).
class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key, this.focusNodeId});

  /// A node to open the tree at and highlight for a moment, from the
  /// Summary's "Open in tree" (M2 frame 8, AT-029).
  final String? focusNodeId;

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  final _scroll = ScrollController();
  String? _pendingFocus;
  String? _highlighted;
  Timer? _fade;

  @override
  void initState() {
    super.initState();
    _pendingFocus = widget.focusNodeId;
  }

  @override
  void didUpdateWidget(ExplorerScreen old) {
    super.didUpdateWidget(old);
    if (widget.focusNodeId != old.focusNodeId) {
      _pendingFocus = widget.focusNodeId;
    }
  }

  @override
  void dispose() {
    _fade?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Opens the ancestors of the pending node, scrolls to it and highlights
  /// it. The provider change happens after the frame, not during build.
  void _applyFocus(Tree tree) {
    final id = _pendingFocus;
    if (id == null) return;
    _pendingFocus = null;
    if (!tree.contains(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(expandedProvider.notifier)
          .open(tree.ancestorsOf(id).map((a) => a.id));
      setState(() => _highlighted = id);
      _fade?.cancel();
      _fade = Timer(highlightDuration, () {
        if (mounted) setState(() => _highlighted = null);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(tree, id));
    });
  }

  void _scrollTo(Tree tree, String id) {
    if (!mounted || !_scroll.hasClients) return;
    final rows = explorerRows(tree, ref.read(expandedProvider));
    final index = rows.indexWhere((r) => r is NodeLine && r.node.id == id);
    if (index < 0) return;
    // Rows vary in height, so this lands near the row rather than on it.
    final target = (index * _rowEstimate).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider);
    if (tree case AsyncData(:final value)) _applyFocus(value);
    final hasRoots = tree.value?.roots.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.explorer),
        actions: const [SettingsButton()],
      ),
      body: switch (tree) {
        AsyncData(:final value) when value.roots.isEmpty => const _EmptyTree(),
        AsyncData(:final value) => _TreeList(
          tree: value,
          controller: _scroll,
          highlighted: _highlighted,
        ),
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

/// A rough row height, for scrolling near a highlighted row.
const _rowEstimate = 64.0;

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
  const _TreeList({
    required this.tree,
    required this.controller,
    required this.highlighted,
  });

  final Tree tree;
  final ScrollController controller;
  final String? highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = explorerRows(tree, ref.watch(expandedProvider));
    // Set-aside marks change when an item wakes.
    ref.watch(recomputeTickProvider);
    final now = ref.watch(clockProvider).now();
    return ListView.separated(
      controller: controller,
      // Room for the floating button over the last row.
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: rows.length,
      separatorBuilder: (context, i) => const Divider(height: 1),
      itemBuilder: (context, i) => switch (rows[i]) {
        final NodeLine line => _NodeTile(
          tree: tree,
          line: line,
          now: now,
          highlighted: line.node.id == highlighted,
        ),
        final AddLine line => _AddTile(line: line),
      },
    );
  }
}

/// Width of one level of indentation.
const _indent = 16.0;

class _NodeTile extends ConsumerWidget {
  const _NodeTile({
    required this.tree,
    required this.line,
    required this.now,
    required this.highlighted,
  });

  final Tree tree;
  final NodeLine line;
  final DateTime now;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final node = line.node;
    final isContainer = !node.type.hasStatus;
    final actions = ref.read(nodeActionsProvider);
    // M3 frame 11: a set-aside node says when it's back, and everything
    // under it is greyed and says why.
    final wakeAt = wakeTimeOf(node, now);
    final hiddenBy = wakeAt == null
        ? setAsideAncestor(tree, node.id, now)
        : null;
    final subtitle = theme.textTheme.bodySmall;
    return InkWell(
      onTap: () => _openActions(context, ref, tree, node, now),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: highlighted
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: EdgeInsets.only(left: line.depth * _indent),
          child: Opacity(
            opacity: hiddenBy == null ? 1 : 0.55,
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
                        completeWithUndo(context, actions, node.id, line.title),
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
                        if (wakeAt != null)
                          Row(
                            children: [
                              Icon(
                                node.remindOnWake
                                    ? Icons.schedule
                                    : Icons.notifications_off_outlined,
                                size: 16,
                                semanticLabel: node.remindOnWake
                                    ? null
                                    : Strings.remindOff,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  Strings.back(
                                    wakeLabel(wakeAt, now, inSentence: true),
                                  ),
                                  style: subtitle,
                                ),
                              ),
                            ],
                          )
                        else if (hiddenBy != null)
                          Text(
                            Strings.hiddenWhile(displayTitle(tree, hiddenBy)),
                            style: subtitle,
                          )
                        else
                          Text(line.subtitle, style: subtitle),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: Strings.actionsFor(line.title),
                  onPressed: () => _openActions(context, ref, tree, node, now),
                ),
              ],
            ),
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
  DateTime now,
) async {
  final choice = await showNodeActions(context, tree, node, now: now);
  if (choice == null || !context.mounted) return;
  final actions = ref.read(nodeActionsProvider);
  switch (choice) {
    case NodeChoice.edit:
      await context.push(Routes.editNode(node.id));
    case NodeChoice.add:
      await _add(context, node);
    case NodeChoice.markDone:
      await completeWithUndo(
        context,
        actions,
        node.id,
        displayTitle(tree, node),
      );
    case NodeChoice.reopen:
      await runAction(context, () => actions.reopen(node.id));
    case NodeChoice.setAside:
      // The node is chosen directly, so no scope dropdown (frame 12).
      await setAsideWithPicker(context, ref, tree, node, withScope: false);
    case NodeChoice.wakeNow:
      await wakeNow(context, ref, node);
    case NodeChoice.changeTime:
      await changeTimeWithPicker(context, ref, tree, node);
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
