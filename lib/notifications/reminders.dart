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

/// Where the ids of late reminders start, clear of the scheduled ones
/// (at most [maxPlanned]). Android replaces a notification that reuses an id,
/// so a scheduled reminder would otherwise overwrite one shown late.
const firstLateId = 1000;

/// What a reminder carries for when it's tapped or found still undelivered:
/// its time, because Android's pending list gives no time, and its item.
String reminderPayload(ReminderMessage m) =>
    '${m.at.millisecondsSinceEpoch}|${m.nodeId ?? ''}';

/// The time in [payload]. Null for one saved before reminders carried it.
DateTime? timeOfPayload(String? payload) {
  final bar = payload?.indexOf('|') ?? -1;
  if (bar < 0) return null;
  final millis = int.tryParse(payload!.substring(0, bar));
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

/// The item in [payload], or null for a grouped reminder. A notification
/// already in the shade from an older version holds only the item id.
String? nodeIdOfPayload(String? payload) {
  if (payload == null) return null;
  final id = payload.substring(payload.indexOf('|') + 1);
  return id.isEmpty ? null : id;
}

/// Words the plan (frame 13): one item is "<title> is back" with its path;
/// several are "3 items are back", expanding to list them. Recurring
/// reminders read "<title> is due Nov 5" or "<title> is due today", and "2
/// items are due today" (M4 frame 10). When a group's dates differ it says
/// "2 items are due", and each line gives its own date.
List<ReminderMessage> messagesFor(
  Tree tree,
  List<PlannedNotification> plan, {
  int firstId = 0,
}) => [
  for (final (i, n) in plan.indexed)
    if (n.dueToday case final dueToday?)
      _dueMessage(tree, firstId + i, n, dueToday)
    else if (n.grouped)
      ReminderMessage(
        id: firstId + i,
        at: n.at,
        title: Strings.itemsBack(n.cards.length),
        body: n.cards.map((c) => displayTitle(tree, c.node)).join(', '),
        lines: [for (final c in n.cards) displayTitle(tree, c.node)],
        nodeId: null,
      )
    else
      ReminderMessage(
        id: firstId + i,
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

  /// The times of the reminders Android hasn't delivered yet. Read before
  /// [replaceAll], which cancels them: any whose time has passed is late.
  Future<List<DateTime>> undelivered();

  /// Shows [messages] now rather than at their time.
  Future<void> showNow(List<ReminderMessage> messages);

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
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_sahai'),
      ),
      onDidReceiveNotificationResponse: (r) =>
          onOpen(nodeIdOfPayload(r.payload)),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      onOpen(nodeIdOfPayload(launch!.notificationResponse?.payload));
    }
  }

  NotificationDetails _detailsOf(ReminderMessage m) => NotificationDetails(
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
  );

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
          notificationDetails: _detailsOf(m),
          androidScheduleMode: mode,
          title: m.title,
          body: m.body,
          payload: reminderPayload(m),
        );
      } on Exception catch (e) {
        // The type only: messages hold item titles, which are never logged.
        debugPrint('Reminder not scheduled: ${e.runtimeType}');
      }
    }
  }

  @override
  Future<List<DateTime>> undelivered() async {
    try {
      // The plugin takes a one-off reminder off this list when it fires, so
      // whatever is here hasn't reached the phone's shade.
      final pending = await _plugin.pendingNotificationRequests();
      return [for (final p in pending) ?timeOfPayload(p.payload)];
    } on Exception catch (e) {
      // Scheduling matters more than a late reminder, so it carries on.
      debugPrint('Pending reminders not read: ${e.runtimeType}');
      return const [];
    }
  }

  @override
  Future<void> showNow(List<ReminderMessage> messages) async {
    for (final m in messages) {
      try {
        await _plugin.show(
          id: m.id,
          title: m.title,
          body: m.body,
          notificationDetails: _detailsOf(m),
          payload: reminderPayload(m),
        );
      } on Exception catch (e) {
        // The type only: messages hold item titles, which are never logged.
        debugPrint('Reminder not shown: ${e.runtimeType}');
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
