/// Which items newly appeared on, or left, the Summary (PRD 9, `surfaced`).
class SurfacedDiff {
  const SurfacedDiff({required this.appeared, required this.disappeared});

  /// Items on the new Summary that weren't on the previous one, in Summary
  /// order. Each gets a `surfaced` event.
  final List<String> appeared;

  /// Items that were on the previous Summary and aren't any more.
  final List<String> disappeared;

  bool get isEmpty => appeared.isEmpty && disappeared.isEmpty;
}

/// Compares the previous visible set with the new one (tech plan 4.5).
///
/// Pure, so the caller decides the time each appearance gets: the action's
/// time in M2, or the wake time that made the item visible when the app was
/// closed (E-002, M3). Items in [suppress] are left out of [appeared]: Undo
/// of a completion restores a card as if the tap never happened, so it gets
/// no new `surfaced` event (E-001).
SurfacedDiff diffVisible({
  required Set<String> previous,
  required List<String> current,
  Set<String> suppress = const {},
}) {
  final now = current.toSet();
  return SurfacedDiff(
    appeared: [
      for (final id in current)
        if (!previous.contains(id) && !suppress.contains(id)) id,
    ],
    disappeared: [
      for (final id in previous)
        if (!now.contains(id)) id,
    ],
  );
}
