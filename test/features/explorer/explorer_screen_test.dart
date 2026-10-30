import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/shared/strings.dart';

import '../../helpers.dart';
import '../../widget_helpers.dart';

/// Starts the app on the frame 3 example tree, fully expanded.
Future<(TestApp, SampleTree)> pumpSample(
  WidgetTester tester, {
  TestApp? app,
  double textScale = 1,
}) async {
  final testApp = app ?? TestApp();
  final sample = await SampleTree.create(testApp);
  await pumpSahai(tester, app: testApp, textScale: textScale);
  await expandAll(tester);
  return (testApp, sample);
}

Finder lockIcon(String title) => find.byWidgetPredicate(
  (w) => w is Icon && w.semanticLabel == Strings.lockedLabel(title),
);

void main() {
  testSahai('empty Explorer offers to add a domain', (tester) async {
    final app = await pumpSahai(tester);
    expect(find.text(Strings.emptyTitle), findsOneWidget);

    await tester.tap(find.text(Strings.addADomain));
    await tester.pumpAndSettle();
    expect(find.text('New domain'), findsOneWidget);
    await fillForm(tester, 'Biztras');

    expect(find.text('Biztras'), findsOneWidget);
    expect(find.text(Strings.emptyTitle), findsNothing);
    expect((await app.actions.loadTree()).roots.single.title, 'Biztras');
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testSahai('AT-001 create every node type, and they survive a restart', (
    tester,
  ) async {
    final file = tempDatabaseFile();
    final first = await pumpSahai(tester, app: appOnFile(file));

    await tester.tap(find.text(Strings.addADomain));
    await tester.pumpAndSettle();
    await fillForm(tester, 'Biztras');
    // A new item opens with an Add line, so its first child is one tap away.
    await tester.tap(find.text('Add project or stream'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Project'));
    await tester.pumpAndSettle();
    expect(find.text('In Biztras'), findsOneWidget);
    await fillForm(tester, 'Website relaunch');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await fillForm(tester, 'Write copy');
    await openActions(tester, '1. Write copy');
    await choose(tester, 'Add subtask');
    await fillForm(tester, 'Draft homepage');
    await openActions(tester, 'Biztras');
    await choose(tester, 'Add project or stream');
    await tester.tap(find.text('Stream'));
    await tester.pumpAndSettle();
    await fillForm(tester, 'Client admin');
    await tester.tap(find.text('Add stream item'));
    await tester.pumpAndSettle();
    await fillForm(tester, 'Send invoice');

    await closeSahai(tester, first);
    final second = await pumpSahai(tester, app: appOnFile(file));
    await expandAll(tester);
    for (final title in [
      'Biztras',
      'Website relaunch',
      '1. Write copy',
      'Draft homepage',
      'Client admin',
      'Send invoice',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    final tree = await second.actions.loadTree();
    final types = {
      for (final n in tree.descendantsOf(tree.roots.single.id)) n.title: n.type,
    };
    expect(types, {
      'Website relaunch': NodeType.project,
      'Write copy': NodeType.task,
      'Draft homepage': NodeType.subtask,
      'Client admin': NodeType.stream,
      'Send invoice': NodeType.streamItem,
    });
  });

  testSahai('AT-002 only valid child types are offered', (tester) async {
    await pumpSample(tester);

    await openActions(tester, 'Biztras');
    await choose(tester, 'Add project or stream');
    expect(find.text('Add to Biztras'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Stream'), findsOneWidget);
    expect(find.text('Task'), findsNothing);
    await closeSheet(tester);

    final expected = {
      'Website relaunch': 'Add task',
      '1. Write copy': 'Add subtask',
      'Client admin': 'Add stream item',
    };
    for (final MapEntry(key: title, value: add) in expected.entries) {
      await openActions(tester, title);
      expect(find.text(add), findsOneWidget, reason: title);
      await closeSheet(tester);
    }
    for (final title in ['Draft homepage', 'Send invoice']) {
      await openActions(tester, title);
      expect(find.textContaining('Add '), findsNothing, reason: title);
      await closeSheet(tester);
    }
  });

  testSahai('AT-003 domains and streams have no checkmark or Mark done', (
    tester,
  ) async {
    await pumpSample(tester);

    for (final title in ['Biztras', 'Client admin']) {
      expect(find.byTooltip(Strings.markDoneTooltip(title)), findsNothing);
      await openActions(tester, title);
      expect(find.text(Strings.markDone), findsNothing, reason: title);
      await closeSheet(tester);
    }
    expect(
      find.byTooltip(Strings.markDoneTooltip('Send invoice')),
      findsOneWidget,
    );
  });

  testSahai('AT-007 locked tasks show a lock until the task before is done', (
    tester,
  ) async {
    await pumpSample(tester);

    expect(lockIcon('Design pages'), findsOneWidget);
    expect(lockIcon('Launch'), findsOneWidget);
    expect(find.text('Locked until 1 is done'), findsOneWidget);
    expect(find.text('Locked until 2 is done'), findsOneWidget);
    expect(find.text('Current task · 2 subtasks'), findsOneWidget);
    expect(
      find.byTooltip(Strings.markDoneTooltip('Design pages')),
      findsNothing,
    );
    await openActions(tester, '2. Design pages');
    expect(find.text(Strings.markDone), findsNothing);
    await closeSheet(tester);

    for (final title in [
      'Draft homepage',
      'Draft pricing page',
      'Write copy',
    ]) {
      await tester.tap(find.byTooltip(Strings.markDoneTooltip(title)));
      await tester.pumpAndSettle();
    }
    expect(lockIcon('Design pages'), findsNothing);
    expect(
      find.byTooltip(Strings.markDoneTooltip('Design pages')),
      findsOneWidget,
    );
    expect(find.text('Locked until 2 is done'), findsOneWidget);
  });

  testSahai('a refused action explains why', (tester) async {
    await pumpSample(tester);

    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Write copy')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.hasTodoChildren), findsOneWidget);
  });

  testSahai('done items are struck through and can be reopened', (
    tester,
  ) async {
    final (app, sample) = await pumpSample(tester);

    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Send invoice')));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[sample.items[0]]!.isDone, isTrue);
    final text = tester.widget<Text>(find.text('Send invoice'));
    expect(text.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.byTooltip(Strings.reopenTooltip('Send invoice')));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[sample.items[0]]!.isTodo, isTrue);
  });

  testSahai('AT-006 a subtask moves to another task', (tester) async {
    final (app, sample) = await pumpSample(tester);

    await openActions(tester, 'Draft pricing page');
    await choose(tester, 'Move to another task…');
    expect(find.text('Move subtask'), findsOneWidget);
    expect(find.text('Biztras › Website relaunch'), findsOneWidget);
    expect(find.text(Strings.whereItIsNow), findsOneWidget);
    // Only tasks are offered as the new parent.
    expect(find.byType(RadioListTile<String>), findsNWidgets(3));

    await tester.tap(find.text('2. Design pages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.moveHere));
    await tester.pumpAndSettle();

    final tree = await app.actions.loadTree();
    expect(tree.childrenOf(sample.tasks[1]).map((n) => n.title), [
      'Draft pricing page',
    ]);
    expect(find.text('Locked until 1 is done · 1 subtask'), findsOneWidget);
  });

  testSahai('E-008 the Move list warns that a DONE parent will reopen', (
    tester,
  ) async {
    final app = TestApp();
    final sample = await SampleTree.create(app);
    final other = await app.actions.create(
      type: NodeType.project,
      parentId: sample.domain,
      title: 'Freelance site',
    );
    final done = await app.actions.create(
      type: NodeType.task,
      parentId: other,
      title: 'Finished task',
    );
    await app.actions.markDone(done);
    await pumpSahai(tester, app: app);
    await expandAll(tester);

    await openActions(tester, 'Draft pricing page');
    await choose(tester, 'Move to another task…');
    expect(find.text(Strings.reopensIfMovedHere), findsOneWidget);
    await tester.tap(find.text('1. Finished task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.moveHere));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[done]!.isTodo, isTrue);
  });

  testSahai('AT-008 delete removes everything under it, and Undo restores it', (
    tester,
  ) async {
    final (app, sample) = await pumpSample(tester);

    await openActions(tester, 'Website relaunch');
    await choose(tester, Strings.delete);
    expect(
      find.text('Deleted Website relaunch and 5 items under it'),
      findsOneWidget,
    );
    expect(find.text('Website relaunch'), findsNothing);
    expect(find.text('1. Write copy'), findsNothing);
    expect((await app.actions.loadTree())[sample.project], isNull);

    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    final tree = await app.actions.loadTree();
    expect(tree.descendantsOf(sample.project), hasLength(5));
    expect(find.text('Website relaunch'), findsOneWidget);
  });

  testSahai('AT-004 reorder tasks with the arrows, and it survives a restart', (
    tester,
  ) async {
    final file = tempDatabaseFile();
    final (first, sample) = await pumpSample(tester, app: appOnFile(file));

    await openActions(tester, '1. Write copy');
    await choose(tester, 'Reorder tasks');
    await tester.tap(find.byTooltip(Strings.moveUpTooltip('Launch')));
    await tester.pump();
    await tester.tap(find.byTooltip(Strings.moveUpTooltip('Launch')));
    await tester.pump();
    expect(find.text('1. Launch'), findsOneWidget);
    expect(find.text(Strings.currentTask), findsOneWidget);
    await tester.tap(find.text(Strings.doneButton));
    await tester.pumpAndSettle();
    expect(find.text('1. Launch'), findsOneWidget);

    await closeSahai(tester, first);
    final second = await pumpSahai(tester, app: appOnFile(file));
    final tree = await second.actions.loadTree();
    expect(tree.childrenOf(sample.project).map((n) => n.title), [
      'Launch',
      'Write copy',
      'Design pages',
    ]);
    expect(tree.currentTaskOf(sample.project)?.title, 'Launch');
  });

  testSahai('closing the Reorder screen keeps the old order', (tester) async {
    final (app, sample) = await pumpSample(tester);

    await openActions(tester, '1. Write copy');
    await choose(tester, 'Reorder tasks');
    await tester.tap(find.byTooltip(Strings.moveDownTooltip('Write copy')));
    await tester.pump();
    await tester.tap(find.byTooltip(Strings.close));
    await tester.pumpAndSettle();

    final tree = await app.actions.loadTree();
    expect(tree.childrenOf(sample.project).first.title, 'Write copy');
  });

  testSahai('AT-005 reorder subtasks and stream items, and it survives a '
      'restart', (tester) async {
    final file = tempDatabaseFile();
    final (first, sample) = await pumpSample(tester, app: appOnFile(file));

    await openActions(tester, 'Draft homepage');
    await tester.tap(find.text(Strings.moveDown));
    await tester.pumpAndSettle();
    await openActions(tester, 'Send invoice');
    await choose(tester, 'Reorder items');
    await tester.tap(
      find.byTooltip(Strings.moveUpTooltip('Renew domain name')),
    );
    await tester.pump();
    await tester.tap(find.text(Strings.doneButton));
    await tester.pumpAndSettle();

    await closeSahai(tester, first);
    final second = await pumpSahai(tester, app: appOnFile(file));
    final tree = await second.actions.loadTree();
    expect(tree.childrenOf(sample.tasks[0]).map((n) => n.title), [
      'Draft pricing page',
      'Draft homepage',
    ]);
    expect(tree.childrenOf(sample.stream).map((n) => n.title), [
      'Renew domain name',
      'Send invoice',
    ]);
  });

  testSahai('edit changes the title and notes', (tester) async {
    final (app, sample) = await pumpSample(tester);

    await openActions(tester, 'Website relaunch');
    await choose(tester, Strings.edit);
    expect(find.text('Edit project'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Website relaunch'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, Strings.notesLabel),
      'Launch before Diwali',
    );
    await fillForm(tester, 'Website v2');

    expect(find.text('Website v2'), findsOneWidget);
    final node = (await app.actions.loadTree())[sample.project]!;
    expect(node.title, 'Website v2');
    expect(node.notes, 'Launch before Diwali');
  });

  testSahai('Save stays disabled until there is a title', (tester) async {
    await pumpSahai(tester);
    await tester.tap(find.text(Strings.addADomain));
    await tester.pumpAndSettle();

    FilledButton save() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, Strings.save),
    );
    expect(save().onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, Strings.titleLabel),
      '   ',
    );
    await tester.pump();
    expect(save().onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, Strings.titleLabel),
      'Personal',
    );
    await tester.pump();
    expect(save().onPressed, isNotNull);
  });

  testSahai('the tree and its menus work at twice the text size', (
    tester,
  ) async {
    await pumpSample(tester, textScale: 2);
    expect(tester.takeException(), isNull);

    await openActions(tester, '1. Write copy');
    expect(tester.takeException(), isNull);
    expect(find.text(Strings.delete), findsOneWidget);
  });

  testSahai('every button has a label for TalkBack', (tester) async {
    await pumpSample(tester);
    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      expect(button.tooltip, isNotNull, reason: '$button');
    }
  });
}
