import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/settings.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Onboarding (PRD 8.1, M7 frames 1 to 9 and 16).
///
/// Local time, as on the phone: Tuesday, Nov 3, 3:00 PM.
void main() {
  TestApp freshApp() => TestApp(clock: TestClock(DateTime(2026, 11, 3, 15)));

  Future<TestApp> pumpFirstRun(WidgetTester tester) =>
      pumpSahai(tester, app: freshApp(), onboarded: false);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextField, label), text);
    await tester.pump();
  }

  /// Steps 1 and 2: Biztras and Personal, then Website relaunch with Write
  /// the copy and its two subtasks, ending on step 3.
  Future<void> makeFirstProject(WidgetTester tester) async {
    await tapText(tester, Strings.getStarted);
    await type(tester, Strings.firstArea, 'Biztras');
    await type(tester, Strings.secondArea, 'Personal');
    await tapText(tester, Strings.next);
    await type(tester, Strings.projectLabel, 'Website relaunch');
    await type(tester, Strings.firstTaskLabel, 'Write the copy');
    await tapText(tester, Strings.next);
    await type(tester, Strings.subtaskLabel(1), 'Draft homepage');
    await type(tester, Strings.subtaskLabel(2), 'Draft pricing page');
    await tapText(tester, Strings.next);
  }

  Future<Map<String, String>> titlesByType(TestApp app) async {
    final tree = await app.actions.loadTree();
    return {for (final node in tree.nodes) node.title: node.type.dbName};
  }

  testSahai('a first run opens on Welcome', (tester) async {
    await pumpFirstRun(tester);
    expect(find.text(Strings.welcomeTitle), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testSahai('an install that already has areas opens on the Summary, even '
      'if onboarding was never done (updated from 0.6.0)', (tester) async {
    final app = freshApp();
    await SampleTree.create(app);
    await pumpSahai(tester, app: app, onboarded: false);
    expect(find.text(Strings.welcomeTitle), findsNothing);
    expect(find.text('Draft homepage'), findsOneWidget);
  });

  testSahai('AT-105 onboarding builds real data, and the Summary shows only '
      'the first subtask', (tester) async {
    final app = await pumpFirstRun(tester);
    await makeFirstProject(tester);
    expect(find.text(Strings.revealTitle), findsOneWidget);
    expect(await titlesByType(app), {
      'Biztras': NodeType.domain.dbName,
      'Personal': NodeType.domain.dbName,
      'Website relaunch': NodeType.project.dbName,
      'Write the copy': NodeType.task.dbName,
      'Draft homepage': NodeType.subtask.dbName,
      'Draft pricing page': NodeType.subtask.dbName,
    });
    // Saved through the normal actions, so each has a real created event.
    final created = await (app.db.select(
      app.db.events,
    )..where((e) => e.eventType.equals('created'))).get();
    expect(created, hasLength(6));

    await tapText(tester, Strings.skip);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Draft pricing page'), findsNothing);
    expect((await readSettings(app.db)).onboardingDone, isTrue);
  });

  testSahai('the project can go in the second area', (tester) async {
    final app = await pumpFirstRun(tester);
    await tapText(tester, Strings.getStarted);
    await type(tester, Strings.firstArea, 'Biztras');
    await type(tester, Strings.secondArea, 'Personal');
    await tapText(tester, Strings.next);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Personal'));
    await tester.pump();
    await type(tester, Strings.projectLabel, 'Move house');
    await type(tester, Strings.firstTaskLabel, 'Book a van');
    await tapText(tester, Strings.next);
    final tree = await app.actions.loadTree();
    final project = tree.nodes.singleWhere((n) => n.title == 'Move house');
    expect(tree[project.parentId!]!.title, 'Personal');
  });

  testSahai('Back changes what was made rather than making it again', (
    tester,
  ) async {
    final app = await pumpFirstRun(tester);
    await tapText(tester, Strings.getStarted);
    await type(tester, Strings.firstArea, 'Biztras');
    await type(tester, Strings.secondArea, 'Personal');
    await tapText(tester, Strings.next);
    await type(tester, Strings.projectLabel, 'Website relaunch');
    await type(tester, Strings.firstTaskLabel, 'Write the copy');
    await tapText(tester, Strings.next);

    // Back twice, to step 1: rename the first area and clear the second.
    await tapText(tester, Strings.backButton);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await type(tester, Strings.firstArea, 'Biztras Ltd');
    await type(tester, Strings.secondArea, '');
    await tapText(tester, Strings.next);
    await tapText(tester, Strings.next);

    final tree = await app.actions.loadTree();
    final domains = tree.nodes.where((n) => n.type == NodeType.domain);
    expect(domains.map((d) => d.title), ['Biztras Ltd']);
    expect(
      tree.nodes.where((n) => n.type == NodeType.project).map((p) => p.title),
      ['Website relaunch'],
    );
    expect(
      tree.nodes.where((n) => n.type == NodeType.task).map((p) => p.title),
      ['Write the copy'],
    );
  });

  testSahai('AT-107 Skip opens the Summary and keeps what was saved', (
    tester,
  ) async {
    final app = await pumpFirstRun(tester);
    await tapText(tester, Strings.getStarted);
    await type(tester, Strings.firstArea, 'Biztras');
    await tapText(tester, Strings.next);
    // On step 2, with the project typed but not yet saved.
    await type(tester, Strings.projectLabel, 'Website relaunch');
    await tapText(tester, Strings.skip);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(await titlesByType(app), {'Biztras': NodeType.domain.dbName});
    expect((await readSettings(app.db)).onboardingDone, isTrue);
  });

  testSahai('Skip on Welcome makes nothing', (tester) async {
    final app = await pumpFirstRun(tester);
    await tapText(tester, Strings.skip);
    expect(find.text(Strings.summaryEmptyTitle), findsOneWidget);
    expect(await titlesByType(app), isEmpty);
    expect((await readSettings(app.db)).onboardingDone, isTrue);
  });

  testSahai('AT-106 the practice step changes nothing', (tester) async {
    final app = await pumpFirstRun(tester);
    await makeFirstProject(tester);
    final nodesBefore = await app.db.select(app.db.nodes).get();
    final eventsBefore = await app.db.select(app.db.events).get();

    await tapText(tester, Strings.tryIt);
    expect(find.text(Strings.practiceBanner), findsOneWidget);
    // Leaving the practice is switched off.
    expect(find.byTooltip(Strings.settings), findsNothing);

    // 1. Tick off, then Undo.
    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    expect(find.text('Draft pricing page'), findsOneWidget);
    expect(find.textContaining('Now tap Undo'), findsOneWidget);
    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    expect(find.text('Draft homepage'), findsOneWidget);

    // 2. Set it aside with a preset.
    await tester.tap(find.byTooltip(Strings.setAsideTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.presetName(Preset.tonight)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Now open Set-Aside'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // 3. Wake now on the Set-Aside page.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(Strings.setAside),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Tap Wake now'), findsOneWidget);
    await tester.tap(find.text(Strings.wakeNow).first);
    await tester.pumpAndSettle();

    expect(find.text(Strings.finishTitle), findsOneWidget);
    expect(await app.db.select(app.db.nodes).get(), nodesBefore);
    expect(await app.db.select(app.db.events).get(), eventsBefore);

    await tapText(tester, Strings.goToSummary);
    expect(find.text('Draft homepage'), findsOneWidget);
    final tree = await app.actions.loadTree();
    expect(tree.nodes.where((n) => n.isDone), isEmpty);
    expect(tree.nodes.where((n) => n.snoozeUntil != null), isEmpty);
  });

  testSahai('Skip during the practice keeps the project as made', (
    tester,
  ) async {
    final app = await pumpFirstRun(tester);
    await makeFirstProject(tester);
    await tapText(tester, Strings.tryIt);
    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    await tapText(tester, Strings.skip);
    expect(find.text('Draft homepage'), findsOneWidget);
    final tree = await app.actions.loadTree();
    expect(tree.nodes.where((n) => n.isDone), isEmpty);
  });

  testSahai('AT-108 Replay onboarding from Settings asks first, then runs '
      'again, adding next to what exists', (tester) async {
    final app = freshApp();
    await SampleTree.create(app);
    await pumpSahai(tester, app: app);
    final before = await app.db.select(app.db.nodes).get();
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(Strings.replayOnboarding),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.replayOnboarding));
    await tester.pumpAndSettle();
    expect(find.text(Strings.replayTitle), findsOneWidget);
    await tester.tap(find.text(Strings.replay));
    await tester.pumpAndSettle();
    expect(find.text(Strings.welcomeTitle), findsOneWidget);

    await makeFirstProject(tester);
    await tapText(tester, Strings.skip);
    final after = await app.db.select(app.db.nodes).get();
    expect(after, containsAll(before));
    expect(after, hasLength(before.length + 6));
  });

  testSahai('Cancel on Replay onboarding changes nothing', (tester) async {
    final app = freshApp();
    await SampleTree.create(app);
    await pumpSahai(tester, app: app);
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(Strings.replayOnboarding),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.replayOnboarding));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(Strings.welcomeTitle), findsNothing);
    expect(find.text(Strings.replayOnboarding), findsOneWidget);
  });
}
