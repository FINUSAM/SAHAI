import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/settings.dart';
import '../../engine/settings.dart';
import '../../engine/time.dart';
import '../../shared/strings.dart';
import '../../shared/time.dart';
import '../../shared/time_format.dart';
import '../set_aside/set_aside_picker.dart';
import 'setting_widgets.dart';

/// Set-aside presets (M7 frames 11 and 12). Only the times change; the
/// names and days stay fixed. A new time applies to the next set aside, and
/// items already set aside keep theirs (AT-109).
class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final times =
        (ref.watch(settingsProvider).value ?? const AppSettings()).presetTimes;
    Future<void> save(PresetTimes next) => saveSettings(
      ref.read(databaseProvider),
      nowMillis: utcMillis(ref.read(clockProvider)),
      presetTimes: next,
    );
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.setAsidePresets)),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(Strings.presetsIntro),
          ),
          for (final preset in Preset.values)
            SettingValueRow(
              leading: Icon(presetIcon(preset)),
              title: Strings.presetName(preset),
              subtitle: Strings.presetHint(preset),
              value: minutesClock(times.of(preset)),
              onTap: () async {
                final picked = await askTimeOfDay(
                  context,
                  initialMinutes: times.of(preset),
                  helpText: Strings.changePresetTime(
                    Strings.presetName(preset),
                  ),
                );
                if (picked != null) await save(times.withTime(preset, picked));
              },
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(Strings.presetsNote),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: times.isDefault
                    ? null
                    : () => save(const PresetTimes()),
                child: const Text(Strings.resetToDefaults),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
