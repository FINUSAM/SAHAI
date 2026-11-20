import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../actions/capture_actions.dart';
import '../../app/providers.dart';
import '../../engine/groups.dart';
import '../../engine/node_type.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';
import '../explorer/due_date_fields.dart';
import '../explorer/explorer_rows.dart';
import '../explorer/explorer_state.dart';
import '../explorer/schedule_fields.dart';
import '../groups/group_picker.dart';
import 'edit_capture_screen.dart';
import 'place_picker_screen.dart';

/// What a capture can become (PRD 8.5): not a domain or a stream.
const captureTypes = [
  NodeType.project,
  NodeType.task,
  NodeType.subtask,
  NodeType.streamItem,
];

/// Makes one item from a capture (PRD 8.5, M6 frames 8 and 10 to 12). The
/// capture sits above the form and isn't copied in: the user types the
/// title. The type comes first, because it decides where the item can go
/// and which fields follow. After Save: Remove this capture, or Keep it to
/// make more.
class CreateFromCaptureScreen extends ConsumerStatefulWidget {
  const CreateFromCaptureScreen({super.key, required this.captureId});

  final String captureId;

  @override
  ConsumerState<CreateFromCaptureScreen> createState() =>
      _CreateFromCaptureScreenState();
}

class _CreateFromCaptureScreenState
    extends ConsumerState<CreateFromCaptureScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  NodeType? _type;
  String? _placeId;
  var _repeat = false;
  ScheduleDraft? _draft;
  var _due = const DueDraft();
  var _saving = false;

  /// The group setting: null to follow the place, [noGroup], or a group id.
  String? _group;

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

  void _setType(NodeType type, Tree tree) => setState(() {
    _type = type;
    // A place of the wrong kind can't hold the new type.
    final place = _placeId == null ? null : tree[_placeId!];
    if (place?.type != type.parentType) _placeId = null;
    if (type != NodeType.streamItem) {
      _repeat = false;
      _draft = null;
    }
  });

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
    final captures = ref.watch(capturesProvider).value;
    final tree = ref.watch(treeProvider).value;
    final entry = findCapture(captures, widget.captureId);
    if (entry == null || tree == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: captures == null || tree == null
              ? const CircularProgressIndicator()
              : const Text(Strings.notFound),
        ),
      );
    }
    final theme = Theme.of(context);
    final type = _type;
    final place = _placeId == null ? null : tree[_placeId!];
    final draft = _repeat ? _draft : null;
    final groups = ref.watch(groupsProvider).value ?? const <ContextGroup>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: Strings.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(Strings.createItem),
        actions: [
          ValueListenableBuilder(
            valueListenable: _title,
            builder: (context, value, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed:
                    type == null ||
                        place == null ||
                        value.text.trim().isEmpty ||
                        _saving ||
                        (draft != null && !draft.isValid)
                    ? null
                    : () => _save(entry, type, place, tree),
                child: const Text(Strings.save),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _CaptureReference(entry: entry),
          const SizedBox(height: 24),
          Text(Strings.whatToMake, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in captureTypes)
                ChoiceChip(
                  label: Text(Strings.typeName(t)),
                  selected: t == type,
                  onSelected: (_) => _setType(t, tree),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: type != null,
            title: const Text(Strings.goesIn),
            subtitle: Text(
              place != null
                  ? placeLabel(tree, place)
                  : type == null
                  ? Strings.chooseTypeFirst
                  : Strings.pickA(type.parentType!),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: type == null ? null : () => _pickPlace(type),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
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
            minLines: 3,
            maxLines: 12,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: Strings.notesLabel,
              hintText: Strings.notesHint,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // A due date for anything that can be ticked off, unless it
          // repeats (E-019, M7 frame 27, AT-132).
          if (type != null && type.hasStatus && !_repeat) ...[
            DueDateFields(
              draft: _due,
              today: _today,
              now: ref.read(clockProvider).now(),
              reminderMinutes: _settings.reminderMinutes,
              onChanged: (d) => setState(() => _due = d),
            ),
            const Divider(height: 1),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(Strings.contextGroup),
            subtitle: Text(
              groupSummary(tree, groups, setting: _group, parentId: _placeId),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickGroup(tree, groups),
          ),
          if (type == NodeType.streamItem) ...[
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

  Future<void> _pickPlace(NodeType type) async {
    final id = await pickPlace(context, type: type, selected: _placeId);
    if (id != null && mounted) setState(() => _placeId = id);
  }

  Future<void> _pickGroup(Tree tree, List<ContextGroup> groups) async {
    final pick = await chooseGroup(
      context,
      tree: tree,
      groups: groups,
      title: _title.text.trim(),
      parentId: _placeId,
      current: _group,
    );
    if (pick != null && mounted) setState(() => _group = pick.setting);
  }

  Future<void> _save(
    CaptureEntry entry,
    NodeType type,
    TreeNode place,
    Tree tree,
  ) async {
    setState(() => _saving = true);
    final actions = ref.read(nodeActionsProvider);
    final captures = ref.read(captureActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final draft = _repeat ? _draft : null;
    final title = _title.text.trim();
    final id = await runAction(
      context,
      () => actions.create(
        type: type,
        parentId: place.id,
        title: title,
        notes: _notes.text,
        schedule: draft?.schedule,
        dueOn: draft?.dueOn ?? _due.dueOn,
        dueReminder: _due.reminder,
        leadDays: draft?.leadDays,
        group: _group,
        fromCapture: entry.id,
      ),
    );
    if (!mounted) return;
    if (id == null) return setState(() => _saving = false);
    // Open the new item's place in the Explorer, so it's in view there.
    ref.read(expandedProvider.notifier).open([
      place.id,
      ...tree.ancestorsOf(place.id).map((a) => a.id),
    ]);

    final remove = await _askRemove(title, displayTitle(tree, place));
    if (!mounted) return;
    if (!remove) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(Strings.createdItem(title))));
      return;
    }
    final removed = await runAction(context, () async {
      await captures.delete(entry.id);
      return true;
    });
    navigator.pop();
    if (removed == null) return;
    showUndo(
      messenger,
      Strings.createdAndRemoved(title),
      () => captures.undoDelete(entry.id),
    );
  }

  /// Remove or Keep (frame 10). Closing the dialog any other way keeps the
  /// capture, which loses nothing.
  Future<bool> _askRemove(String title, String place) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text(Strings.removeCaptureTitle),
          content: Text(Strings.removeCaptureBody(title, place)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: const Text(Strings.keep),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: const Text(Strings.remove),
            ),
          ],
        ),
      ) ??
      false;
}

/// The capture, greyed, above the form for reference (frame 8). The whole
/// text shows, however long.
class _CaptureReference extends StatelessWidget {
  const _CaptureReference({required this.entry});

  final CaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final heading = [
      Strings.fromYourCapture,
      if (entry.itemsMade > 0) Strings.itemsMade(entry.itemsMade),
    ].join(Strings.separator).toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 6),
          Text(
            entry.text,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            capturedTime(entry.capturedAt),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
