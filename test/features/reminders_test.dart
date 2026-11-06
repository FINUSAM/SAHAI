import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Reminders from the app's side, with the phone's notifications faked:
/// when permission is asked, what gets scheduled, what a tap opens, and
/// the Settings switches (PRD 7, 8.6; M3 frames 7, 13, 14).
///
/// Local time, as on the phone: Tuesday, Nov 3, 3:00 PM.
void main() {
  Future<(TestApp, SampleTree)> pumpAt(WidgetTester tester) async {
    final app = TestApp(clock: TestClock(DateTime(2026, 11, 3, 15)));
    final sample = await SampleTree.create(app);
    await pumpSahai(tester, app: app);
    return (app, sample);
  }

  Future<void> setAside(
    WidgetTester tester,
    String title,
    Preset preset, {
    bool remind = true,
  }) async {
    await tester.tap(find.byTooltip(Strings.setAsideTooltip(title)));
    await tester.pumpAndSettle();
    if (!remind) {
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(Strings.presetName(preset)));
    await tester.pumpAndSettle();
    // Let the snackbar go.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
  }

  testSahai('AT-055 permission is asked at the first set aside, not at '
      'launch', (tester) async {
    final (app, _) = await pumpAt(tester);
    expect(app.reminders.initCalls, 1);
    expect(app.reminders.permissionRequests, 0);
    await setAside(tester, 'Draft homepage', Preset.tomorrowMorning);
    expect(app.reminders.permissionRequests, 1);
    // The item is set aside whatever the answer.
    expect(find.text('Draft homepage'), findsNothing);
  });

  testSahai('AT-051 setting aside schedules a named reminder at the wake '
      'time', (tester) async {
    final (app, sample) = await pumpAt(tester);
    expect(app.reminders.scheduled, isEmpty);
    await setAside(tester, 'Draft homepage', Preset.tomorrowMorning);
    final message = app.reminders.scheduled.single;
    expect(message.title, 'Draft homepage is back');
    expect(message.body, 'Biztras › Website relaunch › 1. Write copy');
    expect(message.at, DateTime(2026, 11, 4, 8).toUtc());
    expect(message.nodeId, sample.subtasks[0]);
    expect(app.reminders.lastExact, isFalse);
  });

  testSahai('AT-053 Remind me off schedules nothing', (tester) async {
    final (app, _) = await pumpAt(tester);
    await setAside(
      tester,
      'Draft homepage',
      Preset.tomorrowMorning,
      remind: false,
    );
    expect(find.text('Draft homepage'), findsNothing);
    expect(app.reminders.scheduled, isEmpty);
  });

  testSahai('Wake now takes the reminder away again', (tester) async {
    final (app, _) = await pumpAt(tester);
    await setAside(tester, 'Send invoice', Preset.nextWeek);
    expect(app.reminders.scheduled, hasLength(1));
    await goToTab(tester, Strings.setAside);
    await tester.tap(find.bySemanticsLabel('Wake Send invoice now'));
    await tester.pumpAndSettle();
    expect(app.reminders.scheduled, isEmpty);
  });

  testSahai('AT-051 tapping a named reminder opens the Summary with the '
      'card highlighted', (tester) async {
    final (app, sample) = await pumpAt(tester);
    await goToTab(tester, Strings.explorer);
    app.reminders.tap(sample.items[0]);
    await tester.pumpAndSettle();
    expect(find.text(Strings.summaryEmptyTitle), findsNothing);
    final card = tester.widget<Card>(
      find.ancestor(of: find.text('Send invoice'), matching: find.byType(Card)),
    );
    final theme = Theme.of(tester.element(find.text('Send invoice')));
    expect(card.color, theme.colorScheme.primaryContainer);

    // The highlight fades.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Card>(
            find.ancestor(
              of: find.text('Send invoice'),
              matching: find.byType(Card),
            ),
          )
          .color,
      isNull,
    );
  });

  testSahai('AT-050 tapping a grouped reminder opens the Summary', (
    tester,
  ) async {
    final (app, _) = await pumpAt(tester);
    await goToTab(tester, Strings.explorer);
    app.reminders.tap(null);
    await tester.pumpAndSettle();
    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Send invoice'), findsOneWidget);
  });

  testSahai('AT-056 turning notifications off clears the schedule and the '
      'prompt', (tester) async {
    final (app, _) = await pumpAt(tester);
    await setAside(tester, 'Draft homepage', Preset.tomorrowMorning);
    expect(app.reminders.scheduled, hasLength(1));

    await openSettings(tester);
    expect(find.text('REMINDERS'), findsOneWidget);
    await tester.tap(find.text(Strings.notifications));
    await tester.pumpAndSettle();
    expect(app.reminders.scheduled, isEmpty);
    // Exact reminders can't be changed while notifications are off.
    final exact = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, Strings.exactReminders),
    );
    expect(exact.onChanged, isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final asked = app.reminders.permissionRequests;
    await setAside(tester, 'Send invoice', Preset.nextWeek);
    expect(app.reminders.permissionRequests, asked);
    expect(app.reminders.scheduled, isEmpty);
    // The item still goes away and will come back on its own.
    expect(find.text('Send invoice'), findsNothing);
  });

  testSahai('AT-058 Exact reminders asks Android and schedules exactly', (
    tester,
  ) async {
    final (app, _) = await pumpAt(tester);
    await setAside(tester, 'Draft homepage', Preset.tomorrowMorning);
    await openSettings(tester);
    await tester.tap(find.text(Strings.exactReminders));
    await tester.pumpAndSettle();
    expect(app.reminders.exactAlarmRequests, 1);
    expect(app.reminders.lastExact, isTrue);
    expect(app.reminders.scheduled, hasLength(1));
  });

  testSahai('Settings fits at twice the text size', (tester) async {
    await pumpAt(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await openSettings(tester);
    expect(tester.takeException(), isNull);
  });
}
