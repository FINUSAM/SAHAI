// Recurring schedules (PRD 7, tech plan 4.4).
//
// Due dates are calendar dates, not moments: a bill due on the 5th is due on
// the 5th wherever the phone is (AT-081). They're held as local midnight and
// stored as `YYYY-MM-DD`, and every step is built from calendar fields, so a
// daylight-saving change can't move a date.

import 'dart:convert';
import 'dart:math';

enum Frequency { daily, weekly, monthly, yearly }

/// What the next occurrence counts from (PRD 7).
enum RepeatFrom {
  dueDate('due_date'),
  completionDate('completion_date');

  const RepeatFrom(this.jsonName);

  final String jsonName;

  static RepeatFrom fromJsonName(String name) =>
      values.firstWhere((v) => v.jsonName == name);
}

/// A repeat schedule, stored as JSON in `nodes.recurrence`.
class Schedule {
  const Schedule.daily({
    this.interval = 1,
    this.repeatFrom = RepeatFrom.dueDate,
  }) : frequency = Frequency.daily,
       days = const [],
       month = null;

  /// [weekdays] use [DateTime.monday] to [DateTime.sunday]. With none chosen
  /// it simply counts weeks, like a haircut every 4 weeks (AT-069).
  const Schedule.weekly({
    List<int> weekdays = const [],
    this.interval = 1,
    this.repeatFrom = RepeatFrom.dueDate,
  }) : frequency = Frequency.weekly,
       days = weekdays,
       month = null;

  Schedule.monthly({
    required int day,
    this.interval = 1,
    this.repeatFrom = RepeatFrom.dueDate,
  }) : frequency = Frequency.monthly,
       days = [day],
       month = null;

  Schedule.yearly({
    required int this.month,
    required int day,
    this.interval = 1,
    this.repeatFrom = RepeatFrom.dueDate,
  }) : frequency = Frequency.yearly,
       days = [day];

  const Schedule._({
    required this.frequency,
    required this.interval,
    required this.days,
    required this.month,
    required this.repeatFrom,
  });

  factory Schedule.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return Schedule._(
      frequency: Frequency.values.byName(json['frequency']! as String),
      interval: json['interval']! as int,
      days: (json['days']! as List<Object?>).cast<int>(),
      month: json['month'] as int?,
      repeatFrom: RepeatFrom.fromJsonName(json['repeat_from']! as String),
    );
  }

  final Frequency frequency;

  /// Every this many days, weeks, months or years.
  final int interval;

  /// The chosen weekdays for weekly; the chosen day of the month, alone, for
  /// monthly and yearly. Kept rather than read from the due date, so a bill
  /// on the 31st that fell on Nov 30 goes back to the 31st in December.
  final List<int> days;

  /// The month of a yearly schedule.
  final int? month;
  final RepeatFrom repeatFrom;

  String toJson() => jsonEncode({
    'frequency': frequency.name,
    'interval': interval,
    'days': days,
    if (month != null) 'month': month,
    'repeat_from': repeatFrom.jsonName,
  });

  /// The next occurrence after [from], which is the due date, or the logical
  /// date of the completion when repeating from completion (AT-067, AT-069).
  DateTime nextDue(DateTime from) => switch (frequency) {
    Frequency.daily => DateTime(from.year, from.month, from.day + interval),
    Frequency.weekly => _nextWeekly(from),
    Frequency.monthly => _dayIn(from.year, from.month + interval, days.first),
    Frequency.yearly => _dayIn(from.year + interval, month!, days.first),
  };

  DateTime _nextWeekly(DateTime from) {
    if (days.isEmpty) {
      return DateTime(from.year, from.month, from.day + 7 * interval);
    }
    final sorted = [...days]..sort();
    for (final weekday in sorted) {
      if (weekday > from.weekday) {
        return DateTime(
          from.year,
          from.month,
          from.day + weekday - from.weekday,
        );
      }
    }
    // Past the last chosen day: the first one, [interval] weeks on.
    final monday = from.day - (from.weekday - DateTime.monday);
    return DateTime(
      from.year,
      from.month,
      monday + 7 * interval + sorted.first - DateTime.monday,
    );
  }

  /// A day missing from a month falls on its last day (AT-073).
  static DateTime _dayIn(int year, int month, int day) {
    // DateTime normalises month 13 and day 0.
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, min(day, lastDay));
  }
}

/// The moment a recurring item appears: the start of the day [leadDays]
/// before [dueOn], worked out in the phone's current zone each time rather
/// than stored (tech plan 4.4).
DateTime showTime(
  DateTime dueOn, {
  required int leadDays,
  required int dayStartMinutes,
}) =>
    DateTime(dueOn.year, dueOn.month, dueOn.day - leadDays, 0, dayStartMinutes);

/// Whole days from the logical date [today] to [dueOn]: 0 on the due date,
/// negative once overdue.
int daysUntilDue(DateTime dueOn, DateTime today) =>
    // UTC dates, so a daylight-saving change can't make a day 23 hours long.
    DateTime.utc(
      dueOn.year,
      dueOn.month,
      dueOn.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

/// `nodes.due_on` as a date.
DateTime parseDueOn(String value) => DateTime.parse(value);

/// A date as `nodes.due_on` stores it: `YYYY-MM-DD`.
String formatDueOn(DateTime date) {
  String pad(int n, int width) => n.toString().padLeft(width, '0');
  return '${pad(date.year, 4)}-${pad(date.month, 2)}-${pad(date.day, 2)}';
}
