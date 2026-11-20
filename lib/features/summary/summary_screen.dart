import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../actions/node_actions.dart';
import '../../app/home_shell.dart';
import '../../app/practice_scope.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../engine/groups.dart';
import '../../engine/node_type.dart';
import '../../engine/set_aside_list.dart';
import '../../engine/settings.dart';
import '../../engine/tree.dart';
import '../../engine/visibility.dart';
import '../../shared/dashed_box.dart';
import '../../shared/group_icons.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';
import '../explorer/explorer_rows.dart';
import '../groups/group_picker.dart';
import '../set_aside/set_aside_flow.dart';
import 'card_sheet.dart';
import 'due_line.dart';

/// How long a card opened from a notification stays highlighted.
const focusHighlightDuration = Duration(seconds: 3);

/// The Summary Page (PRD 8.2, M2 frames 1–6): the next step of every
/// project and stream, nothing else.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, this.focusNodeId});

  /// A card to scroll to and highlight for a moment, when a notification
  /// for it was tapped (AT-051).
  final String? focusNodeId;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final _focusKey = GlobalKey();
  String? _pendingFocus;
  String? _highlighted;
  Timer? _fade;

  @override
  void initState() {
    super.initState();
    _pendingFocus = widget.focusNodeId;
  }

  @override
  void didUpdateWidget(SummaryScreen old) {
    super.didUpdateWidget(old);
    if (widget.focusNodeId != old.focusNodeId) {
      _pendingFocus = widget.focusNodeId;
    }
  }

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

  /// Highlights the pending card once it is on the Summary, after the
  /// frame, and scrolls it into view.
  void _applyFocus(SummaryResult summary) {
    final id = _pendingFocus;
    if (id == null) return;
    if (!summary.visibleIds.contains(id)) {
      _openHiddenItem(id);
      return;
    }
    _pendingFocus = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _highlighted = id);
      _fade?.cancel();
      _fade = Timer(focusHighlightDuration, () {
        if (mounted) setState(() => _highlighted = null);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _focusKey.currentContext;
        if (target != null && target.mounted) {
          unawaited(Scrollable.ensureVisible(target, alignment: 0.3));
        }
      });
    });
  }

  /// A recurring item's reminder can arrive while the item isn't on the
  /// Summary, so its sheet opens directly, saying why (AT-079, frame 11).
  /// Anything else waits until it's on the Summary.
  void _openHiddenItem(String id) {
    final tree = ref.read(treeProvider).value;
    final node = tree?[id];
    if (tree == null || node == null || !node.isRecurring) return;
    _pendingFocus = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final now = ref.read(clockProvider).now();
      final settings = ref.read(settingsProvider).value ?? const AppSettings();
      final card = SummaryCard.ofRecurring(tree, node);
      final choice = await showCardSheet(
        context,
        tree,
        card,
        now: now,
        settings: settings,
        hiddenNote: _hiddenNote(tree, node, now, settings),
      );
      if (choice != null && mounted) {
        await applyCardChoice(context, ref, tree, card, choice);
      }
    });
  }

  /// "Personal is set aside until Tue, Nov 10, so this isn't on the Summary."
  String _hiddenNote(
    Tree tree,
    TreeNode node,
    DateTime now,
    AppSettings settings,
  ) {
    final holder = setAsideAncestor(tree, node.id, now) ?? node;
    final until = wakeTimeOf(holder, now, settings: settings) ?? now;
    return Strings.notOnSummary(displayTitle(tree, holder), shortDate(until));
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(summaryProvider);
    if (summary case AsyncData(:final value)) _applyFocus(value);
    final arranged = ref.watch(arrangedSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.summary),
        actions: const [SettingsButton()],
      ),
      body: WithPracticeCoach(
        child: switch (arranged) {
          AsyncData(:final value) when value.cards.isEmpty =>
            const _EmptySummary(),
          AsyncData(:final value) => _CardList(
            arranged: value,
            highlighted: _highlighted,
            focusKey: _focusKey,
          ),
          AsyncError() => const Center(child: Text(Strings.loadError)),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Frame 2: a fresh install, or everything finished.
class _EmptySummary extends StatelessWidget {
  const _EmptySummary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 48,
              child: Icon(Icons.inbox_outlined, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              Strings.summaryEmptyTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              Strings.summaryEmptyBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text(Strings.openExplorer),
              onPressed: () => context.go(Routes.explorer),
            ),
          ],
        ),
      ),
    );
  }
}

// A Column rather than a lazy list, so a highlighted card further down
// exists and can be scrolled to. The Summary is short by design.
class _CardList extends ConsumerStatefulWidget {
  const _CardList({
    required this.arranged,
    required this.highlighted,
    required this.focusKey,
  });

  final ArrangedSummary arranged;
  final String? highlighted;
  final GlobalKey focusKey;

  @override
  ConsumerState<_CardList> createState() => _CardListState();
}

/// How close to the top or bottom edge a dragged card starts the list
/// scrolling, and how far it scrolls each frame at the edge.
const _autoScrollEdge = 72.0;
const _autoScrollStep = 14.0;

class _CardListState extends ConsumerState<_CardList> {
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  SummaryCard? _dragging;
  Timer? _autoScroll;
  double _scrollBy = 0;

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _startDrag(SummaryCard card) => setState(() => _dragging = card);

  void _endDrag() {
    _autoScroll?.cancel();
    _autoScroll = null;
    _scrollBy = 0;
    if (mounted && _dragging != null) setState(() => _dragging = null);
  }

  /// Scrolls while the dragged card is held near the top or bottom edge,
  /// so it can reach a group that's off screen.
  void _dragMoved(DragUpdateDetails details) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final y = box.globalToLocal(details.globalPosition).dy;
    final height = box.size.height;
    _scrollBy = y < _autoScrollEdge
        ? -_autoScrollStep
        : y > height - _autoScrollEdge
        ? _autoScrollStep
        : 0;
    if (_scrollBy == 0) {
      _autoScroll?.cancel();
      _autoScroll = null;
      return;
    }
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final target = (position.pixels + _scrollBy).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (target != position.pixels) _scroll.jumpTo(target);
    });
  }

  /// Drops [card] in [groupId] (null for No group). Within its own group it
  /// takes [index]; in another group it goes to the end, with Undo
  /// (frames 3 and 4, AT-087). Only slots and the group setting change,
  /// never the tree (AT-092).
  Future<void> _drop(SummaryCard card, String? groupId, {int? index}) async {
    _endDrag();
    final actions = ref.read(nodeActionsProvider);
    final found = widget.arranged.find(card.id);
    if (found == null) return;
    final (section, from) = found;
    if (section.group?.id == groupId) {
      if (index == null || index == from) return;
      await runAction(context, () => actions.reorderCard(card.id, index));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final token = await runAction(
      context,
      () => actions.moveCardToGroup(card.id, groupId),
    );
    if (token == null) return;
    showUndo(
      messenger,
      Strings.movedTo(groupName(widget.arranged.groups, groupId)),
      () => actions.undoGroupChange(token),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arranged = widget.arranged;
    final shown = {for (final s in arranged.sections) s.group?.id};
    // While a card is lifted, every group it could go to that has no cards
    // shows as a dashed place to drop it, after the list so nothing above
    // moves (frame 3).
    final emptyGroups = _dragging == null
        ? const <ContextGroup?>[]
        : <ContextGroup?>[
            for (final g in arranged.groups)
              if (!shown.contains(g.id)) g,
            if (!shown.contains(null) && arranged.groups.isNotEmpty) null,
          ];
    return SingleChildScrollView(
      key: _viewportKey,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (s, section) in arranged.sections.indexed) ...[
            if (arranged.showsHeaders)
              _GroupHeader(
                group: section.group,
                count: section.cards.length,
                first: s == 0,
                onDrop: (card) => _drop(card, section.group?.id, index: 0),
              )
            else if (s > 0)
              const SizedBox(height: 10),
            for (final (i, card) in section.cards.indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              _DraggableCard(
                key: ValueKey(card.id),
                tree: arranged.tree,
                card: card,
                focusKey: card.id == widget.highlighted
                    ? widget.focusKey
                    : null,
                highlighted: card.id == widget.highlighted,
                onDragStarted: () => _startDrag(card),
                onDragUpdate: _dragMoved,
                onDragEnd: _endDrag,
                onDrop: (dropped) =>
                    _drop(dropped, section.group?.id, index: i),
              ),
            ],
          ],
          for (final group in emptyGroups) ...[
            const SizedBox(height: 16),
            _EmptyGroupZone(
              group: group,
              onDrop: (card) => _drop(card, group?.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// A group's icon, name and card count (frame 2). Dropping a card on it
/// puts the card in that group, or at the top when it's already there.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.count,
    required this.first,
    required this.onDrop,
  });

  /// Null for No group.
  final ContextGroup? group;
  final int count;
  final bool first;
  final void Function(SummaryCard card) onDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = group?.name ?? Strings.noGroup;
    final icon = groupIcon(group?.icon);
    return DragTarget<SummaryCard>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => Semantics(
        header: true,
        label: Strings.groupHeader(name, count),
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: EdgeInsets.only(top: first ? 0 : 14, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: candidates.isEmpty
              ? null
              : BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Row(
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 12)],
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An empty group, shown only during a drag as a dashed place to drop the
/// card (frame 3). Empty groups are hidden at rest (AT-084).
class _EmptyGroupZone extends StatelessWidget {
  const _EmptyGroupZone({required this.group, required this.onDrop});

  final ContextGroup? group;
  final void Function(SummaryCard card) onDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = group?.name ?? Strings.noGroup;
    final icon = groupIcon(group?.icon);
    return DragTarget<SummaryCard>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => Semantics(
        label: Strings.dropInGroup(name),
        excludeSemantics: true,
        child: DashedBox(
          color: candidates.isEmpty
              ? theme.colorScheme.outline
              : theme.colorScheme.primary,
          fill: candidates.isEmpty ? null : theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 12)],
                Flexible(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Strings.emptyGroup,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card that lifts on press and hold, anywhere on it, with no separate
/// handle (M5 wireframe choice). It's also a place to drop another card,
/// which takes its position.
class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    super.key,
    required this.tree,
    required this.card,
    required this.focusKey,
    required this.highlighted,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDrop,
  });

  final Tree tree;
  final SummaryCard card;
  final GlobalKey? focusKey;
  final bool highlighted;
  final VoidCallback onDragStarted;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final VoidCallback onDragEnd;
  final void Function(SummaryCard card) onDrop;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scheme = Theme.of(context).colorScheme;
      final tile = SummaryCardTile(
        key: focusKey,
        tree: tree,
        card: card,
        highlighted: highlighted,
      );
      return DragTarget<SummaryCard>(
        onWillAcceptWithDetails: (details) => details.data.id != card.id,
        onAcceptWithDetails: (details) => onDrop(details.data),
        builder: (context, candidates, _) => LongPressDraggable<SummaryCard>(
          data: card,
          onDragStarted: onDragStarted,
          onDragUpdate: onDragUpdate,
          onDragEnd: (_) => onDragEnd(),
          feedback: SizedBox(
            width: constraints.maxWidth,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: SummaryCardTile(tree: tree, card: card),
            ),
          ),
          childWhenDragging: DashedBox(
            color: scheme.outline,
            child: Opacity(opacity: 0, child: tile),
          ),
          child: candidates.isEmpty
              ? tile
              : DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: tile,
                ),
        ),
      );
    },
  );
}

/// One card (frame 1): type label, title, path, a hint for sign-off and
/// empty-project cards, the clock that sets it aside (M3 frame 1) and the
/// checkmark. Tapping the card opens its sheet (frame 7).
class SummaryCardTile extends ConsumerWidget {
  const SummaryCardTile({
    super.key,
    required this.tree,
    required this.card,
    this.highlighted = false,
  });

  final Tree tree;
  final SummaryCard card;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final node = card.node;
    final title = displayTitle(tree, node);
    final path = card.path
        .map((a) => displayTitle(tree, a))
        .join(Strings.pathSeparator);
    final hint = cardHint(tree, card);
    final actions = ref.read(nodeActionsProvider);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: highlighted ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.typeName(node.type).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      path,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (node.dueOn != null) DueLine(node: node),
                    if (hint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(hint, style: theme.textTheme.bodySmall),
                      ),
                    if (card.reason == CardReason.emptyProject)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text(Strings.addATask),
                          onPressed: () => context.push(
                            Routes.newNode(NodeType.task, node.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.schedule),
                tooltip: Strings.setAsideTooltip(title),
                onPressed: () => setAsideWithPicker(context, ref, tree, node),
              ),
              IconButton(
                icon: const Icon(Icons.radio_button_unchecked),
                tooltip: Strings.markDoneTooltip(title),
                onPressed: () =>
                    completeWithUndo(context, actions, node.id, title),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showCardSheet(
      context,
      tree,
      card,
      now: ref.read(clockProvider).now(),
      settings: ref.read(settingsProvider).value ?? const AppSettings(),
    );
    if (choice == null || !context.mounted) return;
    await applyCardChoice(context, ref, tree, card, choice);
  }
}

/// Carries out what was picked in a card's sheet.
Future<void> applyCardChoice(
  BuildContext context,
  WidgetRef ref,
  Tree tree,
  SummaryCard card,
  CardChoice choice,
) async {
  final actions = ref.read(nodeActionsProvider);
  final title = displayTitle(tree, card.node);
  switch (choice) {
    case CardChoice.markDone:
      await completeWithUndo(context, actions, card.node.id, title);
    case CardChoice.setAside:
      await setAsideWithPicker(context, ref, tree, card.node);
    case CardChoice.skip:
      await skipWithUndo(context, actions, card.node);
    case CardChoice.stopRepeating:
      await stopRepeatingWithUndo(context, actions, card.node.id, title);
    case CardChoice.contextGroup:
      await changeCardGroup(context, ref, card.node.id);
    case CardChoice.openInTree:
      if (PracticeScope.isOn(context)) {
        showMessage(context, Strings.notInPractice);
        return;
      }
      context.go(Routes.explorerNode(card.node.id));
  }
}

/// Opens the group picker for a card's own item (frame 7). When that moves
/// the card to another group, it goes to the end there, with "Moved to"
/// and Undo, as a drag does (frame 4).
Future<void> changeCardGroup(
  BuildContext context,
  WidgetRef ref,
  String nodeId,
) async {
  final actions = ref.read(nodeActionsProvider);
  final tree = await actions.loadTree();
  final groups = await actions.loadGroups();
  final node = tree[nodeId];
  if (node == null || !context.mounted) return;
  final pick = await chooseGroup(
    context,
    tree: tree,
    groups: groups,
    title: displayTitle(tree, node),
    parentId: node.parentId,
    current: node.groupId,
  );
  if (pick == null || !context.mounted) return;
  final before = tree.effectiveGroupOf(nodeId);
  final messenger = ScaffoldMessenger.of(context);
  final token = await runAction(
    context,
    () => actions.setGroup(nodeId, pick.setting),
  );
  if (token == null) return;
  final after = (await actions.loadTree()).effectiveGroupOf(nodeId);
  if (after == before) return;
  final latest = await actions.loadGroups();
  showUndo(
    messenger,
    Strings.movedTo(groupName(latest, after)),
    () => actions.undoGroupChange(token),
  );
}

/// The grey hint under the path: why a sign-off or empty-project card is
/// here and what Mark done will do (frames 3–5). Null for a plain next step.
String? cardHint(Tree tree, SummaryCard card) => switch (card.reason) {
  CardReason.next => null,
  CardReason.taskSignOff => [
    Strings.allDone(NodeType.subtask, card.doneChildren),
    if (card.unlocks case final next?)
      Strings.markDoneToUnlock(displayTitle(tree, next)),
  ].join(Strings.separator),
  CardReason.projectSignOff => Strings.allDone(
    NodeType.task,
    card.doneChildren,
  ),
  CardReason.emptyProject => Strings.noTasksYet,
};
