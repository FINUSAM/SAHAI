import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/data/log_retention.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Log retention (PRD 9, E-004, AT-113). Local time, as on the phone, with
/// the default day start of 4:00 AM. Today is Wednesday, Dec 15, 2027, so
/// events before Dec 15, 2026 are compacted.
void main() {
  final today = DateTime(2027, 12, 15, 10);
  var nextId = 0;

  /// An event at local time [at], as the app logs it.
  EventsCompanion event(
    DateTime at, {
    String type = 'completed',
    String? domainId = 'd1',
    String? groupId,
    String? nodeId,
    String payload = '{}',
  }) {
    final millis = at.toUtc().millisecondsSinceEpoch;
    return EventsCompanion.insert(
      eventId: 'e${++nextId}',
      eventType: type,
      nodeId: Value(nodeId),
      domainId: Value(domainId),
      groupId: Value(groupId),
      occurredAt: millis,
      tzOffsetMinutes: at.timeZoneOffset.inMinutes,
      payload: Value(payload),
      createdAt: millis,
      updatedAt: millis,
    );
  }

  Future<void> insert(SahaiDatabase db, List<EventsCompanion> events) =>
      db.batch((b) => b.insertAll(db.events, events));

  Future<List<String>> eventIds(SahaiDatabase db) async => [
    for (final e in await db.select(db.events).get()) e.eventId,
  ];

  test('retention starts on the same date 12 months back, or the month\'s '
      'last day', () {
    expect(retentionStart(DateTime(2027, 12, 15)), DateTime(2026, 12, 15));
    expect(retentionStart(DateTime(2028, 2, 29)), DateTime(2027, 2, 28));
    expect(retentionStart(DateTime(2027, 1, 31)), DateTime(2026, 1, 31));
  });

  test('an event belongs to its logical day in the time it happened', () {
    // 2:00 AM IST on Dec 15 is still Dec 14 night; 5:00 AM is Dec 15.
    final twoAm = DateTime.utc(2026, 12, 14, 20, 30).millisecondsSinceEpoch;
    final fiveAm = DateTime.utc(2026, 12, 14, 23, 30).millisecondsSinceEpoch;
    expect(eventDay(twoAm, 330, 240), DateTime(2026, 12, 14));
    expect(eventDay(fiveAm, 330, 240), DateTime(2026, 12, 15));
    // The same instant in New York is the evening of Dec 14.
    expect(eventDay(fiveAm, -300, 240), DateTime(2026, 12, 14));
  });

  group('compaction', () {
    late TestApp app;

    setUp(() {
      nextId = 0;
      app = TestApp(clock: TestClock(today));
    });

    tearDown(() => app.close());

    test('AT-113 events older than 12 months become daily counts per day, '
        'domain, group and type, and the raw rows go', () async {
      final db = app.db;
      await insert(db, [
        // Nov 3, 2026: three completions in Work, two of them in a group,
        // and a set-aside in Personal.
        event(DateTime(2026, 11, 3, 9)),
        event(DateTime(2026, 11, 3, 11), groupId: 'g1'),
        event(DateTime(2026, 11, 3, 18), groupId: 'g1'),
        event(DateTime(2026, 11, 3, 20), type: 'set_aside', domainId: 'd2'),
        // 1:00 AM on Nov 4 still counts as Nov 3 (day starts at 4 AM).
        event(DateTime(2026, 11, 4, 1)),
        // A capture has no domain.
        event(DateTime(2026, 11, 3, 12), type: 'captured', domainId: null),
        // The last compacted day, and the first kept one.
        event(DateTime(2026, 12, 14, 22), type: 'surfaced'),
        event(DateTime(2026, 12, 15, 5), type: 'surfaced'),
        event(DateTime(2027, 6, 1, 9)),
      ]);

      expect(await compactEventLog(db, clock: app.clock.clock), 7);

      expect(await eventIds(db), ['e8', 'e9']);
      final summaries = {
        for (final s in await db.select(db.eventDailySummaries).get())
          '${s.day} ${s.domainId} ${s.groupId} ${s.eventType}': s.count,
      };
      expect(summaries, {
        '2026-11-03 d1 null completed': 2,
        '2026-11-03 d1 g1 completed': 2,
        '2026-11-03 d2 null set_aside': 1,
        '2026-11-03 null null captured': 1,
        '2026-12-14 d1 null surfaced': 1,
      });
    });

    test('a later run adds to the same day\'s counts, and a run with nothing '
        'old changes nothing', () async {
      final db = app.db;
      await insert(db, [event(DateTime(2026, 11, 3, 9))]);
      await compactEventLog(db, clock: app.clock.clock);
      expect(await compactEventLog(db, clock: app.clock.clock), 0);

      await insert(db, [event(DateTime(2026, 11, 3, 15))]);
      expect(await compactEventLog(db, clock: app.clock.clock), 1);
      final rows = await db.select(db.eventDailySummaries).get();
      expect(rows, hasLength(1));
      expect(rows.single.count, 2);
      expect(await eventIds(db), isEmpty);
    });

    test('the latest completion or skip of a repeating item is kept while it '
        'can be reopened (E-018, decision 0009)', () async {
      final a = app.actions;
      final personal = await a.create(type: NodeType.domain, title: 'P');
      final bills = await a.create(
        type: NodeType.stream,
        parentId: personal,
        title: 'Bills',
      );
      final insurance = await a.create(
        type: NodeType.streamItem,
        parentId: bills,
        title: 'Car insurance',
        schedule: Schedule.yearly(month: 11, day: 20),
        dueOn: DateTime(2028, 11, 20),
      );
      final db = app.db;
      // Paid in Nov 2025 (e1) and Nov 2026 (e2, the latest), both more
      // than 12 months ago.
      await insert(db, [
        event(DateTime(2025, 11, 18, 9), nodeId: insurance),
        event(DateTime(2026, 11, 19, 9), nodeId: insurance),
        // A one-off item's completion (e3) is compacted as usual.
        event(DateTime(2026, 11, 19, 10), nodeId: 'one-off'),
      ]);
      await compactEventLog(db, clock: app.clock.clock);

      final after = await eventIds(db);
      expect(after, contains('e2'));
      expect(after, isNot(contains('e1')));
      expect(after, isNot(contains('e3')));
    });

    test(
      'AT-113 after 25 months of heavy use the log stays under 10 MB',
      () async {
        final db = app.db;
        // 80 events a day, every day, from Nov 2025: far more than typical.
        const perDay = 80;
        final types = ['surfaced', 'completed', 'set_aside', 'woke', 'created'];
        var day = DateTime(2025, 11, 15);
        var total = 0;
        while (day.isBefore(DateTime(2027, 12, 15))) {
          await insert(db, [
            for (var i = 0; i < perDay; i++)
              event(
                DateTime(day.year, day.month, day.day, 8, i),
                type: types[i % types.length],
                domainId: 'domain-${i % 4}',
                groupId: i.isEven ? 'group-${i % 3}' : null,
                nodeId: 'node-$i',
                payload: '{"wake_at":1793746101000,"preset":"tonight"}',
              ),
          ]);
          total += perDay;
          day = DateTime(day.year, day.month, day.day + 1);
        }

        final compacted = await compactEventLog(db, clock: app.clock.clock);

        final remaining = await db.select(db.events).get();
        expect(compacted + remaining.length, total);
        final summed = await db
            .customSelect('SELECT SUM(count) AS n FROM event_daily_summaries')
            .getSingle();
        expect(summed.read<int>('n'), compacted);
        await db.customStatement('VACUUM');
        final size = await db
            .customSelect(
              'SELECT page_count * page_size AS bytes '
              'FROM pragma_page_count(), pragma_page_size()',
            )
            .getSingle();
        expect(size.read<int>('bytes'), lessThan(10 * 1024 * 1024));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  testSahai('the app compacts the log when it starts', (tester) async {
    nextId = 0;
    final app = TestApp(clock: TestClock(today));
    await insert(app.db, [
      event(DateTime(2026, 11, 3, 9)),
      event(DateTime(2027, 11, 3, 9)),
    ]);
    await pumpSahai(tester, app: app);
    await tester.pumpAndSettle();
    expect(await eventIds(app.db), ['e2']);
    expect(await app.db.select(app.db.eventDailySummaries).get(), hasLength(1));
  });
}
