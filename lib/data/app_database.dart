import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'database.dart';

/// Opens `sahai.sqlite` in the app's private storage. drift_flutter runs the
/// queries on a background isolate, so the UI thread never waits on the
/// database (PRD 13).
///
/// The capture dialog runs in its own Flutter engine in the same Android
/// process (decision 0007). With `shareAcrossIsolates`, it and the app use
/// one connection, so the file is never written through two at once. Both
/// must open the database through here.
SahaiDatabase openAppDatabase({Clock clock = const Clock()}) => SahaiDatabase(
  driftDatabase(
    name: 'sahai',
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  ),
  clock: clock,
);
