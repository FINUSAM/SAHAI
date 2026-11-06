import 'package:intl/intl.dart';

import '../engine/recurrence.dart';
import '../engine/time.dart';
import 'strings.dart';

// How wake times read on screen (M3 wireframes): "Tonight 8:00 PM",
// "Wed 8:00 AM", "Mon, Nov 9 8:00 AM", "in 5 h". Always in the phone's
// local time. Patterns are spelled out so AM and PM keep a plain space.
final _time = DateFormat('h:mm a');
final _weekday = DateFormat('EEE');
final _date = DateFormat('EEE, MMM d');
final _monthDay = DateFormat('MMM d');

/// Which group of the Set-Aside page a wake time falls in (frame 8), by
/// calendar day.
enum WakeDay { today, tomorrow, later }

WakeDay wakeDayOf(DateTime wakeAt, DateTime now) {
  final a = wakeAt.toLocal();
  final n = now.toLocal();
  // UTC dates, so a daylight-saving change can't make a day 23 hours long.
  final days = DateTime.utc(
    a.year,
    a.month,
    a.day,
  ).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
  return switch (days) {
    <= 0 => WakeDay.today,
    1 => WakeDay.tomorrow,
    _ => WakeDay.later,
  };
}

/// "Today 8:00 AM", "Tonight 8:00 PM" (from 6 PM, when [tonight] is true),
/// "Wed 8:00 AM" for tomorrow, "Fri, Nov 6 8:00 AM" after that. With
/// [inSentence], today's words are lower case: "Set aside until tonight
/// 8:00 PM".
String wakeLabel(
  DateTime wakeAt,
  DateTime now, {
  bool tonight = true,
  bool inSentence = false,
}) {
  final local = wakeAt.toLocal();
  final time = _time.format(local);
  switch (wakeDayOf(wakeAt, now)) {
    case WakeDay.today:
      final word = tonight && local.hour >= 18
          ? Strings.tonightWord
          : Strings.todayWord;
      return '${inSentence ? word.toLowerCase() : word} $time';
    case WakeDay.tomorrow:
      return '${_weekday.format(local)} $time';
    case WakeDay.later:
      return '${_date.format(local)} $time';
  }
}

/// "in 25 min", "in 17 h", "in 5 days": whole units, rounded down.
String timeRemaining(DateTime wakeAt, DateTime now) {
  final left = wakeAt.difference(now);
  if (left.inMinutes < 60) {
    return Strings.inMinutes(left.inMinutes < 1 ? 1 : left.inMinutes);
  }
  if (left.inHours < 24) return Strings.inHours(left.inHours);
  return Strings.inDays(left.inDays);
}

/// "3:00 PM".
String clockTime(DateTime at) => _time.format(at.toLocal());

/// "Tue, Nov 3".
String shortDate(DateTime at) => _date.format(at.toLocal());

/// A recurring card's label (PRD 7): "Due Nov 5", "Due today" or "3 days
/// overdue". "Due today" lasts until the next day start (AT-062, AT-063).
String dueLabel(
  DateTime dueOn,
  DateTime now, {
  int dayStartMinutes = defaultDayStartMinutes,
}) {
  final today = logicalDate(now, dayStartMinutes: dayStartMinutes);
  final days = daysUntilDue(dueOn, today);
  if (days == 0) return Strings.dueToday;
  return days > 0
      ? Strings.dueOn(_monthDay.format(dueOn))
      : Strings.daysOverdue(-days);
}
