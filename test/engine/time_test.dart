import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/time.dart';

/// Presets and the logical day (PRD 7, tech plan 4.3). The times are local
/// wall-clock times, as on the phone, using the AT sheet's November 2026
/// dates: Tuesday, Nov 3 is the reference day.
void main() {
  Map<Preset, DateTime> presets(DateTime now, {int dayStart = 240}) => {
    for (final p in presetsAt(now, dayStartMinutes: dayStart))
      p.preset: p.wakeAt,
  };

  group('logicalDate', () {
    final cases = <(String, DateTime, DateTime)>[
      ('3 PM is that day', DateTime(2026, 11, 3, 15), DateTime(2026, 11, 3)),
      (
        '1:30 AM is the night before',
        DateTime(2026, 11, 4, 1, 30),
        DateTime(2026, 11, 3),
      ),
      (
        '3:59 AM is still the night before',
        DateTime(2026, 11, 4, 3, 59),
        DateTime(2026, 11, 3),
      ),
      (
        '4:00 AM starts the day',
        DateTime(2026, 11, 4, 4),
        DateTime(2026, 11, 4),
      ),
      (
        'just after midnight on the 1st is the last day of the month before',
        DateTime(2026, 12, 1, 0, 10),
        DateTime(2026, 11, 30),
      ),
      (
        'just after midnight on Jan 1 is Dec 31',
        DateTime(2027, 1, 1, 0, 5),
        DateTime(2026, 12, 31),
      ),
    ];
    for (final (name, instant, expected) in cases) {
      test(name, () => expect(logicalDate(instant), expected));
    }

    test('a different day start moves the boundary', () {
      expect(
        logicalDate(DateTime(2026, 11, 4, 1, 30), dayStartMinutes: 0),
        DateTime(2026, 11, 4),
      );
      expect(
        logicalDate(DateTime(2026, 11, 4, 5, 30), dayStartMinutes: 6 * 60),
        DateTime(2026, 11, 3),
      );
    });

    test('a UTC instant is read in the local zone', () {
      final local = DateTime(2026, 11, 4, 1, 30);
      expect(logicalDate(local.toUtc()), logicalDate(local));
    });
  });

  test('AT-042 default preset times at 3:00 PM on Tuesday, Nov 3', () {
    expect(presets(DateTime(2026, 11, 3, 15)), {
      Preset.tonight: DateTime(2026, 11, 3, 20),
      Preset.tomorrowMorning: DateTime(2026, 11, 4, 8),
      Preset.threeDaysLater: DateTime(2026, 11, 6, 8),
      Preset.nextWeek: DateTime(2026, 11, 9, 8),
    });
    // Menu order is fixed.
    expect(presetsAt(DateTime(2026, 11, 3, 15)).map((p) => p.preset), [
      Preset.tonight,
      Preset.tomorrowMorning,
      Preset.threeDaysLater,
      Preset.nextWeek,
    ]);
  });

  test('AT-043 at 1:30 AM Tomorrow morning is later that same morning', () {
    final at = presets(DateTime(2026, 11, 4, 1, 30));
    expect(at[Preset.tomorrowMorning], DateTime(2026, 11, 4, 8));
    expect(at[Preset.threeDaysLater], DateTime(2026, 11, 6, 8));
    expect(at[Preset.nextWeek], DateTime(2026, 11, 9, 8));
    // Tonight was Tuesday 8 PM, which has passed (wireframe frame 4).
    expect(at.containsKey(Preset.tonight), isFalse);
  });

  test('AT-044 past presets are hidden at 11:00 PM', () {
    final at = presets(DateTime(2026, 11, 3, 23));
    expect(at.keys, [
      Preset.tomorrowMorning,
      Preset.threeDaysLater,
      Preset.nextWeek,
    ]);
    expect(at[Preset.tomorrowMorning], DateTime(2026, 11, 4, 8));
  });

  test('AT-044 Tonight is hidden from 8:00 PM exactly', () {
    expect(presets(DateTime(2026, 11, 3, 19, 59)), contains(Preset.tonight));
    expect(presets(DateTime(2026, 11, 3, 20)), isNot(contains(Preset.tonight)));
  });

  test('a late day start can hide Tonight and Tomorrow morning', () {
    // Day starts at 9:00 AM and it's 8:30 AM: still yesterday, so
    // "Tomorrow morning" is today at 8 AM and "Tonight" was last night,
    // both gone.
    final at = presets(DateTime(2026, 11, 4, 8, 30), dayStart: 9 * 60);
    expect(at, {
      Preset.threeDaysLater: DateTime(2026, 11, 6, 8),
      Preset.nextWeek: DateTime(2026, 11, 9, 8),
    });
  });

  test('Next week is always the following Monday', () {
    // Monday Nov 9 gives the Monday after, not the same day.
    expect(
      presets(DateTime(2026, 11, 9, 10))[Preset.nextWeek],
      DateTime(2026, 11, 16, 8),
    );
    // Sunday Nov 8 gives the next day.
    expect(
      presets(DateTime(2026, 11, 8, 10))[Preset.nextWeek],
      DateTime(2026, 11, 9, 8),
    );
  });

  test('presets cross month and year ends', () {
    final at = presets(DateTime(2026, 12, 30, 10)); // a Wednesday
    expect(at[Preset.tomorrowMorning], DateTime(2026, 12, 31, 8));
    expect(at[Preset.threeDaysLater], DateTime(2027, 1, 2, 8));
    expect(at[Preset.nextWeek], DateTime(2027, 1, 4, 8));
  });

  test('AT-045 only future times can be chosen', () {
    final now = DateTime(2026, 11, 3, 15);
    expect(isValidWakeTime(DateTime(2026, 11, 3, 14, 30), now), isFalse);
    expect(isValidWakeTime(now, now), isFalse);
    expect(isValidWakeTime(DateTime(2026, 11, 3, 15, 1), now), isTrue);
  });

  test('every preset logs a distinct name, and custom has its own', () {
    final names = {for (final p in Preset.values) p.logName};
    expect(names, hasLength(Preset.values.length));
    expect(names, isNot(contains(Preset.customLogName)));
  });
}
