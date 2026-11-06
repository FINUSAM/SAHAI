import 'time.dart';

/// The settings the engine and reminders read (PRD 8.6). The defaults are
/// the PRD's, used until the user changes them in Settings (M3 PR 3, M7).
class AppSettings {
  const AppSettings({
    this.dayStartMinutes = defaultDayStartMinutes,
    this.notificationsEnabled = true,
    this.exactReminders = false,
    this.reminderMinutes = 9 * 60,
    this.defaultLeadDays = 3,
  });

  /// "Day starts at", in minutes after midnight.
  final int dayStartMinutes;
  final bool notificationsEnabled;

  /// Exact alarms instead of Android's inexact ones (AT-058).
  final bool exactReminders;

  /// When recurring reminders arrive, in minutes after midnight (M4).
  final int reminderMinutes;

  /// How many days early recurring items show (M4).
  final int defaultLeadDays;
}
