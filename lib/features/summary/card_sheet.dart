import 'package:flutter/material.dart';

import '../../engine/tree.dart';
import '../../engine/visibility.dart';
import '../../shared/strings.dart';
import '../explorer/explorer_rows.dart';

/// What the user picked in a card's sheet (frame 7).
enum CardChoice { markDone, openInTree }

/// Tapping a card shows where it lives, as a chip per ancestor, and offers
/// Mark done and Open in tree (PRD 8.2, AT-029).
Future<CardChoice?> showCardSheet(
  BuildContext context,
  Tree tree,
  SummaryCard card,
) => showModalBottomSheet<CardChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => _CardSheet(tree: tree, card: card),
);

class _CardSheet extends StatelessWidget {
  const _CardSheet({required this.tree, required this.card});

  final Tree tree;
  final SummaryCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final node = card.node;
    void pick(CardChoice choice) => Navigator.of(context).pop(choice);

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
                  Strings.typeName(node.type),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final (i, ancestor) in card.path.indexed) ...[
                      if (i > 0)
                        Text(
                          Strings.pathSeparator.trim(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      Chip(
                        label: Text(displayTitle(tree, ancestor)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (node.notes.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Text(node.notes, style: theme.textTheme.bodyMedium),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text(Strings.markDone),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            onTap: () => pick(CardChoice.markDone),
          ),
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text(Strings.openInTree),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            onTap: () => pick(CardChoice.openInTree),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
