import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/capture_actions.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/features/capture/capture_dialog.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Stands in for `CaptureActivity`: what it was opened with, and what the
/// dialog asked it to do.
class FakeCaptureHost implements CaptureHost {
  FakeCaptureHost({this.text, this.source = CaptureSource.widget});

  final String? text;
  final CaptureSource source;
  final savedMessages = <String>[];
  var cancels = 0;
  VoidCallback? _onFocused;

  /// Acts as if Android gave the window focus.
  void focus() => _onFocused!();

  bool get closed => savedMessages.isNotEmpty || cancels > 0;

  @override
  Future<CaptureRequest> request() async =>
      CaptureRequest(text: text, source: source);

  @override
  void listen({required VoidCallback onFocused}) => _onFocused = onFocused;

  @override
  Future<void> saved(String message) async => savedMessages.add(message);

  @override
  Future<void> cancel() async => cancels++;
}

/// Shows the dialog alone, as `captureMain` does, saving into [app].
Future<void> pumpDialog(
  WidgetTester tester, {
  required TestApp app,
  required CaptureHost host,
  SaveCapture? save,
  double textScale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.devicePixelRatio = 2.625;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  final captures = CaptureActions(app.db, clock: app.clock.clock);
  await tester.pumpWidget(
    CaptureDialogApp(
      host: host,
      save: save ?? (text, source) async => captures.add(text, source: source),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get captureField => find.byType(TextField);

FilledButton saveButton(WidgetTester tester) =>
    tester.widget(find.widgetWithText(FilledButton, Strings.save));

Future<List<CaptureRow>> savedCaptures(TestApp app) =>
    app.db.select(app.db.captures).get();

Future<Map<String, Object?>> capturedPayload(TestApp app) async {
  final events = await app.db.select(app.db.events).get();
  final captured = events.singleWhere(
    (e) => e.eventType == EventTypes.captured,
  );
  return jsonDecode(captured.payload) as Map<String, Object?>;
}

void main() {
  testSahai('AT-099 the widget dialog saves a capture from the widget', (
    tester,
  ) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost();
    await pumpDialog(tester, app: app, host: host);

    expect(find.text(Strings.capture), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await tester.enterText(captureField, 'ask Priya for the invoice template');
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    final saved = await savedCaptures(app);
    expect(saved.single.body, 'ask Priya for the invoice template');
    expect(await capturedPayload(app), {'source': 'widget'});
    expect(host.savedMessages, [Strings.savedToCapture]);
  });

  testSahai('AT-100 shared text opens filled in, can be trimmed, and saves '
      'as a share', (tester) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost(
      text: 'Deep work: rules for focused success https://example.com/dw',
      source: CaptureSource.share,
    );
    await pumpDialog(tester, app: app, host: host);

    expect(
      find.text('Deep work: rules for focused success https://example.com/dw'),
      findsOneWidget,
    );
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.enterText(captureField, 'Deep work: block two hours');
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(
      (await savedCaptures(app)).single.body,
      'Deep work: block two hours',
    );
    expect(await capturedPayload(app), {'source': 'share'});
    expect(host.savedMessages, [Strings.savedToCapture]);
  });

  testSahai('Cancel closes the dialog and saves nothing', (tester) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost(text: 'a link', source: CaptureSource.share);
    await pumpDialog(tester, app: app, host: host);

    await tester.tap(find.text(Strings.cancel));
    await tester.pumpAndSettle();

    expect(host.cancels, 1);
    expect(host.savedMessages, isEmpty);
    expect(await savedCaptures(app), isEmpty);
  });

  testSahai('Save stays off while the box holds only spaces', (tester) async {
    final app = TestApp();
    addTearDown(app.close);
    await pumpDialog(tester, app: app, host: FakeCaptureHost());

    await tester.enterText(captureField, '   \n  ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);
  });

  testSahai('a capture can be a whole list (M6 decision 6)', (tester) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost();
    await pumpDialog(tester, app: app, host: host);

    final field = tester.widget<TextField>(captureField);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.maxLines, 6);

    await tester.enterText(captureField, 'call Rahul\nbuy milk\nbook dentist');
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(
      (await savedCaptures(app)).single.body,
      'call Rahul\nbuy milk\nbook dentist',
    );
  });

  testSahai('a failed save keeps the text, says so, and leaves the dialog '
      'open', (tester) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost();
    await pumpDialog(
      tester,
      app: app,
      host: host,
      save: (_, _) async => throw StateError('disk full'),
    );

    await tester.enterText(captureField, 'renew passport');
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(find.text('renew passport'), findsOneWidget);
    expect(find.text(Strings.captureSaveFailed), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
    expect(host.closed, isFalse);
  });

  testSahai('tapping outside the dialog keeps it open', (tester) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost();
    await pumpDialog(tester, app: app, host: host);
    await tester.enterText(captureField, 'half a thought');
    await tester.pump();

    await tester.tapAt(const Offset(200, 850));
    await tester.pumpAndSettle();

    expect(find.text('half a thought'), findsOneWidget);
    expect(host.closed, isFalse);
  });

  testSahai('the box asks for the keyboard again once the window has focus', (
    tester,
  ) async {
    final app = TestApp();
    addTearDown(app.close);
    final host = FakeCaptureHost();
    await pumpDialog(tester, app: app, host: host);
    final box = tester.widget<EditableText>(find.byType(EditableText));
    // On a computer Flutter's test keyboard reports whether it is up. On a
    // phone the real keyboard is used and can't be read, so there the test
    // checks what brings it up: the box having focus.
    final keyboardReadable = tester.testTextInput.isRegistered;
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(box.focusNode.hasFocus, isFalse);
    if (keyboardReadable) expect(tester.testTextInput.isVisible, isFalse);

    host.focus();
    await tester.pump();

    expect(box.focusNode.hasFocus, isTrue);
    if (keyboardReadable) expect(tester.testTextInput.isVisible, isTrue);
  });

  group('accessibility', () {
    testSahai('Cancel and Save are labelled and at least 48 dp', (
      tester,
    ) async {
      final app = TestApp();
      addTearDown(app.close);
      final semantics = tester.ensureSemantics();
      await pumpDialog(
        tester,
        app: app,
        host: FakeCaptureHost(text: 'a', source: CaptureSource.share),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testSahai('the dialog fits at twice the text size', (tester) async {
      final app = TestApp();
      addTearDown(app.close);
      await pumpDialog(
        tester,
        app: app,
        host: FakeCaptureHost(
          text: 'call Rahul\nbuy milk\nrenew passport\nbook dentist\nfix tap',
          source: CaptureSource.share,
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(Strings.save), findsOneWidget);
    });
  });

  group('saveToAppDatabase', () {
    testSahai('opens the database and saves with its source', (tester) async {
      final file = tempDatabaseFile();
      final clock = TestClock();
      SahaiDatabase? opened;
      await tester.runAsync(
        () => saveToAppDatabase(
          'water the plants',
          CaptureSource.widget,
          open: () => opened = SahaiDatabase(NativeDatabase(file)),
          clock: clock.clock,
        ),
      );
      expect(opened, isNotNull);

      final app = appOnFile(file);
      addTearDown(app.close);
      await tester.runAsync(() async {
        expect((await savedCaptures(app)).single.body, 'water the plants');
        expect(await capturedPayload(app), {'source': 'widget'});
      });
    });
  });
}
