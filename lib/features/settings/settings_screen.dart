import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/settings.dart';
import '../../engine/settings.dart';
import '../../shared/strings.dart';
import '../../shared/time.dart';

/// Settings (PRD 8.6, M3 frame 14). M3 brings the Reminders section; the
/// rest arrives with M4 and M7.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    Future<void> save({bool? notifications, bool? exact}) =>
        saveReminderSettings(
          ref.read(databaseProvider),
          notificationsEnabled: notifications,
          exactReminders: exact,
          nowMillis: utcMillis(ref.read(clockProvider)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              Strings.remindersSection.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text(Strings.notifications),
            subtitle: const Text(Strings.notificationsHint),
            value: settings.notificationsEnabled,
            onChanged: (on) async {
              await save(notifications: on);
              if (on) await ref.read(remindersProvider).askPermission();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: const Text(Strings.exactReminders),
            subtitle: const Text(Strings.exactRemindersHint),
            value: settings.exactReminders,
            onChanged: settings.notificationsEnabled
                ? (on) async {
                    await save(exact: on);
                    // Android 14 and higher deny this by default and send
                    // the user to a system screen (tech plan 7).
                    if (on) await ref.read(remindersProvider).askExactAlarms();
                  }
                : null,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              Strings.laterSettings,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
