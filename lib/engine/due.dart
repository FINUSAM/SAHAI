/// When a one-off item's due-date reminder arrives (E-019). Each reminder
/// comes at the Reminder time setting; an early one is followed by one on
/// the due day if the item still isn't done.
enum DueReminder {
  /// The default, stored as null.
  onTheDay(null, 0, 'on_the_day'),
  dayBefore('1_day', 1, '1_day'),
  threeDaysBefore('3_days', 3, '3_days'),
  weekBefore('1_week', 7, '1_week'),
  none('none', null, 'none');

  const DueReminder(this.dbName, this.daysBefore, this.logName);

  /// The `nodes.due_reminder` value; null for [onTheDay].
  final String? dbName;

  /// Days before the due date of the first reminder; null for [none].
  final int? daysBefore;

  /// How the activity log names it (`due_changed`).
  final String logName;

  /// An unknown value reads as the default rather than failing.
  static DueReminder fromDbName(String? name) => values.firstWhere(
    (r) => r.dbName == name,
    orElse: () => DueReminder.onTheDay,
  );
}
