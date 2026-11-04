import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/settings.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';
import 'set_aside_picker.dart';

/// Opens the picker for [node], sets the choice aside and offers Undo for
/// 5 seconds (frame 1). Undo wakes it at once and is logged as a Wake now
/// (M3 wireframe choice). [withScope] is false from the Explorer.
Future<void> setAsideWithPicker(
  BuildContext context,
  WidgetRef ref,
  Tree tree,
  TreeNode node, {
  bool withScope = true,
}) async {
  final clock = ref.read(clockProvider);
  final choice = await showSetAsidePicker(
    context,
    tree: tree,
    node: node,
    clock: clock,
    dayStartMinutes: _dayStart(ref),
    withScope: withScope,
  );
  if (choice == null || !context.mounted) return;
  final actions = ref.read(nodeActionsProvider);
  final done = await runAction(context, () async {
    await actions.setAside(
      choice.target.id,
      choice.until,
      preset: choice.preset,
      level: choice.level,
      remind: choice.remind,
    );
    return true;
  });
  if (done == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          Strings.setAsideUntil(
            wakeLabel(choice.until, clock.now(), inSentence: true),
          ),
        ),
        duration: const Duration(seconds: 5),
        // Snackbars with an action stay until dismissed unless told not to.
        persist: false,
        action: SnackBarAction(
          label: Strings.undo,
          onPressed: () =>
              runAction(context, () => actions.wakeNow(choice.target.id)),
        ),
      ),
    );
}

/// Change time on something already set aside (frames 9 and 12, AT-049):
/// the same presets and Custom, without the scope.
Future<void> changeTimeWithPicker(
  BuildContext context,
  WidgetRef ref,
  Tree tree,
  TreeNode node,
) async {
  final clock = ref.read(clockProvider);
  final choice = await showSetAsidePicker(
    context,
    tree: tree,
    node: node,
    clock: clock,
    dayStartMinutes: _dayStart(ref),
    changeTime: true,
  );
  if (choice == null || !context.mounted) return;
  final actions = ref.read(nodeActionsProvider);
  final done = await runAction(context, () async {
    await actions.changeWakeTime(node.id, choice.until, preset: choice.preset);
    return true;
  });
  if (done == null || !context.mounted) return;
  showMessage(
    context,
    Strings.setAsideUntil(
      wakeLabel(choice.until, clock.now(), inSentence: true),
    ),
  );
}

/// Wakes [node] straight away (AT-048).
Future<void> wakeNow(BuildContext context, WidgetRef ref, TreeNode node) =>
    runAction(context, () => ref.read(nodeActionsProvider).wakeNow(node.id));

int _dayStart(WidgetRef ref) =>
    (ref.read(settingsProvider).value ?? const AppSettings()).dayStartMinutes;
