import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/shared/strings.dart';
import 'package:sahai/shared/time_format.dart';

/// A new schedule's first date and how schedules read (M4 frames 3, 5, 8).
void main() {
  group('first due date', () {
    final monday = DateTime(2026, 11, 9);

    test('a day already past this month moves to the next', () {
      expect(Schedule.monthly(day: 5).firstDue(monday), DateTime(2026, 12, 5));
    });

    test('today counts', () {
      expect(Schedule.monthly(day: 9).firstDue(monday), monday);
      expect(
        const Schedule.weekly(weekdays: [DateTime.monday]).firstDue(monday),
        monday,
      );
    });

    test('a missing month day falls on the last day (AT-073)', () {
      expect(
        Schedule.monthly(day: 31).firstDue(monday),
        DateTime(2026, 11, 30),
      );
      expect(
        Schedule.monthly(day: 30).firstDue(DateTime(2027, 2, 10)),
        DateTime(2027, 2, 28),
      );
    });

    test('weekly finds the next chosen weekday', () {
      expect(
        const Schedule.weekly(weekdays: [DateTime.tuesday, DateTime.thursday])
            .firstDue(DateTime(2026, 11, 13)),
        DateTime(2026, 11, 17),
      );
    });

    test('schedules with no fixed day start today', () {
      expect(const Schedule.daily().firstDue(monday), monday);
      expect(const Schedule.weekly(interval: 4).firstDue(monday), monday);
    });

    test('yearly moves to next year once the date has passed', () {
      expect(
        Schedule.yearly(month: 3, day: 14).firstDue(monday),
        DateTime(2027, 3, 14),
      );
      expect(
        Schedule.yearly(month: 12, day: 25).firstDue(monday),
        DateTime(2026, 12, 25),
      );
    });
  });

  group('wording', () {
    test('names', () {
      expect(scheduleName(const Schedule.daily()), 'Daily');
      expect(scheduleName(Schedule.monthly(day: 5)), 'Monthly');
      expect(
        scheduleName(Schedule.monthly(day: 5, interval: 2)),
        'Every 2 months',
      );
      expect(scheduleName(const Schedule.weekly(interval: 4)), 'Every 4 weeks');
    });

    test('sentences', () {
      expect(repeatsLine(const Schedule.daily()), 'Repeats daily');
      expect(
        repeatsLine(Schedule.monthly(day: 5)),
        'Repeats monthly on the 5th',
      );
      expect(
        repeatsLine(Schedule.monthly(day: 22, interval: 3)),
        'Repeats every 3 months on the 22nd',
      );
      expect(
        repeatsLine(
          const Schedule.weekly(weekdays: [DateTime.thursday, DateTime.monday]),
        ),
        'Repeats weekly on Mon, Thu',
      );
      expect(
        repeatsLine(
          const Schedule.weekly(
            interval: 4,
            repeatFrom: RepeatFrom.completionDate,
          ),
        ),
        'Repeats every 4 weeks from completion',
      );
      expect(
        repeatsLine(Schedule.yearly(month: 2, day: 29)),
        'Repeats yearly on Feb 29',
      );
    });

    test('ordinals', () {
      expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 31].map(Strings.theDay), [
        'the 1st',
        'the 2nd',
        'the 3rd',
        'the 4th',
        'the 11th',
        'the 12th',
        'the 13th',
        'the 21st',
        'the 22nd',
        'the 23rd',
        'the 31st',
      ]);
    });

    test('a due label can sit inside a sentence', () {
      final today = DateTime(2026, 11, 5, 10);
      expect(
        dueLabel(DateTime(2026, 11, 5), today, inSentence: true),
        'due today',
      );
      expect(
        dueLabel(DateTime(2026, 12, 5), today, inSentence: true),
        'due Dec 5',
      );
      expect(
        dueLabel(DateTime(2026, 11, 1), today, inSentence: true),
        '4 days overdue',
      );
    });
  });
}
