import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/groups.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// The M5 screens: groups on the Summary, dragging, the card sheet, the
/// group picker, forms, Explorer rows and Settings (M5 frames 1 to 14).
void main() {
  /// The frame 3 example tree, plus groups made through the actions.
  Future<(TestApp, SampleTree)> sample() async {
    final app = TestApp();
    return (app, await SampleTree.create(app));
  }

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(BottomSheet), matching: finder);

  /// Presses and holds [title]'s card until it lifts.
  Future<TestGesture> lift(WidgetTester tester, String title) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(title)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 8));
    await tester.pump();
    return gesture;
  }

  Future<void> drop(
    WidgetTester tester,
    TestGesture gesture,
    Finder target,
  ) async {
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Drags [title]'s card onto [target] and lets go.
  Future<void> drag(WidgetTester tester, String title, Finder target) async {
    final gesture = await lift(tester, title);
    await drop(tester, gesture, target);
  }

  Future<void> openSettingsGroups(WidgetTester tester) async {
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    // Below the Reminders section, off screen with large text.
    await tester.scrollUntilVisible(find.text(Strings.contextGroups), 100);
    await tapInView(tester, find.text(Strings.contextGroups));
  }

  testSahai('AT-083 with no groups on the Summary there are no headers', (
    tester,
  ) async {
    final (app, _) = await sample();
    // A group that isn't set on anything stays off the Summary (AT-084).
    await app.actions.createGroup('Errands', icon: 'bag');
    await pumpSahai(tester, app: app);

    expect(find.text('Draft homepage'), findsOneWidget);
    expect(find.text('Send invoice'), findsOneWidget);
    expect(find.text(Strings.noGroup), findsNothing);
    expect(find.text('Errands'), findsNothing);
  });

  testSahai('AT-083 AT-085 cards sit under their group, with No group last', (
    tester,
  ) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await app.actions.setGroup(s.project, laptop);
    await pumpSahai(tester, app: app);

    expect(find.text('At laptop'), findsOneWidget);
    expect(find.byIcon(Icons.laptop_outlined), findsOneWidget);
    expect(find.text(Strings.noGroup), findsOneWidget);
    expect(
      find.bySemanticsLabel(Strings.groupHeader('At laptop', 1)),
      findsOneWidget,
    );
    final order = [
      top(tester, find.text('At laptop')),
      top(tester, find.text('Draft homepage')),
      top(tester, find.text(Strings.noGroup)),
      top(tester, find.text('Send invoice')),
    ];
    expect(order, [...order]..sort());
  });

  testSahai('AT-084 a group made in Settings is listed, and stays off the '
      'Summary until it is set on something', (tester) async {
    final (app, _) = await sample();
    await pumpSahai(tester, app: app);
    await openSettingsGroups(tester);
    expect(find.text(Strings.noGroupsYet), findsOneWidget);

    await tester.tap(find.text(Strings.newGroup));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, Strings.nameLabel),
      'At laptop',
    );
    await tester.tap(find.bySemanticsLabel(Strings.iconName('laptop')));
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(find.text('At laptop'), findsOneWidget);
    expect(find.text(Strings.setOnItems(0)), findsOneWidget);
    final groups = await app.actions.loadGroups();
    expect(groups.single.name, 'At laptop');
    expect(groups.single.icon, 'laptop');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Strings.groupCount(1)), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('At laptop'), findsNothing);
    expect(find.text(Strings.noGroup), findsNothing);
  });

  testSahai('AT-084 renaming a group and changing its icon', (tester) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await app.actions.setGroup(s.project, laptop);
    await pumpSahai(tester, app: app);
    await openSettingsGroups(tester);

    await tester.tap(find.text('At laptop'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.editGroup), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, Strings.nameLabel),
      'Desk',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(Strings.noIcon));
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    final group = (await app.actions.loadGroups()).single;
    expect(group.name, 'Desk');
    expect(group.icon, isNull);
    expect(find.text('Desk'), findsOneWidget);
  });

  testSahai('AT-087 AT-092 dragging a card to another group sets that group '
      'on the item only, without touching the tree, and Undo puts it back', (
    tester,
  ) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await app.actions.setGroup(s.project, laptop);
    await pumpSahai(tester, app: app);
    final before = await app.actions.loadTree();

    await drag(tester, 'Send invoice', find.text('At laptop'));

    expect(find.text(Strings.movedTo('At laptop')), findsOneWidget);
    final after = await app.actions.loadTree();
    expect(after[s.items[0]]!.groupId, laptop);
    expect(after[s.stream]!.groupId, isNull);
    expect(after[s.items[1]]!.groupId, isNull);
    for (final id in [s.domain, s.stream, s.project]) {
      expect(
        after.childrenOf(id).map((n) => n.id),
        before.childrenOf(id).map((n) => n.id),
      );
    }
    // It goes to the end of its new group, and No group is gone.
    expect(
      top(tester, find.text('Draft homepage')),
      lessThan(top(tester, find.text('Send invoice'))),
    );
    expect(find.text(Strings.noGroup), findsNothing);

    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[s.items[0]]!.groupId, isNull);
    expect(find.text(Strings.noGroup), findsOneWidget);
  });

  testSahai('frame 3 empty groups show as places to drop only during a drag', (
    tester,
  ) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    final home = await app.actions.createGroup('At home', icon: 'home');
    await app.actions.setGroup(s.project, laptop);
    await pumpSahai(tester, app: app);
    expect(find.text('At home'), findsNothing);

    final gesture = await lift(tester, 'Send invoice');
    expect(find.text('At home'), findsOneWidget);
    expect(find.text(Strings.emptyGroup), findsOneWidget);
    await drop(tester, gesture, find.text('At home'));

    expect(find.text(Strings.movedTo('At home')), findsOneWidget);
    expect((await app.actions.loadTree())[s.items[0]]!.groupId, home);
    expect(find.text(Strings.emptyGroup), findsNothing);
  });

  testSahai('AT-088 dragging within a group changes the order only, and the '
      'next card takes the same place', (tester) async {
    final (app, s) = await sample();
    await pumpSahai(tester, app: app);
    final before = await app.actions.loadTree();

    await drag(tester, 'Send invoice', find.text('Draft homepage'));

    expect(find.byType(SnackBar), findsNothing);
    expect(
      top(tester, find.text('Send invoice')),
      lessThan(top(tester, find.text('Draft homepage'))),
    );
    final after = await app.actions.loadTree();
    expect(
      after.childrenOf(s.domain).map((n) => n.id),
      before.childrenOf(s.domain).map((n) => n.id),
    );

    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    expect(
      top(tester, find.text('Send invoice')),
      lessThan(top(tester, find.text('Draft pricing page'))),
    );
  });

  testSahai('AT-116 the card sheet moves a card up and down and stays open', (
    tester,
  ) async {
    final (app, _) = await sample();
    await pumpSahai(tester, app: app);

    await tester.tap(find.text('Send invoice'));
    await tester.pumpAndSettle();
    expect(inSheet(find.text(Strings.positionOnSummary(2, 2))), findsOneWidget);
    expect(
      find.bySemanticsLabel(Strings.moveCardUp('Send invoice')),
      findsOneWidget,
    );

    await tester.tap(inSheet(find.text(Strings.moveUp)));
    await tester.pumpAndSettle();
    expect(inSheet(find.text(Strings.positionOnSummary(1, 2))), findsOneWidget);
    final sections = await app.actions.loadArrangedSummary();
    expect(sections.single.cards.map((c) => c.node.title), [
      'Send invoice',
      'Draft homepage',
    ]);

    await tester.tap(inSheet(find.text(Strings.moveDown)));
    await tester.pumpAndSettle();
    expect(inSheet(find.text(Strings.positionOnSummary(2, 2))), findsOneWidget);
  });

  testSahai('frames 6 and 7 the card sheet changes the group through the '
      'picker, with Undo (E-013)', (tester) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await app.actions.setGroup(s.project, laptop);
    await pumpSahai(tester, app: app);

    await tester.tap(find.text('Draft homepage'));
    await tester.pumpAndSettle();
    expect(
      inSheet(find.text(Strings.groupFrom('At laptop', 'Website relaunch'))),
      findsOneWidget,
    );
    expect(
      inSheet(find.text(Strings.positionIn(1, 1, 'At laptop'))),
      findsOneWidget,
    );

    await tester.tap(inSheet(find.text(Strings.contextGroup)));
    await tester.pumpAndSettle();
    expect(
      inSheet(find.text(Strings.sameAs('Website relaunch'))),
      findsOneWidget,
    );
    expect(inSheet(find.text(Strings.keepOutOf('At laptop'))), findsOneWidget);
    await tester.tap(inSheet(find.text(Strings.noGroup)));
    await tester.pumpAndSettle();

    expect(find.text(Strings.movedTo(Strings.noGroup)), findsOneWidget);
    expect((await app.actions.loadTree())[s.subtasks[0]]!.groupId, noGroup);
    expect(find.text('At laptop'), findsNothing);

    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[s.subtasks[0]]!.groupId, isNull);
    expect(find.text('At laptop'), findsOneWidget);
  });

  testSahai('the group picker can make a new group and pick it', (
    tester,
  ) async {
    final (app, s) = await sample();
    await pumpSahai(tester, app: app);

    await tester.tap(find.text('Send invoice'));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text(Strings.contextGroup)));
    await tester.pumpAndSettle();
    // No group above, so no "Same as" (E-013).
    expect(find.textContaining('Same as'), findsNothing);
    await tester.tap(inSheet(find.text(Strings.newGroup)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, Strings.nameLabel),
      'Errands',
    );
    await tester.pump();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    final errands = (await app.actions.loadGroups()).single;
    expect((await app.actions.loadTree())[s.items[0]]!.groupId, errands.id);
    expect(find.text(Strings.movedTo('Errands')), findsOneWidget);
    expect(find.text('Errands'), findsOneWidget);
  });

  testSahai('AT-090 the form sets a group on a new item and on an edited one', (
    tester,
  ) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await pumpExplorer(tester, app: app);
    await expandAll(tester);

    await openActions(tester, 'Client admin');
    await choose(tester, Strings.addChild([NodeType.streamItem]));
    expect(find.text(Strings.contextGroup), findsOneWidget);
    await tester.tap(find.text(Strings.contextGroup));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('At laptop')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.cardsAppearHere('At laptop')), findsOneWidget);
    await fillForm(tester, 'Book a call');

    var tree = await app.actions.loadTree();
    final call = tree.childrenOf(s.stream).last;
    expect(call.title, 'Book a call');
    expect(call.groupId, laptop);

    await openActions(tester, 'Website relaunch');
    await choose(tester, Strings.edit);
    expect(find.text(Strings.noGroup), findsOneWidget);
    await tester.tap(find.text(Strings.contextGroup));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text('At laptop')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();
    tree = await app.actions.loadTree();
    expect(tree[s.project]!.groupId, laptop);
    expect(tree[s.project]!.title, 'Website relaunch');
  });

  testSahai('frames 9 and 10 the Explorer shows a group only where it is set, '
      'and the menu says where it comes from', (tester) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await app.actions.setGroup(s.project, laptop);
    await app.actions.setGroup(s.subtasks[1], noGroup);
    await pumpExplorer(tester, app: app);
    await expandAll(tester);

    expect(
      find.textContaining('At laptop', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining(Strings.noGroup, findRichText: true),
      findsOneWidget,
    );

    await openActions(tester, 'Website relaunch');
    expect(inSheet(find.text(Strings.setHere('At laptop'))), findsOneWidget);
    await closeSheet(tester);
    await openActions(tester, '1. Write copy');
    expect(
      inSheet(find.text(Strings.groupFrom('At laptop', 'Website relaunch'))),
      findsOneWidget,
    );
    await choose(tester, Strings.contextGroup);
    await tester.tap(inSheet(find.text(Strings.noGroup)));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[s.tasks[0]]!.groupId, noGroup);
  });

  testSahai('AT-084 E-014 the groups list sets the Summary order, and a '
      'deleted group comes back with Undo', (tester) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    final errands = await app.actions.createGroup('Errands', icon: 'bag');
    await app.actions.setGroup(s.project, laptop);
    await app.actions.setGroup(s.stream, errands);
    await pumpSahai(tester, app: app);
    expect(
      top(tester, find.text('At laptop')),
      lessThan(top(tester, find.text('Errands'))),
    );

    await openSettingsGroups(tester);
    expect(find.text(Strings.setOnItems(1)), findsNWidgets(2));
    await tester.tap(find.byTooltip(Strings.moveGroupDown('At laptop')));
    await tester.pumpAndSettle();
    expect((await app.actions.loadGroups()).map((g) => g.id), [
      errands,
      laptop,
    ]);

    await tester.tap(find.text('Errands'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.deleteGroupHint(1)), findsOneWidget);
    await tester.tap(find.text(Strings.deleteGroup));
    await tester.pumpAndSettle();
    expect(find.text(Strings.contextGroups), findsOneWidget);
    expect(find.text(Strings.deleted('Errands', 0)), findsOneWidget);
    expect((await app.actions.loadGroups()).map((g) => g.id), [laptop]);

    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    expect((await app.actions.loadGroups()).map((g) => g.id), [
      errands,
      laptop,
    ]);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      top(tester, find.text('Errands')),
      lessThan(top(tester, find.text('At laptop'))),
    );
  });

  testSahai('AT-093 the Summary order survives a restart', (tester) async {
    final file = tempDatabaseFile();
    final first = appOnFile(file);
    final s = await SampleTree.create(first);
    final laptop = await first.actions.createGroup('At laptop');
    await first.actions.setGroup(s.project, laptop);
    await first.actions.setGroup(s.stream, laptop);
    await pumpSahai(tester, app: first);
    await drag(tester, 'Send invoice', find.text('Draft homepage'));
    expect(
      top(tester, find.text('Send invoice')),
      lessThan(top(tester, find.text('Draft homepage'))),
    );

    await closeSahai(tester, first);
    final second = await pumpSahai(tester, app: appOnFile(file));
    expect(find.text('At laptop'), findsOneWidget);
    expect(
      top(tester, find.text('Send invoice')),
      lessThan(top(tester, find.text('Draft homepage'))),
    );
    final sections = await second.actions.loadArrangedSummary();
    expect(sections.single.group?.id, laptop);
  });

  testSahai('PRD 13 the M5 screens fit with the largest system text', (
    tester,
  ) async {
    final (app, s) = await sample();
    final laptop = await app.actions.createGroup('At laptop', icon: 'laptop');
    await app.actions.setGroup(s.project, laptop);
    await pumpSahai(tester, app: app, textScale: 2);
    expect(find.text('At laptop'), findsOneWidget);

    await tester.tap(find.text('Draft homepage'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(inSheet(find.text(Strings.contextGroup)));
    await tester.pumpAndSettle();
    await tester.tap(inSheet(find.text(Strings.contextGroup)));
    await tester.pumpAndSettle();
    expect(
      inSheet(find.text(Strings.sameAs('Website relaunch'))),
      findsOneWidget,
    );
    // The sheet fills the screen at this size, so there's nothing above it
    // to tap.
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    await openSettingsGroups(tester);
    await tester.tap(find.text('At laptop'));
    await tester.pumpAndSettle();
    expect(find.text(Strings.deleteGroup), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
