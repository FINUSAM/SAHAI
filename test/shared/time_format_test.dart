import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/shared/time_format.dart';

/// How wake times read on screen (M3 frames 1, 2, 4, 8, 11). Local times,
/// so they read the same in any zone.
void main() {
  final now = DateTime(2026, 11, 3, 15); // Tuesday, 3:00 PM

  test('labels by day', () {
    expect(wakeLabel(DateTime(2026, 11, 3, 20), now), 'Tonight 8:00 PM');
    expect(wakeLabel(DateTime(2026, 11, 3, 17), now), 'Today 5:00 PM');
    expect(
      wakeLabel(DateTime(2026, 11, 3, 20), now, tonight: false),
      'Today 8:00 PM',
    );
    expect(wakeLabel(DateTime(2026, 11, 4, 8), now), 'Wed 8:00 AM');
    expect(wakeLabel(DateTime(2026, 11, 6, 8), now), 'Fri, Nov 6 8:00 AM');
    expect(wakeLabel(DateTime(2026, 11, 16, 9), now), 'Mon, Nov 16 9:00 AM');
  });

  test('in a sentence, today and tonight are lower case', () {
    expect(
      wakeLabel(DateTime(2026, 11, 3, 20), now, inSentence: true),
      'tonight 8:00 PM',
    );
    expect(
      wakeLabel(DateTime(2026, 11, 4, 8), now, inSentence: true),
      'Wed 8:00 AM',
    );
  });

  test('time remaining in whole units, rounded down', () {
    expect(timeRemaining(DateTime(2026, 11, 3, 20), now), 'in 5 h');
    expect(timeRemaining(DateTime(2026, 11, 4, 8), now), 'in 17 h');
    expect(timeRemaining(DateTime(2026, 11, 9, 8), now), 'in 5 days');
    expect(timeRemaining(DateTime(2026, 11, 16, 9), now), 'in 12 days');
    expect(timeRemaining(DateTime(2026, 11, 4, 16), now), 'in 1 day');
    expect(timeRemaining(DateTime(2026, 11, 3, 15, 25), now), 'in 25 min');
    expect(timeRemaining(DateTime(2026, 11, 3, 15, 0, 20), now), 'in 1 min');
  });

  test('groups by calendar day', () {
    expect(wakeDayOf(DateTime(2026, 11, 3, 23, 59), now), WakeDay.today);
    expect(wakeDayOf(DateTime(2026, 11, 4), now), WakeDay.tomorrow);
    expect(wakeDayOf(DateTime(2026, 11, 4, 23, 59), now), WakeDay.tomorrow);
    expect(wakeDayOf(DateTime(2026, 11, 5), now), WakeDay.later);
    expect(
      wakeDayOf(DateTime(2027, 1, 1, 8), DateTime(2026, 12, 31, 22)),
      WakeDay.tomorrow,
    );
  });

  test('clock time and short date', () {
    expect(clockTime(now), '3:00 PM');
    expect(shortDate(now), 'Tue, Nov 3');
  });

  group('#85 the year on due dates outside the current year', () {
    final today = DateTime(2026, 12, 28);

    test('a due date this year has no year, and another year has one', () {
      expect(dueDate(DateTime(2026, 12, 31), today), 'Dec 31');
      expect(dueDate(DateTime(2027, 1, 1), today), 'Jan 1, 2027');
      expect(dueDate(DateTime(2028, 3, 15), today), 'Mar 15, 2028');
      expect(dueDate(DateTime(2025, 12, 5), today), 'Dec 5, 2025');
    });

    test('the short date with the weekday does the same', () {
      expect(shortDueDate(DateTime(2026, 12, 30), today), 'Wed, Dec 30');
      expect(shortDueDate(DateTime(2028, 3, 15), today), 'Wed, Mar 15, 2028');
    });

    test('the card label shows the year only when needed', () {
      final now = DateTime(2026, 12, 28, 15);
      expect(dueLabel(DateTime(2026, 12, 31), now), 'Due Dec 31');
      expect(dueLabel(DateTime(2027, 3, 15), now), 'Due Mar 15, 2027');
      expect(
        dueLabel(DateTime(2027, 3, 15), now, inSentence: true),
        'due Mar 15, 2027',
      );
      // Overdue and today are counts, not dates, so they have no year.
      expect(dueLabel(DateTime(2026, 12, 28), now), 'Due today');
    });
  });
}
