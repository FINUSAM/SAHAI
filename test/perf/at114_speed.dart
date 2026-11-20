// AT-114, fast with 10,000 items (PRD 13). The real check runs on a
// mid-range phone in profile mode, through integration_test/speed_test.dart
// (see there for how). Run on a computer, `flutter test
// test/perf/at114_speed.dart` checks that the flow works and prints its
// times, but asserts the limits only in profile or release mode: debug
// builds are many times slower and say nothing about the phone.
//
// It never touches the app's real `sahai.sqlite`: the 10,000 items go into
// a throwaway database in the temporary folder, which on Android is the
// app's cache folder.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/visibility.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// PRD 13's limits.
const coldStartLimit = Duration(seconds: 2);
const recomputeLimit = Duration(milliseconds: 50);

/// Monday, Nov 9, 2026, 10:00 AM local time.
final perfNow = DateTime(2026, 11, 9, 10);

/// Fills [db] with a little over 10,000 items shaped like real use: 14
/// domains, each with 10 projects of 10 tasks of 5 subtasks, and 5 streams
/// of 30 items. About a third of tasks are done, some items are set aside,
/// and some have one-off due dates. Titles are made up and numbered.
Future<int> fillLargeTree(SahaiDatabase db) async {
  final t = perfNow.toUtc().millisecondsSinceEpoch;
  final rows = <NodesCompanion>[];
  var n = 0;
  String add(
    String type,
    String? parent,
    int order, {
    String? status,
    int? snoozeUntil,
    String? dueOn,
  }) {
    final id = 'n${n++}';
    rows.add(
      NodesCompanion.insert(
        id: id,
        parentId: Value(parent),
        type: type,
        title: '$type $n',
        sortOrder: order,
        status: Value(status),
        snoozeUntil: Value(snoozeUntil),
        dueOn: Value(dueOn),
        createdAt: t,
        updatedAt: t,
      ),
    );
    return id;
  }

  final later = perfNow
      .add(const Duration(days: 3))
      .toUtc()
      .millisecondsSinceEpoch;
  for (var d = 0; d < 14; d++) {
    final domain = add('domain', null, d);
    for (var p = 0; p < 10; p++) {
      final project = add(
        'project',
        domain,
        p,
        status: 'todo',
        snoozeUntil: p == 9 ? later : null,
      );
      for (var k = 0; k < 10; k++) {
        final done = k < 3;
        final task = add(
          'task',
          project,
          k,
          status: done ? 'done' : 'todo',
          dueOn: k == 4 ? '2026-11-${10 + p}' : null,
        );
        for (var s = 0; s < 5; s++) {
          add('subtask', task, s, status: done || s < 2 ? 'done' : 'todo');
        }
      }
    }
    for (var s = 0; s < 5; s++) {
      final stream = add('stream', domain, 10 + s);
      for (var i = 0; i < 30; i++) {
        add(
          'stream_item',
          stream,
          i,
          status: i < 5 ? 'done' : 'todo',
          snoozeUntil: i == 6 ? later : null,
          dueOn: i == 8 ? '2026-11-2${s % 10}' : null,
        );
      }
    }
  }
  await db.batch((b) => b.insertAll(db.nodes, rows));
  return n;
}

/// [report] gets each measurement in milliseconds, for the phone run's
/// report; the limits are asserted only when [strict].
void at114SpeedChecks({
  void Function(String name, double milliseconds)? report,
  bool strict = !kDebugMode,
}) {
  void record(String name, Duration time) {
    final ms = time.inMicroseconds / 1000;
    report?.call(name, ms);
    // Times only: no item content is ever logged.
    debugPrint('AT-114 $name: ${ms.toStringAsFixed(1)} ms');
  }

  Future<File> filledDatabase(WidgetTester tester) async {
    final file = tempDatabaseFile();
    await tester.runAsync(() async {
      final filler = TestApp(executor: NativeDatabase(file));
      final count = await fillLargeTree(filler.db);
      expect(count, greaterThanOrEqualTo(10000));
      await filler.close();
    });
    return file;
  }

  testWidgets('AT-114 cold start: opening the database to the first Summary '
      'frame with 10,000 items', (tester) async {
    final file = await filledDatabase(tester);
    final watch = Stopwatch()..start();
    final app = TestApp(
      executor: NativeDatabase(file),
      clock: TestClock(perfNow),
    );
    await pumpSahai(tester, app: app);
    expect(find.byType(Card), findsWidgets);
    watch.stop();
    record('cold start to the Summary', watch.elapsed);
    if (strict) expect(watch.elapsed, lessThan(coldStartLimit));
    await closeSahai(tester, app);
  });

  testWidgets('AT-114 completing an item recomputes the Summary in under '
      '50 ms', (tester) async {
    final file = await filledDatabase(tester);
    await tester.runAsync(() async {
      final app = TestApp(
        executor: NativeDatabase(file),
        clock: TestClock(perfNow),
      );
      var tree = await app.actions.loadTree();
      final first = computeSummary(tree, now: perfNow).cards.first.id;

      final complete = Stopwatch()..start();
      await app.actions.markDone(first);
      tree = await app.actions.loadTree();
      complete.stop();
      record('marking done and reloading', complete.elapsed);

      // The slowest of several runs, so one lucky run can't hide a slow one.
      var slowest = Duration.zero;
      for (var i = 0; i < 10; i++) {
        final watch = Stopwatch()..start();
        final summary = computeSummary(tree, now: perfNow);
        watch.stop();
        expect(summary.visibleIds, isNot(contains(first)));
        if (watch.elapsed > slowest) slowest = watch.elapsed;
      }
      record('Summary recompute (slowest of 10)', slowest);
      if (strict) expect(slowest, lessThan(recomputeLimit));
      await app.close();
    });
  });
}

void main() => at114SpeedChecks();
