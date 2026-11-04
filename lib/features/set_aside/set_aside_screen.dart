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
import '../explorer/explorer_rows.dart';
import '../explorer/node_icons.dart';
import 'set_aside_flow.dart';

/// The Set-Aside page (PRD 8.3, frames 8 to 10): everything set aside,
/// soonest first, grouped Today, Tomorrow and Later.
class SetAsideScreen extends ConsumerStatefulWidget {
  const SetAsideScreen({super.key});

  @override
  ConsumerState<SetAsideScreen> createState() => _SetAsideScreenState();
}

class _SetAsideScreenState extends ConsumerState<SetAsideScreen> {
  // "in 5 h" counts down, and an item whose time passes leaves the list,
  // even when its waking doesn't change the Summary.
  late final Timer _minute;

  @override
  void initState() {
    super.initState();
    _minute = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minute.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider);
    ref.watch(recomputeTickProvider);
    final now = ref.watch(clockProvider).now();
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.setAside),
        actions: const [SettingsButton()],
      ),
      body: switch (tree) {
        AsyncData(:final value) => _Body(
          tree: value,
          entries: setAsideEntries(value, now: now),
          now: now,
        ),
        AsyncError() => const Center(child: Text(Strings.loadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.tree, required this.entries, required this.now});

  final Tree tree;
  final List<SetAsideEntry> entries;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const _Empty();
    final theme = Theme.of(context);
    final children = <Widget>[];
    WakeDay? group;
    for (final entry in entries) {
      final day = wakeDayOf(entry.wakeAt, now);
      if (day != group) {
        group = day;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              switch (day) {
                WakeDay.today => Strings.groupToday,
                WakeDay.tomorrow => Strings.groupTomorrow,
                WakeDay.later => Strings.groupLater,
              }.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SetAsideCard(tree: tree, entry: entry, now: now),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: children,
    );
  }
}

/// Frame 10.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              Strings.nothingSetAside,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              Strings.nothingSetAsideBody,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Hides 2 items", "Hides 1 project, 1 stream". Null when it hides
/// nothing.
String? hidesLine(List<TreeNode> hidden) {
  if (hidden.isEmpty) return null;
  final counts = <NodeType, int>{};
  for (final node in hidden) {
    counts[node.type] = (counts[node.type] ?? 0) + 1;
  }
  return Strings.hides(
    [for (final e in counts.entries) Strings.count(e.key, e.value)].join(', '),
  );
}

/// One card (frame 8): type, title, path, wake time and time remaining,
/// what it hides, and Wake now. Tapping it opens its sheet (frame 9).
class SetAsideCard extends ConsumerWidget {
  const SetAsideCard({
    super.key,
    required this.tree,
    required this.entry,
    required this.now,
  });

  final Tree tree;
  final SetAsideEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final node = entry.node;
    final title = displayTitle(tree, node);
    final path = pathOf(tree, node);
    final hides = hidesLine(entry.hidden);
    final small = theme.textTheme.bodySmall;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
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
                    if (path.isNotEmpty)
                      Text(
                        path,
                        style: small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    WakeLine(
                      wakeAt: entry.wakeAt,
                      now: now,
                      remind: node.remindOnWake,
                    ),
                    if (hides != null)
                      Row(
                        children: [
                          Text(hides, style: small),
                          const Icon(Icons.expand_more, size: 18),
                        ],
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => wakeNow(context, ref, node),
                child: Text(
                  Strings.wakeNow,
                  semanticsLabel: Strings.wakeNowTooltip(title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showSetAsideSheet(context, tree, entry, now);
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case SetAsideChoiceAction.wakeNow:
        await wakeNow(context, ref, entry.node);
      case SetAsideChoiceAction.changeTime:
        await changeTimeWithPicker(context, ref, tree, entry.node);
      case SetAsideChoiceAction.openInTree:
        context.go(Routes.explorerNode(entry.node.id));
    }
  }
}

/// "🕓 Wed 8:00 AM · in 17 h", with a crossed-out bell instead of the clock
/// when Remind me is off (M3 wireframe choice).
class WakeLine extends StatelessWidget {
  const WakeLine({
    super.key,
    required this.wakeAt,
    required this.now,
    required this.remind,
  });

  final DateTime wakeAt;
  final DateTime now;
  final bool remind;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        remind ? Icons.schedule : Icons.notifications_off_outlined,
        size: 18,
        semanticLabel: remind ? null : Strings.remindOff,
      ),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          [
            wakeLabel(wakeAt, now),
            timeRemaining(wakeAt, now),
          ].join(Strings.separator),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

/// What the user picked in a Set-Aside card's sheet.
enum SetAsideChoiceAction { wakeNow, changeTime, openInTree }

/// Frame 9: when it comes back, where it lives, what it hides until then,
/// and Wake now, Change time and Open in tree.
Future<SetAsideChoiceAction?> showSetAsideSheet(
  BuildContext context,
  Tree tree,
  SetAsideEntry entry,
  DateTime now,
) => showModalBottomSheet<SetAsideChoiceAction>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final theme = Theme.of(context);
    final node = entry.node;
    final chain = [...tree.ancestorsOf(node.id).reversed, node];
    void pick(SetAsideChoiceAction choice) => Navigator.of(context).pop(choice);
    Widget item(IconData icon, String label, SetAsideChoiceAction choice) =>
        ListTile(
          leading: Icon(icon),
          title: Text(label),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onTap: () => pick(choice),
        );
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
                    Strings.backAt(wakeLabel(entry.wakeAt, now)),
                    timeRemaining(entry.wakeAt, now),
                  ].join(Strings.separator),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final (i, n) in chain.indexed) ...[
                      if (i > 0)
                        Text(
                          Strings.pathSeparator.trim(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      Chip(
                        label: Text(displayTitle(tree, n)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                if (entry.hidden.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    Strings.hiddenUntilThen,
                    style: theme.textTheme.bodyMedium,
                  ),
                  for (final hidden in entry.hidden)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            hidden.type.hasStatus
                                ? Icons.radio_button_unchecked
                                : iconForType(hidden.type),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(displayTitle(tree, hidden))),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          item(Icons.alarm_on, Strings.wakeNow, SetAsideChoiceAction.wakeNow),
          item(
            Icons.edit_calendar_outlined,
            Strings.changeTime,
            SetAsideChoiceAction.changeTime,
          ),
          item(
            Icons.account_tree_outlined,
            Strings.openInTree,
            SetAsideChoiceAction.openInTree,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  },
);
