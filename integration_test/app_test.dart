// Runs the app's widget tests on a real phone, including the restart flows
// for AT-001 (create every node type), AT-004 (reorder tasks) and AT-005
// (reorder subtasks and stream items), the M2 Summary flows, the M3 set-aside
// and reminder flows, the M4 recurring flows (with the phone's notifications
// faked), the M5 group flows, including the restart for AT-093 (Summary
// order persists), and the M6 capture flows, including the restart for
// AT-097 (an edited capture persists) and the capture dialog that the
// widget and the share sheet open (AT-099, AT-100; opening it from outside
// the app is checked by hand), and the M7 Settings and onboarding flows,
// including the practice step (AT-105 to AT-110, AT-120), the year on
// due dates outside the current year (#85), one-off due dates and their
// reminders (AT-128 to AT-132) and the accessibility pass over every screen
// (AT-116, AT-117). The AT-114 speed check is its own file, speed_test.dart.
//
// Each test uses its own throwaway database (in memory, or a file in the
// app's temporary folder), never the app's real `sahai.sqlite`.
//
// summary_refresher_test.dart stays out: it skips hours ahead with pump(), which
// is instant on a computer but a real wait on a phone. CI runs it on every PR.
//
// With the phone connected over USB:
//   flutter test integration_test --no-uninstall
//
// Without --no-uninstall the run uninstalls the app when it finishes, which
// deletes its data on the phone. The test build still replaces the installed
// app, so reinstall the release build afterwards with `adb install -r`.
// Never run it from an older version than the one installed: Android refuses
// the downgrade, and Flutter then uninstalls the app, flag or not.
// Check this again in M8: once the app has its own signing key, a test build
// won't install over the release build, and that could trigger an uninstall.
import 'package:integration_test/integration_test.dart';

import '../test/app/home_shell_test.dart' as home_shell;
import '../test/features/capture_dialog_test.dart' as capture_dialog;
import '../test/features/a11y_screens_test.dart' as a11y_screens;
import '../test/features/capture_test.dart' as capture;
import '../test/features/due_dates_test.dart' as due_dates;
import '../test/features/due_year_test.dart' as due_year;
import '../test/features/explorer/explorer_m2_test.dart' as explorer_m2;
import '../test/features/explorer/explorer_screen_test.dart' as explorer;
import '../test/features/groups_test.dart' as groups;
import '../test/features/m7_accessibility_test.dart' as m7_accessibility;
import '../test/features/onboarding_test.dart' as onboarding;
import '../test/features/recurring_test.dart' as recurring;
import '../test/features/reopen_occurrence_test.dart' as reopen_occurrence;
import '../test/features/reminders_test.dart' as reminders;
import '../test/features/set_aside/set_aside_screens_test.dart' as set_aside;
import '../test/features/settings_test.dart' as settings;
import '../test/features/summary/summary_screen_test.dart' as summary;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  home_shell.main();
  explorer.main();
  explorer_m2.main();
  summary.main();
  set_aside.main();
  reminders.main();
  recurring.main();
  groups.main();
  capture.main();
  capture_dialog.main();
  settings.main();
  onboarding.main();
  due_year.main();
  m7_accessibility.main();
  reopen_occurrence.main();
  due_dates.main();
  a11y_screens.main();
}
