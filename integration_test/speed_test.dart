// AT-114 on the phone: 10,000 items, in profile mode, against PRD 13's
// limits (cold start to the Summary under 2 seconds, a recompute under
// 50 ms). The items go into a throwaway database in the app's cache folder,
// never the real `sahai.sqlite`.
//
// Never run it on the owner's phone, or on any phone whose data matters.
// Profile mode needs `flutter drive`, which stops and uninstalls the app
// when it finishes (flutter_tools' drive_service.dart, `stop()`), deleting
// its data. On 2026-11-21 that deleted the owner's recent items (plan
// 0009). Use a spare phone or an emulator:
//   flutter drive --profile --driver=test_driver/integration_test.dart --target=integration_test/speed_test.dart
//
// For Android's own process start, time the release build with the screen
// on and unlocked: `adb shell am start -W com.finusam.sahai/.MainActivity`.
// A locked screen gives a meaningless 3-second WaitTime.
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
