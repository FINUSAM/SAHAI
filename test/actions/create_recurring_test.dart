import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/recurrence.dart';
import 'package:sahai/engine/settings.dart';

import '../helpers.dart';

/// Creating a stream item that repeats from the start (M4 frames 2, 3).
void main() {
  late TestApp app;
  late String personal, home;

  setUp(() async {
    app = TestApp(clock: TestClock(DateTime(2026, 11, 1, 10)));
    personal = await app.actions.create(
      type: NodeType.domain,
      title: 'Personal',
    );
    home = await app.actions.create(
      type: NodeType.stream,
      parentId: personal,
      title: 'Home',
    );
  });

  tearDown(() => app.close());

  Future<String> createBill() => app.actions.create(
    type: NodeType.streamItem,
    parentId: home,
    title: 'Electricity bill',
    schedule: Schedule.monthly(day: 20),
    dueOn: DateTime(2026, 11, 20),
  );

  test(
    'it repeats from the start, with the Settings lead by default',
    () async {
      final id = await createBill();
      final node = (await app.actions.loadTree())[id]!;
      expect(node.isRecurring, isTrue);
      expect(node.dueOn, DateTime(2026, 11, 20));
      expect(node.leadDays, const AppSettings().defaultLeadDays);
    },
  );

  test('a bill waiting for its show date never surfaces', () async {
    final id = await createBill();
    final rows = await (app.db.select(
      app.db.events,
    )..where((e) => e.nodeId.equals(id))).get();
    expect(rows.map((r) => r.eventType), [EventTypes.created]);
  });

  test('anything but a stream item is refused', () async {
    await expectLater(
      app.actions.create(
        type: NodeType.project,
        parentId: personal,
        title: 'Move house',
        schedule: Schedule.monthly(day: 20),
        dueOn: DateTime(2026, 11, 20),
      ),
      throwsA(
        isA<ActionRejected>().having(
          (e) => e.reason,
          'reason',
          RejectReason.cantRepeat,
        ),
      ),
    );
  });
}
