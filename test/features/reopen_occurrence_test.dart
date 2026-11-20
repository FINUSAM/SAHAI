import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Reopen last completion and Reopen last skip on screen (E-018): in the
/// Explorer menu, and as a shortcut on the Set-Aside page. Local time, as
/// on the phone: Saturday, Nov 7, 2026.
void main() {
  /// Personal › Finance & Bills › Pay HDFC card, monthly on the 5th.
  Future<(TestApp, String)> billApp() async {
    final app = TestApp(clock: TestClock(DateTime(2026, 11, 7, 10)));
    final a = app.actions;
    final personal = await a.create(type: NodeType.domain, title: 'Personal');
    final finance = await a.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Finance & Bills',
    );
    final hdfc = await a.create(
      type: NodeType.streamItem,
      parentId: finance,
      title: 'Pay HDFC card',
      schedule: Schedule.monthly(day: 5),
      dueOn: DateTime(2026, 11, 5),
    );
    return (app, hdfc);
  }

  testSahai('AT-125 the Explorer menu reopens the last completion with its '
      'dates, and the bill is back on the Summary, overdue', (tester) async {
    final (app, hdfc) = await billApp();
    await app.actions.markDone(hdfc);
    await pumpExplorer(tester, app: app);
    await expandAll(tester);
    await openActions(tester, 'Pay HDFC card');
    expect(find.text(Strings.reopenLastCompletion), findsOneWidget);
    expect(find.text('Done Nov 7, was due Nov 5'), findsOneWidget);
    expect(find.text(Strings.reopenLastSkip), findsNothing);

    await choose(tester, Strings.reopenLastCompletion);
    expect(find.text('Reopened. Due Nov 5'), findsOneWidget);

    await goToTab(tester, Strings.summary);
    expect(find.text('Pay HDFC card'), findsOneWidget);
    expect(find.text('2 days overdue'), findsOneWidget);
  });

  testSahai('AT-126 the Set-Aside page offers Reopen last skip next to Wake '
      'now and Change time', (tester) async {
    final (app, hdfc) = await billApp();
    await app.actions.skipOccurrence(hdfc);
    await pumpSahai(tester, app: app, tab: Strings.setAside);
    await tester.tap(find.text('Pay HDFC card'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.wakeNow), findsWidgets);
    expect(find.text(Strings.changeTime), findsOneWidget);
    expect(find.text('Skipped Nov 7, was due Nov 5'), findsOneWidget);

    await tester.tap(find.text(Strings.reopenLastSkip));
    await tester.pumpAndSettle();
    expect(find.text('Reopened. Due Nov 5'), findsOneWidget);
    // It no longer waits for Dec 2: it is back on the Summary.
    expect(find.text('Pay HDFC card'), findsNothing);
    await goToTab(tester, Strings.summary);
    expect(find.text('2 days overdue'), findsOneWidget);
  });

  testSahai('AT-127 only the latest completion is offered, and nothing once '
      'it is reopened', (tester) async {
    final (app, hdfc) = await billApp();
    await app.actions.markDone(hdfc);
    app.clock.now = DateTime(2026, 12, 5, 10);
    await app.actions.markDone(hdfc);
    await pumpExplorer(tester, app: app);
    await expandAll(tester);
    await openActions(tester, 'Pay HDFC card');
    expect(find.text('Done Dec 5, was due Dec 5'), findsOneWidget);
    expect(find.textContaining('was due Nov 5'), findsNothing);

    await choose(tester, Strings.reopenLastCompletion);
    await openActions(tester, 'Pay HDFC card');
    expect(find.text(Strings.reopenLastCompletion), findsNothing);
    expect(find.text(Strings.reopenLastSkip), findsNothing);
  });

  testSahai('items that never repeated, and repeating items with nothing to '
      'reopen, offer no Reopen line', (tester) async {
    final (app, _) = await billApp();
    final personal = (await app.actions.loadTree()).roots.single.id;
    await app.actions.create(
      type: NodeType.project,
      parentId: personal,
      title: 'Move house',
    );
    await pumpExplorer(tester, app: app);
    await expandAll(tester);
    for (final title in ['Pay HDFC card', 'Move house']) {
      await openActions(tester, title);
      expect(find.text(Strings.reopenLastCompletion), findsNothing);
      expect(find.text(Strings.reopenLastSkip), findsNothing);
      await closeSheet(tester);
    }
    expect(find.byType(BottomSheet), findsNothing);
  });
}
