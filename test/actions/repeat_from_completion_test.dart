import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';

import '../helpers.dart';

/// Completing an item that repeats from the completion date (#84, E-016).
/// Times are local, as the rules are; 10:00 AM is well after the 4:00 AM
/// day start, so the finish day is the calendar date.
void main() {
  /// Creates a stream item with [schedule] due on [dueOn], marks it done at
  /// 10:00 AM on [finishedOn], and returns the next due date.
  Future<DateTime> finish(
    Schedule schedule, {
    required DateTime dueOn,
    required DateTime finishedOn,
  }) async {
    final app = TestApp(
      clock: TestClock(
        DateTime(finishedOn.year, finishedOn.month, finishedOn.day, 10),
      ),
    );
    addTearDown(app.close);
    final actions = app.actions;
    final domain = await actions.create(
      type: NodeType.domain,
      title: 'Personal',
    );
    final stream = await actions.create(
      type: NodeType.stream,
      parentId: domain,
      title: 'Home',
    );
    final item = await actions.create(
      type: NodeType.streamItem,
      parentId: stream,
      title: 'Chore',
      schedule: schedule,
      dueOn: dueOn,
    );
    await actions.markDone(item);
    return (await actions.loadTree())[item]!.dueOn!;
  }

  const fromCompletion = RepeatFrom.completionDate;

  group('#84 finishing early never gives back the same due date', () {
    test('#84 monthly on the 1st, finished Oct 30', () async {
      final next = await finish(
        Schedule.monthly(day: 1, repeatFrom: fromCompletion),
        dueOn: DateTime(2026, 11, 1),
        finishedOn: DateTime(2026, 10, 30),
      );
      expect(next, DateTime(2026, 11, 30));
    });

    test('#84 yearly on Jan 2, finished Dec 30', () async {
      final next = await finish(
        Schedule.yearly(month: 1, day: 2, repeatFrom: fromCompletion),
        dueOn: DateTime(2027, 1, 2),
        finishedOn: DateTime(2026, 12, 30),
      );
      expect(next, DateTime(2027, 12, 30));
    });

    test('#84 weekly on Thursday, finished the Wednesday before', () async {
      final next = await finish(
        const Schedule.weekly(
          weekdays: [DateTime.thursday],
          repeatFrom: fromCompletion,
        ),
        dueOn: DateTime(2026, 11, 12),
        finishedOn: DateTime(2026, 11, 11),
      );
      expect(next, DateTime(2026, 11, 19));
    });
  });

  group('E-016 repeating from completion counts from the finish day', () {
    test(
      'E-016 monthly on the 8th, finished Nov 5, is next due Dec 5',
      () async {
        final next = await finish(
          Schedule.monthly(day: 8, repeatFrom: fromCompletion),
          dueOn: DateTime(2026, 11, 8),
          finishedOn: DateTime(2026, 11, 5),
        );
        expect(next, DateTime(2026, 12, 5));
      },
    );

    test('E-016 monthly finished late counts from the finish day', () async {
      final next = await finish(
        Schedule.monthly(day: 8, repeatFrom: fromCompletion),
        dueOn: DateTime(2026, 11, 8),
        finishedOn: DateTime(2026, 11, 12),
      );
      expect(next, DateTime(2026, 12, 12));
    });

    test('E-016 a day the month lacks falls on its last day', () async {
      final next = await finish(
        Schedule.monthly(day: 31, repeatFrom: fromCompletion),
        dueOn: DateTime(2027, 1, 31),
        finishedOn: DateTime(2027, 1, 31),
      );
      expect(next, DateTime(2027, 2, 28));
    });

    test('E-016 yearly, finished Nov 5, is next due Nov 5 a year on', () async {
      final next = await finish(
        Schedule.yearly(month: 11, day: 20, repeatFrom: fromCompletion),
        dueOn: DateTime(2026, 11, 20),
        finishedOn: DateTime(2026, 11, 5),
      );
      expect(next, DateTime(2027, 11, 5));
    });

    test(
      'E-016 every 2 months counts two months from the finish day',
      () async {
        final next = await finish(
          Schedule.monthly(day: 8, interval: 2, repeatFrom: fromCompletion),
          dueOn: DateTime(2026, 11, 8),
          finishedOn: DateTime(2026, 11, 5),
        );
        expect(next, DateTime(2027, 1, 5));
      },
    );

    test(
      'E-016 a daily item finished early still moves past its due date',
      () async {
        final next = await finish(
          const Schedule.daily(repeatFrom: fromCompletion),
          dueOn: DateTime(2026, 11, 10),
          finishedOn: DateTime(2026, 11, 5),
        );
        expect(next, DateTime(2026, 11, 11));
      },
    );

    test('E-016 repeating from the due date is unchanged', () async {
      final next = await finish(
        Schedule.monthly(day: 5),
        dueOn: DateTime(2026, 11, 5),
        finishedOn: DateTime(2026, 11, 2),
      );
      expect(next, DateTime(2026, 12, 5));
    });
  });
}
