import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/time.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// The new M7 screens for TalkBack and large text (PRD 13): every button
/// has a label, tap targets are at least 48 dp, and at the largest font
/// nothing is cut off (M7 frame 18). A layout overflow fails the test on
/// its own. Local time, as on the phone: Tuesday, Nov 3, 3:00 PM.
void main() {
  TestApp newApp() => TestApp(clock: TestClock(DateTime(2026, 11, 3, 15)));

  /// The largest font Android offers is 200%.
  const largest = 2.0;

  Future<void> checkGuidelines(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }

  Future<void> scrollThrough(WidgetTester tester) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 20; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  testSahai('AT-117 Settings at the largest font puts values below their '
      'labels and cuts nothing off', (tester) async {
    final app = newApp();
    await SampleTree.create(app);
    await pumpSahai(tester, app: app, textScale: largest);
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    // The value is on its own line, not at the end of the row.
    final value = find.text('4:00 AM');
    final label = find.text(Strings.dayStartsAt);
    expect(
      tester.getTopLeft(value).dy,
      greaterThan(tester.getBottomLeft(label).dy),
    );
    await checkGuidelines(tester);
    await scrollThrough(tester);
    expect(find.text(Strings.sendFeedback), findsOneWidget);
  });

  testSahai('the presets screen, Day starts at and About work at the '
      'largest font', (tester) async {
    final app = newApp();
    await SampleTree.create(app);
    await pumpSahai(tester, app: app, textScale: largest);
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.setAsidePresets));
    await tester.pumpAndSettle();
    await checkGuidelines(tester);
    await tester.scrollUntilVisible(
      find.text(Strings.resetToDefaults),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(Strings.presetName(Preset.nextWeek)), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(Strings.dayStartsAt));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('6:00 AM'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(Strings.aboutSahai),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(Strings.aboutSahai));
    await tester.pumpAndSettle();
    await checkGuidelines(tester);
    await scrollThrough(tester);
    expect(find.text(Strings.licences), findsOneWidget);
  });

  testSahai('onboarding works through to the end at the largest font, with '
      'labelled buttons', (tester) async {
    await pumpSahai(
      tester,
      app: newApp(),
      onboarded: false,
      textScale: largest,
    );
    await checkGuidelines(tester);
    Future<void> tapText(String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    Future<void> type(String label, String text) async {
      await tester.enterText(find.widgetWithText(TextField, label), text);
      await tester.pump();
    }

    await tapText(Strings.getStarted);
    await type(Strings.firstArea, 'Biztras');
    await type(Strings.secondArea, 'Personal');
    await checkGuidelines(tester);
    await tapText(Strings.next);
    await type(Strings.projectLabel, 'Website relaunch');
    await type(Strings.firstTaskLabel, 'Write the copy');
    await checkGuidelines(tester);
    await tapText(Strings.next);
    await type(Strings.subtaskLabel(1), 'Draft homepage');
    await type(Strings.subtaskLabel(2), 'Draft pricing page');
    await tapText(Strings.next);
    await checkGuidelines(tester);
    await tapText(Strings.tryIt);
    expect(find.text(Strings.practiceBanner), findsOneWidget);
    await checkGuidelines(tester);
    await tapText(Strings.skip);
    expect(find.text('Draft homepage'), findsOneWidget);
  });
}
