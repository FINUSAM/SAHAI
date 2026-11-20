import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/log_retention.dart';
import 'providers.dart';

/// Looks after the database file while the app runs (PRD 3, risk R5).
///
/// Once the app has started, it compacts activity log events older than 12
/// months into daily counts (PRD 9, E-004), so the log stays small enough
/// for Auto Backup. It runs after the first frame, so the Summary never
/// waits for it.
///
/// When the app goes to the background it folds the write-ahead log back
/// into the main file. Auto Backup copies both files anyway, so this is a
/// second layer: it keeps the `-wal` file small and usually empty.
class DataUpkeep extends ConsumerStatefulWidget {
  const DataUpkeep({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DataUpkeep> createState() => _DataUpkeepState();
}

class _DataUpkeepState extends ConsumerState<DataUpkeep> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: () => unawaited(_checkpoint()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_compact()));
  }

  Future<void> _compact() async {
    if (!mounted) return;
    try {
      await compactEventLog(
        ref.read(databaseProvider),
        clock: ref.read(clockProvider),
      );
    } on Exception catch (e) {
      // Nothing is lost: the events stay until the next start tries again.
      debugPrint('Log compaction failed: ${e.runtimeType}');
    }
  }

  Future<void> _checkpoint() async {
    try {
      await ref.read(databaseProvider).checkpoint();
    } on Exception catch (e) {
      // Not urgent: SQLite checkpoints on its own as the log grows.
      debugPrint('Checkpoint failed: ${e.runtimeType}');
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
