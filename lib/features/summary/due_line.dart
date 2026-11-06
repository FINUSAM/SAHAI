import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/recurrence.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';

/// The repeat mark and due label on a recurring card (M4 frames 1, 7), with
/// overdue in bold. It's a label, not a status (PRD 7).
class DueLine extends ConsumerWidget {
  const DueLine({super.key, required this.node});

  final TreeNode node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).now();
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final start = settings.dayStartMinutes;
    final dueOn = node.dueOn!;
    final overdue =
        daysUntilDue(dueOn, logicalDate(now, dayStartMinutes: start)) < 0;
    return Row(
      children: [
        const Icon(Icons.repeat, size: 18, semanticLabel: Strings.repeatsLabel),
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
