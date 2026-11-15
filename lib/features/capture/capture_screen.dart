import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../actions/capture_actions.dart';
import '../../app/home_shell.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';

/// The Capture tab (PRD 8.5, M6 frames 1 to 7): a box to capture a thought
/// without leaving the tab, and the captures, newest first.
class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captures = ref.watch(capturesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.capture),
        actions: const [SettingsButton()],
      ),
      body: Column(
        children: [
          const _CaptureBox(),
          Expanded(
            child: switch (captures) {
              AsyncData(:final value) when value.isEmpty => const _Empty(),
              AsyncData(:final value) => ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: value.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _CaptureRow(entry: value[i]),
              ),
              AsyncError() => const Center(child: Text(Strings.loadError)),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Grows to about 6 lines, then scrolls. Enter starts a new line and only
/// Save saves, so a capture can be a whole list (M6 decision 6).
class _CaptureBox extends ConsumerStatefulWidget {
  const _CaptureBox();

  @override
  ConsumerState<_CaptureBox> createState() => _CaptureBoxState();
}

class _CaptureBoxState extends ConsumerState<_CaptureBox> {
  final _text = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final id = await runAction(
      context,
      () => ref.read(captureActionsProvider).add(_text.text),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (id != null) _text.clear();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            minLines: 1,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: Strings.captureHint,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ValueListenableBuilder(
          valueListenable: _text,
          builder: (context, value, _) => SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: value.text.trim().isEmpty || _saving ? null : _save,
              child: const Text(Strings.save),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(Strings.nothingCaptured, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              Strings.nothingCapturedBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sun, Nov 15 · 6:00 PM", plus "· 3 items made" once some are (frame 11).
String captureLine(CaptureEntry entry) => [
  capturedTime(entry.capturedAt),
  if (entry.itemsMade > 0) Strings.itemsMade(entry.itemsMade),
].join(Strings.separator);

/// The first 3 lines, its time, a Create button and a menu (frame 2).
class _CaptureRow extends StatelessWidget {
  const _CaptureRow({required this.entry});

  final CaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Only the text opens the menu, so TalkBack reaches Create and the menu
    // button on their own rather than as one merged row.
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => showCaptureMenu(context, entry),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    captureLine(entry),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => context.push(Routes.createFromCapture(entry.id)),
          child: const Text(
            Strings.create,
            semanticsLabel: Strings.createFromThis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: Strings.captureActions,
            onPressed: () => showCaptureMenu(context, entry),
          ),
        ),
      ],
    );
  }
}

/// The whole text, when it was captured, then Create an item, Edit and
/// Delete (frame 5).
Future<void> showCaptureMenu(BuildContext context, CaptureEntry entry) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) {
        final theme = Theme.of(sheet);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                    child: Text(entry.text, style: theme.textTheme.titleMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      Strings.capturedOn(captureLine(entry)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text(Strings.createAnItem),
                    subtitle: const Text(Strings.createAnItemHint),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      context.push(Routes.createFromCapture(entry.id));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text(Strings.edit),
                    onTap: () {
                      Navigator.of(sheet).pop();
                      context.push(Routes.editCapture(entry.id));
                    },
                  ),
                  // The row's context, not the sheet's, which closes first.
                  Consumer(
                    builder: (_, ref, _) => ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text(Strings.delete),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        _delete(
                          context,
                          ref.read(captureActionsProvider),
                          entry,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

/// No "Are you sure?": Undo for 5 seconds, as elsewhere (frame 7, AT-098).
Future<void> _delete(
  BuildContext context,
  CaptureActions captures,
  CaptureEntry entry,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = await runAction(context, () async {
    await captures.delete(entry.id);
    return true;
  });
  if (done == null) return;
  showUndo(
    messenger,
    Strings.captureDeleted,
    () => captures.undoDelete(entry.id),
  );
}
