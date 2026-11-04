import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/shared/strings.dart';

import '../../helpers.dart';
import '../../widget_helpers.dart';

/// M2 changes to the Explorer (frames 9 and 10): Mark done with Undo, and
/// the Reopen line that names the ancestors it reopens.
void main() {
  Future<(TestApp, SampleTree)> pumpSample(WidgetTester tester) async {
    final app = TestApp();
    final sample = await SampleTree.create(app);
    await pumpExplorer(tester, app: app);
    await expandAll(tester);
    return (app, sample);
  }

  testSahai('AT-025 Mark done in the Explorer offers Undo', (tester) async {
    final (app, sample) = await pumpSample(tester);
    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Draft homepage')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.doneSnack('Draft homepage')), findsOneWidget);
    expect((await app.actions.loadTree())[sample.subtasks[0]]!.isDone, isTrue);

    await tester.tap(find.text(Strings.undo));
    await tester.pumpAndSettle();
    expect((await app.actions.loadTree())[sample.subtasks[0]]!.isTodo, isTrue);
    expect(
      find.byTooltip(Strings.markDoneTooltip('Draft homepage')),
      findsOneWidget,
    );
  });

  testSahai('AT-026 the Explorer Undo window closes after 5 seconds', (
    tester,
  ) async {
    final (app, sample) = await pumpSample(tester);
    await openActions(tester, 'Draft homepage');
    await choose(tester, Strings.markDone);
    expect(find.text(Strings.undo), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text(Strings.undo), findsNothing);
    expect((await app.actions.loadTree())[sample.subtasks[0]]!.isDone, isTrue);
  });

  testSahai('AT-027 Reopen names the DONE ancestors it reopens', (
    tester,
  ) async {
    final (app, sample) = await pumpSample(tester);
    for (final id in [...sample.subtasks, sample.tasks[0]]) {
      await app.actions.markDone(id);
    }
    await tester.pumpAndSettle();
    await openActions(tester, 'Draft pricing page');
    expect(find.text(Strings.alsoReopens(['1. Write copy'])), findsOneWidget);
    await choose(tester, Strings.reopen);
    final tree = await app.actions.loadTree();
    expect(tree[sample.subtasks[1]]!.isTodo, isTrue);
    expect(tree[sample.tasks[0]]!.isTodo, isTrue);

    // A DONE item with no DONE ancestors shows no hint.
    await openActions(tester, 'Draft homepage');
    expect(find.textContaining('Also reopens'), findsNothing);
    await closeSheet(tester);
  });
}
