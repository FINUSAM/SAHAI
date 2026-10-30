import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/shared/strings.dart';

import '../widget_helpers.dart';

void main() {
  testSahai('the app opens on the Explorer with four tabs', (tester) async {
    await pumpSahai(tester);
    expect(find.text(Strings.emptyTitle), findsOneWidget);
    for (final tab in [
      Strings.summary,
      Strings.setAside,
      Strings.explorer,
      Strings.capture,
    ]) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
  });

  testSahai('later tabs show what is coming', (tester) async {
    await pumpSahai(tester);
    final expected = {
      Strings.summary: 'M2',
      Strings.setAside: 'M3',
      Strings.capture: 'M6',
    };
    for (final MapEntry(key: tab, value: milestone) in expected.entries) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(find.text(Strings.comingIn(milestone)), findsOneWidget);
    }
  });

  testSahai('the gear opens Settings, and back returns', (tester) async {
    await pumpSahai(tester);
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    expect(find.text(Strings.comingIn('M7')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Strings.emptyTitle), findsOneWidget);
  });
}
