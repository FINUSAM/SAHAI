import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/recurrence.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';

/// The due label on a card, with the repeat mark for a repeating item (M4
/// frames 1, 7) or the calendar mark for a one-off due date (M7 frame 23),
/// and overdue in bold. It's a label, not a status (PRD 7), and a DONE item
/// has none.
class DueLine extends ConsumerWidget {
  const DueLine({super.key, required this.node});

  final TreeNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (node.isDone) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).now();
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final start = settings.dayStartMinutes;
    final dueOn = node.dueOn!;
    final overdue =
        daysUntilDue(dueOn, logicalDate(now, dayStartMinutes: start)) < 0;
    return Row(
      children: [
        node.isRecurring
            ? const Icon(
                Icons.repeat,
                size: 18,
                semanticLabel: Strings.repeatsLabel,
              )
            : const Icon(Icons.calendar_today_outlined, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            dueLabel(dueOn, now, dayStartMinutes: start),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: overdue ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
}
