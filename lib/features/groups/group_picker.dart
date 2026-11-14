import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../engine/groups.dart';
import '../../engine/tree.dart';
import '../../shared/group_icons.dart';
import '../../shared/strings.dart';
import '../explorer/explorer_rows.dart';

/// A group setting picked for a node: null to follow its parent, [noGroup],
/// or a group id (E-013).
class GroupPick {
  const GroupPick(this.setting);

  final String? setting;
}

/// The Context group line in the card sheet and the Explorer menu (frames
/// 6 and 10): "At laptop · set here", "At laptop · from Website relaunch",
/// or "No group".
String groupLine(Tree tree, List<ContextGroup> groups, TreeNode node) {
  final source = tree.groupSourceOf(node.id);
  if (source == null) {
    return node.groupId == noGroup && tree.inheritedGroupOf(node.id) != null
        ? Strings.setHere(Strings.noGroup)
        : Strings.noGroup;
  }
  final name = groupName(groups, source.groupId);
  return source.id == node.id
      ? Strings.setHere(name)
      : Strings.groupFrom(name, displayTitle(tree, source));
}

/// [groupId]'s name, or "No group" when it's null or gone.
String groupName(List<ContextGroup> groups, String? groupId) {
  for (final group in groups) {
    if (group.id == groupId) return group.name;
  }
  return Strings.noGroup;
}

/// The setting as it counts now: a deleted group counts as unset (E-014),
/// and "No group" with nothing above to override is the same as unset
/// (E-013).
String? liveSetting(Tree tree, String? setting, {String? parentId}) {
  if (setting == null || !tree.hasGroup(setting)) return null;
  final inherited = parentId == null ? null : tree.effectiveGroupOf(parentId);
  if (setting == noGroup && inherited == null) return null;
  return setting;
}

/// Opens the group picker (frame 7) for an item titled [title] whose parent
/// is [parentId] and whose setting is [current]. New group opens the New
/// group screen, and the group made there is the pick. Null when nothing
/// was picked.
Future<GroupPick?> chooseGroup(
  BuildContext context, {
  required Tree tree,
  required List<ContextGroup> groups,
  required String title,
  required String? parentId,
  required String? current,
}) async {
  final pick = await showModalBottomSheet<_Pick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _GroupPicker(
      tree: tree,
      groups: groups,
      title: title,
      parentId: parentId,
      current: liveSetting(tree, current, parentId: parentId),
    ),
  );
  if (pick == null || !context.mounted) return null;
  if (pick.isNewGroup) {
    final id = await context.push<String>(Routes.newGroup);
    return id == null ? null : GroupPick(id);
  }
  return GroupPick(pick.setting);
}

class _Pick {
  const _Pick(this.setting) : isNewGroup = false;
  const _Pick.newGroup() : setting = null, isNewGroup = true;

  final String? setting;
  final bool isNewGroup;
}

class _GroupPicker extends StatelessWidget {
  const _GroupPicker({
    required this.tree,
    required this.groups,
    required this.title,
    required this.parentId,
    required this.current,
  });

  final Tree tree;
  final List<ContextGroup> groups;
  final String title;
  final String? parentId;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parent = parentId;
    // "Same as" and a separate "No group" only make sense when there's a
    // group above to follow or to stay out of (E-013).
    final source = parent == null ? null : tree.groupSourceOf(parent);
    final inherited = source == null ? null : groupName(groups, source.groupId);
    void pick(_Pick value) => Navigator.of(context).pop(value);

    Widget option({
      required String? value,
      required String label,
      String? subtitle,
      IconData? icon,
    }) {
      final selected = value == current;
      return Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Row(
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 16)],
              Flexible(child: Text(label)),
            ],
          ),
          subtitle: subtitle == null ? null : Text(subtitle),
          onTap: () => pick(_Pick(value)),
        ),
      );
    }

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
                Text(Strings.contextGroup, style: theme.textTheme.titleLarge),
                if (title.isNotEmpty)
                  Text(title, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const Divider(height: 1),
          if (source != null)
            option(
              value: null,
              label: Strings.sameAs(displayTitle(tree, source)),
              subtitle: inherited,
            ),
          for (final group in groups)
            option(
              value: group.id,
              label: group.name,
              icon: groupIcon(group.icon),
            ),
          if (source != null)
            option(
              value: noGroup,
              label: Strings.noGroup,
              subtitle: Strings.keepOutOf(inherited!),
            )
          else
            option(value: null, label: Strings.noGroup),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: const Icon(Icons.add),
            title: const Text(Strings.newGroup),
            onTap: () => pick(const _Pick.newGroup()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
