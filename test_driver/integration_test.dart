// The host side of `flutter drive`, which the profile-mode speed check
// (integration_test/speed_test.dart) needs: `flutter test` can't build in
// profile mode. It writes the reported times to build/integration_response_data.json.
// `flutter drive` uninstalls the app when it finishes, deleting its data,
// so never run it on a phone whose data matters (see speed_test.dart).
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
