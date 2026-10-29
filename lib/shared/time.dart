import 'package:clock/clock.dart';

// All code reads the time through an injected Clock so tests can run as if it
// were any date (decision record 0004). CI rejects DateTime.now() in lib/.

/// The current moment as UTC milliseconds since the epoch, the storage format
/// for every moment in the database.
int utcMillis(Clock clock) => clock.now().toUtc().millisecondsSinceEpoch;

/// The phone's current offset from UTC, in minutes, for activity log events.
int tzOffsetMinutes(Clock clock) => clock.now().timeZoneOffset.inMinutes;
