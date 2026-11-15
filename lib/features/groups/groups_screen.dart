import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../actions/node_actions.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../engine/groups.dart';
import '../../engine/tree.dart';
import '../../shared/group_icons.dart';
import '../../shared/strings.dart';
import '../explorer/action_feedback.dart';

/// Context groups in Settings (frame 12): the groups in Summary order, with
/// up and down buttons, how many items each is set on, and New group. The
/// order is set only here; headers on the Summary don't drag.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(groupsProvider);
    final tree = ref.watch(treeProvider).value;
    final actions = ref.read(nodeActionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.contextGroups)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text(Strings.newGroup),
        onPressed: () => context.push(Routes.newGroup),
      ),
      body: switch (groups) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                value.isEmpty ? Strings.noGroupsYet : Strings.groupsHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final (i, group) in value.indexed) ...[
              ListTile(
                minTileHeight: 64,
                leading: SizedBox(
                  width: 32,
                  child: Icon(groupIcon(group.icon)),
                ),
                title: Text(group.name),
                subtitle: Text(
                  Strings.setOnItems(
                    tree == null ? 0 : setOnCount(tree, group),
                  ),
                ),
                onTap: () => context.push(Routes.editGroup(group.id)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: Strings.moveGroupUp(group.name),
                      onPressed: i == 0
                          ? null
                          : () => runAction(
                              context,
                              () => actions.moveGroupUp(group.id),
                            ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      tooltip: Strings.moveGroupDown(group.name),
                      onPressed: i == value.length - 1
                          ? null
                          : () => runAction(
                              context,
                              () => actions.moveGroupDown(group.id),
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
        AsyncError() => const Center(child: Text(Strings.loadError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// How many items [group] is set on directly (frame 12).
int setOnCount(Tree tree, ContextGroup group) =>
    tree.nodes.where((n) => n.groupId == group.id).length;
