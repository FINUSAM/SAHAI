import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../actions/node_actions.dart';
import '../../app/providers.dart';
import '../../engine/recurrence.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../engine/tree.dart';
import '../../engine/visibility.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';
import '../explorer/explorer_rows.dart';
import '../groups/group_picker.dart';

/// What the user picked in a card's sheet (frame 7).
enum CardChoice {
  markDone,
  setAside,
  skip,
  stopRepeating,
  contextGroup,
  openInTree,
}

/// Tapping a card shows where it lives, as a chip per ancestor, and offers
/// Mark done, Set aside (M3) and Open in tree (PRD 8.2, AT-029). A recurring
/// card adds its due date and schedule, Skip and Stop repeating (M4 frame 5).
/// M5 adds Context group, and Move up and Move down with the card's place,
/// everything a drag does without dragging (M5 frame 6, AT-116). The sheet
/// stays open between Move taps.
///
/// [hiddenNote] says why an item opened from a reminder isn't on the Summary
/// (M4 frame 11). The sheet then offers only what that frame shows.
Future<CardChoice?> showCardSheet(
  BuildContext context,
  Tree tree,
  SummaryCard card, {
  required DateTime now,
  required AppSettings settings,
  String? hiddenNote,
}) => showModalBottomSheet<CardChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => _CardSheet(
    tree: tree,
    card: card,
    now: now,
    settings: settings,
    hiddenNote: hiddenNote,
  ),
);

class _CardSheet extends ConsumerWidget {
  const _CardSheet({
    required this.tree,
    required this.card,
    required this.now,
    required this.settings,
    required this.hiddenNote,
  });

  final Tree tree;
  final SummaryCard card;
  final DateTime now;
  final AppSettings settings;
  final String? hiddenNote;

  /// "4 days overdue · due Nov 5" or "Due today", in bold once it's the day
  /// (frames 5, 11); otherwise the plain label.
  Widget _dueLine(ThemeData theme, DateTime dueOn) {
    final start = settings.dayStartMinutes;
    final days = daysUntilDue(dueOn, logicalDate(now, dayStartMinutes: start));
    return Text(
      [
        dueLabel(dueOn, now, dayStartMinutes: start),
        if (days < 0)
          Strings.dueOn(
            dueDate(dueOn, logicalDate(now, dayStartMinutes: start)),
          ).toLowerCase(),
      ].join(Strings.separator),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: days <= 0 ? FontWeight.bold : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final node = card.node;
    void pick(CardChoice choice) => Navigator.of(context).pop(choice);
    // Live, so the position line follows each Move tap.
    final arranged = hiddenNote == null
        ? ref.watch(arrangedSummaryProvider).value
        : null;

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
                if (node.dueOn case final dueOn?) ...[
                  const SizedBox(height: 10),
                  _dueLine(theme, dueOn),
                ],
                if (node.schedule case final schedule?)
                  Text(
                    repeatsLine(schedule),
                    style: theme.textTheme.bodyMedium,
                  ),
                if (hiddenNote case final note?) ...[
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(note, style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ],
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
          if (hiddenNote == null)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text(Strings.setAsideTitle),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () => pick(CardChoice.setAside),
            ),
          if (node.schedule case final schedule?) ...[
            ListTile(
              leading: const Icon(Icons.skip_next_outlined),
              title: const Text(Strings.skipOccurrence),
              subtitle: Text(
                Strings.nextDueOn(
                  dueDate(
                    schedule.nextDue(node.dueOn!),
                    logicalDate(now, dayStartMinutes: settings.dayStartMinutes),
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () => pick(CardChoice.skip),
            ),
            if (hiddenNote == null)
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text(Strings.stopRepeating),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                onTap: () => pick(CardChoice.stopRepeating),
              ),
          ],
          if (arranged != null) ..._orderRows(context, ref, arranged, pick),
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

  /// Context group, Move up and Move down, and "Position 1 of 3 in At
  /// laptop" (frame 6).
  List<Widget> _orderRows(
    BuildContext context,
    WidgetRef ref,
    ArrangedSummary arranged,
    void Function(CardChoice choice) pick,
  ) {
    final theme = Theme.of(context);
    final tree = arranged.tree;
    final node = tree[card.node.id];
    if (node == null) return const [];
    final found = arranged.find(node.id);
    final actions = ref.read(nodeActionsProvider);
    final title = displayTitle(tree, node);
    return [
      ListTile(
        leading: const Icon(Icons.view_agenda_outlined),
        title: const Text(Strings.contextGroup),
        subtitle: Text(groupLine(tree, arranged.groups, node)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        onTap: () => pick(CardChoice.contextGroup),
      ),
      if (found case (final section, final index)) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: Strings.moveCardUp(title),
                  excludeSemantics: true,
                  button: true,
                  enabled: index > 0,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text(Strings.moveUp),
                    onPressed: index > 0
                        ? () => runAction(
                            context,
                            () => actions.moveCardUp(node.id),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: Strings.moveCardDown(title),
                  excludeSemantics: true,
                  button: true,
                  enabled: index < section.cards.length - 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text(Strings.moveDown),
                    onPressed: index < section.cards.length - 1
                        ? () => runAction(
                            context,
                            () => actions.moveCardDown(node.id),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Semantics(
            liveRegion: true,
            child: Text(
              arranged.showsHeaders
                  ? Strings.positionIn(
                      index + 1,
                      section.cards.length,
                      section.group?.name ?? Strings.noGroup,
                    )
                  : Strings.positionOnSummary(index + 1, section.cards.length),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
      const Divider(height: 1),
    ];
  }
}
