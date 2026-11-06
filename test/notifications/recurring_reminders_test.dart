import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/notifications/planner.dart';
import 'package:sahai/notifications/reminders.dart';

import '../engine/engine_helpers.dart';

/// Which reminders a recurring item gets and how they read (PRD 7, M4
/// frame 10, and the owner's decisions recorded in plan 0006). Times are
/// local, as the rules are. It starts on Sunday, Nov 1, at 10:00 AM.
void main() {
  const on = AppSettings();
  final start = DateTime(2026, 11, 1, 10);
  DateTime nov(int day, [int hour = 9]) => DateTime(2026, 11, day, hour);

  /// Personal › Finance with HDFC, due Nov 5, showing 3 days early.
  TreeBuilder bills({
    DateTime? personalUntil,
    DateTime? hdfcUntil,
    int lead = 3,
    bool remind = true,
  }) => TreeBuilder()
    ..add(NodeType.domain, 'personal', snoozeUntil: personalUntil)
    ..add(NodeType.stream, 'finance', parent: 'personal')
    ..add(
      NodeType.streamItem,
      'HDFC',
      parent: 'finance',
      dueOn: DateTime(2026, 11, 5),
      leadDays: lead,
      snoozeUntil: hdfcUntil,
      remind: remind,
    );

  String kindOf(PlannedNotification n) {
    final today = n.dueToday;
    if (today == null) return 'back';
    return today.isEmpty ? 'show' : 'due';
  }

  /// "5 9:00 due: HDFC", in local time, one per notification.
  List<String> reminders(
    TreeBuilder b, {
    DateTime? from,
    AppSettings settings = on,
  }) => [
    for (final n in planNotifications(
      b.build(),
      now: from ?? start,
      settings: settings,
    ))
      [
        n.at.toLocal().day,
        ' ',
        n.at.toLocal().hour,
        ':',
        n.at.toLocal().minute.toString().padLeft(2, '0'),
        ' ',
        kindOf(n),
        ': ',
        n.cards.map((c) => c.id).join(', '),
      ].join(),
  ];

  test('AT-078 two reminders at the reminder time, not the day start', () {
    expect(reminders(bills()), ['2 9:00 show: HDFC', '5 9:00 due: HDFC']);
    final plan = planNotifications(bills().build(), now: start, settings: on);
    expect(plan.first.at, nov(2).toUtc());
    expect(plan.last.at, nov(5).toUtc());
  });

  test('AT-078 only what is still ahead is planned', () {
    expect(reminders(bills(), from: nov(2, 10)), ['5 9:00 due: HDFC']);
    expect(reminders(bills(), from: nov(5, 10)), isEmpty);
  });

  test('the reminder time comes from Settings', () {
    expect(
      reminders(
        bills(),
        settings: const AppSettings(reminderMinutes: 8 * 60 + 30),
      ),
      ['2 8:30 show: HDFC', '5 8:30 due: HDFC'],
    );
  });

  test('a reminder time before the day start ends that logical day', () {
    expect(
      reminders(bills(), settings: const AppSettings(reminderMinutes: 120)),
      ['3 2:00 show: HDFC', '6 2:00 due: HDFC'],
    );
  });

  test('AT-079 the due reminder fires inside a paused domain, and the '
      'show-day one does not', () {
    expect(reminders(bills(personalUntil: nov(10, 8))), [
      '5 9:00 due: HDFC',
      '10 8:00 back: HDFC',
    ]);
  });

  test('a domain back before the show day leaves the show-day reminder', () {
    expect(reminders(bills(personalUntil: nov(2, 8))), [
      '2 8:00 back: HDFC',
      '2 9:00 show: HDFC',
      '5 9:00 due: HDFC',
    ]);
  });

  test('a bill set aside past its show day keeps that reminder and adds "is '
      'back" when it wakes (owner decision 1, AT-072)', () {
    expect(reminders(bills(hdfcUntil: nov(4, 8))), [
      '2 9:00 show: HDFC',
      '4 8:00 back: HDFC',
      '5 9:00 due: HDFC',
    ]);
  });

  test('Remind me off silences only "is back"', () {
    expect(reminders(bills(hdfcUntil: nov(4, 8), remind: false)), [
      '2 9:00 show: HDFC',
      '5 9:00 due: HDFC',
    ]);
  });

  test('a bill set aside past its due date still gets the due reminder '
      '(owner decision 2)', () {
    expect(reminders(bills(hdfcUntil: nov(7, 8))), [
      '2 9:00 show: HDFC',
      '5 9:00 due: HDFC',
      '7 8:00 back: HDFC',
    ]);
  });

  test('no lead means one reminder, not two (owner decision 3)', () {
    expect(reminders(bills(lead: 0)), ['5 9:00 due: HDFC']);
  });

  test('waking at the reminder time gives one reminder, not two', () {
    expect(reminders(bills(hdfcUntil: nov(5))), [
      '2 9:00 show: HDFC',
      '5 9:00 due: HDFC',
    ]);
  });

  test('bills at the same moment share one notification', () {
    final b = bills()
      ..add(
        NodeType.streamItem,
        'SBI',
        parent: 'finance',
        dueOn: DateTime(2026, 11, 5),
      )
      ..add(
        NodeType.streamItem,
        'Axis',
        parent: 'finance',
        dueOn: DateTime(2026, 11, 8),
      );
    expect(reminders(b), [
      '2 9:00 show: HDFC, SBI',
      '5 9:00 due: HDFC, SBI, Axis',
      '8 9:00 due: Axis',
    ]);
    final mixed = planNotifications(b.build(), now: start, settings: on)[1];
    expect(mixed.dueToday, {'HDFC', 'SBI'});
  });

  test('AT-056 nothing is planned with notifications off', () {
    expect(
      reminders(
        bills(),
        settings: const AppSettings(notificationsEnabled: false),
      ),
      isEmpty,
    );
  });

  test('a date past the 60-day window waits for a later plan', () {
    final b = TreeBuilder()
      ..add(NodeType.domain, 'd')
      ..add(NodeType.stream, 's', parent: 'd')
      ..add(
        NodeType.streamItem,
        'far',
        parent: 's',
        dueOn: DateTime(2027, 3, 1),
      );
    expect(reminders(b), isEmpty);
  });

  group('wording (frame 10)', () {
    /// HDFC due Nov 5; [more] adds bills as title and due day.
    List<ReminderMessage> messages([Map<String, int> more = const {}]) {
      final b = TreeBuilder()
        ..add(NodeType.domain, 'Personal')
        ..add(NodeType.stream, 'Finance', parent: 'Personal')
        ..add(
          NodeType.streamItem,
          'Pay HDFC card',
          parent: 'Finance',
          dueOn: DateTime(2026, 11, 5),
        );
      for (final MapEntry(key: title, value: day) in more.entries) {
        b.add(
          NodeType.streamItem,
          title,
          parent: 'Finance',
          dueOn: DateTime(2026, 11, day),
        );
      }
      final tree = b.build();
      return messagesFor(
        tree,
        planNotifications(tree, now: start, settings: on),
      );
    }

    test('the show day gives the date, the due day says today', () {
      final [show, due] = messages();
      expect(show.title, 'Pay HDFC card is due Nov 5');
      expect(show.body, 'Personal › Finance');
      expect(show.nodeId, 'Pay HDFC card');
      expect(due.title, 'Pay HDFC card is due today');
      expect(due.body, 'Personal › Finance');
      expect(due.nodeId, 'Pay HDFC card');
    });

    test('several due today are counted and listed, and open the Summary', () {
      final due = messages({'Water the plants': 5})[1];
      expect(due.title, '2 items are due today');
      expect(due.lines, ['Pay HDFC card', 'Water the plants']);
      expect(due.nodeId, isNull);
    });

    test('a group with different dates gives each its own (owner decision '
        '4)', () {
      final mixed = messages({'Pay Axis card': 8})[1];
      expect(mixed.title, '2 items are due');
      expect(mixed.lines, [
        'Pay HDFC card · Due today',
        'Pay Axis card · Due Nov 8',
      ]);
      expect(mixed.nodeId, isNull);
    });
  });
}
