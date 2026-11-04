import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/shared/strings.dart';

import '../../helpers.dart';
import '../../widget_helpers.dart';

/// The M3 screens: the picker from a Summary card, Custom date and time,
/// the Set-Aside page and the Explorer's set-aside marks and menu.
///
/// The clock here is local time, as on the phone, so the labels read the
/// same in any time zone: Tuesday, Nov 3, 3:00 PM unless a test says
/// otherwise.
void main() {
  Future<(TestApp, SampleTree)> pumpAt(
    WidgetTester tester, {
    DateTime? at,
    double textScale = 1,
    Future<void> Function(TestApp app, SampleTree sample)? before,
  }) async {
    final app = TestApp(clock: TestClock(at ?? DateTime(2026, 11, 3, 15)));
    final sample = await SampleTree.create(app);
    if (before != null) await before(app, sample);
    await pumpSahai(tester, app: app, textScale: textScale);
    return (app, sample);
  }

  Future<void> openPicker(WidgetTester tester, String title) async {
    await tester.tap(find.byTooltip(Strings.setAsideTooltip(title)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<List<Map<String, Object?>>> payloads(
    WidgetTester tester,
    TestApp app,
    String type,
  ) async {
    final rows = await tester.runAsync(
      () => (app.db.select(
        app.db.events,
      )..where((e) => e.eventType.equals(type))).get(),
    );
    return [
      for (final r in rows!) jsonDecode(r.payload) as Map<String, Object?>,
    ];
  }

  group('picker', () {
    testSahai('AT-033 setting aside a subtask surfaces the next, with Undo', (
      tester,
    ) async {
      final (app, _) = await pumpAt(tester);
      await openPicker(tester, 'Draft homepage');
      // AT-042: the presets show their real times (frame 2).
      expect(find.text(Strings.setAsideTitle), findsOneWidget);
      expect(find.text('Today 8:00 PM'), findsOneWidget);
      expect(find.text('Wed 8:00 AM'), findsOneWidget);
      expect(find.text('Fri, Nov 6 8:00 AM'), findsOneWidget);
      expect(find.text('Mon, Nov 9 8:00 AM'), findsOneWidget);
      expect(find.text(Strings.remindMe), findsOneWidget);

      await tapText(tester, Strings.presetName(Preset.tomorrowMorning));
      expect(find.text('Draft homepage'), findsNothing);
      expect(find.text('Draft pricing page'), findsOneWidget);
      expect(find.text('Set aside until Wed 8:00 AM'), findsOneWidget);

      await tapText(tester, Strings.undo);
      expect(find.text('Draft homepage'), findsOneWidget);
      expect(find.text('Draft pricing page'), findsNothing);
      final woke = await payloads(tester, app, EventTypes.woke);
      expect(woke.single['cause'], 'wake_now');
      await tester.pump(const Duration(seconds: 6));
    });

    testSahai('the card sheet offers Set aside too', (tester) async {
      await pumpAt(tester);
      await tester.tap(find.text('Draft homepage'));
      await tester.pumpAndSettle();
      await tapText(tester, Strings.setAsideTitle);
      expect(find.text(Strings.whatToSetAside), findsOneWidget);
      expect(find.text(Strings.customDateTime), findsOneWidget);
    });

    testSahai('AT-036 scope options match the card type', (tester) async {
      await pumpAt(tester);
      await openPicker(tester, 'Draft homepage');
      await tapText(tester, 'This subtask');
      for (final text in [
        'Its task',
        '1. Write copy',
        'Its project',
        'Website relaunch',
        'Its domain',
        'Biztras, with everything in it',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(find.text('Its stream'), findsNothing);
      await tapText(tester, 'This subtask');
      await closeSheet(tester);

      await openPicker(tester, 'Send invoice');
      await tapText(tester, 'This stream item');
      expect(find.text('Its stream'), findsWidgets);
      expect(find.text('Its domain'), findsWidgets);
      expect(find.text('Its task'), findsNothing);
    });

    testSahai('AT-038 and AT-059 scope its project, logged with Remind me', (
      tester,
    ) async {
      final (app, sample) = await pumpAt(tester);
      await openPicker(tester, 'Draft homepage');
      await tapText(tester, 'This subtask');
      await tapText(tester, 'Its project');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tapText(tester, Strings.presetName(Preset.tonight));
      expect(find.text('Draft homepage'), findsNothing);
      expect(find.text('Send invoice'), findsOneWidget);
      final logged = (await payloads(tester, app, EventTypes.setAside)).single;
      expect(logged['preset'], 'tonight');
      expect(logged['level'], 'project');
      expect(logged['remind'], false);

      await goToTab(tester, Strings.setAside);
      expect(find.text('Website relaunch'), findsOneWidget);
      expect(find.text('Hides 3 tasks'), findsOneWidget);
      expect(find.text('Draft homepage'), findsNothing);
      // Remind me off: a crossed-out bell instead of the clock.
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(sample.project, isNotEmpty);
    });

    testSahai('AT-044 Tonight is hidden at 11:00 PM', (tester) async {
      await pumpAt(tester, at: DateTime(2026, 11, 3, 23));
      await openPicker(tester, 'Draft homepage');
      expect(find.text(Strings.presetName(Preset.tonight)), findsNothing);
      expect(find.text('Wed 8:00 AM'), findsOneWidget);
    });

    testSahai('AT-043 at 1:30 AM Tomorrow morning is later this morning', (
      tester,
    ) async {
      await pumpAt(tester, at: DateTime(2026, 11, 4, 1, 30));
      await openPicker(tester, 'Draft homepage');
      expect(find.text(Strings.presetName(Preset.tonight)), findsNothing);
      expect(find.text('Today 8:00 AM'), findsOneWidget);
    });

    testSahai('AT-045 the custom time step refuses a past time', (
      tester,
    ) async {
      await pumpAt(tester);
      await openPicker(tester, 'Draft homepage');
      await tapText(tester, Strings.customDateTime);
      // Android's date picker opens on today; earlier days are greyed.
      await tapText(tester, Strings.ok);
      expect(find.text('Tue, Nov 3 · Enter time'), findsOneWidget);

      Finder ok() => find.widgetWithText(TextButton, Strings.ok);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '02');
      await tester.enterText(fields.at(1), '30');
      await tester.pumpAndSettle();
      expect(find.text('Pick a time after 3:00 PM'), findsOneWidget);
      expect(tester.widget<TextButton>(ok()).onPressed, isNull);

      await tester.enterText(fields.at(0), '05');
      await tester.pumpAndSettle();
      expect(find.text('Pick a time after 3:00 PM'), findsNothing);
      await tester.tap(ok());
      await tester.pumpAndSettle();
      expect(find.text('Set aside until today 5:30 PM'), findsOneWidget);
      expect(find.text('Draft pricing page'), findsOneWidget);
    });

    testSahai('the custom time step says when the time is not a time', (
      tester,
    ) async {
      await pumpAt(tester);
      await openPicker(tester, 'Draft homepage');
      await tapText(tester, Strings.customDateTime);
      await tapText(tester, Strings.ok);
      await tester.enterText(find.byType(TextField).at(1), '75');
      await tester.pumpAndSettle();
      expect(find.text(Strings.invalidTime), findsOneWidget);
    });

    testSahai('the picker fits at twice the text size', (tester) async {
      await pumpAt(tester, textScale: 2);
      await openPicker(tester, 'Draft homepage');
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.text(Strings.setAsideTitle),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Set-Aside page', () {
    // Draft homepage tonight, 2. Design pages tomorrow, the Client admin
    // stream next week.
    Future<(TestApp, SampleTree)> pumpThree(WidgetTester tester) => pumpAt(
      tester,
      before: (app, s) async {
        await app.actions.setAside(s.subtasks[0], DateTime(2026, 11, 3, 20));
        await app.actions.setAside(s.tasks[1], DateTime(2026, 11, 4, 8));
        await app.actions.setAside(s.stream, DateTime(2026, 11, 9, 8));
      },
    );

    testSahai('AT-046 lists items soonest first with wake time and time '
        'remaining', (tester) async {
      await pumpThree(tester);
      await goToTab(tester, Strings.setAside);
      for (final text in [
        'TODAY',
        'TOMORROW',
        'LATER',
        'Tonight 8:00 PM · in 5 h',
        'Wed 8:00 AM · in 17 h',
        'Mon, Nov 9 8:00 AM · in 5 days',
        'Biztras › Website relaunch › 1. Write copy',
        'Hides 2 items',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      final ys = [
        for (final t in ['Draft homepage', '2. Design pages', 'Client admin'])
          tester.getTopLeft(find.text(t)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(find.text(Strings.wakeNow), findsNWidgets(3));
    });

    testSahai('AT-048 Wake now puts it back on the Summary', (tester) async {
      await pumpThree(tester);
      await goToTab(tester, Strings.setAside);
      await tester.tap(find.bySemanticsLabel('Wake Draft homepage now'));
      await tester.pumpAndSettle();
      expect(find.text('Draft homepage'), findsNothing);
      await goToTab(tester, Strings.summary);
      expect(find.text('Draft homepage'), findsOneWidget);
    });

    testSahai('AT-049 Change time from the sheet', (tester) async {
      await pumpThree(tester);
      await goToTab(tester, Strings.setAside);
      await tester.tap(find.text('Client admin'));
      await tester.pumpAndSettle();
      // Frame 9: what it hides until then.
      expect(find.text(Strings.hiddenUntilThen), findsOneWidget);
      expect(find.text('Send invoice'), findsOneWidget);
      expect(find.text('Renew domain name'), findsOneWidget);
      await tapText(tester, Strings.changeTime);
      expect(find.text(Strings.whatToSetAside), findsNothing);
      expect(find.text(Strings.remindMe), findsNothing);
      await tapText(tester, Strings.presetName(Preset.tomorrowMorning));
      expect(find.text('Wed 8:00 AM · in 17 h'), findsNWidgets(2));
      expect(find.text('LATER'), findsNothing);
    });

    testSahai('AT-047 hidden descendants sit under their ancestor', (
      tester,
    ) async {
      await pumpAt(
        tester,
        before: (app, s) async {
          await app.actions.setAside(s.subtasks[0], DateTime(2026, 11, 3, 20));
          await app.actions.setAside(s.project, DateTime(2026, 11, 9, 8));
        },
      );
      await goToTab(tester, Strings.setAside);
      expect(find.text('Website relaunch'), findsOneWidget);
      expect(find.text('Draft homepage'), findsNothing);
      expect(find.text(Strings.wakeNow), findsOneWidget);
    });

    testSahai('Open in tree from the sheet lands in the Explorer', (
      tester,
    ) async {
      await pumpThree(tester);
      await goToTab(tester, Strings.setAside);
      await tester.tap(find.text('Draft homepage'));
      await tester.pumpAndSettle();
      await tapText(tester, Strings.openInTree);
      expect(find.text('Back tonight 8:00 PM'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testSahai('an item leaves the page when its time passes', (tester) async {
      final (app, _) = await pumpThree(tester);
      await goToTab(tester, Strings.setAside);
      app.clock.advance(const Duration(hours: 5, minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('Draft homepage'), findsNothing);
      expect(find.text('Wed 8:00 AM · in 11 h'), findsOneWidget);
    });

    testSahai('the page fits at twice the text size', (tester) async {
      await pumpThree(tester);
      await goToTab(tester, Strings.setAside);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Explorer', () {
    testSahai('AT-041 set aside a stream from the Explorer, then wake it', (
      tester,
    ) async {
      await pumpAt(tester);
      await goToTab(tester, Strings.explorer);
      await expandAll(tester);
      await openActions(tester, 'Client admin');
      await choose(tester, Strings.setAsideMenu);
      // The node is chosen directly: no scope (frame 12).
      expect(find.text(Strings.whatToSetAside), findsNothing);
      await tapText(tester, Strings.presetName(Preset.nextWeek));

      expect(find.text('Back Mon, Nov 9 8:00 AM'), findsOneWidget);
      expect(
        find.text('Hidden while Client admin is set aside'),
        findsNWidgets(2),
      );
      await goToTab(tester, Strings.summary);
      expect(find.text('Send invoice'), findsNothing);

      await goToTab(tester, Strings.explorer);
      await openActions(tester, 'Client admin');
      expect(find.text(Strings.setAsideMenu), findsNothing);
      expect(find.text(Strings.changeSetAsideTime), findsOneWidget);
      await choose(tester, Strings.wakeNow);
      expect(find.text('Back Mon, Nov 9 8:00 AM'), findsNothing);
      await goToTab(tester, Strings.summary);
      expect(find.text('Send invoice'), findsOneWidget);
    });

    testSahai('Change set-aside time from the Explorer', (tester) async {
      await pumpAt(
        tester,
        before: (app, s) =>
            app.actions.setAside(s.stream, DateTime(2026, 11, 9, 8)),
      );
      await goToTab(tester, Strings.explorer);
      await expandAll(tester);
      await openActions(tester, 'Client admin');
      expect(find.textContaining('back Mon, Nov 9 8:00 AM'), findsOneWidget);
      await choose(tester, Strings.changeSetAsideTime);
      await tapText(tester, Strings.presetName(Preset.tomorrowMorning));
      expect(find.text('Back Wed 8:00 AM'), findsOneWidget);
    });
  });
}
