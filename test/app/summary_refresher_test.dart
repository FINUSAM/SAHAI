import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// The Summary keeps up with time passing while nothing is tapped (PRD 6):
/// a timer for the next wake, and a recompute on resume.
void main() {
  Future<(TestApp, SampleTree)> setAsideFirstSubtask(Duration by) async {
    final app = TestApp();
    final sample = await SampleTree.create(app);
    await app.actions.setAside(sample.subtasks[0], app.clock.now.add(by));
    return (app, sample);
  }

  testSahai('AT-034 a waking subtask takes its place back while the app is '
      'open', (tester) async {
    final (app, _) = await setAsideFirstSubtask(const Duration(hours: 2));
    await pumpSahai(tester, app: app);
    expect(find.text('Draft pricing page'), findsOneWidget);
    expect(find.text('Draft homepage'), findsNothing);

    // 5:00 PM passes with the app open and nothing tapped.
    app.clock.advance(const Duration(hours: 2));
    await tester.pump(const Duration(hours: 2));
    await tester.pumpAndSettle();
    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Draft pricing page'), findsNothing);
  });

  testSahai('nothing changes before the wake time', (tester) async {
    final (app, _) = await setAsideFirstSubtask(const Duration(hours: 2));
    await pumpSahai(tester, app: app);
    app.clock.advance(const Duration(minutes: 119));
    await tester.pump(const Duration(minutes: 119));
    await tester.pumpAndSettle();
    expect(find.text('Draft pricing page'), findsOneWidget);
  });

  testSahai('coming back to the app recomputes and logs the wake', (
    tester,
  ) async {
    final (app, sample) = await setAsideFirstSubtask(const Duration(hours: 2));
    await pumpSahai(tester, app: app);
    // The phone slept through the wake time; no timer has run yet.
    app.clock.advance(const Duration(hours: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Draft homepage'), findsOneWidget);
    final woke = await tester.runAsync(
      () => (app.db.select(
        app.db.events,
      )..where((e) => e.eventType.equals(EventTypes.woke))).get(),
    );
    expect(woke!.single.nodeId, sample.subtasks[0]);
  });

  testSahai('items that woke while the app was closed show at start', (
    tester,
  ) async {
    final (app, _) = await setAsideFirstSubtask(const Duration(hours: 2));
    app.clock.advance(const Duration(days: 1));
    await pumpSahai(tester, app: app);
    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Draft pricing page'), findsNothing);
  });
}
