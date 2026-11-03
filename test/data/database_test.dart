import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/database.dart';

import '../drift/sahai/generated/schema_v1.dart' as v1;
import '../helpers.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sahai_db');
    file = File('${dir.path}${Platform.pathSeparator}sahai.sqlite');
  });

  tearDown(() => dir.delete(recursive: true));

  Directory backups() =>
      Directory('${dir.path}${Platform.pathSeparator}pre-migration');

  test('a new database has one settings row with the PRD defaults', () async {
    final app = TestApp();
    addTearDown(app.close);
    final settings = await app.db.select(app.db.settingsTable).getSingle();
    expect(settings.id, 1);
    expect(settings.dayStartMinutes, 240);
    expect(settings.reminderMinutes, 540);
    expect(settings.defaultLeadDays, 3);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.exactReminders, isFalse);
  });

  test('a file database uses WAL journaling', () async {
    final db = SahaiDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final mode = await db.customSelect('PRAGMA journal_mode').getSingle();
    expect(mode.read<String>('journal_mode'), 'wal');
  });

  group('AT-012 schema migration keeps data', () {
    test('upgrading copies the database first and keeps every row', () async {
      // A real v1 database file, built from the exported v1 schema.
      final old = v1.DatabaseAtV1(NativeDatabase(file));
      const t = 1793746101000;
      await old.batch((b) {
        b.insertAll(old.nodes, const [
          v1.NodesData(
            id: 'd',
            type: 'domain',
            title: 'Personal',
            notes: '',
            sortOrder: 0,
            remindOnWake: 1,
            isDeleted: 0,
            snoozeOverridesShow: 0,
            createdAt: t,
            updatedAt: t,
          ),
          v1.NodesData(
            id: 's',
            parentId: 'd',
            type: 'stream',
            title: 'Errands',
            notes: '',
            sortOrder: 0,
            remindOnWake: 1,
            isDeleted: 0,
            snoozeOverridesShow: 0,
            createdAt: t,
            updatedAt: t,
          ),
        ]);
      });
      await old.close();

      final upgraded = SahaiDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      expect(await upgraded.select(upgraded.summaryVisible).get(), isEmpty);
      final titles = await (upgraded.select(upgraded.nodes))
          .map((r) => r.title)
          .get();
      expect(titles, unorderedEquals(['Personal', 'Errands']));

      final copies = backups().listSync().whereType<File>().toList();
      expect(copies, hasLength(1));
      expect(copies.single.path, contains('sahai-v1-'));

      final copy = SahaiDatabase(NativeDatabase(copies.single));
      addTearDown(copy.close);
      final copied = await copy.select(copy.nodes).get();
      expect(
        copied.map((r) => r.title),
        unorderedEquals(['Personal', 'Errands']),
      );
    });

    test('only the newest two copies are kept', () async {
      final clock = TestClock();
      final db = SahaiDatabase(NativeDatabase(file), clock: clock.clock);
      addTearDown(db.close);
      for (var i = 0; i < 4; i++) {
        await db.backupBeforeMigration(1);
        clock.advance(const Duration(seconds: 1));
      }
      final names =
          backups().listSync().map((f) => f.uri.pathSegments.last).toList()
            ..sort();
      final start = DateTime.utc(2026, 11, 3, 15).millisecondsSinceEpoch;
      expect(names, [
        'sahai-v1-${start + 2000}.sqlite',
        'sahai-v1-${start + 3000}.sqlite',
      ]);
    });

    test('an in-memory database makes no copy', () async {
      final db = SahaiDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.backupBeforeMigration(1);
      expect(backups().existsSync(), isFalse);
    });
  });
}
