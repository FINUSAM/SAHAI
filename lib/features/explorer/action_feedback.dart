import 'package:flutter/material.dart';

import '../../actions/node_actions.dart';
import '../../shared/strings.dart';

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
/// Used by the Summary's checkmark and the Explorer alike (frames 6, 9).
Future<void> completeWithUndo(
  BuildContext context,
  NodeActions actions,
  String id,
  String title,
) async {
  final token = await runAction(context, () => actions.markDone(id));
  if (token == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(Strings.doneSnack(title)),
        duration: const Duration(seconds: 5),
        // Snackbars with an action stay until dismissed unless told not to.
        persist: false,
        action: SnackBarAction(
          label: Strings.undo,
          onPressed: () =>
              runAction(context, () => actions.undoComplete(token)),
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
