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
}
