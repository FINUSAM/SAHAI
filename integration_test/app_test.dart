// Runs the app's widget tests on a real phone, including the restart flows
// for AT-001 (create every node type), AT-004 (reorder tasks) and AT-005
// (reorder subtasks and stream items), the M2 Summary flows, and the M3
// set-aside and reminder flows (with the phone's notifications faked).
//
// Each test uses its own throwaway database (in memory, or a file in the
// app's temporary folder), never the app's real `sahai.sqlite`.
//
// summary_refresher_test.dart stays out: it skips hours ahead with pump(), which
// is instant on a computer but a real wait on a phone. CI runs it on every PR.
//
// With the phone connected over USB:
//   flutter test integration_test
import 'package:integration_test/integration_test.dart';

import '../test/app/home_shell_test.dart' as home_shell;
import '../test/features/explorer/explorer_m2_test.dart' as explorer_m2;
import '../test/features/explorer/explorer_screen_test.dart' as explorer;
import '../test/features/reminders_test.dart' as reminders;
import '../test/features/set_aside/set_aside_screens_test.dart' as set_aside;
import '../test/features/summary/summary_screen_test.dart' as summary;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  home_shell.main();
  explorer.main();
  explorer_m2.main();
  summary.main();
  set_aside.main();
  reminders.main();
}
