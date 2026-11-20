import 'time.dart';

/// The settings the engine and reminders read (PRD 8.6). The defaults are
/// the PRD's, used until the user changes them in Settings (M3 PR 3, M7).
class AppSettings {
  const AppSettings({
    this.dayStartMinutes = defaultDayStartMinutes,
    this.notificationsEnabled = true,
    this.exactReminders = false,
    this.reminderMinutes = defaultReminderMinutes,
    this.defaultLeadDays = defaultLeadDaysValue,
    this.presetTimes = const PresetTimes(),
    this.onboardingDone = false,
  });

  static const defaultReminderMinutes = 9 * 60;
  static const defaultLeadDaysValue = 3;

  /// The choices for "Day starts at": whole hours from midnight to 6 AM
  /// (M7 wireframe choice).
  static const dayStartChoices = [0, 60, 120, 180, 240, 300, 360];

  /// "Day starts at", in minutes after midnight.
  final int dayStartMinutes;
  final bool notificationsEnabled;

  /// Exact alarms instead of Android's inexact ones (AT-058).
  final bool exactReminders;

  /// When recurring reminders arrive, in minutes after midnight (M4).
  final int reminderMinutes;

  /// How many days early new recurring items show (M4).
  final int defaultLeadDays;

  /// The set-aside preset times (AT-109).
  final PresetTimes presetTimes;

  /// Whether onboarding was finished or skipped (PRD 8.1).
  final bool onboardingDone;
}
