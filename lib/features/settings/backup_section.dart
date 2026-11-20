import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/strings.dart';
import 'setting_widgets.dart';

/// Above this size Settings warns that Auto Backup may stop: Android
/// silently stops backing up an app over 25 MB (PRD 3, AT-112).
const backupWarningBytes = 20 * _megabyte;

const _megabyte = 1024 * 1024;

/// [bytes] in megabytes with one decimal, such as "1.4".
String megabytesOf(int bytes) => (bytes / _megabyte).toStringAsFixed(1);

/// The Backup section of Settings (M7 frames 10 and 14): the size of the
/// data Android backs up, against 20 MB, and a warning above it. It
/// doesn't suggest deleting things, because deleted items are kept.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bytes = ref.watch(dataSizeProvider).value;
    final over = bytes != null && bytes > backupWarningBytes;
    final size = bytes == null ? '' : Strings.megabytes(megabytesOf(bytes));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSection(Strings.backupSection),
        SettingValueRow(title: Strings.dataOnPhone, value: size),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Semantics(
            label: Strings.dataOnPhone,
            value: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bytes == null
                    ? 0
                    : (bytes / backupWarningBytes).clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: over
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.onSurface,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            const TextSpan(
                              children: [
                                TextSpan(
                                  text: Strings.backupWarningTitle,
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: Strings.backupWarningBody),
                              ],
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Text(
                  Strings.backupExplained,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ],
    );
  }
}
