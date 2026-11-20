// AT-114 on the phone: 10,000 items, in profile mode, against PRD 13's
// limits (cold start to the Summary under 2 seconds, a recompute under
// 50 ms). The items go into a throwaway database in the app's cache folder,
// never the real `sahai.sqlite`.
//
// Warn the owner first. With the phone connected over USB:
//   flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/speed_test.dart
//
// `flutter drive` installs the profile build over the installed app, which
// keeps its data, and doesn't uninstall it afterwards. Reinstall the
// release build with `adb install -r` when done, and never run it from an
// older version than the one installed. For Android's own process start,
// time the release build too: `adb shell am start -W com.finusam.sahai/.MainActivity`.
//
// `flutter test integration_test` (debug mode) runs it as well; it then
// reports the times without checking the limits.
import 'package:integration_test/integration_test.dart';

import '../test/perf/at114_speed.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final times = <String, double>{};
  binding.reportData = {'at114_ms': times};
  at114SpeedChecks(report: (name, ms) => times[name] = ms);
}
