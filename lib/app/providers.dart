import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actions/node_actions.dart';
import '../data/database.dart';
import '../data/settings.dart';
import '../engine/settings.dart';
import '../engine/tree.dart';
import '../engine/visibility.dart';

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

/// The user's settings, with the PRD defaults until they change them.
final settingsProvider = StreamProvider<AppSettings>(
  (ref) => watchSettings(ref.watch(databaseProvider)),
);

/// Bumped when time alone may have changed the Summary: on resume and when
/// `nextChangeAt` arrives (`SummaryRefresher`).
final recomputeTickProvider = NotifierProvider<RecomputeTick, int>(
  RecomputeTick.new,
);

class RecomputeTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// The Summary, recomputed from the tree after every change and whenever
/// time may have changed it, and never stored (PRD 6).
final summaryProvider = Provider<AsyncValue<SummaryResult>>((ref) {
  final clock = ref.watch(clockProvider);
  ref.watch(recomputeTickProvider);
  return ref
      .watch(treeProvider)
      .whenData((tree) => computeSummary(tree, now: clock.now().toUtc()));
});
