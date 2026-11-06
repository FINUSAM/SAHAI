import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../engine/tree.dart';
import '../engine/visibility.dart';
import '../features/explorer/explorer_rows.dart';
import '../shared/strings.dart';
import '../shared/time_format.dart';
import 'planner.dart';

/// One scheduled notification, worded and ready to hand to Android.
class ReminderMessage {
  const ReminderMessage({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.lines,
    required this.nodeId,
  });

  final int id;

  /// UTC.
  final DateTime at;
  final String title;
  final String body;

  /// For a grouped notification, one line per item when expanded.
  final List<String> lines;

  /// The item a tap opens; null for a grouped one, which opens the Summary.
  final String? nodeId;
}

/// Words the plan (frame 13): one item is "<title> is back" with its path;
/// several are "3 items are back", expanding to list them. Recurring
/// reminders read "<title> is due Nov 5" or "<title> is due today", and "2
/// items are due today" (M4 frame 10). When a group's dates differ it says
/// "2 items are due", and each line gives its own date.
List<ReminderMessage> messagesFor(Tree tree, List<PlannedNotification> plan) =>
    [
      for (final (i, n) in plan.indexed)
        if (n.dueToday case final dueToday?)
          _dueMessage(tree, i, n, dueToday)
        else if (n.grouped)
          ReminderMessage(
            id: i,
            at: n.at,
            title: Strings.itemsBack(n.cards.length),
            body: n.cards.map((c) => displayTitle(tree, c.node)).join(', '),
            lines: [for (final c in n.cards) displayTitle(tree, c.node)],
            nodeId: null,
          )
        else
          ReminderMessage(
            id: i,
            at: n.at,
            title: Strings.isBack(displayTitle(tree, n.cards.single.node)),
            body: _pathOf(tree, n.cards.single),
            lines: const [],
            nodeId: n.cards.single.id,
          ),
    ];

ReminderMessage _dueMessage(
  Tree tree,
  int id,
  PlannedNotification n,
  Set<String> dueToday,
) {
  if (!n.grouped) {
    final card = n.cards.single;
    final title = displayTitle(tree, card.node);
    return ReminderMessage(
      id: id,
      at: n.at,
      title: dueToday.contains(card.id)
          ? Strings.isDueToday(title)
          : Strings.isDueOn(title, monthDay(card.node.dueOn!)),
      body: _pathOf(tree, card),
      lines: const [],
      nodeId: card.id,
    );
  }
  final allToday = n.cards.every((c) => dueToday.contains(c.id));
  final lines = [
    for (final c in n.cards)
      allToday
          ? displayTitle(tree, c.node)
          : Strings.dueLine(
              displayTitle(tree, c.node),
              dueToday.contains(c.id)
                  ? Strings.dueToday
                  : Strings.dueOn(monthDay(c.node.dueOn!)),
            ),
  ];
  return ReminderMessage(
    id: id,
    at: n.at,
    title: allToday
        ? Strings.itemsDueToday(n.cards.length)
        : Strings.itemsDue(n.cards.length),
    body: lines.join(', '),
    lines: lines,
    nodeId: null,
  );
}

String _pathOf(Tree tree, SummaryCard card) =>
    card.path.map((a) => displayTitle(tree, a)).join(Strings.pathSeparator);

/// The phone's notifications, behind an interface so tests use a fake and
/// never touch the real ones.
abstract interface class Reminders {
  /// Sets up the channel and tap handling. [onOpen] gets the tapped
  /// notification's item id, or null for a grouped one, including when the
  /// tap is what started the app.
  Future<void> init(void Function(String? nodeId) onOpen);

  /// Replaces every scheduled reminder with [messages]. Exact timing only
  /// when [exact] and Android allows it (AT-058); otherwise Android may
  /// deliver a few minutes late (PRD 7).
  Future<void> replaceAll(
    List<ReminderMessage> messages, {
    required bool exact,
  });

  /// Asks for notification permission on Android 13 and higher. Android
  /// shows nothing when it's already granted or refused for good.
  Future<void> askPermission();

  /// Opens Android's "Alarms and reminders" screen for Exact reminders.
  Future<void> askExactAlarms();
}

/// [Reminders] on Android through flutter_local_notifications.
class PluginReminders implements Reminders {
  PluginReminders({this._clock = const Clock()});

  final Clock _clock;
  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static const _channelId = 'reminders';

  @override
  Future<void> init(void Function(String? nodeId) onOpen) async {
    String? idOf(String? payload) =>
        payload == null || payload.isEmpty ? null : payload;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_sahai'),
      ),
      onDidReceiveNotificationResponse: (r) => onOpen(idOf(r.payload)),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      onOpen(idOf(launch!.notificationResponse?.payload));
    }
  }

  @override
  Future<void> replaceAll(
    List<ReminderMessage> messages, {
    required bool exact,
  }) async {
    // Pending only: notifications already in the shade stay there.
    await _plugin.cancelAllPendingNotifications();
    final canExact =
        exact && (await _android?.canScheduleExactNotifications() ?? false);
    final mode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final m in messages) {
      // Android refuses a time already past; the next recompute catches it.
      if (!m.at.isAfter(_clock.now())) continue;
      try {
        await _plugin.zonedSchedule(
          id: m.id,
          // Set-aside times are fixed moments, so UTC needs no zone data.
          scheduledDate: tz.TZDateTime.from(m.at, tz.UTC),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              Strings.remindersChannel,
              channelDescription: Strings.remindersChannelDescription,
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: m.lines.isEmpty
                  ? BigTextStyleInformation(m.body)
                  : InboxStyleInformation(m.lines, contentTitle: m.title),
            ),
          ),
          androidScheduleMode: mode,
          title: m.title,
          body: m.body,
          payload: m.nodeId ?? '',
        );
      } on Exception catch (e) {
        // The type only: messages hold item titles, which are never logged.
        debugPrint('Reminder not scheduled: ${e.runtimeType}');
      }
    }
  }

  @override
  Future<void> askPermission() async {
    await _android?.requestNotificationsPermission();
  }

  @override
  Future<void> askExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }
}
