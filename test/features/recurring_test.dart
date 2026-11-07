import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Recurring items on the screens (PRD 7, 8.2 to 8.4; M4 frames 1 to 9 and
/// 11). Local time, as on the phone: Monday, Nov 9, 2026, at 10:00 AM, as in
/// the frames.
void main() {
  TestApp newApp([DateTime? at]) =>
      TestApp(clock: TestClock(at ?? DateTime(2026, 11, 9, 10)));

  /// Personal › Finance & Bills, with HDFC monthly on the 5th.
  Future<({String personal, String finance, String hdfc})> addBill(
    TestApp app, {
    DateTime? dueOn,
  }) async {
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
      dueOn: dueOn ?? DateTime(2026, 11, 5),
      leadDays: 3,
    );
    return (personal: personal, finance: finance, hdfc: hdfc);
  }

  Future<List<String>> eventTypes(TestApp app) async {
    final rows = await (app.db.select(
      app.db.events,
    )..orderBy([(e) => OrderingTerm.asc(e.occurredAt)])).get();
    return [for (final r in rows) r.eventType];
  }

  /// Lets a 5-second snackbar go.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  Future<void> openCard(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<void> openNewItemForm(WidgetTester tester) async {
    await expandAll(tester);
    await openActions(tester, 'Finance & Bills');
    await choose(tester, Strings.addChild([NodeType.streamItem]));
  }

  Future<void> turnRepeatOn(WidgetTester tester) async {
    await tapInView(tester, find.text(Strings.repeat));
  }

  Future<void> pickFrom<T>(
    WidgetTester tester,
    String label,
    String choice,
  ) async {
    await tapInView(
      tester,
      find.ancestor(
        of: find.text(label),
        matching: find.byType(DropdownButtonFormField<T>),
      ),
    );
    await tester.tap(find.text(choice).last);
    await tester.pumpAndSettle();
  }

  group('form (frames 2 to 4)', () {
    testSahai('Repeat is offered on stream items only', (tester) async {
      final app = newApp();
      final bill = await addBill(app);
      final project = await app.actions.create(
        type: NodeType.project,
        parentId: bill.personal,
        title: 'Move house',
      );
      await app.actions.create(
        type: NodeType.task,
        parentId: project,
        title: 'Pack',
      );
      await pumpExplorer(tester, app: app);
      await openNewItemForm(tester);
      expect(find.text(Strings.repeat), findsOneWidget);
      expect(find.text(Strings.repeatHint), findsOneWidget);
      await tester.tap(find.byTooltip(Strings.close));
      await tester.pumpAndSettle();
      await openActions(tester, '1. Pack');
      await choose(tester, Strings.edit);
      expect(find.text(Strings.repeat), findsNothing);
    });

    testSahai('a monthly bill fills in its next date and when it appears, and '
        'never shows as a normal item first', (tester) async {
      final app = newApp();
      final bill = await addBill(app);
      await pumpExplorer(tester, app: app);
      final before = await eventTypes(app);
      await openNewItemForm(tester);
      await turnRepeatOn(tester);
      await pickFrom<int>(tester, Strings.onDay, '5');
      // The 5th has passed this month, so the next one is in December.
      expect(find.text('Sat, Dec 5'), findsOneWidget);
      expect(find.text(Strings.appears('Wed, Dec 2')), findsOneWidget);
      await fillForm(tester, 'Pay Axis card');

      final tree = await app.actions.loadTree();
      final axis = tree
          .childrenOf(bill.finance)
          .firstWhere((n) => n.title == 'Pay Axis card');
      expect(axis.schedule!.toJson(), Schedule.monthly(day: 5).toJson());
      expect(axis.dueOn, DateTime(2026, 12, 5));
      expect(axis.leadDays, 3);
      expect((await eventTypes(app)).skip(before.length), [EventTypes.created]);
    });

    testSahai('weekly shows weekday buttons and follows them', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app);
      await openNewItemForm(tester);
      await turnRepeatOn(tester);
      await pickFrom<Frequency>(
        tester,
        Strings.periodName(Frequency.monthly, interval: 1),
        Strings.periodName(Frequency.weekly, interval: 1),
      );
      await tapInView(tester, find.text('Th'));
      expect(find.text('Thu, Nov 12'), findsOneWidget);
      await tapInView(tester, find.text('Tu'));
      expect(find.text('Tue, Nov 10'), findsOneWidget);
      expect(find.text(Strings.onDay), findsNothing);
    });

    testSahai('yearly asks for the month and day (owner decision 5)', (
      tester,
    ) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app);
      await openNewItemForm(tester);
      await turnRepeatOn(tester);
      await pickFrom<Frequency>(
        tester,
        Strings.periodName(Frequency.monthly, interval: 1),
        Strings.periodName(Frequency.yearly, interval: 1),
      );
      await pickFrom<int>(tester, Strings.inMonth, 'December');
      expect(find.text('Wed, Dec 9'), findsOneWidget);
    });

    testSahai('daily has no day field (owner decision 5), and a bad number '
        'blocks Save', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app);
      await openNewItemForm(tester);
      await tester.enterText(
        find.widgetWithText(TextField, Strings.titleLabel),
        'Water the plants',
      );
      await turnRepeatOn(tester);
      await pickFrom<Frequency>(
        tester,
        Strings.periodName(Frequency.monthly, interval: 1),
        Strings.periodName(Frequency.daily, interval: 1),
      );
      expect(find.text(Strings.onDay), findsNothing);
      expect(find.text(Strings.onWeekdays), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, Strings.every),
        '0',
      );
      await tester.pump();
      expect(find.text(Strings.everyError), findsOneWidget);
      final save = find.widgetWithText(FilledButton, Strings.save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });

    testSahai('a date the user picked stays when the schedule changes', (
      tester,
    ) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app);
      await openNewItemForm(tester);
      await turnRepeatOn(tester);
      await tapInView(tester, find.text(Strings.nextDue));
      await tester.tap(find.text('20'));
      await tester.tap(find.text(Strings.ok.toUpperCase()).hitTestable().last);
      await tester.pumpAndSettle();
      expect(find.text('Fri, Nov 20'), findsOneWidget);
      await pickFrom<int>(tester, Strings.onDay, '5');
      expect(find.text('Fri, Nov 20'), findsOneWidget);
    });

    testSahai('editing the title leaves this occurrence alone', (tester) async {
      final app = newApp();
      final bill = await addBill(app, dueOn: DateTime(2026, 12, 5));
      // Wake now keeps it on the Summary until the occurrence ends (E-005).
      await app.actions.wakeNow(bill.hdfc);
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      await openActions(tester, 'Pay HDFC card');
      await choose(tester, Strings.edit);
      expect(find.text('Sat, Dec 5'), findsOneWidget);
      await fillForm(tester, 'Pay HDFC');
      final node = (await app.actions.loadTree())[bill.hdfc]!;
      expect(node.title, 'Pay HDFC');
      expect(node.snoozeOverridesShow, isTrue);
    });

    testSahai('turning Repeat off is Stop repeating, with Undo', (
      tester,
    ) async {
      final app = newApp();
      final bill = await addBill(app);
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      await openActions(tester, 'Pay HDFC card');
      await choose(tester, Strings.edit);
      await tapInView(tester, find.text(Strings.repeat));
      await tester.tap(find.text(Strings.save));
      await tester.pumpAndSettle();
      expect(find.text(Strings.noLongerRepeats('Pay HDFC card')), findsWidgets);
      expect((await app.actions.loadTree())[bill.hdfc]!.isRecurring, isFalse);
      await tester.tap(find.text(Strings.undo).last);
      await tester.pumpAndSettle();
      expect((await app.actions.loadTree())[bill.hdfc]!.isRecurring, isTrue);
      await settle(tester);
    });
  });

  group('Summary (frames 1, 5, 6, 9)', () {
    testSahai('AT-062 the card reads Due today until the next day start', (
      tester,
    ) async {
      final app = newApp(DateTime(2026, 11, 5, 10));
      await addBill(app);
      await pumpSahai(tester, app: app);
      expect(find.text(Strings.dueToday), findsOneWidget);
    });

    testSahai('AT-062 still Due today at 3:59 AM the next night', (
      tester,
    ) async {
      final app = newApp(DateTime(2026, 11, 6, 3, 59));
      await addBill(app);
      await pumpSahai(tester, app: app);
      expect(find.text(Strings.dueToday), findsOneWidget);
    });

    testSahai('AT-063 overdue counts logical days, in bold', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpSahai(tester, app: app);
      final label = tester.widget<Text>(find.text('4 days overdue'));
      expect(label.style?.fontWeight, FontWeight.bold);
    });

    testSahai('AT-063 one day overdue at the day start', (tester) async {
      final app = newApp(DateTime(2026, 11, 6, 4));
      await addBill(app);
      await pumpSahai(tester, app: app);
      expect(find.text('1 day overdue'), findsOneWidget);
    });

    testSahai('a bill before its due date gives the date, not in bold', (
      tester,
    ) async {
      final app = newApp(DateTime(2026, 11, 3, 10));
      await addBill(app);
      await pumpSahai(tester, app: app);
      final label = tester.widget<Text>(find.text('Due Nov 5'));
      expect(label.style?.fontWeight, isNot(FontWeight.bold));
    });

    testSahai('AT-070 Done gives the next date, and Undo brings it back', (
      tester,
    ) async {
      final app = newApp(DateTime(2026, 11, 3, 10));
      final bill = await addBill(app);
      await pumpSahai(tester, app: app);
      await tester.tap(
        find.byTooltip(Strings.markDoneTooltip('Pay HDFC card')),
      );
      await tester.pumpAndSettle();
      expect(find.text(Strings.doneNextDue('Dec 5')), findsOneWidget);
      expect(find.text('Pay HDFC card'), findsNothing);
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      expect(find.text('Pay HDFC card'), findsOneWidget);
      expect(find.text('Due Nov 5'), findsOneWidget);
      final node = (await app.actions.loadTree())[bill.hdfc]!;
      expect(node.dueOn, DateTime(2026, 11, 5));
      expect(await eventTypes(app), contains(EventTypes.completionUndone));
      await settle(tester);
    });

    testSahai('the sheet shows the schedule, Skip with its date, and Stop '
        'repeating', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpSahai(tester, app: app);
      await openCard(tester, 'Pay HDFC card');
      expect(find.text('4 days overdue · due nov 5'), findsOneWidget);
      expect(find.text('Repeats monthly on the 5th'), findsOneWidget);
      expect(find.text(Strings.skipOccurrence), findsOneWidget);
      expect(find.text(Strings.nextDueOn('Dec 5')), findsOneWidget);
      expect(find.text(Strings.stopRepeating), findsOneWidget);
      expect(find.text(Strings.setAsideTitle), findsOneWidget);
      await closeSheet(tester);
    });

    testSahai('a normal card keeps its sheet as it was', (tester) async {
      final app = newApp();
      final sample = await SampleTree.create(app);
      await pumpSahai(tester, app: app);
      expect(sample.items, isNotEmpty);
      await openCard(tester, 'Send invoice');
      expect(find.text(Strings.skipOccurrence), findsNothing);
      expect(find.text(Strings.stopRepeating), findsNothing);
      await closeSheet(tester);
    });

    testSahai('AT-071 Skip moves on without a completion, and Undo puts it '
        'back', (tester) async {
      final app = newApp();
      final bill = await addBill(app);
      await pumpSahai(tester, app: app);
      await openCard(tester, 'Pay HDFC card');
      await choose(tester, Strings.skipOccurrence);
      expect(find.text(Strings.skippedNextDue('Dec 5')), findsOneWidget);
      var node = (await app.actions.loadTree())[bill.hdfc]!;
      expect(node.dueOn, DateTime(2026, 12, 5));
      final types = await eventTypes(app);
      expect(types, contains(EventTypes.skipped));
      expect(types, isNot(contains(EventTypes.completed)));
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      node = (await app.actions.loadTree())[bill.hdfc]!;
      expect(node.dueOn, DateTime(2026, 11, 5));
      expect(await eventTypes(app), contains(EventTypes.skipUndone));
      await settle(tester);
    });

    testSahai('AT-080 Stop repeating drops the due line, and Undo restores '
        'it', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpSahai(tester, app: app);
      await openCard(tester, 'Pay HDFC card');
      await choose(tester, Strings.stopRepeating);
      expect(
        find.text(Strings.noLongerRepeats('Pay HDFC card')),
        findsOneWidget,
      );
      expect(find.text('4 days overdue'), findsNothing);
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      expect(find.text('4 days overdue'), findsOneWidget);
      await settle(tester);
    });

    testSahai('Undo of a set aside leaves the bill on the Summary', (
      tester,
    ) async {
      final app = newApp();
      await addBill(app);
      await pumpSahai(tester, app: app);
      await tester.tap(
        find.byTooltip(Strings.setAsideTooltip('Pay HDFC card')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomorrow morning'));
      await tester.pumpAndSettle();
      expect(find.text('Pay HDFC card'), findsNothing);
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      expect(find.text('Pay HDFC card'), findsOneWidget);
      await settle(tester);
    });
  });

  group('Set-Aside page (frame 7)', () {
    testSahai('E-005 a waiting bill shows its show time and due date, and '
        'Wake now brings it back with its real label', (tester) async {
      final app = newApp();
      final bill = await addBill(app, dueOn: DateTime(2026, 12, 5));
      await pumpSahai(tester, app: app, tab: Strings.setAside);
      expect(find.text('Pay HDFC card'), findsOneWidget);
      expect(find.textContaining('Wed, Dec 2 4:00 AM'), findsOneWidget);
      expect(find.text('Due Dec 5'), findsOneWidget);
      await tester.tap(find.text(Strings.wakeNow));
      await tester.pumpAndSettle();
      expect(find.text('Pay HDFC card'), findsNothing);
      await goToTab(tester, Strings.summary);
      expect(find.text('Due Dec 5'), findsOneWidget);
      final node = (await app.actions.loadTree())[bill.hdfc]!;
      expect(node.dueOn, DateTime(2026, 12, 5));
      expect(node.schedule, isNotNull);
    });
  });

  group('Explorer (frame 8)', () {
    testSahai('AT-077 a completed bill stays TODO with its next date', (
      tester,
    ) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      expect(find.text('Monthly · 4 days overdue'), findsOneWidget);
      await tapInView(
        tester,
        find.byTooltip(Strings.markDoneTooltip('Pay HDFC card')),
      );
      expect(find.text(Strings.doneNextDue('Dec 5')), findsOneWidget);
      expect(find.text('Monthly · due Dec 5 · back Dec 2'), findsOneWidget);
      expect(
        find.byTooltip(Strings.reopenTooltip('Pay HDFC card')),
        findsNothing,
      );
      expect(
        find.byTooltip(Strings.markDoneTooltip('Pay HDFC card')),
        findsOneWidget,
      );
      await settle(tester);
    });

    testSahai('a waiting bill offers Wake now, not Set aside', (tester) async {
      final app = newApp();
      await addBill(app, dueOn: DateTime(2026, 12, 5));
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      await openActions(tester, 'Pay HDFC card');
      expect(find.text(Strings.wakeNow), findsOneWidget);
      expect(find.text(Strings.setAsideMenu), findsNothing);
      await closeSheet(tester);
    });

    testSahai('a bill under a set-aside domain says why it is hidden', (
      tester,
    ) async {
      final app = newApp();
      final bill = await addBill(app);
      await app.actions.setAside(bill.personal, DateTime(2026, 11, 10, 8));
      await pumpExplorer(tester, app: app);
      await expandAll(tester);
      expect(find.text(Strings.hiddenWhile('Personal')), findsNWidgets(2));
    });
  });

  group('reminders (frames 10, 11)', () {
    testSahai('AT-078 a new bill schedules its two reminders', (tester) async {
      final app = newApp(DateTime(2026, 11, 1, 10));
      await addBill(app);
      await pumpSahai(tester, app: app);
      expect(app.reminders.scheduled.map((m) => m.title), [
        'Pay HDFC card is due Nov 5',
        'Pay HDFC card is due today',
      ]);
      expect(app.reminders.scheduled.map((m) => m.at), [
        DateTime(2026, 11, 2, 9).toUtc(),
        DateTime(2026, 11, 5, 9).toUtc(),
      ]);
    });

    testSahai('a tap on a bill on the Summary opens its card', (tester) async {
      final app = newApp();
      final bill = await addBill(app);
      await pumpSahai(tester, app: app);
      app.reminders.tap(bill.hdfc);
      await tester.pumpAndSettle();
      expect(find.text(Strings.skipOccurrence), findsNothing);
      await settle(tester);
    });

    testSahai('AT-079 a tap inside a paused domain opens the item, and it can '
        'be marked done', (tester) async {
      final app = newApp(DateTime(2026, 11, 5, 9));
      final bill = await addBill(app);
      await app.actions.setAside(bill.personal, DateTime(2026, 11, 10, 8));
      await pumpSahai(tester, app: app);
      expect(find.text('Pay HDFC card'), findsNothing);
      app.reminders.tap(bill.hdfc);
      await tester.pumpAndSettle();
      expect(find.text('Pay HDFC card'), findsOneWidget);
      expect(find.text(Strings.dueToday), findsOneWidget);
      expect(
        find.text(Strings.notOnSummary('Personal', 'Tue, Nov 10')),
        findsOneWidget,
      );
      expect(find.text(Strings.setAsideTitle), findsNothing);
      expect(find.text(Strings.stopRepeating), findsNothing);
      await choose(tester, Strings.markDone);
      expect(find.text(Strings.doneNextDue('Dec 5')), findsOneWidget);
      final node = (await app.actions.loadTree())[bill.hdfc]!;
      expect(node.dueOn, DateTime(2026, 12, 5));
      await settle(tester);
    });

    testSahai('a tap on a bill set aside itself says so (owner decision 2)', (
      tester,
    ) async {
      final app = newApp(DateTime(2026, 11, 5, 9));
      final bill = await addBill(app);
      await app.actions.setAside(bill.hdfc, DateTime(2026, 11, 7, 8));
      await pumpSahai(tester, app: app);
      app.reminders.tap(bill.hdfc);
      await tester.pumpAndSettle();
      expect(
        find.text(Strings.notOnSummary('Pay HDFC card', 'Sat, Nov 7')),
        findsOneWidget,
      );
      await closeSheet(tester);
    });

    group('#77 a reminder still undelivered when the app opens', () {
      // The reminder was for 9:00 AM and Android hasn't delivered it yet.
      // Opening the app cancels it along with the rest of the schedule.
      final nineAm = DateTime(2026, 11, 5, 9);
      TestApp lateApp() => newApp(DateTime(2026, 11, 5, 9, 2));

      testSahai('shows at once for a bill the Summary hides, and opens it', (
        tester,
      ) async {
        final app = lateApp();
        final bill = await addBill(app);
        await app.actions.setAside(bill.personal, DateTime(2026, 11, 10, 8));
        app.reminders.undeliveredTimes = [nineAm];
        await pumpSahai(tester, app: app);
        expect(find.text('Pay HDFC card'), findsNothing);
        final shown = app.reminders.shownNow.single;
        expect(shown.title, 'Pay HDFC card is due today');
        expect(shown.nodeId, bill.hdfc);
        app.reminders.tap(shown.nodeId);
        await tester.pumpAndSettle();
        expect(
          find.text(Strings.notOnSummary('Personal', 'Tue, Nov 10')),
          findsOneWidget,
        );
        await closeSheet(tester);
      });

      testSahai('shows only once', (tester) async {
        final app = lateApp();
        final bill = await addBill(app);
        await app.actions.setAside(bill.personal, DateTime(2026, 11, 10, 8));
        app.reminders.undeliveredTimes = [nineAm];
        await pumpSahai(tester, app: app);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(app.reminders.shownNow, hasLength(1));
      });

      testSahai('stays quiet for a bill on the Summary', (tester) async {
        final app = lateApp();
        await addBill(app);
        app.reminders.undeliveredTimes = [nineAm];
        await pumpSahai(tester, app: app);
        expect(find.text('Pay HDFC card'), findsOneWidget);
        expect(app.reminders.replaceCalls, greaterThan(0));
        expect(app.reminders.scheduled, isEmpty);
        expect(app.reminders.shownNow, isEmpty);
      });

      for (final (name, act)
          in <(String, Future<String> Function(TestApp, String))>[
            ('done', (app, id) => app.actions.markDone(id)),
            ('skipped', (app, id) => app.actions.skipOccurrence(id)),
            ('stopped', (app, id) => app.actions.stopRepeating(id)),
          ]) {
        testSahai('stays quiet for a bill already $name', (tester) async {
          final app = lateApp();
          final bill = await addBill(app);
          await app.actions.setAside(bill.personal, DateTime(2026, 11, 10, 8));
          await act(app, bill.hdfc);
          app.reminders.undeliveredTimes = [nineAm];
          await pumpSahai(tester, app: app);
          expect(app.reminders.replaceCalls, greaterThan(0));
          expect(app.reminders.shownNow, isEmpty);
        });
      }
    });
  });

  group('large text', () {
    testSahai('the form fits at twice the text size', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app, textScale: 2);
      await openNewItemForm(tester);
      await turnRepeatOn(tester);
      await pickFrom<Frequency>(
        tester,
        Strings.periodName(Frequency.monthly, interval: 1),
        Strings.periodName(Frequency.weekly, interval: 1),
      );
      expect(tester.takeException(), isNull);
    });

    testSahai('the card and its sheet fit at twice the text size', (
      tester,
    ) async {
      final app = newApp();
      await addBill(app);
      await pumpSahai(tester, app: app, textScale: 2);
      await openCard(tester, 'Pay HDFC card');
      expect(tester.takeException(), isNull);
      await closeSheet(tester);
    });
  });

  group('accessibility', () {
    testSahai('weekday buttons are named and at least 48 dp', (tester) async {
      final app = newApp();
      await addBill(app);
      await pumpExplorer(tester, app: app);
      await openNewItemForm(tester);
      await turnRepeatOn(tester);
      await pickFrom<Frequency>(
        tester,
        Strings.periodName(Frequency.monthly, interval: 1),
        Strings.periodName(Frequency.weekly, interval: 1),
      );
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Thursday'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
