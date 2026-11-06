import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/visibility.dart';
import 'providers.dart';

/// Keeps the Summary current while time passes with no change to the data
/// (PRD 6): it recomputes when the app starts, when it comes back to the
/// foreground, and when the next set-aside item is due to wake (AT-034).
/// Each recompute also logs the wakes and appearances since the last one.
class SummaryRefresher extends ConsumerStatefulWidget {
  const SummaryRefresher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SummaryRefresher> createState() => _SummaryRefresherState();
}

class _SummaryRefresherState extends ConsumerState<SummaryRefresher> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    ref.listenManual<AsyncValue<SummaryResult>>(
      summaryProvider,
      (_, next) => _schedule(next.value?.nextChangeAt),
      fireImmediately: true,
    );
    // Items may have woken while the app was closed.
    unawaited(_refresh());
  }

  /// One timer, for the next moment the Summary changes on its own.
  void _schedule(DateTime? at) {
    _timer?.cancel();
    _timer = null;
    if (at == null) return;
    final wait = at.difference(ref.read(clockProvider).now());
    _timer = Timer(wait.isNegative ? Duration.zero : wait, _refresh);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await ref.read(nodeActionsProvider).recompute();
    if (!mounted) return;
    ref.read(recomputeTickProvider.notifier).bump();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
