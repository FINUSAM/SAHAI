import '../engine/recurrence.dart';
import '../engine/set_aside_list.dart';
import '../engine/settings.dart';
import '../engine/time.dart';
import '../engine/tree.dart';
import '../engine/visibility.dart';
import '../features/explorer/explorer_rows.dart';

/// How far ahead reminders are scheduled, and how many at most (tech plan
/// 7, decision 0005). Rescheduling on every start and resume keeps the
/// window moving; an app left unopened for longer misses later ones (R4).
const planHorizon = Duration(days: 60);
const maxPlanned = 100;

/// One notification: the items that come back onto the Summary at [at], or
/// the recurring items reminded at [at]. One item is named; several share a
/// grouped notification (PRD 7).
class PlannedNotification {
  const PlannedNotification({
    required this.at,
    required this.cards,
    this.dueToday,
  });

  /// UTC.
  final DateTime at;
  final List<SummaryCard> cards;

  /// For a recurring reminder, the ids of the [cards] due that day; the
  /// others are on their show day. Null for "is back".
  final Set<String>? dueToday;

  bool get grouped => cards.length > 1;
}

/// Works out the notifications to schedule, assuming nothing else changes
/// (tech plan 7). It steps through the moments the Summary next changes
/// and, at each, takes the cards that newly appear:
///
/// - several at one moment share one notification (AT-050), one is named
///   (AT-051), and different moments notify separately (AT-052);
/// - a card notifies only if something waking at that moment, on it or an
///   ancestor, has Remind me on (AT-053);
/// - an item that wakes but stays hidden under a set-aside ancestor
///   doesn't notify; it comes back, and notifies, when the ancestor does
///   (AT-054);
/// - nothing is planned when notifications are off in Settings (AT-056).
///
/// Recurring items add their own reminders; see [_recurringReminders].
List<PlannedNotification> planNotifications(
  Tree tree, {
  required DateTime now,
  required AppSettings settings,
}) {
  if (!settings.notificationsEnabled) return const [];
  final end = now.add(planHorizon);
  final recurring = _recurringReminders(
    tree,
    now: now,
    end: end,
    settings: settings,
  );
  final remindedAt = {
    for (final n in recurring)
      n.at.millisecondsSinceEpoch: {for (final c in n.cards) c.id},
  };
  final plan = <PlannedNotification>[];
  var previous = computeSummary(tree, now: now, settings: settings);
  var at = previous.nextChangeAt;
  while (at != null && !at.isAfter(end) && plan.length < maxPlanned) {
    final current = computeSummary(tree, now: at, settings: settings);
    final before = previous.visibleIds;
    final moment = at;
    final alreadyReminded = remindedAt[moment.millisecondsSinceEpoch] ?? {};
    final cards = [
      for (final card in current.cards)
        if (!before.contains(card.id) &&
            !alreadyReminded.contains(card.id) &&
            _remindedAt(tree, card, moment))
          card,
    ];
    if (cards.isNotEmpty) {
      plan.add(PlannedNotification(at: moment.toUtc(), cards: cards));
    }
    previous = current;
    at = current.nextChangeAt;
  }
  plan.addAll(recurring);
  plan.sort((a, b) => a.at.compareTo(b.at));
  return plan.take(maxPlanned).toList();
}

/// The reminders to show now because replacing the schedule would otherwise
/// lose them (#77): Android can deliver inexact ones up to an hour late, or
/// more, and [undelivered] holds the times it still hadn't reached.
///
/// Only recurring reminders qualify, for items the Summary can't show. With
/// the app open a card on the Summary needs no reminder, which also rules
/// out "is back": its item is on the Summary, or is hidden again and so
/// doesn't notify (PRD 7). The reminders are worked out again from today's
/// data, so a bill since done, skipped or stopped has none to show.
List<PlannedNotification> lateReminders(
  Tree tree, {
  required List<DateTime> undelivered,
  required DateTime now,
  required AppSettings settings,
}) {
  if (!settings.notificationsEnabled) return const [];
  final late = undelivered.where((at) => !at.isAfter(now)).toList();
  if (late.isEmpty) return const [];
  final moments = {for (final at in late) at.millisecondsSinceEpoch};
  final earliest = late.reduce((a, b) => a.isBefore(b) ? a : b);
  final onSummary = computeSummary(
    tree,
    now: now,
    settings: settings,
  ).visibleIds;
  final today = logicalDate(now, dayStartMinutes: settings.dayStartMinutes);
  final reminders = _recurringReminders(
    tree,
    // That function looks strictly after this time.
    now: earliest.subtract(const Duration(milliseconds: 1)),
    end: now,
    settings: settings,
  )..sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final n in reminders)
      if (moments.contains(n.at.millisecondsSinceEpoch))
        if ([
              for (final c in n.cards)
                if (!onSummary.contains(c.id)) c,
            ]
            case final hidden when hidden.isNotEmpty)
          PlannedNotification(
            at: n.at,
            cards: hidden,
            // Today's rather than the planned day's: it may be shown days
            // later, and "is due today" would then be wrong.
            dueToday: {
              for (final c in hidden)
                if (daysUntilDue(c.node.dueOn!, today) == 0) c.id,
            },
          ),
  ];
}

/// Whether what woke at [at] to bring [card] back asked to be reminded.
bool _remindedAt(Tree tree, SummaryCard card, DateTime at) => [
  card.node,
  ...tree.ancestorsOf(card.id),
].any((n) => (n.snoozeUntil?.isAtSameMomentAs(at) ?? false) && n.remindOnWake);

/// Each recurring item's reminders for its current occurrence, at the
/// reminder time rather than the day start (PRD 7, AT-078), grouped by
/// moment. Marking it done or skipping it replans the next occurrence.
///
/// - On its due date, always: pausing a domain never hides a bill's due date
///   (AT-079), and nor does setting the bill itself aside.
/// - On its show day, unless an ancestor still hides it then (PRD 7). The
///   item being set aside itself doesn't stop this one, by the owner's
///   choice.
/// - With no lead, the two are the same day, so only the due one.
List<PlannedNotification> _recurringReminders(
  Tree tree, {
  required DateTime now,
  required DateTime end,
  required AppSettings settings,
}) {
  DateTime momentOf(DateTime date) => reminderTime(
    date,
    reminderMinutes: settings.reminderMinutes,
    dayStartMinutes: settings.dayStartMinutes,
  );
  final byMoment = <DateTime, List<TreeNode>>{};
  final dueToday = <DateTime, Set<String>>{};

  void add(DateTime moment, TreeNode node, {required bool isDueDay}) {
    if (!moment.isAfter(now) || moment.isAfter(end)) return;
    final at = moment.toUtc();
    (byMoment[at] ??= []).add(node);
    if (isDueDay) (dueToday[at] ??= {}).add(node.id);
  }

  for (final node in inTreeOrder(tree)) {
    final due = node.dueOn;
    if (due == null || !node.isTodo) continue;
    final lead = node.leadDays ?? settings.defaultLeadDays;
    add(momentOf(due), node, isDueDay: true);
    if (lead <= 0) continue;
    final showDay = momentOf(DateTime(due.year, due.month, due.day - lead));
    if (setAsideAncestor(tree, node.id, showDay) == null) {
      add(showDay, node, isDueDay: false);
    }
  }
  return [
    for (final MapEntry(key: at, value: nodes) in byMoment.entries)
      PlannedNotification(
        at: at,
        cards: [for (final n in nodes) SummaryCard.ofRecurring(tree, n)],
        dueToday: dueToday[at] ?? const {},
      ),
  ];
}
