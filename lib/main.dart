import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/capture/capture_dialog.dart';

void main() {
  runApp(const ProviderScope(child: SahaiApp()));
}

/// The entry point `CaptureActivity` starts instead of [main]: the small
/// capture dialog from the widget and the share sheet (decision 0007). The
/// pragma keeps it in release builds, where nothing in Dart calls it.
@pragma('vm:entry-point')
void captureMain() => runCaptureDialog();
