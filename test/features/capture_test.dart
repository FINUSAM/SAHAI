import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/capture_actions.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/shared/strings.dart';
import 'package:sahai/shared/time_format.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

CaptureActions capturesOf(TestApp app) =>
    CaptureActions(app.db, clock: app.clock.clock);

Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet), matching: finder);

Finder inDialog(Finder finder) =>
    find.descendant(of: find.byType(AlertDialog), matching: finder);

Future<void> typeCapture(WidgetTester tester, String text) async {
  await tester.enterText(
    find.widgetWithText(TextField, Strings.captureHint),
    text,
  );
  await tester.pump();
}

Future<void> tapSave(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, Strings.save));
  await tester.pumpAndSettle();
}

/// Opens the menu of the capture showing [text] (frame 5).
/// The row of the capture showing [text]: its text, Create and the menu.
Finder captureRow(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Row)).first;

Future<void> openCaptureMenu(WidgetTester tester, String text) async {
  final row = captureRow(text);
  await tester.tap(
    find.descendant(of: row, matching: find.byTooltip(Strings.captureActions)),
  );
  await tester.pumpAndSettle();
}

/// Taps the Create button on the capture showing [text] (frame 2).
Future<void> tapCreate(WidgetTester tester, String text) async {
  final row = captureRow(text);
  await tester.tap(
    find.descendant(of: row, matching: find.text(Strings.create)),
  );
  await tester.pumpAndSettle();
}

/// Fills in the Create form: what to make, where it goes and the title.
Future<void> fillCreateForm(
  WidgetTester tester, {
  required NodeType type,
  required String place,
  required String title,
}) async {
  await tester.tap(find.widgetWithText(ChoiceChip, Strings.typeName(type)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(Strings.goesIn));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(RadioListTile<String>, place));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, Strings.titleLabel),
    title,
  );
  await tester.pump();
}

/// Saves the Create form and answers Remove this capture? (frame 10).
Future<void> saveAndAnswer(WidgetTester tester, String answer) async {
  await tapSave(tester);
  expect(find.text(Strings.removeCaptureTitle), findsOneWidget);
  await tester.tap(inDialog(find.text(answer)));
  await tester.pumpAndSettle();
}

void main() {
  group('capturing', () {
    testSahai('AT-095 a typed capture goes on top with its date and time', (
      tester,
    ) async {
      final app = TestApp();
      await capturesOf(app).add('older thought');
      app.clock.advance(const Duration(hours: 1));
      await pumpSahai(tester, app: app, tab: Strings.capture);

      final save = find.widgetWithText(FilledButton, Strings.save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await typeCapture(tester, 'Call Rahul abut invoice');
      await tapSave(tester);

      expect(find.text('Call Rahul abut invoice'), findsOneWidget);
      expect(find.text(capturedTime(app.clock.now)), findsOneWidget);
      final newer = tester.getTopLeft(find.text('Call Rahul abut invoice'));
      final older = tester.getTopLeft(find.text('older thought'));
      expect(newer.dy, lessThan(older.dy));
      // The box is empty again, ready for the next thought.
      expect(find.text(Strings.captureHint), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });

    testSahai('Enter starts a new line, and only Save saves', (tester) async {
      final app = await pumpSahai(tester, tab: Strings.capture);

      await typeCapture(tester, 'call Rahul\nbuy milk');
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      await tester.pumpAndSettle();
      expect(await app.db.select(app.db.captures).get(), isEmpty);

      await tapSave(tester);
      expect(find.text('call Rahul\nbuy milk'), findsOneWidget);
    });

    testSahai('the empty Capture tab says what it is for', (tester) async {
      await pumpSahai(tester, tab: Strings.capture);

      expect(find.text(Strings.nothingCaptured), findsOneWidget);
      expect(find.text(Strings.nothingCapturedBody), findsOneWidget);
    });

    testSahai('a long capture shows its first 3 lines in the list, and all '
        'of it in the menu', (tester) async {
      const long = 'call Rahul\nbuy milk\nrenew passport\nbook dentist';
      final app = TestApp();
      await capturesOf(app).add(long);
      await pumpSahai(tester, app: app, tab: Strings.capture);

      final row = tester.widget<Text>(find.text(long));
      expect(row.maxLines, 3);
      expect(row.overflow, TextOverflow.ellipsis);

      await openCaptureMenu(tester, long);
      final full = tester.widget<Text>(inSheet(find.text(long)));
      expect(full.maxLines, isNull);
      expect(inSheet(find.text(Strings.createAnItem)), findsOneWidget);
      expect(inSheet(find.text(Strings.edit)), findsOneWidget);
      expect(inSheet(find.text(Strings.delete)), findsOneWidget);
    });

    testSahai('AT-096 newest captures come first, each with its date and '
        'time', (tester) async {
      final app = TestApp();
      final captures = capturesOf(app);
      final day = DateTime.utc(2026, 11, 15);
      final times = <String, DateTime>{};
      for (final (hour, text) in [(9, '9 AM'), (13, '1 PM'), (18, '6 PM')]) {
        app.clock.now = day.add(Duration(hours: hour));
        times[text] = app.clock.now;
        await captures.add(text);
      }
      await pumpSahai(tester, app: app, tab: Strings.capture);

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('6 PM'), lessThan(top('1 PM')));
      expect(top('1 PM'), lessThan(top('9 AM')));
      for (final MapEntry(:key, :value) in times.entries) {
        expect(find.text(capturedTime(value)), findsOneWidget, reason: key);
      }
    });
  });

  group('AT-097 edit a capture', () {
    testSahai('the corrected text is saved, keeps its time and stays after '
        'restarting the app', (tester) async {
      final file = tempDatabaseFile();
      final first = appOnFile(file);
      await capturesOf(first).add('Call Rahul abut invoice');
      final capturedAt = first.clock.now;
      first.clock.advance(const Duration(hours: 3));
      await pumpSahai(tester, app: first, tab: Strings.capture);

      await openCaptureMenu(tester, 'Call Rahul abut invoice');
      await tester.tap(inSheet(find.text(Strings.edit)));
      await tester.pumpAndSettle();
      expect(find.text(Strings.editCapture), findsOneWidget);
      expect(
        find.text(Strings.editKeepsTime(capturedTime(capturedAt))),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, Strings.capture),
        'Call Rahul about invoice',
      );
      await tester.pump();
      await tapSave(tester);

      expect(find.text('Call Rahul about invoice'), findsOneWidget);
      expect(find.text(capturedTime(capturedAt)), findsOneWidget);

      await closeSahai(tester, first);
      final second = appOnFile(file);
      await pumpSahai(tester, app: second, tab: Strings.capture);
      expect(find.text('Call Rahul about invoice'), findsOneWidget);
      expect(find.text('Call Rahul abut invoice'), findsNothing);
    });
  });

  group('AT-098 delete a capture with Undo', () {
    testSahai('Undo brings it back; deleted again, it is gone once the Undo '
        'window passes', (tester) async {
      final app = TestApp();
      await capturesOf(app).add('Call Rahul');
      await pumpSahai(tester, app: app, tab: Strings.capture);

      Future<void> delete() async {
        await openCaptureMenu(tester, 'Call Rahul');
        await tester.tap(inSheet(find.text(Strings.delete)));
        await tester.pumpAndSettle();
      }

      await delete();
      expect(find.text('Call Rahul'), findsNothing);
      expect(find.text(Strings.captureDeleted), findsOneWidget);
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();
      expect(find.text('Call Rahul'), findsOneWidget);

      await delete();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text(Strings.captureDeleted), findsNothing);
      expect(find.text('Call Rahul'), findsNothing);
      expect(find.text(Strings.nothingCaptured), findsOneWidget);
    });
  });

  group('making items from a capture', () {
    testSahai('AT-101 create a stream item with a group, then Remove', (
      tester,
    ) async {
      final app = TestApp();
      final a = app.actions;
      final personal = await a.create(type: NodeType.domain, title: 'Personal');
      final bills = await a.create(
        type: NodeType.stream,
        parentId: personal,
        title: 'Finance & Bills',
      );
      final errands = await a.createGroup('Errands');
      await capturesOf(app).add('electricity bill due soon');
      await pumpSahai(tester, app: app, tab: Strings.capture);

      await tapCreate(tester, 'electricity bill due soon');
      // The capture is above the form, not copied in.
      expect(find.text(Strings.createItem), findsOneWidget);
      expect(find.text('electricity bill due soon'), findsOneWidget);
      final title = find.widgetWithText(TextField, Strings.titleLabel);
      expect(tester.widget<TextField>(title).controller!.text, isEmpty);
      final save = find.widgetWithText(FilledButton, Strings.save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await fillCreateForm(
        tester,
        type: NodeType.streamItem,
        place: 'Finance & Bills',
        title: 'Pay electricity bill',
      );
      expect(find.text('Personal › Finance & Bills'), findsOneWidget);
      // A stream item can repeat; the Repeat row appears for it.
      expect(find.text(Strings.repeat), findsOneWidget);

      await tester.tap(find.text(Strings.contextGroup));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Errands')).last);
      await tester.pumpAndSettle();

      await saveAndAnswer(tester, Strings.remove);

      expect(find.text('electricity bill due soon'), findsNothing);
      expect(
        find.text(Strings.createdAndRemoved('Pay electricity bill')),
        findsOneWidget,
      );
      final tree = await a.loadTree();
      final item = tree.childrenOf(bills).single;
      expect(item.title, 'Pay electricity bill');
      expect(item.type, NodeType.streamItem);
      expect(item.groupId, errands);
    });

    testSahai('AT-102 create a project, a task and a subtask, removing each '
        'capture', (tester) async {
      final app = TestApp();
      final s = await SampleTree.create(app);
      final captures = capturesOf(app);
      for (final text in ['first capture', 'second capture', 'third capture']) {
        await captures.add(text);
        app.clock.advance(const Duration(minutes: 1));
      }
      await pumpSahai(tester, app: app, tab: Strings.capture);

      for (final (capture, type, place, title) in [
        ('first capture', NodeType.project, 'Biztras', 'Hiring'),
        ('second capture', NodeType.task, 'Website relaunch', 'Test forms'),
        ('third capture', NodeType.subtask, '2. Design pages', 'Pick fonts'),
      ]) {
        await tapCreate(tester, capture);
        await fillCreateForm(tester, type: type, place: place, title: title);
        await saveAndAnswer(tester, Strings.remove);
        expect(find.text(capture), findsNothing, reason: capture);
      }

      final tree = await app.actions.loadTree();
      String parentOf(String title) =>
          tree.nodes.singleWhere((n) => n.title == title).parentId!;
      expect(parentOf('Hiring'), s.domain);
      expect(parentOf('Test forms'), s.project);
      expect(parentOf('Pick fonts'), s.tasks[1]);
      expect(find.text(Strings.nothingCaptured), findsOneWidget);
    });

    testSahai('AT-103 Keep a capture to make another item, then Remove', (
      tester,
    ) async {
      final app = TestApp();
      final s = await SampleTree.create(app);
      await capturesOf(app).add('call Rahul, buy milk');
      await pumpSahai(tester, app: app, tab: Strings.capture);

      await tapCreate(tester, 'call Rahul, buy milk');
      await fillCreateForm(
        tester,
        type: NodeType.streamItem,
        place: 'Client admin',
        title: 'Call Rahul',
      );
      await saveAndAnswer(tester, Strings.keep);
      expect(find.text('call Rahul, buy milk'), findsOneWidget);
      expect(find.text(Strings.createdItem('Call Rahul')), findsOneWidget);
      expect(find.textContaining(Strings.itemsMade(1)), findsOneWidget);

      await tapCreate(tester, 'call Rahul, buy milk');
      expect(
        find.text(
          '${Strings.fromYourCapture}${Strings.separator}${Strings.itemsMade(1)}'
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      await fillCreateForm(
        tester,
        type: NodeType.streamItem,
        place: 'Client admin',
        title: 'Buy milk',
      );
      await saveAndAnswer(tester, Strings.remove);
      expect(find.text('call Rahul, buy milk'), findsNothing);

      final titles = (await app.actions.loadTree())
          .childrenOf(s.stream)
          .map((n) => n.title);
      expect(titles, containsAll(['Call Rahul', 'Buy milk']));
    });

    testSahai('Undo after Remove brings back the capture, not the item', (
      tester,
    ) async {
      final app = TestApp();
      final s = await SampleTree.create(app);
      await capturesOf(app).add('hire a designer');
      await pumpSahai(tester, app: app, tab: Strings.capture);

      await tapCreate(tester, 'hire a designer');
      await fillCreateForm(
        tester,
        type: NodeType.task,
        place: 'Website relaunch',
        title: 'Hire a designer',
      );
      await saveAndAnswer(tester, Strings.remove);
      await tester.tap(find.text(Strings.undo));
      await tester.pumpAndSettle();

      expect(find.text('hire a designer'), findsOneWidget);
      expect(find.textContaining(Strings.itemsMade(1)), findsOneWidget);
      final titles = (await app.actions.loadTree())
          .childrenOf(s.project)
          .map((n) => n.title);
      expect(titles, contains('Hire a designer'));
    });

    testSahai('Goes in lists only places of the right kind, with their path, '
        'and can be searched', (tester) async {
      final app = TestApp();
      await SampleTree.create(app);
      final other = await app.actions.create(
        type: NodeType.domain,
        title: 'Personal',
      );
      await app.actions.create(
        type: NodeType.project,
        parentId: other,
        title: 'Paperwork',
      );
      await capturesOf(app).add('renew passport');
      await pumpSahai(tester, app: app, tab: Strings.capture);
      await tapCreate(tester, 'renew passport');

      // Goes in waits for the type.
      expect(find.text(Strings.chooseTypeFirst), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Task'));
      await tester.pumpAndSettle();
      expect(find.text(Strings.pickA(NodeType.project)), findsOneWidget);
      await tester.tap(find.text(Strings.goesIn));
      await tester.pumpAndSettle();

      final options = find.byType(RadioListTile<String>);
      expect(options, findsNWidgets(2));
      expect(find.text('Website relaunch'), findsOneWidget);
      expect(find.text('Paperwork'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget); // Paperwork's path
      expect(find.text('Client admin'), findsNothing);
      expect(
        find.text(Strings.goesInHint(NodeType.task, NodeType.project)),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, Strings.searchPlaces(NodeType.project)),
        'paper',
      );
      await tester.pump();
      expect(options, findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, Strings.searchPlaces(NodeType.project)),
        'nothing like this',
      );
      await tester.pump();
      expect(find.text(Strings.noMatches), findsOneWidget);
    });

    testSahai('changing the type clears a place that can no longer hold it', (
      tester,
    ) async {
      final app = TestApp();
      await SampleTree.create(app);
      await capturesOf(app).add('renew passport');
      await pumpSahai(tester, app: app, tab: Strings.capture);
      await tapCreate(tester, 'renew passport');

      await fillCreateForm(
        tester,
        type: NodeType.task,
        place: 'Website relaunch',
        title: 'Renew passport',
      );
      expect(find.text('Biztras › Website relaunch'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Stream item'));
      await tester.pumpAndSettle();
      expect(find.text('Biztras › Website relaunch'), findsNothing);
      expect(find.text(Strings.pickA(NodeType.stream)), findsOneWidget);
      final save = find.widgetWithText(FilledButton, Strings.save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
    });
  });

  group('accessibility', () {
    testSahai('Create and the menu are labelled and at least 48 dp', (
      tester,
    ) async {
      final app = TestApp();
      await capturesOf(app).add('Call Rahul');
      final semantics = tester.ensureSemantics();
      await pumpSahai(tester, app: app, tab: Strings.capture);

      final create = find.bySemanticsLabel(Strings.createFromThis);
      final menu = find.byTooltip(Strings.captureActions);
      expect(create, findsOneWidget);
      expect(menu, findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testSahai('the list, menu and Create form fit at twice the text size', (
      tester,
    ) async {
      final app = TestApp();
      await SampleTree.create(app);
      await capturesOf(app).add(
        'call Rahul\nbuy milk\nrenew passport – check fees first\nbook dentist',
      );
      await pumpSahai(tester, app: app, tab: Strings.capture, textScale: 2);
      expect(tester.takeException(), isNull);

      await openCaptureMenu(
        tester,
        'call Rahul\nbuy milk\nrenew passport – '
        'check fees first\nbook dentist',
      );
      expect(tester.takeException(), isNull);
      await tester.tap(inSheet(find.text(Strings.createAnItem)));
      await tester.pumpAndSettle();
      expect(find.text(Strings.createItem), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.goesIn));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
