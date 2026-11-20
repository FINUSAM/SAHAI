import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/set_aside_list.dart';
import 'package:sahai/engine/visibility.dart';
import 'package:sahai/shared/time_format.dart';

import '../helpers.dart';

/// AT-118: set-aside times are moments, not wall-clock times, so a time-zone
/// change doesn't move them. AT-119: a change and its log event are saved
/// together or not at all (PRD 13).
void main() {
  late TestApp app;
  late NodeActions actions;
  late String biztras, sales, proposal;

  setUp(() async {
    app = TestApp(clock: TestClock(DateTime.utc(2026, 11, 9, 4, 30)));
    actions = app.actions;
    biztras = await actions.create(type: NodeType.domain, title: 'Biztras');
    sales = await actions.create(
      type: NodeType.stream,
      parentId: biztras,
      title: 'Sales',
    );
    proposal = await actions.create(
      type: NodeType.streamItem,
      parentId: sales,
      title: 'Send proposal to Acme',
    );
  });

  tearDown(() => app.close());

  Future<int> eventCount() async =>
      (await app.db.select(app.db.events).get()).length;

  group('AT-118 set-aside times survive a time-zone change', () {
    // 8:00 AM India time (UTC+5:30) is 2:30 AM UTC, and 6:30 AM in Dubai
    // (UTC+4).
    final eightInIndia = DateTime.utc(2026, 11, 10, 2, 30);

    test('the time is stored as one moment, in UTC', () async {
      await actions.setAside(proposal, eightInIndia);
      final row = await app.db
          .customSelect(
            'SELECT snooze_until FROM nodes WHERE id = ?',
            variables: [Variable.withString(proposal)],
          )
          .getSingle();
      expect(
        row.read<int>('snooze_until'),
        eightInIndia.millisecondsSinceEpoch,
      );
      final node = (await actions.loadTree())[proposal]!;
      expect(node.snoozeUntil!.isAtSameMomentAs(eightInIndia), isTrue);
    });

    test(
      'it wakes at the same moment whichever way "now" is written',
      () async {
        await actions.setAside(proposal, eightInIndia);
        final tree = await actions.loadTree();
        bool visibleAt(DateTime now) =>
            computeSummary(tree, now: now).visibleIds.contains(proposal);
        final before = eightInIndia.subtract(const Duration(minutes: 1));
        // The same moments, as UTC and as the phone's own local time.
        for (final now in [before, before.toLocal()]) {
          expect(visibleAt(now), isFalse, reason: '$now');
        }
        for (final now in [eightInIndia, eightInIndia.toLocal()]) {
          expect(visibleAt(now), isTrue, reason: '$now');
        }
        expect(wakeTimeOf(tree[proposal]!, before)!.isUtc, isTrue);
      },
    );

    test('it is shown in the local time of the moment', () {
      // The label converts to local time, so the same moment reads the same
      // however it was stored. Switching the phone's zone is the device
      // check.
      final now = DateTime.utc(2026, 11, 9, 4, 30);
      expect(
        wakeLabel(eightInIndia, now),
        wakeLabel(eightInIndia.toLocal(), now.toLocal()),
      );
    });
  });

  group('AT-119 no half-finished changes', () {
    /// Makes the database refuse any new log event, as if the app died
    /// between the change and its event.
    Future<void> breakTheLog() => app.db.customStatement(
      'CREATE TEMP TRIGGER refuse_events BEFORE INSERT ON events '
      "BEGIN SELECT RAISE(ABORT, 'forced failure'); END",
    );

    Future<void> mendTheLog() =>
        app.db.customStatement('DROP TRIGGER refuse_events');

    test(
      'a completion whose event fails leaves the item TODO and no event',
      () async {
        final before = await eventCount();
        await breakTheLog();
        await expectLater(actions.markDone(proposal), throwsA(anything));
        expect((await actions.loadTree())[proposal]!.isTodo, isTrue);
        expect(await eventCount(), before);

        await mendTheLog();
        await actions.markDone(proposal);
        expect((await actions.loadTree())[proposal]!.isDone, isTrue);
        expect(await eventCount(), before + 1);
      },
    );

    test('so do setting aside and changing a due date', () async {
      final before = await eventCount();
      await breakTheLog();
      await expectLater(
        actions.setAside(proposal, DateTime.utc(2026, 11, 10, 2, 30)),
        throwsA(anything),
      );
      await expectLater(
        actions.setDueDate(proposal, DateTime(2026, 11, 20)),
        throwsA(anything),
      );
      final node = (await actions.loadTree())[proposal]!;
      expect(node.snoozeUntil, isNull);
      expect(node.dueOn, isNull);
      expect(await eventCount(), before);
    });
  });
}
