import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/settings.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// The full Settings screen (PRD 8.6, M7 frames 10 to 13).
///
/// Local time, as on the phone: Tuesday, Nov 3, 3:00 PM, unless a test
/// says otherwise.
void main() {
  Future<(TestApp, SampleTree)> pumpAt(
    WidgetTester tester, {
    DateTime? now,
    double textScale = 1,
  }) async {
    final app = TestApp(clock: TestClock(now ?? DateTime(2026, 11, 3, 15)));
    final sample = await SampleTree.create(app);
    await pumpSahai(tester, app: app, textScale: textScale);
    return (app, sample);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  /// Types [hour]:[minute] into Android's time picker in typing mode and
  /// keeps its AM or PM as it is.
  /// Types [hour] (0 to 23) and [minute] into the time picker. A phone set
  /// to the 24-hour clock takes the hour as it is; otherwise the picker
  /// takes 1 to 12 and keeps the AM or PM it already shows.
  Future<void> typeTime(WidgetTester tester, int hour, int minute) async {
    final dialog = find.byType(Dialog);
    final fields = find.descendant(
      of: dialog,
      matching: find.byType(TextField),
    );
    final twentyFourHour = MediaQuery.alwaysUse24HourFormatOf(
      tester.element(dialog),
    );
    final hourOfPeriod = hour % 12 == 0 ? 12 : hour % 12;
    await tester.enterText(
      fields.at(0),
      '${twentyFourHour ? hour : hourOfPeriod}',
    );
    await tester.enterText(fields.at(1), minute.toString().padLeft(2, '0'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testSahai('the screen has every section, with the PRD defaults', (
    tester,
  ) async {
    await pumpAt(tester);
    await openSettings(tester);
    for (final section in [
      Strings.setAsideSection,
      Strings.recurringSection,
      Strings.remindersSection,
      Strings.summarySection,
      Strings.backupSection,
      Strings.helpSection,
    ]) {
      await tester.scrollUntilVisible(
        find.text(section.toUpperCase()),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(section.toUpperCase()), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text(Strings.setAsidePresets),
      -100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        'Tonight 8 PM · Tomorrow morning 8 AM · 3 days later 8 AM · '
        'Next week Mon 8 AM',
      ),
      findsOneWidget,
    );
    expect(find.text('4:00 AM'), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('9:00 AM'), findsOneWidget);
  });

  testSahai('AT-109 Tonight changed to 9 PM in Settings is offered at 9 PM', (
    tester,
  ) async {
    final (app, _) = await pumpAt(tester);
    await openSettings(tester);
    await tester.tap(find.text(Strings.setAsidePresets));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.presetName(Preset.tonight)));
    await tester.pumpAndSettle();
    await typeTime(tester, 21, 0);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect((await readSettings(app.db)).presetTimes.tonight, 21 * 60);

    await back(tester);
    await back(tester);
    await tester.tap(find.byTooltip(Strings.setAsideTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    expect(find.text('Today 9:00 PM'), findsOneWidget);
    expect(find.text('Today 8:00 PM'), findsNothing);
  });

  testSahai('Reset to defaults puts back the PRD times', (tester) async {
    final (app, _) = await pumpAt(tester);
    await saveSettings(
      app.db,
      nowMillis: 1,
      presetTimes: const PresetTimes().withTime(Preset.nextWeek, 10 * 60),
    );
    await openSettings(tester);
    await tester.tap(find.text(Strings.setAsidePresets));
    await tester.pumpAndSettle();
    expect(find.text('10:00 AM'), findsOneWidget);
    await tester.tap(find.text(Strings.resetToDefaults));
    await tester.pumpAndSettle();
    expect(find.text('10:00 AM'), findsNothing);
    expect((await readSettings(app.db)).presetTimes, const PresetTimes());
    // Nothing to reset any more.
    final reset = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, Strings.resetToDefaults),
    );
    expect(reset.onPressed, isNull);
  });

  testSahai('AT-110 with Day starts at changed to 3 AM, Tomorrow morning at '
      '3:30 AM is 8 AM the next calendar day', (tester) async {
    final (app, _) = await pumpAt(tester, now: DateTime(2026, 11, 4, 3, 30));
    await openSettings(tester);
    await tester.tap(find.text(Strings.dayStartsAt));
    await tester.pumpAndSettle();
    expect(find.text('4:00 AM (default)'), findsOneWidget);
    expect(find.text('12:00 AM (midnight)'), findsOneWidget);
    await tester.tap(find.text('3:00 AM'));
    await tester.tap(find.text(Strings.ok));
    await tester.pumpAndSettle();
    expect((await readSettings(app.db)).dayStartMinutes, 180);
    expect(find.text('3:00 AM'), findsOneWidget);

    await back(tester);
    await tester.tap(find.byTooltip(Strings.setAsideTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    // Thursday, Nov 5 at 8 AM, not later this morning.
    expect(find.text('Thu 8:00 AM'), findsOneWidget);
  });

  testSahai('Cancel leaves Day starts at as it was', (tester) async {
    final (app, _) = await pumpAt(tester);
    await openSettings(tester);
    await tester.tap(find.text(Strings.dayStartsAt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6:00 AM'));
    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();
    expect((await readSettings(app.db)).dayStartMinutes, 240);
  });

  testSahai('Show before due and Reminder time are saved', (tester) async {
    final (app, _) = await pumpAt(tester);
    await openSettings(tester);
    await tester.tap(find.text(Strings.showBeforeDueSetting));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '5',
    );
    await tester.tap(find.text(Strings.ok));
    await tester.pumpAndSettle();
    expect(find.text('5 days'), findsOneWidget);

    await tester.tap(find.text(Strings.reminderTime));
    await tester.pumpAndSettle();
    await typeTime(tester, 8, 30);
    final settings = await readSettings(app.db);
    expect(settings.defaultLeadDays, 5);
    expect(settings.reminderMinutes, 8 * 60 + 30);
    expect(find.text('8:30 AM'), findsOneWidget);
  });

  testSahai('a new Reminder time reschedules recurring reminders', (
    tester,
  ) async {
    final (app, sample) = await pumpAt(tester);
    // Due Thursday, Nov 5, showing 3 days early: today.
    await app.actions.setRecurrence(
      sample.items[0],
      const Schedule.daily(),
      dueOn: DateTime(2026, 11, 5),
    );
    await tester.pumpAndSettle();
    final before = app.reminders.scheduled.map((m) => m.at).toSet();
    await saveSettings(app.db, nowMillis: 1, reminderMinutes: 8 * 60);
    await tester.pumpAndSettle();
    final after = app.reminders.scheduled.map((m) => m.at.toLocal()).toList();
    expect(after, isNotEmpty);
    expect(after.every((at) => at.hour == 8), isTrue);
    expect(app.reminders.scheduled.map((m) => m.at).toSet(), isNot(before));
  });

  Future<void> showBackup(WidgetTester tester, int bytes) async {
    final app = TestApp(clock: TestClock(DateTime(2026, 11, 3, 15)))
      ..dataSizeBytes = bytes;
    await pumpSahai(tester, app: app);
    await openSettings(tester);
    await tester.scrollUntilVisible(
      find.text(Strings.dataOnPhone),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testSahai('Backup shows the size of the data and what Android does with '
      'it', (tester) async {
    await showBackup(tester, 1468006); // 1.4 MB
    expect(find.text('1.4 MB'), findsOneWidget);
    expect(find.text(Strings.backupExplained), findsOneWidget);
    expect(find.textContaining(Strings.backupWarningTitle), findsNothing);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.07, 0.01));
  });

  testSahai('AT-112 above 20 MB Settings warns that backup may stop', (
    tester,
  ) async {
    await showBackup(tester, 22334669); // 21.3 MB
    expect(find.text('21.3 MB'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining(Strings.backupWarningTitle),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining(Strings.backupWarningTitle), findsOneWidget);
    expect(
      find.textContaining('Old activity is already shrunk'),
      findsOneWidget,
    );
    expect(find.text(Strings.backupExplained), findsNothing);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1);
  });

  testSahai('exactly 20 MB does not warn yet', (tester) async {
    await showBackup(tester, 20 * 1024 * 1024);
    expect(find.text('20.0 MB'), findsOneWidget);
    expect(find.textContaining(Strings.backupWarningTitle), findsNothing);
  });

  Future<void> openHelpRow(WidgetTester tester, String title) async {
    await tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // The whole row, not just its edge, so the tap lands on it.
    await tester.ensureVisible(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  testSahai('About shows the version, where the data lives, what is coming '
      'and the licences', (tester) async {
    await pumpAt(tester);
    await openSettings(tester);
    await tester.scrollUntilVisible(
      find.text(Strings.aboutHint('0.7.0')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await openHelpRow(tester, Strings.aboutSahai);
    expect(find.text('Version 0.7.0'), findsOneWidget);
    expect(find.text(Strings.yourDataBody), findsOneWidget);
    expect(find.text(Strings.comingNext.last), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(Strings.licences),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.licences));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testSahai('AT-120 Send feedback opens an email draft with only the address '
      'and subject', (tester) async {
    final (app, _) = await pumpAt(tester);
    await openSettings(tester);
    await openHelpRow(tester, Strings.sendFeedback);
    expect(app.platform.feedbackDrafts, hasLength(1));
    final draft = app.platform.feedbackDrafts.single;
    expect(draft.address, contains('@'));
    expect(draft.subject, 'Sahai feedback (0.7.0)');
    // Nothing else is sent to the email app: there is no body to fill in.
    expect(find.text(Strings.noEmailApp), findsNothing);
  });

  testSahai('Send feedback says so when there is no email app', (tester) async {
    final (app, _) = await pumpAt(tester);
    app.platform.hasEmailApp = false;
    await openSettings(tester);
    await openHelpRow(tester, Strings.sendFeedback);
    expect(find.text(Strings.noEmailApp), findsOneWidget);
  });
}
