import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import 'action_feedback.dart';
import 'explorer_state.dart';

/// Creates a node, or edits one: the same screen does both (frame 5,
/// AT-001, AT-010).
class NodeFormScreen extends ConsumerStatefulWidget {
  const NodeFormScreen.create({
    super.key,
    required NodeType this.type,
    this.parentId,
  }) : id = null;

  const NodeFormScreen.edit({super.key, required String this.id})
    : type = null,
      parentId = null;

  /// Set when editing.
  final String? id;

  /// Set when creating.
  final NodeType? type;
  final String? parentId;

  @override
  ConsumerState<NodeFormScreen> createState() => _NodeFormScreenState();
}

class _NodeFormScreenState extends ConsumerState<NodeFormScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  var _filled = false;
  var _saving = false;

  bool get _isEdit => widget.id != null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider).value;
    final node = _isEdit ? (tree?[widget.id!]) : null;
    if (node != null && !_filled) {
      _title.text = node.title;
      _notes.text = node.notes;
      _filled = true;
    }
    final type = node?.type ?? widget.type;
    final parentId = node?.parentId ?? widget.parentId;
    final parent = parentId == null ? null : tree?[parentId];
    final theme = Theme.of(context);

    if (type == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: tree == null
              ? const CircularProgressIndicator()
              : const Text(Strings.notFound),
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
        title: Text(_isEdit ? Strings.editNode(type) : Strings.newNode(type)),
        actions: [
          ValueListenableBuilder(
            valueListenable: _title,
            builder: (context, value, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: value.text.trim().isEmpty || _saving
                    ? null
                    : () => _save(type, tree),
                child: const Text(Strings.save),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (parent != null) ...[
            Text(
              Strings.inParent(parent.title),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: Strings.titleLabel,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _notes,
            minLines: 4,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: Strings.notesLabel,
              hintText: Strings.notesHint,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(NodeType type, Tree? tree) async {
    setState(() => _saving = true);
    final actions = ref.read(nodeActionsProvider);
    final expanded = ref.read(expandedProvider.notifier);
    if (_isEdit) {
      final done = await runAction(context, () async {
        await actions.edit(widget.id!, title: _title.text, notes: _notes.text);
        return true;
      });
      if (done == null) return _failed();
    } else {
      final id = await runAction(
        context,
        () => actions.create(
          type: type,
          parentId: widget.parentId,
          title: _title.text,
          notes: _notes.text,
        ),
      );
      if (id == null) return _failed();
      // Show the new item, already open, so its first child can be added
      // straight away.
      final parentId = widget.parentId;
      expanded.open([
        if (parentId != null) ...[
          parentId,
          ...?tree?.ancestorsOf(parentId).map((a) => a.id),
        ],
        id,
      ]);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _failed() {
    if (mounted) setState(() => _saving = false);
  }
}
