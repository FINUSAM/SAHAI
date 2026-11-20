import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Auto Backup rules (PRD 3, tech plan, Auto Backup). Android can't be
/// asked what it would back up, so these read the rule files themselves: a
/// rule going missing would silently leave the data out of the backup.
/// The restore itself is checked on a phone (AT-111).
void main() {
  const res = 'android/app/src/main/res/xml';
  const wanted = [
    '<include domain="root" path="app_flutter/sahai.sqlite" />',
    '<include domain="root" path="app_flutter/sahai.sqlite-wal" />',
    '<include domain="sharedpref" path="." />',
  ];

  /// The rule elements in [xml], one per line, without the comments.
  List<String> rules(String xml) => xml
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
      .split('\n')
      .map((line) => line.trim())
      .where(
        (line) => line.startsWith('<include') || line.startsWith('<exclude'),
      )
      .toList();

  /// The text between `<tag ...>` and `</tag>`.
  String section(String xml, String tag) {
    final match = RegExp(
      '<$tag[^>]*>(.*?)</$tag>',
      dotAll: true,
    ).firstMatch(xml);
    expect(match, isNotNull, reason: 'no <$tag> section');
    return match!.group(1)!;
  }

  test('the manifest turns on Auto Backup with both rule files', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="true"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('Android 11 and lower back up the database, its WAL and the '
      'preferences, and nothing else', () {
    final xml = File('$res/backup_rules.xml').readAsStringSync();
    expect(rules(section(xml, 'full-backup-content')), wanted);
  });

  test('Android 12 and higher back up and transfer the same files', () {
    final xml = File('$res/data_extraction_rules.xml').readAsStringSync();
    expect(rules(section(xml, 'cloud-backup')), wanted);
    expect(rules(section(xml, 'device-transfer')), wanted);
  });

  test('the -shm file and the pre-migration copies are never included', () {
    for (final file in ['backup_rules.xml', 'data_extraction_rules.xml']) {
      final included = rules(File('$res/$file').readAsStringSync());
      expect(included.where((r) => r.contains('-shm')), isEmpty);
      expect(included.where((r) => r.contains('pre-migration')), isEmpty);
      expect(included.where((r) => r.contains('path="app_flutter"')), isEmpty);
    }
  });
}
