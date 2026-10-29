import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';

/// A clock tests can move forward. Starts at the AT sheet's reference time:
/// Tuesday, Nov 3, 2026, 3:00 PM UTC.
class TestClock {
  TestClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 11, 3, 15);

  DateTime now;

  Clock get clock => Clock(() => now);

  void advance(Duration by) => now = now.add(by);
}

/// Ids that read well in failures: id-1, id-2, ...
String Function() sequentialIds() {
  var next = 0;
  return () => 'id-${++next}';
}

/// An in-memory database plus actions wired to a test clock.
class TestApp {
  TestApp({QueryExecutor? executor, TestClock? clock, String Function()? ids})
    : clock = clock ?? TestClock() {
    db = SahaiDatabase(
      executor ?? NativeDatabase.memory(),
      clock: this.clock.clock,
    );
    actions = NodeActions(
      db,
      clock: this.clock.clock,
      newId: ids ?? sequentialIds(),
    );
  }

  final TestClock clock;
  late final SahaiDatabase db;
  late final NodeActions actions;

  Future<void> close() => db.close();
}
