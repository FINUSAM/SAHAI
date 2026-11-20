import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/due.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';
import 'capture_test.dart' show capturesOf, tapCreate;

/// The accessibility pass over every screen (PRD 13, AT-116, AT-117), at
/// normal size and at the largest font Android offers (200%): every button
/// has a label, tap targets are at least 48 dp, and nothing is cut off. A
/// layout overflow fails a test on its own. Settings, About, the presets and
/// onboarding are covered in m7_accessibility_test.dart.
///
/// TalkBack itself, reading each announcement aloud, is the owner's check
/// on the phone.
///
/// Local time, as on the phone: Monday, Nov 9, 2026, 10:00 AM.
void main() {
  Future<void> checkGuidelines(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }

  /// Checks the screen, then scrolls through it checking as it goes, so
  /// rows further down are checked too.
  Future<void> checkAll(WidgetTester tester) async {
    await checkGuidelines(tester);
    final list = find.byType(Scrollable);
    if (list.evaluate().isEmpty) return;
    for (var i = 0; i < 6; i++) {
      await tester.drag(list.first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await checkGuidelines(tester);
    }
  }

  /// Scrolls the screen's list until [finder] is built and in view, then
  /// taps it. Rows far down a lazy list don't exist until scrolled to.
  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    final list = find.byType(Scrollable).first;
    await tester.drag(list, const Offset(0, 5000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 200, scrollable: list);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openRowActions(WidgetTester tester, String title) =>
      scrollToAndTap(tester, find.byTooltip(Strings.actionsFor(title)));

  /// Biztras › Website relaunch with three tasks (the first due Nov 20, its
  /// first subtask 5 days overdue), Biztras › Admin with three items (the
  /// second set aside), Personal › Finance with a monthly bill, and a
  /// capture.
  Future<(TestApp, SampleTree)> rich() async {
    final app = TestApp(clock: TestClock(DateTime(2026, 11, 3, 15)));
    final s = await SampleTree.create(app);
    final a = app.actions;
    await a.setDueDate(s.tasks[0], DateTime(2026, 11, 20));
    await a.setDueDate(
      s.subtasks[0],
      DateTime(2026, 11, 4),
      reminder: DueReminder.dayBefore,
    );
    await a.setAside(s.items[1], DateTime(2026, 11, 12, 9));
    final personal = await a.create(type: NodeType.domain, title: 'Personal');
    final finance = await a.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Finance',
    );
    await a.create(
      type: NodeType.streamItem,
      parentId: finance,
      title: 'Pay SBI card',
      schedule: Schedule.monthly(day: 12),
      dueOn: DateTime(2026, 11, 12),
      leadDays: 3,
    );
    await capturesOf(app).add('call the plumber about the kitchen tap');
    app.clock.now = DateTime(2026, 11, 9, 10);
    return (app, s);
  }

  for (final (scale, size) in [(1.0, 'normal size'), (2.0, 'largest font')]) {
    group('at $size', () {
      testSahai('the Summary, a card sheet and the set-aside picker', (
        tester,
      ) async {
        final (app, _) = await rich();
        await pumpSahai(tester, app: app, textScale: scale);
        await checkAll(tester);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Draft homepage'));
        await tester.pumpAndSettle();
        await checkGuidelines(tester);
        // Move up and Move down are the drag's button alternative (AT-116).
        expect(find.text(Strings.moveUp), findsOneWidget);
        expect(find.text(Strings.moveDown), findsOneWidget);
        await tapInView(tester, find.text(Strings.setAsideTitle));
        await checkGuidelines(tester);
        await closeSheet(tester);
      });

      testSahai('the Set-Aside page', (tester) async {
        final (app, _) = await rich();
        await pumpSahai(
          tester,
          app: app,
          textScale: scale,
          tab: Strings.setAside,
        );
        await checkAll(tester);
      });

      testSahai('the Explorer and an actions sheet', (tester) async {
        final (app, _) = await rich();
        await pumpExplorer(tester, app: app, textScale: scale);
        await expandAll(tester);
        await checkAll(tester);
        await openRowActions(tester, 'Website relaunch');
        await checkGuidelines(tester);
        await closeSheet(tester);
      });

      testSahai('the reorder screen, with buttons beside each drag handle', (
        tester,
      ) async {
        final (app, _) = await rich();
        await pumpExplorer(tester, app: app, textScale: scale);
        await expandAll(tester);
        await openRowActions(tester, '1. Write copy');
        await tapInView(
          tester,
          find.text(Strings.reorderChildren(NodeType.project)),
        );
        expect(find.byIcon(Icons.arrow_upward), findsNWidgets(3));
        await checkAll(tester);
      });

      testSahai('the move screen', (tester) async {
        final (app, _) = await rich();
        await pumpExplorer(tester, app: app, textScale: scale);
        await expandAll(tester);
        await openRowActions(tester, '1. Write copy');
        await tapInView(
          tester,
          find.text(Strings.moveToAnother(NodeType.project)),
        );
        await checkAll(tester);
      });

      testSahai('the task form with a due date, and the Remind me sheet', (
        tester,
      ) async {
        final (app, _) = await rich();
        await pumpExplorer(tester, app: app, textScale: scale);
        await expandAll(tester);
        await openRowActions(tester, '1. Write copy');
        await tapInView(tester, find.text(Strings.edit));
        await checkAll(tester);
        await tapInView(tester, find.text(Strings.remindMe));
        await checkGuidelines(tester);
        await closeSheet(tester);
      });

      testSahai("a bill's edit form", (tester) async {
        final (app, _) = await rich();
        await pumpExplorer(tester, app: app, textScale: scale);
        // Only Personal › Finance is expanded, so the list stays short.
        for (final row in ['Personal', 'Finance']) {
          await scrollToAndTap(tester, find.byTooltip(Strings.expand(row)));
        }
        await openRowActions(tester, 'Pay SBI card');
        await tapInView(tester, find.text(Strings.edit));
        await checkAll(tester);
      });

      testSahai("the Capture page and a capture's Create form", (tester) async {
        final (app, _) = await rich();
        await pumpSahai(
          tester,
          app: app,
          textScale: scale,
          tab: Strings.capture,
        );
        await checkAll(tester);
        await tapCreate(tester, 'call the plumber about the kitchen tap');
        await checkAll(tester);
      });

      testSahai('the Context groups screen', (tester) async {
        final (app, _) = await rich();
        await pumpSahai(tester, app: app, textScale: scale);
        await tester.tap(find.byTooltip(Strings.settings));
        await tester.pumpAndSettle();
        await scrollToAndTap(tester, find.text(Strings.contextGroups));
        await checkAll(tester);
      });

      testSahai('the sheet a due reminder opens for a hidden item', (
        tester,
      ) async {
        final (app, s) = await rich();
        await pumpSahai(tester, app: app, textScale: scale);
        // Launch waits behind the earlier tasks.
        await app.actions.setDueDate(s.tasks[2], DateTime(2026, 11, 20));
        await tester.pumpAndSettle();
        app.reminders.tap(s.tasks[2]);
        await tester.pumpAndSettle();
        expect(find.text(Strings.changeDueDate), findsOneWidget);
        await checkGuidelines(tester);
        await closeSheet(tester);
      });
    });
  }
}
