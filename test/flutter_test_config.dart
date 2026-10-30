import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;

/// Runs before every test file. Tests open many separate in-memory databases
/// on purpose, so drift's warning about multiple instances is only noise here.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
