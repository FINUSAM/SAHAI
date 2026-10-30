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
};
