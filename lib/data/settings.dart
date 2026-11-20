import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../engine/settings.dart';
import '../engine/time.dart';
import 'database.dart';

/// The settings row as the engine sees it. A missing row reads as the PRD
/// defaults.
AppSettings settingsFromRow(SettingsRow? row) => row == null
    ? const AppSettings()
    : AppSettings(
        dayStartMinutes: row.dayStartMinutes,
        notificationsEnabled: row.notificationsEnabled,
        exactReminders: row.exactReminders,
        reminderMinutes: row.reminderMinutes,
        defaultLeadDays: row.defaultLeadDays,
        presetTimes: _presetTimes(row.presets),
        onboardingDone: row.onboardingDone,
      );

PresetTimes _presetTimes(String? json) {
  if (json == null) return const PresetTimes();
  try {
    return PresetTimes.fromJson(jsonDecode(json));
  } on FormatException {
    return const PresetTimes();
  }
}

/// The settings, emitted again whenever the row changes.
Stream<AppSettings> watchSettings(SahaiDatabase db) => (db.select(
  db.settingsTable,
)..where((s) => s.id.equals(1))).watchSingleOrNull().map(settingsFromRow);

/// Reads the settings once.
Future<AppSettings> readSettings(SahaiDatabase db) async => settingsFromRow(
  await (db.select(
    db.settingsTable,
  )..where((s) => s.id.equals(1))).getSingleOrNull(),
);

/// Saves the settings that are given and leaves the rest as they are. One
/// UPDATE, so a change is saved whole or not at all. Settings changes
/// aren't activity log events (PRD 9). Everything that reads settings
/// watches the row, so the Summary, presets and reminders pick a change up
/// at once.
///
/// [presetTimes] set to the defaults stores null, so the PRD times apply
/// again (Reset to defaults).
Future<void> saveSettings(
  SahaiDatabase db, {
  required int nowMillis,
  bool? notificationsEnabled,
  bool? exactReminders,
  int? dayStartMinutes,
  int? reminderMinutes,
  int? defaultLeadDays,
  PresetTimes? presetTimes,
  bool? onboardingDone,
}) {
  if (dayStartMinutes != null &&
      !AppSettings.dayStartChoices.contains(dayStartMinutes)) {
    throw ArgumentError.value(dayStartMinutes, 'dayStartMinutes');
  }
  if (reminderMinutes != null &&
      (reminderMinutes < 0 || reminderMinutes >= 24 * 60)) {
    throw ArgumentError.value(reminderMinutes, 'reminderMinutes');
  }
  if (defaultLeadDays != null && defaultLeadDays < 0) {
    throw ArgumentError.value(defaultLeadDays, 'defaultLeadDays');
  }
  Value<T> maybe<T>(T? value) =>
      value == null ? const Value.absent() : Value(value);
  return (db.update(db.settingsTable)..where((s) => s.id.equals(1))).write(
    SettingsTableCompanion(
      notificationsEnabled: maybe(notificationsEnabled),
      exactReminders: maybe(exactReminders),
      dayStartMinutes: maybe(dayStartMinutes),
      reminderMinutes: maybe(reminderMinutes),
      defaultLeadDays: maybe(defaultLeadDays),
      presets: presetTimes == null
          ? const Value.absent()
          : Value(
              presetTimes.isDefault ? null : jsonEncode(presetTimes.toJson()),
            ),
      onboardingDone: maybe(onboardingDone),
      updatedAt: Value(nowMillis),
    ),
  );
}
