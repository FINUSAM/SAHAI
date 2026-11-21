import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/due.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';
import 'capture_test.dart'
    show capturesOf, fillCreateForm, saveAndAnswer, tapCreate;

/// Due dates on one-off items on screen (E-019, M7 frames 19 to 27). Local
/// time, as on the phone: Monday, Nov 9, 2026, 10:00 AM, with the default
/// Reminder time of 9:00 AM.
void main() {
  final monday = DateTime(2026, 11, 9, 10);

  /// Biztras › Website relaunch › Write the copy, and Personal › Errands.
  Future<TestApp> sample() async {
    final app = TestApp(clock: TestClock(monday));
    final a = app.actions;
    final biztras = await a.create(type: NodeType.domain, title: 'Biztras');
    final website = await a.create(
      type: NodeType.project,
      parentId: biztras,
      title: 'Website relaunch',
    );
    await a.create(
      type: NodeType.task,
      parentId: website,
      title: 'Write the copy',
    );
    final personal = await a.create(type: NodeType.domain, title: 'Personal');
    await a.create(type: NodeType.stream, parentId: personal, title: 'Errands');
    return app;
  }

  Future<void> openForm(WidgetTester tester, String parent, NodeType t) async {
    await expandAll(tester);
    await openActions(tester, parent);
    await choose(tester, Strings.addChild([t]));
  }

  /// Picks [day] of the month shown in the open date picker, then OK.
  Future<void> pickDay(WidgetTester tester, int day) async {
    await tester.tap(find.text('$day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, String title) async {
    await tester.enterText(
      find.widgetWithText(TextField, Strings.titleLabel),
      title,
    );
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();
  }

  group('forms', () {
    testSahai('AT-128 a new task gets a due date, On the day by default', (
      tester,
    ) async {
      final app = await sample();
      await pumpExplorer(tester, app: app);
      await openForm(tester, 'Website relaunch', NodeType.task);
      expect(find.text(Strings.dueDate), findsOneWidget);
      expect(find.text(Strings.dueDateNone), findsOneWidget);
      expect(find.text(Strings.remindMe), findsNothing);

      await tester.tap(find.text(Strings.addDueDate));
      await tester.pumpAndSettle();
      await pickDay(tester, 20);
      expect(find.text('Fri, Nov 20'), findsOneWidget);
      expect(find.text('On the day · Fri, Nov 20, 9:00 AM'), findsOneWidget);
      expect(find.text(Strings.dueTipOnTheDay), findsOneWidget);

      await save(tester, 'Send proposal to Acme');
      final task = (await app.actions.loadTree()).nodes.singleWhere(
        (n) => n.title == 'Send proposal to Acme',
      );
      expect(task.dueOn, DateTime(2026, 11, 20));
      expect(task.dueReminder, DueReminder.onTheDay);
    });

    testSahai('AT-128 days before today cannot be picked', (tester) async {
      final app = await sample();
      await pumpExplorer(tester, app: app);
      await openForm(tester, 'Website relaunch', NodeType.task);
      await tester.tap(find.text(Strings.addDueDate));
      await tester.pumpAndSettle();
      // Nov 8 is greyed: tapping it leaves today picked.
      await pickDay(tester, 8);
      expect(find.text('Mon, Nov 9'), findsOneWidget);
    });

    testSahai('AT-130 Remind me offers five choices with their dates, past '
        'ones greyed, and an early one adds the tip about the day', (
      tester,
    ) async {
      final app = await sample();
      await pumpExplorer(tester, app: app);
      await openForm(tester, 'Website relaunch', NodeType.task);
      await tester.tap(find.text(Strings.addDueDate));
      await tester.pumpAndSettle();
      // Due Fri, Nov 13: a week before (Nov 6) is already past.
      await pickDay(tester, 13);
      // On a phone the keyboard covers the lower rows, so scroll it into view.
      await tapInView(tester, find.text(Strings.remindMe));
      expect(find.text('Due Fri, Nov 13'), findsOneWidget);
      for (final choice in DueReminder.values) {
        expect(find.text(Strings.dueReminderName(choice)), findsOneWidget);
      }
      RadioListTile<DueReminder> tile(DueReminder r) =>
          tester.widget<RadioListTile<DueReminder>>(
            find.widgetWithText(
              RadioListTile<DueReminder>,
              Strings.dueReminderName(r),
            ),
          );
      expect(tile(DueReminder.weekBefore).enabled, isFalse);
      expect(tile(DueReminder.threeDaysBefore).enabled, isTrue);
      expect(find.text('Tue, Nov 10'), findsOneWidget);

      await tester.tap(
        find.text(Strings.dueReminderName(DueReminder.threeDaysBefore)),
      );
      await tester.pumpAndSettle();
      expect(find.text('3 days before · Tue, Nov 10, 9:00 AM'), findsOneWidget);
      expect(find.text(Strings.dueTipEarly('Fri, Nov 13')), findsOneWidget);

      await save(tester, 'Send proposal to Acme');
      final task = (await app.actions.loadTree()).nodes.singleWhere(
        (n) => n.title == 'Send proposal to Acme',
      );
      expect(task.dueReminder, DueReminder.threeDaysBefore);
    });

    testSahai('AT-128 ✕ on the edit form clears the due date', (tester) async {
      final app = await sample();
      final copy = (await app.actions.loadTree()).nodes.singleWhere(
        (n) => n.title == 'Write the copy',
      );
      await app.actions.setDueDate(copy.id, DateTime(2026, 11, 20));
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      await openActions(tester, '1. Write the copy');
      await choose(tester, Strings.edit);
      expect(find.text('Fri, Nov 20'), findsOneWidget);
      await tester.tap(find.byTooltip(Strings.clearDueDate));
      await tester.pumpAndSettle();
      expect(find.text(Strings.dueDateNone), findsOneWidget);
      await tester.tap(find.text(Strings.save));
      await tester.pumpAndSettle();
      expect((await app.actions.loadTree())[copy.id]!.dueOn, isNull);
    });

    testSahai('AT-128 domains and streams have no Due date row, and a stream '
        'item loses it while Repeat is on', (tester) async {
      final app = await sample();
      await pumpExplorer(tester, app: app);
      for (final container in ['Personal', 'Errands']) {
        await expandAll(tester);
        await openActions(tester, container);
        await choose(tester, Strings.edit);
        expect(find.text(Strings.dueDate), findsNothing, reason: container);
        await tester.tap(find.byTooltip(Strings.close));
        await tester.pumpAndSettle();
      }

      await openForm(tester, 'Errands', NodeType.streamItem);
      expect(find.text(Strings.dueDateNone), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(Strings.repeat),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(Strings.repeat));
      await tester.pumpAndSettle();
      expect(find.text(Strings.dueDateNone), findsNothing);
    });
  });

  testSahai('AT-132 a task made from a capture gets a due date and a week\'s '
      'notice', (tester) async {
    final app = await sample();
    await capturesOf(app)
        .add('renew passport – check fees first, must be done by Dec 14');
    await pumpSahai(tester, app: app, tab: Strings.capture);
    await tapCreate(
      tester,
      'renew passport – check fees first, must be done by Dec 14',
    );
    await fillCreateForm(
      tester,
      type: NodeType.streamItem,
      place: 'Errands',
      title: 'Renew passport',
    );
    await tester.scrollUntilVisible(
      find.text(Strings.addDueDate),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.addDueDate));
    await tester.pumpAndSettle();
    // Next month in the picker, then the 14th.
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await pickDay(tester, 14);
    // Below the fold, and on a phone under the keyboard too, which comes
    // back once the date picker closes.
    await waitForKeyboard(tester);
    await tester.scrollUntilVisible(
      find.text(Strings.remindMe),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tapInView(tester, find.text(Strings.remindMe));
    await tester.tap(
      find.text(Strings.dueReminderName(DueReminder.weekBefore)),
    );
    await tester.pumpAndSettle();
    // On a phone the keyboard comes back for the title when the sheet
    // closes and scrolls the form up to it, so scroll back down to the line.
    const chosen = '1 week before · Mon, Dec 7, 9:00 AM';
    await waitForKeyboard(tester);
    await tester.scrollUntilVisible(
      find.text(chosen),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(chosen), findsOneWidget);

    await saveAndAnswer(tester, Strings.keep);
    final item = (await app.actions.loadTree()).nodes.singleWhere(
      (n) => n.title == 'Renew passport',
    );
    expect(item.dueOn, DateTime(2026, 12, 14));
    expect(item.dueReminder, DueReminder.weekBefore);
    expect(
      find.text('renew passport – check fees first, must be done by Dec 14'),
      findsOneWidget,
    );
  });

  group('labels', () {
    /// Personal › Events with Book the venue (due Nov 6), and Personal ›
    /// Errands with Call the bank (due today) then Buy curtains (no due
    /// date), on Monday, Nov 9. A stream shows one item at a time.
    Future<TestApp> errands() async {
      final app = TestApp(clock: TestClock(DateTime(2026, 11, 5, 10)));
      final a = app.actions;
      final personal = await a.create(type: NodeType.domain, title: 'Personal');
      for (final (stream, items) in [
        ('Events', [('Book the venue', DateTime(2026, 11, 6))]),
        (
          'Errands',
          [('Call the bank', DateTime(2026, 11, 9)), ('Buy curtains', null)],
        ),
      ]) {
        final id = await a.create(
          type: NodeType.stream,
          parentId: personal,
          title: stream,
        );
        for (final (title, due) in items) {
          await a.create(
            type: NodeType.streamItem,
            parentId: id,
            title: title,
            dueOn: due,
          );
        }
      }
      app.clock.now = monday;
      return app;
    }

    Finder rendered(bool Function(String) test) => find.byWidgetPredicate(
      (w) => w is RichText && test(w.text.toPlainText()),
    );

    /// The weight [text] is drawn in, whether it's a Text or a Text.rich.
    FontWeight? weightOf(WidgetTester tester, String text) => tester
        .widget<RichText>(rendered((t) => t == text))
        .text
        .style
        ?.fontWeight;

    testSahai('AT-131 Summary cards show overdue in bold and due today, each '
        'with the calendar mark; done removes the label and Undo brings it '
        'back', (tester) async {
      final app = await errands();
      await pumpSahai(tester, app: app);
      expect(find.text('3 days overdue'), findsOneWidget);
      expect(find.text(Strings.dueToday), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.repeat), findsNothing);
      expect(weightOf(tester, '3 days overdue'), FontWeight.bold);
      expect(weightOf(tester, Strings.dueToday), isNot(FontWeight.bold));

      await tester.tap(
        find.byTooltip(Strings.markDoneTooltip('Call the bank')),
      );
      await tester.pumpAndSettle();
      expect(find.text(Strings.dueToday), findsNothing);
      // The next item in Errands has no due date, so no label.
      expect(find.text('Buy curtains'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      expect(find.text(Strings.dueToday), findsOneWidget);
      // Lets the snackbar and highlight expire.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testSahai('AT-131 an Explorer row shows its due date, bold once overdue, '
        'and none once DONE until it is reopened', (tester) async {
      final app = await errands();
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      expect(weightOf(tester, 'Stream item · 3 days overdue'), FontWeight.bold);
      expect(
        weightOf(tester, 'Stream item · due today'),
        isNot(FontWeight.bold),
      );
      expect(
        find.text('Stream item · due today', findRichText: true),
        findsOneWidget,
      );
      // Buy curtains has no due date.
      expect(rendered((t) => t == 'Stream item'), findsOneWidget);

      await tester.tap(
        find.byTooltip(Strings.markDoneTooltip('Call the bank')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Stream item · due today', findRichText: true),
        findsNothing,
      );
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      expect(
        find.text('Stream item · due today', findRichText: true),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testSahai('a project, a locked task and a due date next year in the '
        'Explorer (frame 24, #85)', (tester) async {
      final app = await sample();
      final tree = await app.actions.loadTree();
      String id(String title) =>
          tree.nodes.singleWhere((n) => n.title == title).id;
      await app.actions.setDueDate(
        id('Website relaunch'),
        DateTime(2026, 12, 1),
      );
      final launch = await app.actions.create(
        type: NodeType.task,
        parentId: id('Website relaunch'),
        title: 'Launch',
        dueOn: DateTime(2027, 1, 5),
      );
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      expect(
        rendered((t) => t.startsWith('Project') && t.endsWith(' · due Dec 1')),
        findsOneWidget,
      );
      final locked = find.ancestor(
        of: find.textContaining('due Jan 5, 2027', findRichText: true),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(
          of: locked.first,
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect((await app.actions.loadTree())[launch]!.dueOn, isNotNull);
    });
  });

  group('reminders', () {
    /// Biztras › Website relaunch: 1. Write the copy and 2. Send proposal to
    /// Acme, due Fri, Nov 20, with Remind me [reminder].
    Future<(TestApp, String)> acme(
      DateTime at, {
      DueReminder reminder = DueReminder.onTheDay,
    }) async {
      final app = await sample();
      final website = (await app.actions.loadTree()).nodes
          .singleWhere((n) => n.title == 'Website relaunch')
          .id;
      app.clock.now = DateTime(2026, 11, 9, 10);
      final id = await app.actions.create(
        type: NodeType.task,
        parentId: website,
        title: 'Send proposal to Acme',
        dueOn: DateTime(2026, 11, 20),
        dueReminder: reminder,
      );
      app.clock.now = at;
      return (app, id);
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    }

    testSahai('AT-130 an early reminder and the one on the day are '
        'scheduled; marking done cancels both, and Undo brings them back', (
      tester,
    ) async {
      final (app, id) = await acme(
        monday,
        reminder: DueReminder.threeDaysBefore,
      );
      await pumpSahai(tester, app: app);
      expect(app.reminders.scheduled.map((m) => (m.title, m.at)), [
        (
          '2. Send proposal to Acme is due Fri, Nov 20',
          DateTime(2026, 11, 17, 9).toUtc(),
        ),
        (
          '2. Send proposal to Acme is due today',
          DateTime(2026, 11, 20, 9).toUtc(),
        ),
      ]);

      await app.actions.markDone(
        (await app.actions.loadTree()).nodes
            .singleWhere((n) => n.title == 'Write the copy')
            .id,
      );
      final token = await app.actions.markDone(id);
      await tester.pumpAndSettle();
      expect(app.reminders.scheduled, isEmpty);
      await app.actions.undoComplete(token);
      await tester.pumpAndSettle();
      expect(app.reminders.scheduled, hasLength(2));
    });

    testSahai('AT-129 a tap inside a set-aside area opens a sheet that says '
        'why, with Mark done, Change due date and Open in tree', (
      tester,
    ) async {
      final (app, id) = await acme(DateTime(2026, 11, 20, 9));
      final tree = await app.actions.loadTree();
      final biztras = tree.nodes.singleWhere((n) => n.title == 'Biztras').id;
      await app.actions.markDone(
        tree.nodes.singleWhere((n) => n.title == 'Write the copy').id,
      );
      await app.actions.setAside(biztras, DateTime(2026, 11, 23, 8));
      await pumpSahai(tester, app: app);
      expect(find.text('2. Send proposal to Acme'), findsNothing);

      app.reminders.tap(id);
      await tester.pumpAndSettle();
      expect(find.text('2. Send proposal to Acme'), findsOneWidget);
      expect(find.text(Strings.dueToday), findsOneWidget);
      expect(
        find.text(Strings.notOnSummary('Biztras', 'Mon, Nov 23')),
        findsOneWidget,
      );
      expect(find.text(Strings.markDone), findsOneWidget);
      expect(find.text(Strings.changeDueDate), findsOneWidget);
      expect(find.text(Strings.openInTree), findsOneWidget);
      expect(find.text(Strings.setAsideTitle), findsNothing);
      expect(find.text(Strings.skipOccurrence), findsNothing);

      await choose(tester, Strings.markDone);
      expect((await app.actions.loadTree())[id]!.isDone, isTrue);
      await settle(tester);
    });

    testSahai('a locked task waiting behind an earlier step says so, with no '
        'Mark done (E-007)', (tester) async {
      final (app, id) = await acme(DateTime(2026, 11, 20, 9));
      await pumpSahai(tester, app: app);
      app.reminders.tap(id);
      await tester.pumpAndSettle();
      expect(find.text(Strings.waitsForEarlier), findsOneWidget);
      expect(find.text(Strings.markDone), findsNothing);
      expect(find.text(Strings.changeDueDate), findsOneWidget);
      expect(find.text(Strings.openInTree), findsOneWidget);

      // Change due date opens the edit form at the due date.
      await choose(tester, Strings.changeDueDate);
      expect(find.text('Fri, Nov 20'), findsOneWidget);
      expect(find.text(Strings.addDueDate), findsNothing);
      await tester.tap(find.byTooltip(Strings.close));
      await tester.pumpAndSettle();
    });
  });
}
