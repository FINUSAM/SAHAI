import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/shared/strings.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// #85: a due date outside the current year shows its year, so a date next
/// year can't be mistaken for this year's (PRD 7, card label). Local time,
/// as on the phone: Monday, Dec 28, 2026, at 10:00 AM.
void main() {
  TestApp newApp() => TestApp(clock: TestClock(DateTime(2026, 12, 28, 10)));

  /// Personal › Finance & Bills with HDFC monthly on the 1st, due Jan 1,
  /// 2027 and showing 7 days early, so it is on the Summary now.
  Future<String> addBill(TestApp app) async {
    final a = app.actions;
    final personal = await a.create(type: NodeType.domain, title: 'Personal');
    final finance = await a.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Finance & Bills',
    );
    return a.create(
      type: NodeType.streamItem,
      parentId: finance,
      title: 'Pay HDFC card',
      schedule: Schedule.monthly(day: 1),
      dueOn: DateTime(2027, 1, 1),
      leadDays: 7,
    );
  }

  testSahai('#85 the Summary card shows the year', (tester) async {
    final app = newApp();
    await addBill(app);
    await pumpSahai(tester, app: app);
    expect(find.text('Due Jan 1, 2027'), findsOneWidget);
  });

  testSahai('#85 the Done message shows the next due date with its year', (
    tester,
  ) async {
    final app = newApp();
    await addBill(app);
    await pumpSahai(tester, app: app);
    await tester.tap(find.byTooltip(Strings.markDoneTooltip('Pay HDFC card')));
    await tester.pumpAndSettle();
    expect(find.text('Done. Next due Feb 1, 2027'), findsOneWidget);
  });

  testSahai('#85 the Skip message shows the year', (tester) async {
    final app = newApp();
    await addBill(app);
    await pumpSahai(tester, app: app);
    await tester.tap(find.text('Pay HDFC card'));
    await tester.pumpAndSettle();
    expect(find.text('Next due Feb 1, 2027'), findsOneWidget);
    await tester.tap(find.text(Strings.skipOccurrence));
    await tester.pumpAndSettle();
    expect(find.text('Skipped. Next due Feb 1, 2027'), findsOneWidget);
  });

  testSahai('#85 the Explorer line and the Next due field show the year', (
    tester,
  ) async {
    final app = newApp();
    await addBill(app);
    await pumpExplorer(tester, app: app);
    await expandAll(tester);
    expect(find.textContaining('due Jan 1, 2027'), findsOneWidget);
    await openActions(tester, 'Pay HDFC card');
    await choose(tester, Strings.edit);
    expect(find.text('Fri, Jan 1, 2027'), findsOneWidget);
  });
}
