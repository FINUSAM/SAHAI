import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/practice_scope.dart';
import '../../app/providers.dart';
import '../../data/database.dart';
import '../../engine/set_aside_list.dart';
import '../../engine/tree.dart';
import '../../notifications/reminders.dart';
import '../../shared/dashed_box.dart';
import '../../shared/strings.dart';
import '../explorer/explorer_rows.dart';
import '../set_aside/set_aside_screen.dart';
import '../summary/summary_screen.dart';

/// Where the practice has got to. Each move is shown in turn (M7 frames 6
/// to 8): tick off and Undo, set aside, then Wake now on the Set-Aside page.
enum PracticeStage { tick, undo, setAside, openSetAside, wake }

/// Step 4 of onboarding: the real Summary and Set-Aside screens, running on
/// a temporary in-memory copy of what onboarding just made (decision
/// 0008). Nothing here touches `sahai.sqlite`, the activity log included,
/// so the practice leaves no trace (AT-106) and nothing has to be deleted
/// afterwards. Reminders are switched off, and Explorer, Capture, Settings
/// and Open in tree, which would leave the copy, are not available.
class PracticeView extends ConsumerStatefulWidget {
  const PracticeView({
    super.key,
    required this.domainId,
    required this.projectId,
    required this.taskId,
    required this.firstSubtaskId,
    required this.secondSubtaskId,
    required this.onFinished,
    required this.onSkip,
    required this.onBack,
  });

  final String domainId;
  final String projectId;
  final String taskId;
  final String firstSubtaskId;
  final String secondSubtaskId;

  /// Wake now brought the first subtask back: the practice is done.
  final VoidCallback onFinished;
  final VoidCallback onSkip;

  /// Android's back: returns to step 3.
  final VoidCallback onBack;

  @override
  ConsumerState<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends ConsumerState<PracticeView> {
  SahaiDatabase? _copy;
  ProviderContainer? _container;
  var _stage = PracticeStage.tick;
  var _tab = 0;
  var _first = '';
  var _second = '';
  var _closed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  /// Copies only what onboarding made, and the user's settings so presets
  /// and the day start match, into a new in-memory database.
  Future<void> _open() async {
    final real = ref.read(databaseProvider);
    final clock = ref.read(clockProvider);
    final ids = [
      widget.domainId,
      widget.projectId,
      widget.taskId,
      widget.firstSubtaskId,
      widget.secondSubtaskId,
    ];
    final rows = await (real.select(
      real.nodes,
    )..where((n) => n.id.isIn(ids))).get();
    final settings = await (real.select(
      real.settingsTable,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    final copy = SahaiDatabase(NativeDatabase.memory(), clock: clock);
    await copy.transaction(() async {
      for (final row in rows) {
        await copy.into(copy.nodes).insert(row);
      }
      if (settings != null) {
        await (copy.update(
          copy.settingsTable,
        )..where((s) => s.id.equals(1))).write(
          SettingsTableCompanion(
            dayStartMinutes: Value(settings.dayStartMinutes),
            presets: Value(settings.presets),
            reminderMinutes: Value(settings.reminderMinutes),
            defaultLeadDays: Value(settings.defaultLeadDays),
            onboardingDone: const Value(true),
          ),
        );
      }
    });
    if (!mounted || _closed) {
      await copy.close();
      return;
    }
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        databaseProvider.overrideWithValue(copy),
        remindersProvider.overrideWithValue(const _NoReminders()),
        appPlatformProvider.overrideWithValue(ref.read(appPlatformProvider)),
      ],
    );
    container.listen<AsyncValue<Tree>>(
      treeProvider,
      (_, next) => _follow(next.value),
      fireImmediately: true,
    );
    setState(() {
      _copy = copy;
      _container = container;
    });
  }

  /// Moves the coach on as the user does each move, read from the copy.
  void _follow(Tree? tree) {
    if (tree == null || !mounted) return;
    final first = tree[widget.firstSubtaskId];
    final second = tree[widget.secondSubtaskId];
    if (first == null) return;
    _first = displayTitle(tree, first);
    _second = second == null ? '' : displayTitle(tree, second);
    final now = ref.read(clockProvider).now();
    final setAside =
        wakeTimeOf(first, now) != null ||
        setAsideAncestor(tree, first.id, now) != null;
    final next = switch (_stage) {
      PracticeStage.tick when first.isDone => PracticeStage.undo,
      PracticeStage.undo when first.isTodo => PracticeStage.setAside,
      PracticeStage.setAside when setAside => PracticeStage.openSetAside,
      PracticeStage.openSetAside || PracticeStage.wake when !setAside => null,
      _ => _stage,
    };
    if (next == null) {
      _finish(widget.onFinished);
      return;
    }
    setState(() => _stage = next);
  }

  void _selectTab(int index) {
    setState(() {
      _tab = index;
      if (index == 1 && _stage == PracticeStage.openSetAside) {
        _stage = PracticeStage.wake;
      }
    });
  }

  /// Leaves the practice and throws the copy away.
  void _finish(VoidCallback then) {
    if (_closed) return;
    _closed = true;
    // An Undo left on screen would act on the copy after it has gone.
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    then();
  }

  @override
  void dispose() {
    _closed = true;
    _container?.dispose();
    unawaited(_copy?.close());
    super.dispose();
  }

  Future<void> _bringBack() async {
    final container = _container;
    if (container == null) return;
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    await container.read(nodeActionsProvider).reopen(widget.firstSubtaskId);
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(widget.onBack);
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const ExcludeSemantics(child: Icon(Icons.replay)),
                    const SizedBox(width: 10),
                    const Expanded(child: Text(Strings.practiceBanner)),
                    TextButton(
                      onPressed: () => _finish(widget.onSkip),
                      child: const Text(Strings.skip),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: container == null
            ? const Center(child: CircularProgressIndicator())
            : UncontrolledProviderScope(
                container: container,
                child: PracticeScope(
                  coach: _Coach(
                    stage: _stage,
                    first: _first,
                    second: _second,
                    onBringBack: _bringBack,
                  ),
                  child: IndexedStack(
                    index: _tab,
                    children: const [SummaryScreen(), SetAsideScreen()],
                  ),
                ),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.format_list_bulleted),
              label: Strings.summary,
            ),
            NavigationDestination(
              icon: _stage == PracticeStage.openSetAside
                  ? DashedBox(
                      color: theme.colorScheme.onSurface,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: Icon(Icons.schedule),
                      ),
                    )
                  : const Icon(Icons.schedule),
              label: Strings.setAside,
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_tree_outlined),
              label: Strings.explorer,
              enabled: false,
            ),
            const NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: Strings.capture,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed box that says what to try next.
class _Coach extends StatelessWidget {
  const _Coach({
    required this.stage,
    required this.first,
    required this.second,
    required this.onBringBack,
  });

  final PracticeStage stage;
  final String first;
  final String second;
  final VoidCallback onBringBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (int? step, String text) = switch (stage) {
      PracticeStage.tick => (null, Strings.practiceTick(first)),
      PracticeStage.undo => (1, Strings.practiceUndo(first, second)),
      PracticeStage.setAside => (null, Strings.practiceSetAside(first)),
      PracticeStage.openSetAside => (
        2,
        Strings.practiceOpenSetAside(first, second),
      ),
      PracticeStage.wake => (3, Strings.practiceWake(first)),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Semantics(
        liveRegion: true,
        child: DashedBox(
          color: theme.colorScheme.onSurfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (step != null)
                        TextSpan(
                          text: '${Strings.coachStep(step)} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      TextSpan(text: text),
                    ],
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                // The 5-second Undo can run out before the user taps it.
                if (stage == PracticeStage.undo)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onBringBack,
                      child: const Text(Strings.bringItBack),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reminders do nothing in the practice: nothing in it is real.
class _NoReminders implements Reminders {
  const _NoReminders();

  @override
  Future<void> init(void Function(String? nodeId) onOpen) async {}

  @override
  Future<void> replaceAll(
    List<ReminderMessage> messages, {
    required bool exact,
  }) async {}

  @override
  Future<List<DateTime>> undelivered() async => const [];

  @override
  Future<void> showNow(List<ReminderMessage> messages) async {}

  @override
  Future<void> askPermission() async {}

  @override
  Future<void> askExactAlarms() async {}
}
