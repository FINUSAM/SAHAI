// Lists which acceptance tests have automated tests, by searching test names
// for AT IDs and comparing them with docs/tech-plan/test-matrix.md.
//
// Usage, from the repo root:
//   dart run tool/at_coverage.dart            all milestones
//   dart run tool/at_coverage.dart M1         one milestone
//
// Tests whose only levels are D (real device) or CI aren't expected to have
// a Dart test, so they're listed separately as manual or CI checks.
import 'dart:io';

final _idPattern = RegExp(r'AT-\d{3}');

void main(List<String> args) {
  final milestone = args.isEmpty ? null : args.first.toUpperCase();
  final matrix = _readMatrix(File('docs/tech-plan/test-matrix.md'));
  final covered = _idsInTests(['test', 'integration_test']);

  final rows = matrix
      .where((r) => milestone == null || r.milestone == milestone)
      .toList();
  if (rows.isEmpty) {
    stderr.writeln(
      'No acceptance tests found for ${milestone ?? 'any milestone'}.',
    );
    exitCode = 1;
    return;
  }

  final automated = rows.where((r) => r.needsDartTest).toList();
  final missing = automated.where((r) => !covered.contains(r.id)).toList();
  final manualOnly = rows.where((r) => !r.needsDartTest).toList();

  stdout.writeln(
    'Acceptance tests ${milestone ?? '(all milestones)'}: ${rows.length}',
  );
  stdout.writeln(
    'With automated tests: '
    '${automated.length - missing.length} of ${automated.length}',
  );
  for (final r in missing) {
    stdout.writeln('  missing  ${r.id}  [${r.levels}]  ${r.scenario}');
  }
  if (manualOnly.isNotEmpty) {
    stdout.writeln('Real-device or CI checks only: ${manualOnly.length}');
    for (final r in manualOnly) {
      stdout.writeln('  manual   ${r.id}  [${r.levels}]  ${r.scenario}');
    }
  }
}

class _Row {
  _Row(this.id, this.milestone, this.scenario, this.levels);

  final String id;
  final String milestone;
  final String scenario;
  final String levels;

  bool get needsDartTest => levels
      .split(',')
      .map((l) => l.trim())
      .any((l) => l == 'U' || l == 'W' || l == 'I');
}

List<_Row> _readMatrix(File file) {
  final rows = <_Row>[];
  String? milestone;
  for (final line in file.readAsLinesSync()) {
    final heading = RegExp(r'^## (M\d)\b').firstMatch(line);
    if (heading != null) milestone = heading.group(1);
    if (milestone == null || !line.startsWith('| AT-')) continue;
    // | ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
    final cells = line.split('|').map((c) => c.trim()).toList();
    rows.add(_Row(cells[1], milestone, cells[2], cells[6]));
  }
  return rows;
}

Set<String> _idsInTests(List<String> dirs) {
  final ids = <String>{};
  for (final path in dirs) {
    final dir = Directory(path);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        ids.addAll(
          _idPattern.allMatches(entity.readAsStringSync()).map((m) => m[0]!),
        );
      }
    }
  }
  return ids;
}
