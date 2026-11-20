import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_platform.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/settings.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../shared/strings.dart';
import '../../shared/time.dart';
import '../../shared/time_format.dart';
import '../explorer/action_feedback.dart';
import 'setting_widgets.dart';

/// Settings (PRD 8.6, M7 frame 10): one scrolling screen in sections. Each
/// row says what it does in a line. The Backup section comes in M7 PR 2.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final groupCount = ref.watch(groupsProvider).value?.length ?? 0;
    final version = ref.watch(appVersionProvider).value;
    Future<void> save({
      bool? notifications,
      bool? exact,
      int? dayStart,
      int? reminder,
      int? leadDays,
    }) => saveSettings(
      ref.read(databaseProvider),
      nowMillis: utcMillis(ref.read(clockProvider)),
      notificationsEnabled: notifications,
      exactReminders: exact,
      dayStartMinutes: dayStart,
      reminderMinutes: reminder,
      defaultLeadDays: leadDays,
    );
    final presets = settings.presetTimes;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settings)),
      body: ListView(
        children: [
          const SettingsSection(Strings.setAsideSection),
          ListTile(
            title: const Text(Strings.setAsidePresets),
            subtitle: Text(
              [
                for (final p in Preset.values)
                  Strings.presetSummary(p, minutesClockShort(presets.of(p))),
              ].join(Strings.separator),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.presets),
          ),
          SettingValueRow(
            title: Strings.dayStartsAt,
            subtitle: Strings.dayStartsAtHint,
            value: minutesClock(settings.dayStartMinutes),
            onTap: () async {
              final picked = await askDayStart(
                context,
                settings.dayStartMinutes,
              );
              if (picked != null) await save(dayStart: picked);
            },
          ),
          const SettingsSection(Strings.recurringSection),
          SettingValueRow(
            title: Strings.showBeforeDueSetting,
            subtitle: Strings.showBeforeDueSettingHint,
            value: Strings.daysCount(settings.defaultLeadDays),
            onTap: () async {
              final picked = await askDays(
                context,
                title: Strings.showBeforeDueSetting,
                initial: settings.defaultLeadDays,
              );
              if (picked != null) await save(leadDays: picked);
            },
          ),
          SettingValueRow(
            title: Strings.reminderTime,
            subtitle: Strings.reminderTimeHint,
            value: minutesClock(settings.reminderMinutes),
            onTap: () async {
              final picked = await askTimeOfDay(
                context,
                initialMinutes: settings.reminderMinutes,
                helpText: Strings.reminderTime,
              );
              if (picked != null) await save(reminder: picked);
            },
          ),
          const SettingsSection(Strings.remindersSection),
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
          const SettingsSection(Strings.summarySection),
          ListTile(
            leading: const Icon(Icons.view_agenda_outlined),
            title: const Text(Strings.contextGroups),
            subtitle: Text(Strings.groupCount(groupCount)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.groups),
          ),
          const SettingsSection(Strings.helpSection),
          ListTile(
            title: const Text(Strings.replayOnboarding),
            subtitle: const Text(Strings.replayOnboardingHint),
            onTap: () async {
              if (await confirmReplay(context) && context.mounted) {
                await context.push(Routes.onboarding);
              }
            },
          ),
          ListTile(
            title: const Text(Strings.aboutSahai),
            subtitle: Text(Strings.aboutHint(version)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.about),
          ),
          ListTile(
            title: const Text(Strings.sendFeedback),
            subtitle: const Text(Strings.sendFeedbackHint),
            onTap: () => sendFeedback(context, ref, version),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// "Replay onboarding?" (M7 frame 16): what is made is added next to the
/// existing data, and nothing existing changes (AT-108).
Future<bool> confirmReplay(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.replayTitle),
        content: const Text(Strings.replayBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Strings.replay),
          ),
        ],
      ),
    ) ??
    false;

/// Opens the email app with the feedback address and the subject "Sahai
/// feedback (version)", and an empty body, so nothing about the user's
/// tasks goes in (AT-120, M7 frame 17).
Future<void> sendFeedback(
  BuildContext context,
  WidgetRef ref,
  String? version,
) async {
  final opened = await ref
      .read(appPlatformProvider)
      .sendFeedback(
        address: feedbackAddress,
        subject: Strings.feedbackSubject(version),
      );
  if (!opened && context.mounted) showMessage(context, Strings.noEmailApp);
}

/// "Day starts at" (M7 frame 13): whole hours from midnight to 6 AM. Null
/// when cancelled.
Future<int?> askDayStart(BuildContext context, int current) => showDialog<int>(
  context: context,
  builder: (context) => _DayStartDialog(current: current),
);

class _DayStartDialog extends StatefulWidget {
  const _DayStartDialog({required this.current});

  final int current;

  @override
  State<_DayStartDialog> createState() => _DayStartDialogState();
}

class _DayStartDialogState extends State<_DayStartDialog> {
  late int _chosen = widget.current;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(Strings.dayStartsAt),
    contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
    content: SingleChildScrollView(
      child: RadioGroup<int>(
        groupValue: _chosen,
        onChanged: (value) {
          if (value != null) setState(() => _chosen = value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(Strings.dayStartsAtBody),
            ),
            for (final minutes in AppSettings.dayStartChoices)
              RadioListTile<int>(
                value: minutes,
                title: Text(
                  Strings.dayStartChoice(minutesClock(minutes), minutes),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(Strings.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_chosen),
        child: const Text(Strings.ok),
      ),
    ],
  );
}
