import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../actions/node_actions.dart';
import '../../app/providers.dart';
import '../../engine/groups.dart';
import '../../shared/group_icons.dart';
import '../../shared/strings.dart';
import '../explorer/action_feedback.dart';
import 'groups_screen.dart';

/// New group and Edit group (frame 13): a name, an optional icon, and for
/// an existing group, Delete group. New group closes with the new group's
/// id, so the group picker can select it.
class GroupFormScreen extends ConsumerStatefulWidget {
  const GroupFormScreen.create({super.key}) : id = null;

  const GroupFormScreen.edit({super.key, required String this.id});

  /// Set when editing.
  final String? id;

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _name = TextEditingController();
  String? _icon;
  var _filled = false;
  var _saving = false;

  bool get _isEdit => widget.id != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ref.watch(groupsProvider).value;
    final tree = ref.watch(treeProvider).value;
    ContextGroup? group;
    for (final g in groups ?? const <ContextGroup>[]) {
      if (g.id == widget.id) group = g;
    }
    if (group != null && !_filled) {
      _name.text = group.name;
      _icon = groupIcons.containsKey(group.icon) ? group.icon : null;
      _filled = true;
    }
    if (_isEdit && group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: groups == null
              ? const CircularProgressIndicator()
              : const Text(Strings.noSuchGroup),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? Strings.editGroup : Strings.newGroup),
        actions: [
          ValueListenableBuilder(
            valueListenable: _name,
            builder: (context, value, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: value.text.trim().isEmpty || _saving ? null : _save,
                child: const Text(Strings.save),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: Strings.nameLabel,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(Strings.iconLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IconChoice(
                label: Strings.noIcon,
                selected: _icon == null,
                onTap: () => setState(() => _icon = null),
                child: const Text(Strings.noIcon),
              ),
              for (final MapEntry(key: name, value: icon) in groupIcons.entries)
                _IconChoice(
                  label: Strings.iconName(name),
                  selected: _icon == name,
                  onTap: () => setState(() => _icon = name),
                  child: Icon(icon),
                ),
            ],
          ),
          if (group != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline),
              title: const Text(Strings.deleteGroup),
              subtitle: Text(
                Strings.deleteGroupHint(
                  tree == null ? 0 : setOnCount(tree, group),
                ),
              ),
              onTap: () => _delete(group!),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final actions = ref.read(nodeActionsProvider);
    final id = widget.id;
    final result = await runAction(context, () async {
      if (id == null) return actions.createGroup(_name.text, icon: _icon);
      await actions.editGroup(id, name: _name.text, icon: _icon);
      return id;
    });
    if (!mounted) return;
    if (result == null) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).pop(result);
  }

  /// No "Are you sure?" step; Undo is the safety net (E-014, frame 14).
  Future<void> _delete(ContextGroup group) async {
    final actions = ref.read(nodeActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final deletion = await runAction(
      context,
      () => actions.deleteGroup(group.id),
    );
    if (deletion == null || !mounted) return;
    Navigator.of(context).pop();
    showUndo(
      messenger,
      Strings.deleted(group.name, 0),
      () => actions.undoDeleteGroup(deletion),
    );
  }
}

/// One square in the icon grid, 56 dp so it's easy to hit.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
