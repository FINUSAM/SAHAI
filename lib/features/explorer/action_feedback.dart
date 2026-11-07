import 'package:flutter/material.dart';

import '../../actions/node_actions.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';

/// Runs [action] and, if the rules refuse it, explains why in a snackbar
/// instead of failing silently. Returns null when refused.
Future<T?> runAction<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } on ActionRejected catch (e) {
    if (context.mounted) showMessage(context, rejectMessage(e.reason));
    return null;
  }
}

/// Marks [id] done and offers Undo for 5 seconds (PRD 7, AT-025, AT-026).
/// Used by the Summary's checkmark and the Explorer alike (frames 6, 9). A
/// recurring item stays TODO with a new date, which the snackbar gives
/// (M4 frame 6).
Future<void> completeWithUndo(
  BuildContext context,
  NodeActions actions,
  String id,
  String title,
) async {
  final token = await runAction(context, () => actions.markDone(id));
  if (token == null || !context.mounted) return;
  final next = (await actions.loadTree())[id]?.dueOn;
  if (!context.mounted) return;
  _showUndo(
    context,
    next == null
        ? Strings.doneSnack(title)
        : Strings.doneNextDue(monthDay(next)),
    () => actions.undoComplete(token),
  );
}

/// Skips [node]'s occurrence, with the same Undo as Done (M4 wireframe
/// choice, AT-071, E-011).
Future<void> skipWithUndo(
  BuildContext context,
  NodeActions actions,
  TreeNode node,
) async {
  final token = await runAction(context, () => actions.skipOccurrence(node.id));
  if (token == null || !context.mounted) return;
  _showUndo(
    context,
    Strings.skippedNextDue(monthDay(node.schedule!.nextDue(node.dueOn!))),
    () => actions.undoSkip(token),
  );
}

/// Stops [id] repeating with no "Are you sure?" step; Undo is the safety
/// net, as for Delete (M4 frame 9, AT-080, E-011).
Future<void> stopRepeatingWithUndo(
  BuildContext context,
  NodeActions actions,
  String id,
  String title,
) async {
  final token = await runAction(context, () => actions.stopRepeating(id));
  if (token == null || !context.mounted) return;
  _showUndo(
    context,
    Strings.noLongerRepeats(title),
    () => actions.undoStopRepeating(token),
  );
}

void _showUndo(
  BuildContext context,
  String text,
  Future<void> Function() undo,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 5),
        // Snackbars with an action stay until dismissed unless told not to.
        persist: false,
        action: SnackBarAction(
          label: Strings.undo,
          onPressed: () => runAction(context, undo),
        ),
      ),
    );
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

String rejectMessage(RejectReason reason) => switch (reason) {
  RejectReason.notFound => Strings.notFound,
  RejectReason.emptyTitle => Strings.emptyTitleError,
  RejectReason.invalidParent => Strings.invalidParent,
  RejectReason.noStatus => Strings.noStatus,
  RejectReason.lockedTask => Strings.lockedTask,
  RejectReason.hasTodoChildren => Strings.hasTodoChildren,
  RejectReason.alreadyDone => Strings.alreadyDone,
  RejectReason.notDone => Strings.notDone,
  RejectReason.pastWakeTime => Strings.pastWakeTime,
  RejectReason.notSetAside => Strings.notSetAside,
  RejectReason.cantRepeat => Strings.cantRepeat,
  RejectReason.notRecurring => Strings.notRecurring,
  RejectReason.staleUndo => Strings.staleUndo,
};
