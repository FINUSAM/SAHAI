import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import 'action_feedback.dart';
import 'explorer_rows.dart';
import 'explorer_state.dart';

/// Moves a node under another parent, listing only parents of the one valid
/// type (frame 8, AT-006).
class MoveScreen extends ConsumerStatefulWidget {
  const MoveScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MoveScreen> createState() => _MoveScreenState();
}

class _MoveScreenState extends ConsumerState<MoveScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider).value;
    final node = tree?[widget.id];
    final parentType = node?.type.parentType;
    if (tree == null || node == null || parentType == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: tree == null
              ? const CircularProgressIndicator()
              : const Text(Strings.notFound),
        ),
      );
    }
    final theme = Theme.of(context);
    final candidates = inTreeOrder(tree)
        .where((n) => n.type == parentType)
        .toList();

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayTitle(tree, node), style: theme.textTheme.titleMedium),
            Text(
              Strings.moveHint(node.type, parentType),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ];
    String? lastPath;
    for (final candidate in candidates) {
      final path = pathOf(tree, candidate);
      if (path.isNotEmpty && path != lastPath) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Text(path, style: theme.textTheme.titleSmall),
          ),
        );
      }
      lastPath = path;
      final isCurrent = candidate.id == node.parentId;
      children.add(
        RadioListTile<String>(
          value: candidate.id,
          enabled: !isCurrent,
          title: Text(displayTitle(tree, candidate)),
          subtitle: Text(
            isCurrent
                ? Strings.whereItIsNow
                : _candidateStatus(tree, candidate, node),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: Strings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(Strings.moveNode(node.type)),
      ),
      body: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (id) => setState(() => _selected = id),
        child: ListView(children: children),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(Strings.cancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _selected == null ? null : () => _move(tree),
                  child: const Text(Strings.moveHere),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _candidateStatus(Tree tree, TreeNode candidate, TreeNode moving) {
    // Moving TODO work under a DONE item reopens it (E-008).
    if (candidate.isDone && moving.isTodo) return Strings.reopensIfMovedHere;
    return subtitleOf(tree, candidate);
  }

  Future<void> _move(Tree tree) async {
    final target = _selected!;
    final actions = ref.read(nodeActionsProvider);
    final moved = await runAction(context, () async {
      await actions.move(widget.id, target);
      return true;
    });
    if (moved == null || !mounted) return;
    // Open the new parent so the moved item is in view.
    ref.read(expandedProvider.notifier).open([
      target,
      ...tree.ancestorsOf(target).map((a) => a.id),
    ]);
    Navigator.of(context).pop();
  }
}
