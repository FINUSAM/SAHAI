import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/shared/strings.dart';

import '../widget_helpers.dart';

void main() {
  testSahai('the app opens on the Summary with four tabs', (tester) async {
    await pumpSahai(tester);
    expect(find.text(Strings.summaryEmptyTitle), findsOneWidget);
    for (final tab in [
      Strings.summary,
      Strings.setAside,
      Strings.explorer,
      Strings.capture,
    ]) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
  });

  testSahai('the Set-Aside tab is real (M3); Capture shows what is coming', (
    tester,
  ) async {
    await pumpSahai(tester);
    await goToTab(tester, Strings.setAside);
    expect(find.text(Strings.nothingSetAside), findsOneWidget);
    await goToTab(tester, Strings.capture);
    expect(find.text(Strings.comingIn('M6')), findsOneWidget);
  });

  testSahai('the gear opens Settings, and back returns', (tester) async {
    await pumpSahai(tester);
    await tester.tap(find.byTooltip(Strings.settings));
    await tester.pumpAndSettle();
    // M3 brings the Reminders section (frame 14).
    expect(find.text(Strings.notifications), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(Strings.summaryEmptyTitle), findsOneWidget);
  });
}
