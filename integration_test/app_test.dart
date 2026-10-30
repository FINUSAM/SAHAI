// Runs the app's widget tests on a real phone, including the restart flows
// for AT-001 (create every node type), AT-004 (reorder tasks) and AT-005
// (reorder subtasks and stream items).
//
// Each test uses its own throwaway database (in memory, or a file in the
// app's temporary folder), never the app's real `sahai.sqlite`.
//
// With the phone connected over USB:
//   flutter test integration_test
import 'package:integration_test/integration_test.dart';

import '../test/app/home_shell_test.dart' as home_shell;
import '../test/features/explorer/explorer_screen_test.dart' as explorer;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  home_shell.main();
  explorer.main();
}
