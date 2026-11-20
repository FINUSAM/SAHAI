// The host side of `flutter drive`, which the profile-mode speed check
// (integration_test/speed_test.dart) needs: `flutter test` can't build in
// profile mode. It writes the reported times to build/integration_response_data.json.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
