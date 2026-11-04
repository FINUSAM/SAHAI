import '../engine/settings.dart';
import 'database.dart';

/// The settings row as the engine sees it. A missing row reads as the PRD
/// defaults. Custom presets (the `presets` column) are read from M7, when
/// they become editable.
AppSettings settingsFromRow(SettingsRow? row) => row == null
    ? const AppSettings()
    : AppSettings(
        dayStartMinutes: row.dayStartMinutes,
        notificationsEnabled: row.notificationsEnabled,
        exactReminders: row.exactReminders,
        reminderMinutes: row.reminderMinutes,
        defaultLeadDays: row.defaultLeadDays,
      );

/// The settings, emitted again whenever the row changes.
Stream<AppSettings> watchSettings(SahaiDatabase db) => (db.select(
  db.settingsTable,
)..where((s) => s.id.equals(1))).watchSingleOrNull().map(settingsFromRow);
