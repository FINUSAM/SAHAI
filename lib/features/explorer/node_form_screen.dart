import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/node_type.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import 'action_feedback.dart';
import 'explorer_state.dart';
import 'schedule_fields.dart';

/// Creates a node, or edits one: the same screen does both (frame 5,
/// AT-001, AT-010). A TODO stream item can repeat (M4 frames 2 to 4).
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
  var _repeat = false;
  ScheduleDraft? _draft;

  bool get _isEdit => widget.id != null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  AppSettings get _settings =>
      ref.read(settingsProvider).value ?? const AppSettings();

  DateTime get _today => logicalDate(
    ref.read(clockProvider).now(),
    dayStartMinutes: _settings.dayStartMinutes,
  );

  void _setRepeat(bool on) => setState(() {
    _repeat = on;
    if (on) {
      _draft ??= ScheduleDraft.start(
        _today,
        leadDays: _settings.defaultLeadDays,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider).value;
    final node = _isEdit ? (tree?[widget.id!]) : null;
    if (node != null && !_filled) {
      _title.text = node.title;
      _notes.text = node.notes;
      if (node.isRecurring) {
        _repeat = true;
        _draft = ScheduleDraft.of(
          node,
          defaultLeadDays: _settings.defaultLeadDays,
        );
      }
      _filled = true;
    }
    final type = node?.type ?? widget.type;
    final parentId = node?.parentId ?? widget.parentId;
    final parent = parentId == null ? null : tree?[parentId];
    final theme = Theme.of(context);
    final canRepeat =
        type == NodeType.streamItem && (node == null || node.isTodo);
    final draft = _repeat ? _draft : null;

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
                onPressed:
                    value.text.trim().isEmpty ||
                        _saving ||
                        (draft != null && !draft.isValid)
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
          if (canRepeat) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(Strings.repeat),
              subtitle: _repeat ? null : const Text(Strings.repeatHint),
              value: _repeat,
              onChanged: _setRepeat,
            ),
            if (draft != null)
              ScheduleFields(
                draft: draft,
                today: _today,
                onChanged: (d) => setState(() => _draft = d),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(NodeType type, Tree? tree) async {
    setState(() => _saving = true);
    final actions = ref.read(nodeActionsProvider);
    final expanded = ref.read(expandedProvider.notifier);
    final draft = _repeat ? _draft : null;
    if (_isEdit) {
      final id = widget.id!;
      final node = tree?[id];
      final done = await runAction(context, () async {
        await actions.edit(id, title: _title.text, notes: _notes.text);
        if (draft != null && _scheduleChanged(node, draft)) {
          await actions.setRecurrence(
            id,
            draft.schedule,
            dueOn: draft.dueOn,
            leadDays: draft.leadDays,
          );
        }
        return true;
      });
      if (done == null) return _failed();
      // Turning Repeat off is Stop repeating, Undo included (M4 wireframe
      // choice).
      if (draft == null && (node?.isRecurring ?? false) && mounted) {
        await stopRepeatingWithUndo(context, actions, id, _title.text.trim());
      }
    } else {
      final id = await runAction(
        context,
        () => actions.create(
          type: type,
          parentId: widget.parentId,
          title: _title.text,
          notes: _notes.text,
          schedule: draft?.schedule,
          dueOn: draft?.dueOn,
          leadDays: draft?.leadDays,
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

  /// Saving a schedule ends any Wake now or Change time on this occurrence,
  /// so an edit that leaves it alone must not save it.
  bool _scheduleChanged(TreeNode? node, ScheduleDraft draft) =>
      node?.schedule?.toJson() != draft.schedule.toJson() ||
      node?.dueOn != draft.dueOn ||
      (node?.leadDays ?? _settings.defaultLeadDays) != draft.leadDays;

  void _failed() {
    if (mounted) setState(() => _saving = false);
  }
}
