import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/features/explorer/explorer_screen.dart';
import 'package:sahai/shared/strings.dart';

import '../../helpers.dart';
import '../../widget_helpers.dart';

/// Starts the app on the Summary with the frame 3 example tree.
Future<(TestApp, SampleTree)> pumpSample(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  final app = TestApp();
  final sample = await SampleTree.create(app);
  await pumpSahai(tester, app: app, textScale: textScale);
  return (app, sample);
}

Finder checkmark(String title) =>
    find.byTooltip(Strings.markDoneTooltip(title));

Future<void> complete(WidgetTester tester, String title) async {
  await tester.tap(checkmark(title));
  await tester.pumpAndSettle();
}

/// Lets a 5-second snackbar and the 3-second highlight expire.
Future<void> settleTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  testSahai('an empty Summary explains itself and opens the Explorer', (
    tester,
  ) async {
    await pumpSahai(tester);
    expect(find.text(Strings.summaryEmptyTitle), findsOneWidget);
    await tester.tap(find.text(Strings.openExplorer));
    await tester.pumpAndSettle();
    expect(find.text(Strings.emptyTitle), findsOneWidget);
  });

  testSahai('AT-013 only the first subtask shows, AT-021 never a domain or '
      'stream, AT-022 one stream item', (tester) async {
    await pumpSample(tester);
    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Draft pricing page'), findsNothing);
    expect(find.text('SUBTASK'), findsOneWidget);
    expect(
      find.text('Biztras › Website relaunch › 1. Write copy'),
      findsOneWidget,
    );
    expect(find.text('Biztras'), findsNothing);
    expect(find.text('Client admin'), findsNothing);
    expect(find.text('Send invoice'), findsOneWidget);
    expect(find.text('STREAM ITEM'), findsOneWidget);
    expect(find.text('Renew domain name'), findsNothing);
  });

  testSahai('AT-014 a task with no subtasks shows directly', (tester) async {
    final app = TestApp();
    final d = await app.actions.create(type: NodeType.domain, title: 'D');
    final p = await app.actions.create(
      type: NodeType.project,
      parentId: d,
      title: 'Portfolio',
    );
    await app.actions.create(type: NodeType.task, parentId: p, title: 'Plan');
    await app.actions.create(type: NodeType.task, parentId: p, title: 'Build');
    await pumpSahai(tester, app: app);
    expect(find.text('1. Plan'), findsOneWidget);
    expect(find.text('TASK'), findsOneWidget);
    expect(find.text('2. Build'), findsNothing);
  });

  testSahai('AT-015 the next subtask takes the place of a done one', (
    tester,
  ) async {
    await pumpSample(tester);
    await complete(tester, 'Draft homepage');
    expect(find.text('Draft homepage'), findsNothing);
    expect(find.text('Draft pricing page'), findsOneWidget);
    expect(find.text(Strings.doneSnack('Draft homepage')), findsOneWidget);
    await settleTimers(tester);
  });

  testSahai('AT-016 the task shows for sign-off and says what it unlocks', (
    tester,
  ) async {
    final (app, sample) = await pumpSample(tester);
    await complete(tester, 'Draft homepage');
    await complete(tester, 'Draft pricing page');
    expect(find.text('1. Write copy'), findsOneWidget);
    expect(find.text('TASK'), findsOneWidget);
    expect(
      find.text('All 2 subtasks done · Mark done to unlock 2. Design pages'),
      findsOneWidget,
    );
    expect((await app.actions.loadTree())[sample.tasks[0]]!.isTodo, isTrue);
    await settleTimers(tester);
  });

  testSahai('AT-017 the next task unlocks after sign-off', (tester) async {
    await pumpSample(tester);
    await complete(tester, 'Draft homepage');
    await complete(tester, 'Draft pricing page');
    await complete(tester, '1. Write copy');
    expect(find.text('2. Design pages'), findsOneWidget);
    expect(find.text('3. Launch'), findsNothing);
    await settleTimers(tester);
  });

  testSahai('AT-019 an empty project prompts for its first task', (
    tester,
  ) async {
    final app = TestApp();
    final d = await app.actions.create(
      type: NodeType.domain,
      title: 'Freelance',
    );
    await app.actions.create(
      type: NodeType.project,
      parentId: d,
      title: 'Portfolio site',
    );
    await pumpSahai(tester, app: app);
    expect(find.text('Portfolio site'), findsOneWidget);
    expect(find.text('PROJECT'), findsOneWidget);
    expect(find.text(Strings.noTasksYet), findsOneWidget);

    await tester.tap(find.text(Strings.addATask));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget);
    expect(find.text('In Portfolio site'), findsOneWidget);
    await fillForm(tester, 'Pick a template');
    expect(find.text('1. Pick a template'), findsOneWidget);
    expect(find.text(Strings.noTasksYet), findsNothing);
  });

  testSahai('AT-020 a finished project shows for sign-off, then nothing', (
    tester,
  ) async {
    await pumpSample(tester);
    for (final title in [
      'Draft homepage',
      'Draft pricing page',
      '1. Write copy',
      '2. Design pages',
      '3. Launch',
    ]) {
      await complete(tester, title);
    }
    expect(find.text('Website relaunch'), findsOneWidget);
    expect(find.text('All 3 tasks done'), findsOneWidget);
    await complete(tester, 'Website relaunch');
    expect(find.text('Website relaunch'), findsNothing);
    expect(find.text('Send invoice'), findsOneWidget);
    await settleTimers(tester);
  });

  testSahai('AT-025 Undo brings the card back and hides the next', (
    tester,
  ) async {
    final (app, sample) = await pumpSample(tester);
    await complete(tester, 'Draft homepage');
    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Draft pricing page'), findsNothing);
    expect((await app.actions.loadTree())[sample.subtasks[0]]!.isTodo, isTrue);
    await settleTimers(tester);
  });

  testSahai('AT-026 the Undo window closes after 5 seconds', (tester) async {
    final (app, sample) = await pumpSample(tester);
    await complete(tester, 'Draft homepage');
    expect(find.text(Strings.undo), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(Strings.undo), findsNothing);
    expect((await app.actions.loadTree())[sample.subtasks[0]]!.isDone, isTrue);
    expect(find.text('Draft pricing page'), findsOneWidget);
  });

  testSahai('AT-027 reopening in the Explorer brings the card back', (
    tester,
  ) async {
    await pumpSample(tester);
    await complete(tester, 'Draft homepage');
    await complete(tester, 'Draft pricing page');
    await complete(tester, '1. Write copy');
    await settleTimers(tester);
    expect(find.text('2. Design pages'), findsOneWidget);

    await goToTab(tester, Strings.explorer);
    await expandAll(tester);
    await openActions(tester, 'Draft pricing page');
    expect(find.text(Strings.alsoReopens(['1. Write copy'])), findsOneWidget);
    await choose(tester, Strings.reopen);

    await goToTab(tester, Strings.summary);
    expect(find.text('Draft pricing page'), findsOneWidget);
    expect(find.text('2. Design pages'), findsNothing);
  });

  testSahai('AT-029 tapping a card shows its path, and Open in tree lands '
      'on the item', (tester) async {
    await pumpSample(tester);
    await tester.tap(find.text('Draft homepage'));
    await tester.pumpAndSettle();
    for (final chip in ['Biztras', 'Website relaunch', '1. Write copy']) {
      expect(find.widgetWithText(Chip, chip), findsOneWidget);
    }
    expect(find.text(Strings.markDone), findsOneWidget);

    await tester.tap(find.text(Strings.openInTree));
    await tester.pumpAndSettle();
    // The Explorer, with the ancestors open and the row highlighted.
    expect(find.text(Strings.explorer), findsWidgets);
    expect(find.text('1. Write copy'), findsOneWidget);
    final row = find.ancestor(
      of: find.text('Draft homepage'),
      matching: find.byType(AnimatedContainer),
    );
    expect(row, findsOneWidget);
    final scheme = Theme.of(tester.element(row)).colorScheme;
    Color? rowColor() =>
        (tester.widget<AnimatedContainer>(row).decoration as BoxDecoration?)
            ?.color;
    expect(rowColor(), scheme.primaryContainer);

    await tester.pump(highlightDuration + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(rowColor(), Colors.transparent);
  });

  testSahai('Mark done from the card sheet also offers Undo', (tester) async {
    await pumpSample(tester);
    await tester.tap(find.text('Send invoice'));
    await tester.pumpAndSettle();
    await choose(tester, Strings.markDone);
    expect(find.text('Renew domain name'), findsOneWidget);
    expect(find.text(Strings.doneSnack('Send invoice')), findsOneWidget);
    await settleTimers(tester);
  });

  testSahai('the Summary works at twice the text size', (tester) async {
    await pumpSample(tester, textScale: 2);
    expect(find.text('Draft homepage'), findsOneWidget);
    await tester.tap(find.text('Draft homepage'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.openInTree), findsOneWidget);
  });

  testSahai('every Summary button has a label for TalkBack', (tester) async {
    await pumpSample(tester);
    for (final element in find.byType(IconButton).evaluate()) {
      final button = element.widget as IconButton;
      expect(button.tooltip, isNotNull, reason: '${button.icon}');
    }
  });
}
