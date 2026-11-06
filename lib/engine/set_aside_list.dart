import 'settings.dart';
import 'tree.dart';

/// [node]'s wake time while it is set aside, or waiting for its show date,
/// which counts as set aside (E-005). Null when it is awake.
DateTime? wakeTimeOf(
  TreeNode node,
  DateTime now, {
  AppSettings settings = const AppSettings(),
}) {
  final until = node.wakeAt(settings);
  return until != null && until.isAfter(now) ? until : null;
}

/// The nearest ancestor of [id] that is set aside, which hides it (PRD 6,
/// check 5), or null.
TreeNode? setAsideAncestor(Tree tree, String id, DateTime now) {
  for (final ancestor in tree.ancestorsOf(id)) {
    if (wakeTimeOf(ancestor, now) != null) return ancestor;
  }
  return null;
}

/// One card on the Set-Aside page.
class SetAsideEntry {
  const SetAsideEntry({
    required this.node,
    required this.wakeAt,
    required this.hidden,
  });

  final TreeNode node;
  final DateTime wakeAt;

  /// What it hides directly: its TODO children, and any streams or
  /// projects in a domain (frame 9's "Hidden until then").
  final List<TreeNode> hidden;
}

/// The Set-Aside page (PRD 8.3): everything set aside directly, soonest
/// first (AT-046), with recurring items waiting for their show date listed
/// once, at whichever time is later (E-005). Something under a set-aside
/// ancestor is listed under that ancestor rather than on its own (AT-047).
List<SetAsideEntry> setAsideEntries(
  Tree tree, {
  required DateTime now,
  AppSettings settings = const AppSettings(),
}) {
  final entries = [
    for (final node in tree.nodes)
      if (wakeTimeOf(node, now, settings: settings) case final wakeAt?
          when setAsideAncestor(tree, node.id, now) == null)
        SetAsideEntry(
          node: node,
          wakeAt: wakeAt,
          hidden: [
            for (final child in tree.childrenOf(node.id))
              if (!child.type.hasStatus || child.isTodo) child,
          ],
        ),
  ];
  entries.sort((a, b) {
    final byTime = a.wakeAt.compareTo(b.wakeAt);
    return byTime != 0 ? byTime : a.node.id.compareTo(b.node.id);
  });
  return entries;
}
