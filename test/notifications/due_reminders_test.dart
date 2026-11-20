import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/due.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/engine/visibility.dart';
import 'package:sahai/notifications/planner.dart';
import 'package:sahai/notifications/reminders.dart';

import '../engine/engine_helpers.dart';

/// Reminders for one-off due dates (E-019, M7 frame 25). Times are local, as
/// the rules are. It starts on Monday, Nov 9, 2026, at 10:00 AM, with the
/// default Reminder time of 9:00 AM.
void main() {
  const on = AppSettings();
  final start = DateTime(2026, 11, 9, 10);

  /// Biztras › Sales with 1. Send proposal to Acme, due Fri, Nov 20, and 2.
  /// Follow up, which waits behind it.
  TreeBuilder sales({
    DueReminder reminder = DueReminder.onTheDay,
    DateTime? biztrasUntil,
    bool done = false,
    String dueItem = 'Send proposal to Acme',
  }) {
    final b = TreeBuilder()
      ..add(NodeType.domain, 'Biztras', snoozeUntil: biztrasUntil)
      ..add(NodeType.project, 'Sales', parent: 'Biztras');
    for (final task in ['Send proposal to Acme', 'Follow up']) {
      b.add(
        NodeType.task,
        task,
        parent: 'Sales',
        done: done && task == dueItem,
        oneOffDue: task == dueItem ? DateTime(2026, 11, 20) : null,
        dueReminder: reminder,
      );
    }
    return b;
  }

  String kindOf(PlannedNotification n) {
    final today = n.dueToday;
    if (today == null) return 'back';
    return today.isEmpty ? 'early' : 'due';
  }

  /// "17 9:00 early: Send proposal to Acme", one per notification.
  List<String> reminders(TreeBuilder b, {DateTime? from}) => [
    for (final n in planNotifications(
      b.build(),
      now: from ?? start,
      settings: on,
    ))
      '${n.at.toLocal().day} ${n.at.toLocal().hour}:'
          '${n.at.toLocal().minute.toString().padLeft(2, '0')} ${kindOf(n)}: '
          '${n.cards.map((c) => c.id).join(', ')}',
  ];

  List<String> titles(TreeBuilder b) {
    final tree = b.build();
    return [
      for (final m in messagesFor(
        tree,
        planNotifications(tree, now: start, settings: on),
      ))
        m.title,
    ];
  }

  test('On the day reminds once, at the Reminder time on the due day', () {
    expect(reminders(sales()), ['20 9:00 due: Send proposal to Acme']);
    expect(titles(sales()), ['1. Send proposal to Acme is due today']);
  });

  test('AT-130 an early reminder, then one on the day', () {
    final b = sales(reminder: DueReminder.threeDaysBefore);
    expect(reminders(b), [
      '17 9:00 early: Send proposal to Acme',
      '20 9:00 due: Send proposal to Acme',
    ]);
    expect(titles(b), [
      '1. Send proposal to Acme is due Fri, Nov 20',
      '1. Send proposal to Acme is due today',
    ]);
    // After the early one, only the day's is left.
    expect(reminders(b, from: DateTime(2026, 11, 17, 10)), [
      '20 9:00 due: Send proposal to Acme',
    ]);
  });

  test('AT-130 the other choices: a day and a week before', () {
    expect(reminders(sales(reminder: DueReminder.dayBefore)), [
      '19 9:00 early: Send proposal to Acme',
      '20 9:00 due: Send proposal to Acme',
    ]);
    expect(reminders(sales(reminder: DueReminder.weekBefore)), [
      '13 9:00 early: Send proposal to Acme',
      '20 9:00 due: Send proposal to Acme',
    ]);
  });

  test('AT-130 with No reminder, or once it is done, nothing arrives', () {
    expect(reminders(sales(reminder: DueReminder.none)), isEmpty);
    expect(
      reminders(sales(reminder: DueReminder.threeDaysBefore, done: true)),
      isEmpty,
    );
  });

  test('AT-129 the reminder gets through a set-aside area, and the item '
      'stays off the Summary', () {
    final b = sales(biztrasUntil: DateTime(2026, 11, 23, 8));
    // Biztras coming back on Nov 23 is its own reminder, as before.
    expect(reminders(b), [
      '20 9:00 due: Send proposal to Acme',
      '23 8:00 back: Send proposal to Acme',
    ]);
    final atNine = computeSummary(
      b.build(),
      now: DateTime(2026, 11, 20, 9),
      settings: on,
    );
    expect(atNine.visibleIds, isNot(contains('Send proposal to Acme')));
  });

  test('a task waiting behind an earlier step is reminded too', () {
    final b = sales(dueItem: 'Follow up');
    expect(reminders(b), ['20 9:00 due: Follow up']);
    expect(
      computeSummary(b.build(), now: start, settings: on).visibleIds,
      isNot(contains('Follow up')),
    );
  });

  test('a Reminder time before Day starts belongs to the next calendar day, '
      'as a bill\'s does', () {
    const late = AppSettings(reminderMinutes: 60, dayStartMinutes: 4 * 60);
    final plan = planNotifications(sales().build(), now: start, settings: late);
    expect(plan.single.at, DateTime(2026, 11, 21, 1).toUtc());
  });

  test('reminders due together share one notification, each line with its '
      'date (frame 25)', () {
    final b = sales()
      ..add(NodeType.domain, 'Personal')
      ..add(NodeType.stream, 'Finance', parent: 'Personal')
      ..add(
        NodeType.streamItem,
        'Pay SBI card',
        parent: 'Finance',
        dueOn: DateTime(2026, 11, 20),
        leadDays: 0,
      )
      ..add(NodeType.stream, 'Events', parent: 'Personal')
      ..add(
        NodeType.streamItem,
        'Book the venue',
        parent: 'Events',
        oneOffDue: DateTime(2026, 11, 23),
        dueReminder: DueReminder.threeDaysBefore,
      );
    final tree = b.build();
    final grouped = messagesFor(
      tree,
      planNotifications(tree, now: start, settings: on),
    ).firstWhere((m) => m.nodeId == null);
    expect(grouped.at, DateTime(2026, 11, 20, 9).toUtc());
    expect(grouped.title, '3 items are due');
    expect(grouped.lines, [
      '1. Send proposal to Acme · Due today',
      'Pay SBI card · Due today',
      'Book the venue · Due Mon, Nov 23',
    ]);
  });
}
