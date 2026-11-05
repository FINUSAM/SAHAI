import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../engine/visibility.dart';
import '../../shared/strings.dart';
import '../explorer/action_feedback.dart';
import '../explorer/explorer_rows.dart';
import '../set_aside/set_aside_flow.dart';
import 'card_sheet.dart';

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
    if (id == null || !summary.visibleIds.contains(id)) return;
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

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(summaryProvider);
    if (summary case AsyncData(:final value)) _applyFocus(value);
    final tree = ref.watch(treeProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.summary),
        actions: const [SettingsButton()],
      ),
      body: switch (summary) {
        AsyncData(:final value) when value.cards.isEmpty =>
          const _EmptySummary(),
        AsyncData(:final value) when tree != null => _CardList(
          tree: tree,
          cards: value.cards,
          highlighted: _highlighted,
          focusKey: _focusKey,
        ),
        AsyncError() => const Center(child: Text(Strings.loadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
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

class _CardList extends StatelessWidget {
  const _CardList({
    required this.tree,
    required this.cards,
    required this.highlighted,
    required this.focusKey,
  });

  final Tree tree;
  final List<SummaryCard> cards;
  final String? highlighted;
  final GlobalKey focusKey;

  // A Column rather than a lazy list, so a highlighted card further down
  // exists and can be scrolled to. The Summary is short by design.
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, card) in cards.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          SummaryCardTile(
            key: card.id == highlighted ? focusKey : null,
            tree: tree,
            card: card,
            highlighted: card.id == highlighted,
          ),
        ],
      ],
    ),
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
    final choice = await showCardSheet(context, tree, card);
    if (choice == null || !context.mounted) return;
    final title = displayTitle(tree, card.node);
    switch (choice) {
      case CardChoice.markDone:
        await completeWithUndo(
          context,
          ref.read(nodeActionsProvider),
          card.node.id,
          title,
        );
      case CardChoice.setAside:
        await setAsideWithPicker(context, ref, tree, card.node);
      case CardChoice.openInTree:
        context.go(Routes.explorerNode(card.node.id));
    }
  }
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
