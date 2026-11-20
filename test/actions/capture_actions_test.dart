import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, RowIdExtension;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/capture_actions.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/node_type.dart';

import '../helpers.dart';

Matcher rejectedWith(RejectReason reason) =>
    throwsA(isA<ActionRejected>().having((e) => e.reason, 'reason', reason));

void main() {
  late TestApp app;
  late CaptureActions captures;

  setUp(() {
    app = TestApp();
    var next = 0;
    captures = CaptureActions(
      app.db,
      clock: app.clock.clock,
      newId: () => 'capture-${++next}',
    );
  });

  tearDown(() => app.close());

  Future<List<CaptureEntry>> list() => captures.watch().first;

  Future<List<EventRow>> eventsOf(String type) async =>
      (await (app.db.select(
            app.db.events,
          )..orderBy([(e) => OrderingTerm.asc(e.rowId)])).get())
          .where((e) => e.eventType == type)
          .toList();

  test(
    'AT-095 a saved capture is listed straight away with its time',
    () async {
      await captures.add('  Call Rahul abut invoice  ');

      final entries = await list();
      expect(entries.single.text, 'Call Rahul abut invoice');
      expect(entries.single.capturedAt, app.clock.now);
      expect(entries.single.itemsMade, 0);
    },
  );

  test('a capture keeps its inner line breaks, so it can be a list', () async {
    await captures.add('call Rahul\nbuy milk\n');

    expect((await list()).single.text, 'call Rahul\nbuy milk');
  });

  test('an empty capture is refused', () async {
    expect(captures.add('  \n '), rejectedWith(RejectReason.emptyCapture));
    expect(await list(), isEmpty);
  });

  test('AT-096 newest captures come first', () async {
    final day = DateTime.utc(2026, 11, 15);
    for (final (hour, text) in [(9, 'nine'), (13, 'one'), (18, 'six')]) {
      app.clock.now = day.add(Duration(hours: hour));
      await captures.add(text);
    }

    final entries = await list();
    expect(entries.map((e) => e.text), ['six', 'one', 'nine']);
    expect(entries.first.capturedAt, day.add(const Duration(hours: 18)));
    expect(entries.last.capturedAt, day.add(const Duration(hours: 9)));
  });

  test('captures made in the same millisecond keep the order they were '
      'saved in', () async {
    await captures.add('first');
    await captures.add('second');

    expect((await list()).map((e) => e.text), ['second', 'first']);
  });

  group('AT-097 edit a capture', () {
    test('the text changes and the captured time stays', () async {
      final id = await captures.add('Call Rahul abut invoice');
      final capturedAt = app.clock.now;
      app.clock.advance(const Duration(hours: 2));

      await captures.edit(id, 'Call Rahul about invoice');

      final entry = (await list()).single;
      expect(entry.text, 'Call Rahul about invoice');
      expect(entry.capturedAt, capturedAt);
    });

    test('the edit stays after restarting the app', () async {
      final dir = await Directory.systemTemp.createTemp('sahai_capture');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/sahai.sqlite');

      final first = TestApp(executor: NativeDatabase(file));
      final before = CaptureActions(first.db, clock: first.clock.clock);
      final id = await before.add('Call Rahul abut invoice');
      await before.edit(id, 'Call Rahul about invoice');
      await first.close();

      final second = TestApp(executor: NativeDatabase(file));
      addTearDown(second.close);
      final after = CaptureActions(second.db, clock: second.clock.clock);
      expect(
        (await after.watch().first).single.text,
        'Call Rahul about invoice',
      );
    });

    test('editing writes no event', () async {
      final id = await captures.add('one');
      await captures.edit(id, 'two');

      expect(await eventsOf(EventTypes.captured), hasLength(1));
      expect(
        (await app.db.select(app.db.events).get()).map((e) => e.eventType),
        [EventTypes.captured],
      );
    });

    test('an empty edit is refused and the text stays', () async {
      final id = await captures.add('one');

      expect(captures.edit(id, ' '), rejectedWith(RejectReason.emptyCapture));
      expect((await list()).single.text, 'one');
    });

    test('a deleted capture cannot be edited', () async {
      final id = await captures.add('one');
      await captures.delete(id);

      expect(captures.edit(id, 'two'), rejectedWith(RejectReason.notFound));
    });
  });

  group('AT-098 delete a capture with Undo', () {
    test('Undo brings it back, in its place', () async {
      final older = await captures.add('older');
      app.clock.advance(const Duration(minutes: 1));
      await captures.add('newer');

      await captures.delete(older);
      expect((await list()).map((e) => e.text), ['newer']);

      await captures.undoDelete(older);
      expect((await list()).map((e) => e.text), ['newer', 'older']);
    });

    test('deleted again, it stays gone and its row is kept', () async {
      final id = await captures.add('one');
      await captures.delete(id);
      await captures.undoDelete(id);
      await captures.delete(id);

      expect(await list(), isEmpty);
      final row = await app.db.select(app.db.captures).getSingle();
      expect(row.isDeleted, isTrue);
    });

    test('deleting twice, or undoing twice, is refused', () async {
      final id = await captures.add('one');
      await captures.delete(id);
      expect(captures.delete(id), rejectedWith(RejectReason.notFound));

      await captures.undoDelete(id);
      expect(captures.undoDelete(id), rejectedWith(RejectReason.notFound));
    });

    test('delete and Undo write no events', () async {
      final id = await captures.add('one');
      await captures.delete(id);
      await captures.undoDelete(id);

      expect(
        (await app.db.select(app.db.events).get()).map((e) => e.eventType),
        [EventTypes.captured],
      );
    });
  });

  group('AT-104 capture events are logged', () {
    test('captured names the capture and its source, never the text', () async {
      final id = await captures.add('secret plan', source: CaptureSource.share);

      final event = (await eventsOf(EventTypes.captured)).single;
      expect(event.nodeId, id);
      expect(event.nodeType, CaptureActions.eventNodeType);
      expect(event.occurredAt, app.clock.now.millisecondsSinceEpoch);
      expect(jsonDecode(event.payload), {'source': 'share'});
      expect(event.payload, isNot(contains('secret')));
    });

    test('the app is the default source', () async {
      await captures.add('one');

      final event = (await eventsOf(EventTypes.captured)).single;
      expect(jsonDecode(event.payload), {'source': 'app'});
    });

    test('a captured event and one converted event per item, each linking '
        'the capture to the new item', () async {
      final captureId = await captures.add('call Rahul, buy milk');
      final domain = await app.actions.create(
        type: NodeType.domain,
        title: 'Personal',
      );
      final stream = await app.actions.create(
        type: NodeType.stream,
        parentId: domain,
        title: 'Errands',
      );
      final call = await app.actions.create(
        type: NodeType.streamItem,
        parentId: stream,
        title: 'Call Rahul',
        fromCapture: captureId,
      );
      final milk = await app.actions.create(
        type: NodeType.streamItem,
        parentId: stream,
        title: 'Buy milk',
        fromCapture: captureId,
      );

      expect(await eventsOf(EventTypes.captured), hasLength(1));
      final converted = await eventsOf(EventTypes.converted);
      expect(converted.map((e) => e.nodeId), [call, milk]);
      for (final e in converted) {
        expect(e.nodeType, NodeType.streamItem.dbName);
        expect(e.domainId, domain);
        expect(jsonDecode(e.payload), {'capture_id': captureId});
      }
      expect((await list()).single.itemsMade, 2);
    });
  });
}
