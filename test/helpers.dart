import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/notifications/reminders.dart';

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

/// Stands in for the phone's notifications and records what the app asks.
class FakeReminders implements Reminders {
  void Function(String? nodeId)? onOpen;
  var initCalls = 0;
  var permissionRequests = 0;
  var exactAlarmRequests = 0;
  List<ReminderMessage> scheduled = const [];
  bool? lastExact;
  var replaceCalls = 0;

  @override
  Future<void> init(void Function(String? nodeId) onOpen) async {
    initCalls++;
    this.onOpen = onOpen;
  }

  @override
  Future<void> replaceAll(
    List<ReminderMessage> messages, {
    required bool exact,
  }) async {
    replaceCalls++;
    scheduled = messages;
    lastExact = exact;
  }

  @override
  Future<void> askPermission() async => permissionRequests++;

  @override
  Future<void> askExactAlarms() async => exactAlarmRequests++;

  /// Acts as if the user tapped a notification.
  void tap(String? nodeId) => onOpen!(nodeId);
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
  final reminders = FakeReminders();
  late final SahaiDatabase db;
  late final NodeActions actions;

  var _closed = false;

  /// Closes the database. Safe to call more than once.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await db.close();
  }
}
