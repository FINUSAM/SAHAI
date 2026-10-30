import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/node_type.dart';

import '../helpers.dart';

/// The real database with its schema version bumped, so tests can run the
/// upgrade path that every future migration goes through.
class _NextVersionDatabase extends SahaiDatabase {
  _NextVersionDatabase(super.executor);

  @override
  int get schemaVersion => super.schemaVersion + 1;
}

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
      final first = TestApp(executor: NativeDatabase(file));
      final d = await first.actions.create(
        type: NodeType.domain,
        title: 'Personal',
      );
      await first.actions.create(
        type: NodeType.stream,
        parentId: d,
        title: 'Errands',
      );
      await first.close();

      final upgraded = _NextVersionDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
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
