/// The items the user moved to turn [before] into [after]: the fewest that
/// explain the change. The rest keep their order relative to each other and
/// only shifted to make room, so they don't count as moved (E-015).
///
/// Both lists hold the same ids. Uses a longest increasing subsequence of
/// the old positions, so it stays fast for long lists.
List<String> movedIds(List<String> before, List<String> after) {
  final oldIndex = {for (var i = 0; i < before.length; i++) before[i]: i};
  final seq = [for (final id in after) oldIndex[id]!];
  // tails[k]: index in seq of the smallest tail of an increasing run of
  // length k + 1. parent links each element to the one before it in its run.
  final tails = <int>[];
  final parent = List<int>.filled(seq.length, -1);
  for (var i = 0; i < seq.length; i++) {
    var lo = 0;
    var hi = tails.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (seq[tails[mid]] < seq[i]) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0) parent[i] = tails[lo - 1];
    if (lo == tails.length) {
      tails.add(i);
    } else {
      tails[lo] = i;
    }
  }
  final kept = <int>{};
  for (var i = tails.isEmpty ? -1 : tails.last; i != -1; i = parent[i]) {
    kept.add(i);
  }
  return [
    for (var i = 0; i < after.length; i++)
      if (!kept.contains(i)) after[i],
  ];
}
