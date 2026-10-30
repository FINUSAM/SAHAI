import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actions/node_actions.dart';
import '../data/database.dart';
import '../engine/tree.dart';

/// The one source of "now". Tests override it with a fake (decision 0004).
final clockProvider = Provider<Clock>((ref) => const Clock());

/// `sahai.sqlite` in the app's private storage. drift_flutter runs the
/// queries on a background isolate, so the UI thread never waits on the
/// database (PRD 13).
final databaseProvider = Provider<SahaiDatabase>((ref) {
  final db = SahaiDatabase(
    driftDatabase(name: 'sahai'),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(db.close);
  return db;
});

final nodeActionsProvider = Provider<NodeActions>(
  (ref) =>
      NodeActions(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

/// The live, non-deleted tree. Every action that writes makes it emit again.
final treeProvider = StreamProvider<Tree>(
  (ref) => ref.watch(nodeActionsProvider).watchTree(),
);
