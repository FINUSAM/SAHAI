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

  /// A monthly or yearly schedule that repeats from completion: it counts
  /// from the finish day, so its chosen day and month don't apply (E-016).
  bool get countsFromFinish =>
      repeatFrom == RepeatFrom.completionDate &&
      (frequency == Frequency.monthly || frequency == Frequency.yearly);

  String toJson() => jsonEncode({
    'frequency': frequency.name,
    'interval': interval,
    'days': days,
    if (month != null) 'month': month,
    'repeat_from': repeatFrom.jsonName,
  });

  /// One step on from [from] (AT-067, AT-069). Repeating from the due date
  /// keeps the chosen day and month. Repeating from completion counts from
  /// [from] itself, so monthly from Nov 5 is Dec 5 (E-016).
  DateTime nextDue(DateTime from) {
    final fromFinish = repeatFrom == RepeatFrom.completionDate;
    return switch (frequency) {
      Frequency.daily => DateTime(from.year, from.month, from.day + interval),
      Frequency.weekly => _nextWeekly(from),
      Frequency.monthly => _dayIn(
        from.year,
        from.month + interval,
        fromFinish ? from.day : days.first,
      ),
      Frequency.yearly => _dayIn(
        from.year + interval,
        fromFinish ? from.month : month!,
        fromFinish ? from.day : days.first,
      ),
    };
  }

  /// The next due date once the occurrence due [dueOn] is finished on the
  /// logical date [finishedOn] (PRD 7). It's always later than [dueOn], so
  /// an item finished early still moves on (E-016, #84).
  DateTime nextAfterCompletion(DateTime dueOn, DateTime finishedOn) {
    if (repeatFrom == RepeatFrom.dueDate) return nextDue(dueOn);
    var next = nextDue(finishedOn);
    while (!next.isAfter(dueOn)) {
      next = nextDue(next);
    }
    return next;
  }

  /// The first date this schedule falls on, on or after the logical date
  /// [today]: what a new schedule's Next due starts as (M4 frame 3). Daily
  /// and plain "every N weeks" schedules have no fixed day, so that's today,
  /// and so do monthly and yearly ones that repeat from completion (E-016).
  DateTime firstDue(DateTime today) {
    if (countsFromFinish) return today;
    switch (frequency) {
      case Frequency.daily:
        return today;
      case Frequency.weekly:
        if (days.isEmpty) return today;
        for (var i = 0; i < DateTime.daysPerWeek; i++) {
          final date = DateTime(today.year, today.month, today.day + i);
          if (days.contains(date.weekday)) return date;
        }
        return today;
      case Frequency.monthly:
        final date = _dayIn(today.year, today.month, days.first);
        return date.isBefore(today)
            ? _dayIn(today.year, today.month + 1, days.first)
            : date;
      case Frequency.yearly:
        final date = _dayIn(today.year, month!, days.first);
        return date.isBefore(today)
            ? _dayIn(today.year + 1, month!, days.first)
            : date;
    }
  }

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

/// When a recurring reminder for the logical day [date] arrives (PRD 7). A
/// reminder time earlier than the day start belongs to the end of that
/// logical day, so it falls on the next calendar date.
DateTime reminderTime(
  DateTime date, {
  required int reminderMinutes,
  required int dayStartMinutes,
}) => DateTime(
  date.year,
  date.month,
  date.day + (reminderMinutes < dayStartMinutes ? 1 : 0),
  0,
  reminderMinutes,
);

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
