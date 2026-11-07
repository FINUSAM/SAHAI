import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/engine/tree.dart';
import 'package:sahai/shared/time_format.dart';

/// The schedule rules and due labels as pure functions (PRD 7).
void main() {
  group('next due date', () {
    test('AT-073 a day missing from a month falls on the last day', () {
      final schedule = Schedule.monthly(day: 31);
      var due = DateTime(2026, 10, 31);
      final dates = [for (var i = 0; i < 4; i++) due = schedule.nextDue(due)];
      expect(dates, [
        DateTime(2026, 11, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
      ]);
    });

    test('AT-074 weekly moves to the next chosen weekday', () {
      const schedule = Schedule.weekly(
        weekdays: [DateTime.thursday, DateTime.monday],
      );
      // Monday, Nov 2, 2026.
      expect(schedule.nextDue(DateTime(2026, 11, 2)), DateTime(2026, 11, 5));
      expect(schedule.nextDue(DateTime(2026, 11, 5)), DateTime(2026, 11, 9));
    });

    test('AT-075 every 2 weeks from the due date', () {
      const byWeeks = Schedule.weekly(interval: 2);
      const byWeekday = Schedule.weekly(
        weekdays: [DateTime.thursday],
        interval: 2,
      );
      expect(byWeeks.nextDue(DateTime(2026, 11, 5)), DateTime(2026, 11, 19));
      expect(byWeekday.nextDue(DateTime(2026, 11, 5)), DateTime(2026, 11, 19));
    });

    test('with an interval, later weekdays in the week come first', () {
      const schedule = Schedule.weekly(
        weekdays: [DateTime.monday, DateTime.thursday],
        interval: 2,
      );
      expect(schedule.nextDue(DateTime(2026, 11, 2)), DateTime(2026, 11, 5));
      expect(schedule.nextDue(DateTime(2026, 11, 5)), DateTime(2026, 11, 16));
    });

    test('AT-076 yearly', () {
      final schedule = Schedule.yearly(month: 3, day: 15);
      expect(schedule.nextDue(DateTime(2027, 3, 15)), DateTime(2028, 3, 15));
    });

    test('yearly on Feb 29 falls on Feb 28 outside leap years', () {
      final schedule = Schedule.yearly(month: 2, day: 29);
      expect(schedule.nextDue(DateTime(2028, 2, 29)), DateTime(2029, 2, 28));
      expect(schedule.nextDue(DateTime(2031, 2, 28)), DateTime(2032, 2, 29));
    });

    test('daily and monthly intervals, across a year end', () {
      const daily = Schedule.daily(interval: 3);
      final quarterly = Schedule.monthly(day: 5, interval: 3);
      expect(daily.nextDue(DateTime(2026, 12, 30)), DateTime(2027, 1, 2));
      expect(quarterly.nextDue(DateTime(2026, 11, 5)), DateTime(2027, 2, 5));
    });

    test('a weekly step across a month end', () {
      const schedule = Schedule.weekly(weekdays: [DateTime.monday]);
      // Monday, Nov 30, 2026.
      expect(schedule.nextDue(DateTime(2026, 11, 30)), DateTime(2026, 12, 7));
    });
  });

  test('a schedule survives being stored as JSON', () {
    final schedules = [
      const Schedule.daily(interval: 2),
      const Schedule.weekly(
        weekdays: [DateTime.monday, DateTime.friday],
        repeatFrom: RepeatFrom.completionDate,
      ),
      Schedule.monthly(day: 31),
      Schedule.yearly(month: 3, day: 15, interval: 2),
    ];
    for (final schedule in schedules) {
      final copy = Schedule.fromJson(schedule.toJson());
      expect(copy.frequency, schedule.frequency);
      expect(copy.interval, schedule.interval);
      expect(copy.days, schedule.days);
      expect(copy.month, schedule.month);
      expect(copy.repeatFrom, schedule.repeatFrom);
    }
  });

  test('a due date is stored as YYYY-MM-DD', () {
    expect(formatDueOn(DateTime(2026, 3, 5)), '2026-03-05');
    expect(parseDueOn('2026-03-05'), DateTime(2026, 3, 5));
  });

  test('show time is the start of the day, lead days before the due date', () {
    expect(
      showTime(DateTime(2026, 11, 5), leadDays: 3, dayStartMinutes: 4 * 60),
      DateTime(2026, 11, 2, 4),
    );
    expect(
      showTime(
        DateTime(2026, 12, 1),
        leadDays: 3,
        dayStartMinutes: 6 * 60 + 30,
      ),
      DateTime(2026, 11, 28, 6, 30),
    );
  });

  group('wakeAt', () {
    TreeNode bill({
      DateTime? snoozeUntil,
      bool overrides = false,
      int? leadDays,
    }) => TreeNode(
      id: 'bill',
      parentId: 'stream',
      type: NodeType.streamItem,
      title: 'Pay HDFC card',
      status: NodeStatus.todo,
      sortOrder: 0,
      isRecurring: true,
      dueOn: DateTime(2026, 11, 5),
      leadDays: leadDays,
      snoozeUntil: snoozeUntil,
      snoozeOverridesShow: overrides,
    );
    const settings = AppSettings(defaultLeadDays: 3);
    final show = DateTime(2026, 11, 2, 4);

    test('is the show time, using the default lead when none is set', () {
      expect(bill().wakeAt(settings), show);
      expect(bill(leadDays: 1).wakeAt(settings), DateTime(2026, 11, 4, 4));
    });

    test('is the later of the show time and a set aside', () {
      final after = DateTime(2026, 11, 4, 8);
      final before = DateTime(2026, 11, 1, 20);
      expect(bill(snoozeUntil: after).wakeAt(settings), after);
      expect(bill(snoozeUntil: before).wakeAt(settings), show);
    });

    test('an override replaces the show time (E-005)', () {
      final early = DateTime(2026, 11, 1, 20);
      expect(bill(snoozeUntil: early, overrides: true).wakeAt(settings), early);
      expect(bill(overrides: true).wakeAt(settings), isNull);
    });
  });

  group('due labels', () {
    final due = DateTime(2026, 11, 5);

    test('before the due date it shows the date', () {
      expect(dueLabel(due, DateTime(2026, 11, 2, 10)), 'Due Nov 5');
      expect(dueLabel(due, DateTime(2026, 11, 4, 23, 59)), 'Due Nov 5');
    });

    test('AT-062 Due today lasts until the next day start', () {
      expect(dueLabel(due, DateTime(2026, 11, 5, 4)), 'Due today');
      expect(dueLabel(due, DateTime(2026, 11, 5, 23)), 'Due today');
      expect(dueLabel(due, DateTime(2026, 11, 6, 3, 59)), 'Due today');
    });

    test('AT-063 overdue starts at the day start and counts up', () {
      expect(dueLabel(due, DateTime(2026, 11, 6, 4)), '1 day overdue');
      expect(dueLabel(due, DateTime(2026, 11, 9, 12)), '4 days overdue');
    });

    test('follows the Day starts at setting', () {
      final sixAm = DateTime(2026, 11, 6, 5);
      expect(dueLabel(due, sixAm, dayStartMinutes: 6 * 60), 'Due today');
      expect(dueLabel(due, sixAm), '1 day overdue');
    });

    test('AT-081 a due date is read in the phone\'s current zone', () {
      // The date is stored without a zone, so it is the 5th on any phone,
      // and the label compares it with the local date. The real zone change
      // is a phone check: a test can't change the zone of a running program.
      final stored = parseDueOn(formatDueOn(due));
      final local5th = DateTime(2026, 11, 5, 12);
      expect(dueLabel(stored, local5th), 'Due today');
      expect(dueLabel(stored, local5th.toUtc()), 'Due today');
    });
  });

  test('the next day start is always after now', () {
    expect(nextDayStart(DateTime(2026, 11, 5, 3)), DateTime(2026, 11, 5, 4));
    expect(nextDayStart(DateTime(2026, 11, 5, 4)), DateTime(2026, 11, 6, 4));
    expect(nextDayStart(DateTime(2026, 11, 5, 23)), DateTime(2026, 11, 6, 4));
    expect(
      nextDayStart(DateTime(2026, 11, 5, 23), dayStartMinutes: 6 * 60),
      DateTime(2026, 11, 6, 6),
    );
  });
}
