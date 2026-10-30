import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/app/app.dart';
import 'package:sahai/app/providers.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/shared/strings.dart';

import 'helpers.dart';

final _open = <TestApp>[];

/// A widget test that closes every database [pumpSahai] opened once [body]
/// ends. Closing has to happen inside the test, because drift only finishes
/// closing once the fake test clock moves on.
void testSahai(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      for (final app in _open.reversed) {
        await closeSahai(tester, app);
      }
      _open.clear();
    }
  });
}

/// Starts the whole app on [app]'s database (in memory unless given one).
/// Use it inside [testSahai], which closes the database afterwards.
Future<TestApp> pumpSahai(
  WidgetTester tester, {
  TestApp? app,
  double textScale = 1,
}) async {
  final testApp = app ?? TestApp();
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  // A typical phone: 411 x 914 logical pixels.
  tester.view.devicePixelRatio = 2.625;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(testApp.clock.clock),
        databaseProvider.overrideWithValue(testApp.db),
        nodeActionsProvider.overrideWithValue(testApp.actions),
      ],
      child: const SahaiApp(),
    ),
  );
  await tester.pumpAndSettle();
  _open.add(testApp);
  return testApp;
}

/// Unmounts the app, so drift's live queries stop, then closes the
/// database, as happens when the app is closed. Safe to call twice.
Future<void> closeSahai(WidgetTester tester, TestApp app) async {
  await tester.pumpWidget(const SizedBox());
  final closing = app.close();
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() => closing);
}

/// A database file that outlives one [TestApp], to simulate restarting the
/// app (AT-001, AT-004, AT-005).
File tempDatabaseFile() {
  final dir = Directory.systemTemp.createTempSync('sahai_widget');
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}${Platform.pathSeparator}sahai.sqlite');
}

TestApp appOnFile(File file) => TestApp(executor: NativeDatabase(file));

/// The example tree from frame 3: Biztras with a project of three tasks
/// (the first with two subtasks) and a stream with two items.
class SampleTree {
  late final String domain;
  late final String project;
  late final List<String> tasks;
  late final List<String> subtasks;
  late final String stream;
  late final List<String> items;

  static Future<SampleTree> create(TestApp app) async {
    final t = SampleTree();
    final a = app.actions;
    t.domain = await a.create(type: NodeType.domain, title: 'Biztras');
    t.project = await a.create(
      type: NodeType.project,
      parentId: t.domain,
      title: 'Website relaunch',
    );
    t.tasks = [
      for (final title in ['Write copy', 'Design pages', 'Launch'])
        await a.create(type: NodeType.task, parentId: t.project, title: title),
    ];
    t.subtasks = [
      for (final title in ['Draft homepage', 'Draft pricing page'])
        await a.create(
          type: NodeType.subtask,
          parentId: t.tasks[0],
          title: title,
        ),
    ];
    t.stream = await a.create(
      type: NodeType.stream,
      parentId: t.domain,
      title: 'Client admin',
    );
    t.items = [
      for (final title in ['Send invoice', 'Renew domain name'])
        await a.create(
          type: NodeType.streamItem,
          parentId: t.stream,
          title: title,
        ),
    ];
    return t;
  }
}

/// Scrolls [finder] into view, then taps it.
Future<void> tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Expands every collapsed row, top to bottom, until none are left.
Future<void> expandAll(WidgetTester tester) async {
  while (true) {
    final collapsed = find.byWidgetPredicate(
      (w) => w is IconButton && (w.tooltip?.startsWith('Expand ') ?? false),
    );
    if (collapsed.evaluate().isEmpty) return;
    await tapInView(tester, collapsed.first);
  }
}

Future<void> openActions(WidgetTester tester, String title) =>
    tapInView(tester, find.byTooltip(Strings.actionsFor(title)));

/// Closes an open bottom sheet by tapping the dimmed area above it.
Future<void> closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(20, 20));
  await tester.pumpAndSettle();
}

/// Taps a choice in the open actions sheet.
Future<void> choose(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Fills in the create/edit form and saves it.
Future<void> fillForm(WidgetTester tester, String title) async {
  await tester.enterText(
    find.widgetWithText(TextField, Strings.titleLabel),
    title,
  );
  await tester.pump();
  await tester.tap(find.text(Strings.save));
  await tester.pumpAndSettle();
}
