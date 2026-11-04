// Runs the app's widget tests on a real phone, including the restart flows
// for AT-001 (create every node type), AT-004 (reorder tasks) and AT-005
// (reorder subtasks and stream items), the M2 Summary flows, and the M3
// set-aside flows.
//
// Each test uses its own throwaway database (in memory, or a file in the
// app's temporary folder), never the app's real `sahai.sqlite`.
//
// With the phone connected over USB:
//   flutter test integration_test
import 'package:integration_test/integration_test.dart';

import '../test/app/home_shell_test.dart' as home_shell;
import '../test/app/summary_refresher_test.dart' as refresher;
import '../test/features/explorer/explorer_m2_test.dart' as explorer_m2;
import '../test/features/explorer/explorer_screen_test.dart' as explorer;
import '../test/features/set_aside/set_aside_screens_test.dart' as set_aside;
import '../test/features/summary/summary_screen_test.dart' as summary;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  home_shell.main();
  explorer.main();
  explorer_m2.main();
  summary.main();
  set_aside.main();
  refresher.main();
}
