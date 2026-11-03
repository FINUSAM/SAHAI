import 'node_type.dart';
import 'tree.dart';

/// What kind of card an item is shown as (PRD 5, "Card").
enum CardKind { subtask, task, project, streamItem }

/// Why the card is on the Summary, which decides its hint line (frames 3–5).
enum CardReason {
  /// The next single action: a subtask, a stream item, or a task with no
  /// subtasks (AT-014).
  next,

  /// Every subtask is done; the task waits for sign-off (AT-016).
  taskSignOff,

  /// Every task is done; the project waits for sign-off (AT-020).
  projectSignOff,

  /// The project has no tasks yet, so it prompts for one (AT-019).
  emptyProject,
}

/// One item on the Summary Page.
class SummaryCard {
  const SummaryCard({
    required this.node,
    required this.kind,
    required this.reason,
    required this.path,
    required this.ownerId,
    this.groupId,
    this.doneChildren = 0,
    this.unlocks,
  });

  final TreeNode node;
  final CardKind kind;
  final CardReason reason;

  /// Ancestors from the domain down to the parent, for the path line
  /// (AT-029: Domain › Project › Task).
  final List<TreeNode> path;

  /// The project, stream or recurring item that owns this card's slot
  /// (PRD 8.2, used by M5). One card per owner at a time.
  final String ownerId;

  /// The effective context group (PRD 8.2); unused until M5.
  final String? groupId;

  /// For sign-off cards: how many children were done.
  final int doneChildren;

  /// For a task sign-off: the task that unlocks when this one is marked
  /// done, if any.
  final TreeNode? unlocks;

  String get id => node.id;
}

/// The Summary and the next moment it will change on its own.
class SummaryResult {
  const SummaryResult({required this.cards, required this.nextChangeAt});

  final List<SummaryCard> cards;

  /// The earliest future set-aside wake time among items that would change
  /// the Summary, or null when nothing is waiting. Always null in M2, where
  /// nothing is set aside yet; M3 starts a timer for it (AT-034).
  final DateTime? nextChangeAt;

  Set<String> get visibleIds => {for (final c in cards) c.id};
}

/// Computes the Summary from the tree and the time, never from stored
/// state (PRD 6, tech plan 4.2). Cards come out in tree order: domains in
/// order, then each domain's projects and streams in order (M2 wireframe
/// choice; M5 adds saved positions and groups).
SummaryResult computeSummary(Tree tree, {required DateTime now}) {
  final cards = <SummaryCard>[];
  DateTime? nextChangeAt;

  bool isAwake(TreeNode node) {
    final until = node.snoozeUntil;
    if (until == null || !until.isAfter(now)) return true;
    if (nextChangeAt == null || until.isBefore(nextChangeAt!)) {
      nextChangeAt = until;
    }
    return false;
  }

  void addCard({
    required TreeNode node,
    required CardKind kind,
    required CardReason reason,
    required List<TreeNode> path,
    required String ownerId,
    int doneChildren = 0,
    TreeNode? unlocks,
  }) {
    cards.add(
      SummaryCard(
        node: node,
        kind: kind,
        reason: reason,
        path: path,
        ownerId: ownerId,
        groupId: tree.effectiveGroupOf(node.id),
        doneChildren: doneChildren,
        unlocks: unlocks,
      ),
    );
  }

  void visitStream(TreeNode stream, List<TreeNode> path) {
    // Check 5: a set-aside stream hides everything in it.
    if (!isAwake(stream)) return;
    final items = tree.childrenOf(stream.id).where((i) => i.isTodo).toList();
    final itemPath = [...path, stream];
    // Check 6: the lowest-order awake TODO non-recurring item, plus every
    // awake recurring item (PRD 6). Recurring items never block the normal
    // one (AT-065), and an unpaid bill never hides the next (AT-064).
    var normalShown = false;
    for (final item in items) {
      if (item.isRecurring) {
        if (isAwake(item)) {
          addCard(
            node: item,
            kind: CardKind.streamItem,
            reason: CardReason.next,
            path: itemPath,
            ownerId: item.id,
          );
        }
      } else if (!normalShown && isAwake(item)) {
        normalShown = true;
        addCard(
          node: item,
          kind: CardKind.streamItem,
          reason: CardReason.next,
          path: itemPath,
          ownerId: stream.id,
        );
      }
    }
  }

  void visitProject(TreeNode project, List<TreeNode> path) {
    if (!isAwake(project)) return;
    // Check 2: a DONE project shows nothing (AT-020).
    if (!project.isTodo) return;
    final tasks = tree.childrenOf(project.id);
    final current = tree.currentTaskOf(project.id);
    if (current == null) {
      // Check 3 and 6: no TODO tasks, so the project itself is the leaf.
      addCard(
        node: project,
        kind: CardKind.project,
        reason: tasks.isEmpty
            ? CardReason.emptyProject
            : CardReason.projectSignOff,
        path: path,
        ownerId: project.id,
        doneChildren: tasks.length,
      );
      return;
    }
    // A set-aside current task stalls the project: later tasks stay locked
    // and nothing shows (PRD 6, AT-040).
    if (!isAwake(current)) return;
    final taskPath = [...path, project];
    final subtasks = tree.childrenOf(current.id);
    final todoSubtasks = subtasks.where((s) => s.isTodo).toList();
    if (todoSubtasks.isEmpty) {
      // The current task is the leaf: shown directly when it has no
      // subtasks (AT-014), or for sign-off when they're all done (AT-016).
      TreeNode? unlocks;
      for (final task in tasks) {
        if (task.sortOrder > current.sortOrder && task.isTodo) {
          unlocks = task;
          break;
        }
      }
      addCard(
        node: current,
        kind: CardKind.task,
        reason: subtasks.isEmpty ? CardReason.next : CardReason.taskSignOff,
        path: taskPath,
        ownerId: project.id,
        doneChildren: subtasks.length,
        unlocks: unlocks,
      );
      return;
    }
    // Check 6 for subtasks: the awake TODO subtask with the lowest order.
    // If every remaining subtask is set aside, nothing shows (AT-035).
    for (final subtask in todoSubtasks) {
      if (isAwake(subtask)) {
        addCard(
          node: subtask,
          kind: CardKind.subtask,
          reason: CardReason.next,
          path: [...taskPath, current],
          ownerId: project.id,
        );
        return;
      }
    }
  }

  for (final domain in tree.roots) {
    if (domain.type != NodeType.domain) continue;
    // Check 1 and 5: domains never appear, and a set-aside domain hides
    // everything below it.
    if (!isAwake(domain)) continue;
    final path = [domain];
    for (final child in tree.childrenOf(domain.id)) {
      switch (child.type) {
        case NodeType.project:
          visitProject(child, path);
        case NodeType.stream:
          visitStream(child, path);
        case NodeType.domain:
        case NodeType.streamItem:
        case NodeType.task:
        case NodeType.subtask:
          // Can't sit under a domain (PRD 4); ignored rather than trusted.
          break;
      }
    }
  }

  return SummaryResult(cards: cards, nextChangeAt: nextChangeAt);
}
