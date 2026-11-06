import '../engine/settings.dart';
import '../engine/tree.dart';
import '../engine/visibility.dart';

/// How far ahead reminders are scheduled, and how many at most (tech plan
/// 7, decision 0005). Rescheduling on every start and resume keeps the
/// window moving; an app left unopened for longer misses later ones (R4).
const planHorizon = Duration(days: 60);
const maxPlanned = 100;

/// One notification: the items that come back onto the Summary at [at].
/// One item is named; several share a grouped notification (PRD 7).
class PlannedNotification {
  const PlannedNotification({required this.at, required this.cards});

  /// UTC.
  final DateTime at;
  final List<SummaryCard> cards;

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
List<PlannedNotification> planNotifications(
  Tree tree, {
  required DateTime now,
  required AppSettings settings,
}) {
  if (!settings.notificationsEnabled) return const [];
  final end = now.add(planHorizon);
  final plan = <PlannedNotification>[];
  var previous = computeSummary(tree, now: now, settings: settings);
  var at = previous.nextChangeAt;
  while (at != null && !at.isAfter(end) && plan.length < maxPlanned) {
    final current = computeSummary(tree, now: at, settings: settings);
    final before = previous.visibleIds;
    final moment = at;
    final cards = [
      for (final card in current.cards)
        if (!before.contains(card.id) && _remindedAt(tree, card, moment)) card,
    ];
    if (cards.isNotEmpty) {
      plan.add(PlannedNotification(at: moment.toUtc(), cards: cards));
    }
    previous = current;
    at = current.nextChangeAt;
  }
  return plan;
}

/// Whether what woke at [at] to bring [card] back asked to be reminded.
bool _remindedAt(Tree tree, SummaryCard card, DateTime at) => [
  card.node,
  ...tree.ancestorsOf(card.id),
].any((n) => (n.snoozeUntil?.isAtSameMomentAs(at) ?? false) && n.remindOnWake);
