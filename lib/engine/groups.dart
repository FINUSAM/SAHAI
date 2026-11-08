import 'visibility.dart';

/// The group setting that stops inheritance: the node and everything that
/// follows it go in the default list, whatever its ancestors have (E-013).
/// Stored in `nodes.group_id` like a group id; a UUID can never equal it
/// (decision 0006).
const noGroup = 'none';

/// A user-created context group (PRD 8.2).
class ContextGroup {
  const ContextGroup({
    required this.id,
    required this.name,
    this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;

  /// One of the app's fixed icon names, or null for none.
  final String? icon;

  /// The group's place on the Summary and in Settings.
  final int sortOrder;
}

/// A saved Summary position for one owner: a project, a stream or a
/// recurring item (PRD 8.2, tech plan 4.6).
class SummarySlot {
  const SummarySlot({
    required this.ownerId,
    required this.groupId,
    required this.position,
  });

  final String ownerId;

  /// The group the slot is in; null for the default list.
  final String? groupId;

  /// Order within the group. Gaps are normal: only the order matters.
  final int position;
}

/// One group's cards on the Summary, in their saved order.
class SummarySection {
  const SummarySection({required this.group, required this.cards});

  /// Null for the default list ("No group").
  final ContextGroup? group;
  final List<SummaryCard> cards;
}

/// Lays the Summary out in groups (PRD 8.2): groups in their order, then the
/// default list last. Groups with no cards are left out (AT-084). Within a
/// group, cards follow their slot's position; a card whose slot isn't in
/// that group yet goes after the others, in tree order, which is where the
/// next write puts it (AT-089, AT-090).
List<SummarySection> arrangeSummary(
  List<SummaryCard> cards, {
  required Iterable<ContextGroup> groups,
  required Map<String, SummarySlot> slots,
}) {
  final ordered = [...groups]
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  final known = {for (final g in ordered) g.id};
  final byGroup = <String?, List<(int, SummaryCard)>>{};
  for (var i = 0; i < cards.length; i++) {
    final card = cards[i];
    final group = known.contains(card.groupId) ? card.groupId : null;
    (byGroup[group] ??= []).add((i, card));
  }

  List<SummaryCard> sorted(String? groupId) {
    final entries = byGroup[groupId] ?? const [];
    int? positionOf(SummaryCard card) {
      final slot = slots[card.ownerId];
      return slot != null && slot.groupId == groupId ? slot.position : null;
    }

    final list = [...entries]
      ..sort((a, b) {
        final pa = positionOf(a.$2);
        final pb = positionOf(b.$2);
        if (pa != null && pb != null && pa != pb) return pa.compareTo(pb);
        if (pa != null && pb == null) return -1;
        if (pa == null && pb != null) return 1;
        return a.$1.compareTo(b.$1);
      });
    return [for (final e in list) e.$2];
  }

  return [
    for (final group in ordered)
      if (byGroup.containsKey(group.id))
        SummarySection(group: group, cards: sorted(group.id)),
    if (byGroup.containsKey(null))
      SummarySection(group: null, cards: sorted(null)),
  ];
}
