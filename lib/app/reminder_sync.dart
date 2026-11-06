import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/planner.dart';
import '../notifications/reminders.dart';
import 'providers.dart';

/// Keeps the phone's scheduled reminders in step with the data (tech plan
/// 7): everything is replaced after every change, when Settings change,
/// on start and on resume. Reminders are fixed moments scheduled in UTC,
/// so a time-zone change needs nothing more than the resume.
class ReminderSync extends ConsumerStatefulWidget {
  const ReminderSync({super.key, required this.onOpen, required this.child});

  /// Opens what a tapped notification points at: an item, or null for the
  /// Summary.
  final void Function(String? nodeId) onOpen;
  final Widget child;

  @override
  ConsumerState<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends ConsumerState<ReminderSync> {
  late final AppLifecycleListener _lifecycle;
  var _ready = false;
  var _running = false;
  var _again = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _sync);
    ref.listenManual(treeProvider, (_, _) => _sync());
    ref.listenManual(settingsProvider, (_, _) => _sync());
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await ref.read(remindersProvider).init(widget.onOpen);
    } on Exception catch (e) {
      debugPrint('Reminders not set up: ${e.runtimeType}');
      return;
    }
    _ready = true;
    await _sync();
  }

  /// One sync at a time; a change during one runs it again afterwards.
  Future<void> _sync() async {
    if (!_ready || !mounted) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        // The current values; a `.future` would give the first one loaded.
        // Until both have loaded there is nothing to plan, and their first
        // values call this again.
        final tree = ref.read(treeProvider).value;
        final settings = ref.read(settingsProvider).value;
        if (tree == null || settings == null) return;
        final plan = planNotifications(
          tree,
          now: ref.read(clockProvider).now(),
          settings: settings,
        );
        await ref
            .read(remindersProvider)
            .replaceAll(
              messagesFor(tree, plan),
              exact: settings.exactReminders,
            );
      } while (_again && mounted);
    } on Exception catch (e) {
      debugPrint('Reminders not scheduled: ${e.runtimeType}');
    } finally {
      _running = false;
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
