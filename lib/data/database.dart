import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../shared/time.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Nodes, ContextGroups, SummarySlots, Events, Captures, SettingsTable],
)
class SahaiDatabase extends _$SahaiDatabase {
  SahaiDatabase(super.executor, {this._clock = const Clock()});

  final Clock _clock;

  /// How many pre-migration copies to keep (tech plan section 5).
  static const keptBackups = 2;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      final now = utcMillis(_clock);
      await into(settingsTable).insert(
        SettingsTableCompanion.insert(
          id: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
      );
    },
    // Version 1 is the first schema, so there is nothing to upgrade from yet.
    // Each future step must call backupBeforeMigration first and must never
    // drop data (PRD 13).
    onUpgrade: (m, from, to) async {
      await backupBeforeMigration(from);
    },
    beforeOpen: (details) async {
      // WAL lets reads continue during writes. The app checkpoints when it
      // goes to the background so Auto Backup copies a complete file.
      await customSelect('PRAGMA journal_mode = WAL').get();
    },
  );

  /// Copies the database to `pre-migration/sahai-v{from}-{millis}.sqlite`
  /// next to the database file, keeping the newest [keptBackups] copies
  /// (PRD 13, AT-012). Does nothing for an in-memory database.
  Future<void> backupBeforeMigration(int from) async {
    final mainFile = await _mainDatabaseFile();
    if (mainFile == null) return;
    final dir = Directory(
      '${File(mainFile).parent.path}${Platform.pathSeparator}pre-migration',
    );
    await dir.create(recursive: true);
    final target =
        '${dir.path}${Platform.pathSeparator}'
        'sahai-v$from-${utcMillis(_clock)}.sqlite';
    // VACUUM INTO writes a consistent copy even while the database is open.
    await customStatement('VACUUM INTO ?', [target]);
    await _pruneBackups(dir);
  }

  /// Folds the write-ahead log back into the main file.
  Future<void> checkpoint() =>
      customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();

  Future<String?> _mainDatabaseFile() async {
    final rows = await customSelect('PRAGMA database_list').get();
    for (final row in rows) {
      if (row.read<String>('name') == 'main') {
        final file = row.read<String>('file');
        return file.isEmpty ? null : file;
      }
    }
    return null;
  }

  Future<void> _pruneBackups(Directory dir) async {
    final copies = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.sqlite'))
        .cast<File>()
        .toList();
    // Newest first, by the timestamp after the last '-' in the file name.
    int stamp(File f) {
      final name = f.uri.pathSegments.last.replaceAll('.sqlite', '');
      return int.tryParse(name.substring(name.lastIndexOf('-') + 1)) ?? 0;
    }

    copies.sort((a, b) => stamp(b).compareTo(stamp(a)));
    for (final old in copies.skip(keptBackups)) {
      await old.delete();
    }
  }
}
