import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actions/capture_actions.dart';
import '../actions/node_actions.dart';
import '../data/app_database.dart';
import '../data/database.dart';
import '../data/settings.dart';
import '../engine/groups.dart';
import '../engine/settings.dart';
import '../engine/tree.dart';
import '../engine/visibility.dart';
import '../notifications/reminders.dart';
import 'app_platform.dart';

/// The one source of "now". Tests override it with a fake (decision 0004).
final clockProvider = Provider<Clock>((ref) => const Clock());

/// `sahai.sqlite`, shared with the capture dialog (see [openAppDatabase]).
final databaseProvider = Provider<SahaiDatabase>((ref) {
  final db = openAppDatabase(clock: ref.watch(clockProvider));
  ref.onDispose(db.close);
  return db;
});

final nodeActionsProvider = Provider<NodeActions>(
  (ref) =>
      NodeActions(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final captureActionsProvider = Provider<CaptureActions>(
  (ref) => CaptureActions(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The captures, newest first, with how many items each has made.
final capturesProvider = StreamProvider<List<CaptureEntry>>(
  (ref) => ref.watch(captureActionsProvider).watch(),
);

/// The live, non-deleted tree. Every action that writes makes it emit again.
final treeProvider = StreamProvider<Tree>(
  (ref) => ref.watch(nodeActionsProvider).watchTree(),
);

/// The phone's notifications. Tests swap in a fake.
final remindersProvider = Provider<Reminders>(
  (ref) => PluginReminders(clock: ref.watch(clockProvider)),
);

/// Android's side of About and Send feedback. Tests swap in a fake.
final appPlatformProvider = Provider<AppPlatform>(
  (ref) => const ChannelAppPlatform(),
);

/// The installed version, such as "0.7.0"; null if Android can't say.
final appVersionProvider = FutureProvider<String?>(
  (ref) => ref.watch(appPlatformProvider).version(),
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
  final settings = ref.watch(settingsProvider).value ?? const AppSettings();
  return ref
      .watch(treeProvider)
      .whenData(
        (tree) =>
            computeSummary(tree, now: clock.now().toUtc(), settings: settings),
      );
});

/// The context groups, in their order (PRD 8.2).
final groupsProvider = StreamProvider<List<ContextGroup>>(
  (ref) => ref.watch(nodeActionsProvider).watchGroups(),
);

/// The tree, groups and saved slots the Summary Page is laid out from.
final summaryLayoutProvider = StreamProvider<SummaryLayout>(
  (ref) => ref.watch(nodeActionsProvider).watchSummaryLayout(),
);

/// The Summary in groups and saved order (PRD 8.2), recomputed like
/// [summaryProvider].
final arrangedSummaryProvider = Provider<AsyncValue<ArrangedSummary>>((ref) {
  final clock = ref.watch(clockProvider);
  ref.watch(recomputeTickProvider);
  final settings = ref.watch(settingsProvider).value ?? const AppSettings();
  return ref
      .watch(summaryLayoutProvider)
      .whenData(
        (layout) => ArrangedSummary(
          layout: layout,
          sections: layout.arrange(clock.now().toUtc(), settings),
        ),
      );
});

/// The Summary's sections with the layout they came from.
class ArrangedSummary {
  const ArrangedSummary({required this.layout, required this.sections});

  final SummaryLayout layout;
  final List<SummarySection> sections;

  Tree get tree => layout.tree;
  List<ContextGroup> get groups => layout.groups;

  /// Every card, top to bottom.
  Iterable<SummaryCard> get cards => sections.expand((s) => s.cards);

  /// Headers show only when a group other than the default list has cards
  /// (frames 1 and 2).
  bool get showsHeaders => sections.any((s) => s.group != null);

  /// The section holding [nodeId]'s card and its index there.
  (SummarySection, int)? find(String nodeId) {
    for (final section in sections) {
      final index = section.cards.indexWhere((c) => c.id == nodeId);
      if (index >= 0) return (section, index);
    }
    return null;
  }
}
