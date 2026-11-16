import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../actions/capture_actions.dart';
import '../../app/providers.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';

/// Changes a capture's text. Its captured time stays (M6 frame 6, AT-097).
class EditCaptureScreen extends ConsumerStatefulWidget {
  const EditCaptureScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<EditCaptureScreen> createState() => _EditCaptureScreenState();
}

class _EditCaptureScreenState extends ConsumerState<EditCaptureScreen> {
  final _text = TextEditingController();
  var _filled = false;
  var _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captures = ref.watch(capturesProvider).value;
    final entry = findCapture(captures, widget.id);
    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: captures == null
              ? const CircularProgressIndicator()
              : const Text(Strings.notFound),
        ),
      );
    }
    if (!_filled) {
      _text.text = entry.text;
      _filled = true;
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.editCapture),
        actions: [
          ValueListenableBuilder(
            valueListenable: _text,
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
            controller: _text,
            autofocus: true,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: Strings.capture,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Strings.editKeepsTime(capturedTime(entry.capturedAt)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final done = await runAction(context, () async {
      await ref.read(captureActionsProvider).edit(widget.id, _text.text);
      return true;
    });
    if (!mounted) return;
    if (done == null) return setState(() => _saving = false);
    Navigator.of(context).pop();
  }
}

/// The capture with [id] in [captures], or null if it's gone or not loaded.
CaptureEntry? findCapture(List<CaptureEntry>? captures, String id) {
  for (final c in captures ?? const <CaptureEntry>[]) {
    if (c.id == id) return c;
  }
  return null;
}
