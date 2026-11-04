import 'dart:convert';

import 'package:drift/drift.dart'
    show BooleanExpressionOperators, OrderingTerm, RowIdExtension;
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/data/settings.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/scope.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/engine/visibility.dart';

import '../helpers.dart';

/// Set aside, Change time and Wake now through the actions, and what the
/// activity log records when time alone wakes items (PRD 6, 7, 9; E-002).
void main() {
  late TestApp app;
  late NodeActions actions;

  // Biztras › Website relaunch › 1. Write copy (1.1, 1.2), 2. Design pages;
  // Client admin stream (A, B); Personal › Home stream (H).
  late String biztras, relaunch, t1, s11, s12, t2, admin, a, b;
  late String personal, home, h;

  // The clock starts at Tuesday, Nov 3, 3:00 PM (UTC in tests).
  DateTime later(Duration by) => app.clock.now.add(by);

  setUp(() async {
    app = TestApp();
    actions = app.actions;
    Future<String> add(NodeType type, String? parent, String title) =>
        actions.create(type: type, parentId: parent, title: title);
    biztras = await add(NodeType.domain, null, 'Biztras');
    relaunch = await add(NodeType.project, biztras, 'Website relaunch');
    t1 = await add(NodeType.task, relaunch, 'Write copy');
    s11 = await add(NodeType.subtask, t1, 'Draft homepage');
    s12 = await add(NodeType.subtask, t1, 'Draft pricing page');
    t2 = await add(NodeType.task, relaunch, 'Design pages');
    admin = await add(NodeType.stream, biztras, 'Client admin');
    a = await add(NodeType.streamItem, admin, 'Send invoice');
    b = await add(NodeType.streamItem, admin, 'Renew domain name');
    personal = await add(NodeType.domain, null, 'Personal');
    home = await add(NodeType.stream, personal, 'Home');
    h = await add(NodeType.streamItem, home, 'Find a dentist nearby');
  });

  tearDown(() => app.close());

  Future<List<String>> visible() async => computeSummary(
    await actions.loadTree(),
    now: app.clock.now,
  ).cards.map((c) => c.id).toList();

  Future<List<EventRow>> events([String? type]) async {
    // Insertion order: the fake clock gives many events the same time.
    final query = app.db.select(app.db.events)
      ..orderBy([(e) => OrderingTerm.asc(e.rowId)]);
    if (type != null) query.where((e) => e.eventType.equals(type));
    return query.get();
  }

  Future<Map<String, int?>> snoozed() async {
    final rows = await (app.db.select(
      app.db.nodes,
    )..where((n) => n.snoozeUntil.isNotNull())).get();
    return {for (final r in rows) r.id: r.snoozeUntil};
  }

  Future<SummaryVisibleRow?> visibleRow(String id) =>
      (app.db.select(app.db.summaryVisible)
            ..where((v) => v.nodeId.equals(id) & v.isDeleted.equals(false)))
          .getSingleOrNull();

  int ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;

  Map<String, Object?> payload(EventRow e) =>
      jsonDecode(e.payload) as Map<String, Object?>;

  Matcher rejected(RejectReason reason) =>
      throwsA(isA<ActionRejected>().having((e) => e.reason, 'reason', reason));

  test('the Summary before anything is set aside', () async {
    expect(await visible(), [s11, a, h]);
  });

  test('AT-033 setting aside a subtask surfaces the next', () async {
    await actions.setAside(s11, later(const Duration(hours: 5)));
    expect(await visible(), [s12, a, h]);
    final surfaced = await events(EventTypes.surfaced);
    expect(surfaced.last.nodeId, s12);
    expect(surfaced.last.occurredAt, ms(app.clock.now));
  });

  test('AT-034 a waking subtask takes its place back on recompute', () async {
    final fivePm = later(const Duration(hours: 2));
    await actions.setAside(s11, fivePm);
    expect(await visible(), [s12, a, h]);
    app.clock.now = fivePm;
    await actions.recompute();
    expect(await visible(), [s11, a, h]);
    expect(await visibleRow(s12), isNull);
    expect((await visibleRow(s11))!.surfacedAt, ms(fivePm));
  });

  test('AT-037 scope its task: only the task holds the wake time', () async {
    final until = later(const Duration(hours: 17));
    await actions.setAside(t1, until, level: SetAsideLevel.task);
    expect(await snoozed(), {t1: ms(until)});
    expect(await visible(), [a, h]);
    app.clock.now = until;
    await actions.recompute();
    expect(await visible(), [s11, a, h]);
  });

  test('AT-038 scope its project: only the project holds it', () async {
    await actions.setAside(
      relaunch,
      later(const Duration(days: 6)),
      level: SetAsideLevel.project,
    );
    expect((await snoozed()).keys, [relaunch]);
    expect(await visible(), [a, h]);
  });

  test('AT-039 scope its domain hides its projects and streams', () async {
    await actions.setAside(
      biztras,
      later(const Duration(days: 6)),
      level: SetAsideLevel.domain,
    );
    expect((await snoozed()).keys, [biztras]);
    expect(await visible(), [h]);
  });

  test('AT-040 a set-aside current task stalls its project', () async {
    await actions.markDone(s11);
    await actions.markDone(s12);
    expect(await visible(), [t1, a, h]);
    await actions.setAside(t1, later(const Duration(hours: 5)));
    expect(await visible(), [a, h]);
    expect((await actions.loadTree()).isLocked(t2), isTrue);
  });

  test('AT-041 a stream set aside from the Explorer hides its items', () async {
    await actions.setAside(admin, later(const Duration(days: 6)));
    expect(await visible(), [s11, h]);
  });

  test('AT-045 a time that is not in the future is refused', () async {
    final before = (await events()).length;
    for (final when in [app.clock.now, later(const Duration(minutes: -30))]) {
      await expectLater(
        actions.setAside(s11, when),
        rejected(RejectReason.pastWakeTime),
      );
    }
    expect(await snoozed(), isEmpty);
    expect(await events(), hasLength(before));
  });

  test('AT-048 Wake now shows it straight away', () async {
    final nextWeek = later(const Duration(days: 6));
    await actions.setAside(s11, nextWeek);
    expect(await visible(), [s12, a, h]);
    await actions.wakeNow(s11);
    expect(await visible(), [s11, a, h]);
    expect(await snoozed(), isEmpty);
    final woke = (await events(EventTypes.woke)).single;
    expect(payload(woke), {'cause': 'wake_now', 'wake_at': ms(nextWeek)});
    expect(woke.occurredAt, ms(app.clock.now));
  });

  test('Undo of a set aside is Wake now', () async {
    await actions.setAside(h, later(const Duration(hours: 5)));
    expect(await visible(), [s11, a]);
    await actions.wakeNow(h);
    expect(await visible(), [s11, a, h]);
  });

  test('AT-049 Change time moves the wake time', () async {
    final nextWeek = later(const Duration(days: 6));
    final tomorrow8am = later(const Duration(hours: 17));
    await actions.setAside(s11, nextWeek, remind: false);
    await actions.changeWakeTime(
      s11,
      tomorrow8am,
      preset: Preset.tomorrowMorning,
    );
    expect(await snoozed(), {s11: ms(tomorrow8am)});
    final changed = (await events(EventTypes.setAside)).last;
    expect(payload(changed), {
      'wake_at': ms(tomorrow8am),
      'preset': 'tomorrow_morning',
      'remind': false,
      'level': 'item',
      'previous_wake_at': ms(nextWeek),
    });
    app.clock.now = tomorrow8am;
    await actions.recompute();
    expect(await visible(), [s11, a, h]);
  });

  test('Wake now and Change time need something set aside', () async {
    await expectLater(actions.wakeNow(s11), rejected(RejectReason.notSetAside));
    await expectLater(
      actions.changeWakeTime(s11, later(const Duration(hours: 1))),
      rejected(RejectReason.notSetAside),
    );
    await actions.setAside(s11, later(const Duration(hours: 1)));
    await expectLater(
      actions.changeWakeTime(s11, app.clock.now),
      rejected(RejectReason.pastWakeTime),
    );
    await expectLater(
      actions.setAside('missing', later(const Duration(hours: 1))),
      rejected(RejectReason.notFound),
    );
  });

  test(
    'AT-059 set aside is logged with time, preset, scope and Remind me',
    () async {
      final tonight = later(const Duration(hours: 5));
      await actions.setAside(
        relaunch,
        tonight,
        preset: Preset.tonight,
        level: SetAsideLevel.project,
        remind: false,
      );
      final event = (await events(EventTypes.setAside)).single;
      expect(event.nodeId, relaunch);
      expect(event.nodeType, NodeType.project.dbName);
      expect(event.domainId, biztras);
      expect(event.occurredAt, ms(app.clock.now));
      expect(payload(event), {
        'wake_at': ms(tonight),
        'preset': 'tonight',
        'remind': false,
        'level': 'project',
      });
      expect((await actions.loadTree())[relaunch]!.remindOnWake, isFalse);

      await actions.setAside(h, later(const Duration(hours: 3)));
      final custom = payload((await events(EventTypes.setAside)).last);
      expect(custom['preset'], 'custom');
      expect(custom['remind'], isTrue);
      expect(custom['level'], 'item');
    },
  );

  test('AT-060 waking is logged as automatic or Wake now', () async {
    final tomorrow8am = later(const Duration(hours: 17));
    await actions.setAside(s11, tomorrow8am);
    await actions.setAside(h, tomorrow8am.add(const Duration(hours: 1)));
    app.clock.now = tomorrow8am.add(const Duration(minutes: 20));
    await actions.recompute();
    await actions.wakeNow(h);
    final woke = await events(EventTypes.woke);
    expect(woke.map((e) => (e.nodeId, payload(e)['cause'])), [
      (s11, 'automatic'),
      (h, 'wake_now'),
    ]);
    expect(woke.first.occurredAt, ms(tomorrow8am));
  });

  group('E-002 items that wake while the app is closed', () {
    test(
      'surfaced and woke carry the wake time, not the time the app noticed',
      () async {
        final wakeAt = later(const Duration(hours: 2));
        await actions.setAside(s11, wakeAt);
        // The app is closed for a day, then opened.
        app.clock.now = later(const Duration(days: 1));
        await actions.recompute();
        final woke = (await events(EventTypes.woke)).single;
        expect(woke.occurredAt, ms(wakeAt));
        expect(payload(woke), {'cause': 'automatic'});
        final surfaced = (await events(EventTypes.surfaced)).last;
        expect(surfaced.nodeId, s11);
        expect(surfaced.occurredAt, ms(wakeAt));
        expect(surfaced.tzOffsetMinutes, 0);
        expect((await visibleRow(s11))!.surfacedAt, ms(wakeAt));
      },
    );

    test(
      "an ancestor's later wake time is the one that made it visible",
      () async {
        final subtaskWakes = later(const Duration(hours: 2));
        final domainWakes = later(const Duration(hours: 6));
        await actions.setAside(s11, subtaskWakes);
        await actions.setAside(biztras, domainWakes);
        app.clock.now = later(const Duration(days: 1));
        await actions.recompute();
        expect(
          (await events(EventTypes.woke)).map((e) => (e.nodeId, e.occurredAt)),
          [(s11, ms(subtaskWakes)), (biztras, ms(domainWakes))],
        );
        final surfaced = await events(EventTypes.surfaced);
        expect(
          surfaced.lastWhere((e) => e.nodeId == s11).occurredAt,
          ms(domainWakes),
        );
        expect(
          surfaced.lastWhere((e) => e.nodeId == a).occurredAt,
          ms(domainWakes),
        );
      },
    );

    test('an item that wakes under a set-aside ancestor is logged as woken but '
        'not surfaced', () async {
      await actions.setAside(s11, later(const Duration(hours: 2)));
      await actions.setAside(biztras, later(const Duration(days: 6)));
      final surfacedBefore = (await events(EventTypes.surfaced)).length;
      app.clock.now = later(const Duration(hours: 3));
      await actions.recompute();
      expect((await events(EventTypes.woke)).single.nodeId, s11);
      expect(await events(EventTypes.surfaced), hasLength(surfacedBefore));
      expect(await visible(), [h]);
    });

    test("the first action after reopening doesn't take the credit", () async {
      final wakeAt = later(const Duration(hours: 2));
      await actions.setAside(s11, wakeAt);
      app.clock.now = later(const Duration(hours: 4));
      // No recompute first: the user's first tap is Mark done on A.
      await actions.markDone(a);
      final surfaced = await events(EventTypes.surfaced);
      expect(surfaced.lastWhere((e) => e.nodeId == s11).occurredAt, ms(wakeAt));
      expect(
        surfaced.lastWhere((e) => e.nodeId == b).occurredAt,
        ms(app.clock.now),
      );
    });

    test('each wake is logged once', () async {
      await actions.setAside(s11, later(const Duration(hours: 2)));
      app.clock.now = later(const Duration(hours: 3));
      await actions.recompute();
      final count = (await events()).length;
      await actions.recompute();
      await actions.markDone(h);
      expect(await events(EventTypes.woke), hasLength(1));
      // Only the completion was added.
      expect(await events(), hasLength(count + 1));
    });

    test('a recompute with nothing due writes nothing', () async {
      await actions.setAside(s11, later(const Duration(hours: 2)));
      final count = (await events()).length;
      await actions.recompute();
      expect(await events(), hasLength(count));
    });
  });

  test('settings read with the PRD defaults', () async {
    final row = await app.db.select(app.db.settingsTable).getSingle();
    final settings = settingsFromRow(row);
    expect(settings.dayStartMinutes, 240);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.exactReminders, isFalse);
    expect(settings.reminderMinutes, 540);
    expect(settings.defaultLeadDays, 3);
    expect(settingsFromRow(null).dayStartMinutes, defaultDayStartMinutes);
    expect(
      (await watchSettings(app.db).first).dayStartMinutes,
      defaultDayStartMinutes,
    );
  });
}
