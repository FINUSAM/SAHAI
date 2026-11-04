import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';
import '../engine/node_type.dart';
import '../engine/scope.dart';
import '../engine/surfaced.dart';
import '../engine/time.dart';
import '../engine/tree.dart';
import '../engine/visibility.dart';
import '../shared/ids.dart';
import '../shared/time.dart';

/// Activity log event types written by these actions (PRD 9).
abstract final class EventTypes {
  static const created = 'created';
  static const completed = 'completed';
  static const reopened = 'reopened';
  static const deleted = 'deleted';
  static const restored = 'restored';

  /// The item appeared on the Summary (PRD 9; E-002 for the time it uses).
  static const surfaced = 'surfaced';

  /// Undo after completing. The `completed` event stays; this one points at
  /// it (E-001).
  static const completionUndone = 'completion_undone';

  /// The payload holds the wake time, the preset or custom, Remind me and
  /// the level chosen (PRD 9, AT-059).
  static const setAside = 'set_aside';

  /// The payload's `cause` is `automatic` or `wake_now` (PRD 9, AT-060).
  static const woke = 'woke';
}

/// Why an item woke, stored in the `woke` event (AT-060).
abstract final class WakeCause {
  static const automatic = 'automatic';
  static const wakeNow = 'wake_now';
}

/// Why an action was refused. The UI turns these into messages.
enum RejectReason {
  notFound,
  emptyTitle,
  invalidParent,
  noStatus,
  lockedTask,
  hasTodoChildren,
  alreadyDone,
  notDone,

  /// A set-aside time that isn't in the future (AT-045).
  pastWakeTime,

  /// Wake now or Change time on something that isn't set aside.
  notSetAside,
}

class ActionRejected implements Exception {
  const ActionRejected(this.reason);

  final RejectReason reason;

  @override
  String toString() => 'ActionRejected(${reason.name})';
}

/// The only code that changes nodes. Each public method is one transaction
/// that updates rows and writes its activity log event together, so a crash
/// leaves all of it or none of it (PRD 13).
class NodeActions {
  NodeActions(this._db, {this._clock = const Clock(), this._newId = newUuid});

  final SahaiDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  /// The non-deleted tree.
  Future<Tree> loadTree() async =>
      Tree((await _liveNodes().get()).map(_toTreeNode));

  /// The non-deleted tree, emitted again after every change, so screens
  /// stay up to date without refreshing by hand.
  Stream<Tree> watchTree() =>
      _liveNodes().watch().map((rows) => Tree(rows.map(_toTreeNode)));

  /// Creates a node at the end of its parent's children (AT-001, AT-002).
  Future<String> create({
    required NodeType type,
    String? parentId,
    required String title,
    String notes = '',
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const ActionRejected(RejectReason.emptyTitle);
    }
    return _write(() async {
      final tree = await loadTree();
      final parent = parentId == null ? null : tree[parentId];
      if (parentId != null && parent == null) {
        throw const ActionRejected(RejectReason.notFound);
      }
      if (!canHaveChild(parent?.type, type)) {
        throw const ActionRejected(RejectReason.invalidParent);
      }
      final id = _newId();
      final now = utcMillis(_clock);
      await _db
          .into(_db.nodes)
          .insert(
            NodesCompanion.insert(
              id: id,
              parentId: Value(parentId),
              type: type.dbName,
              title: cleanTitle,
              notes: Value(notes),
              status: Value(type.hasStatus ? NodeStatus.todo.dbName : null),
              sortOrder: await _nextSortOrder(parentId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _log(
        EventTypes.created,
        nodeId: id,
        nodeType: type,
        domainId: type == NodeType.domain ? id : tree.domainOf(parentId!)?.id,
        groupId: parentId == null ? null : tree.effectiveGroupOf(parentId),
      );
      if (parentId != null && type.hasStatus) {
        await _reopenDoneChain(tree, parentId, cause: 'created', childId: id);
      }
      await _syncSummary();
      return id;
    });
  }

  /// Changes a node's title and notes. Not an activity log event in PRD 9.
  Future<void> edit(String id, {String? title, String? notes}) {
    final cleanTitle = title?.trim();
    if (cleanTitle != null && cleanTitle.isEmpty) {
      throw const ActionRejected(RejectReason.emptyTitle);
    }
    return _write(() async {
      await _requireNode(id);
      await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
        NodesCompanion(
          title: cleanTitle == null ? const Value.absent() : Value(cleanTitle),
          notes: notes == null ? const Value.absent() : Value(notes),
          updatedAt: Value(utcMillis(_clock)),
        ),
      );
    });
  }

  /// Moves a node to [newIndex] among its siblings (AT-004, AT-005).
  Future<void> reorder(String id, int newIndex) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final siblings = [
      ...(node.parentId == null ? tree.roots : tree.childrenOf(node.parentId!)),
    ];
    siblings.removeWhere((s) => s.id == id);
    siblings.insert(newIndex.clamp(0, siblings.length), node);
    final now = utcMillis(_clock);
    for (var i = 0; i < siblings.length; i++) {
      if (siblings[i].sortOrder == i) continue;
      await (_db.update(_db.nodes)..where((n) => n.id.equals(siblings[i].id)))
          .write(NodesCompanion(sortOrder: Value(i), updatedAt: Value(now)));
    }
    await _syncSummary();
  });

  Future<void> moveUp(String id) => _shift(id, -1);

  Future<void> moveDown(String id) => _shift(id, 1);

  /// Moves a node, and everything under it, to the end of [newParentId]'s
  /// children (AT-006). Only a parent of the right type is accepted. Moving
  /// a TODO node under a DONE one reopens it and its DONE ancestors (E-008).
  Future<void> move(String id, String newParentId) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    final newParent = tree[newParentId];
    if (node == null || newParent == null) {
      throw const ActionRejected(RejectReason.notFound);
    }
    if (!canHaveChild(newParent.type, node.type)) {
      throw const ActionRejected(RejectReason.invalidParent);
    }
    if (node.parentId == newParentId) return;
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        parentId: Value(newParentId),
        sortOrder: Value(await _nextSortOrder(newParentId)),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    if (node.isTodo) {
      await _reopenDoneChain(tree, newParentId, cause: 'moved', childId: id);
    }
    await _syncSummary();
  });

  /// Saves a whole new order for [parentId]'s children (null for domains) in
  /// one step, so the Reorder screen saves all of it or none (AT-004,
  /// AT-005). [orderedIds] must be exactly the current children.
  Future<void> setChildOrder(
    String? parentId,
    List<String> orderedIds,
  ) => _write(() async {
    final tree = await loadTree();
    final siblings = parentId == null ? tree.roots : tree.childrenOf(parentId);
    final current = siblings.map((s) => s.id).toSet();
    if (orderedIds.length != current.length ||
        !current.containsAll(orderedIds)) {
      throw const ActionRejected(RejectReason.notFound);
    }
    final orderOf = {for (final s in siblings) s.id: s.sortOrder};
    final now = utcMillis(_clock);
    for (var i = 0; i < orderedIds.length; i++) {
      if (orderOf[orderedIds[i]] == i) continue;
      await (_db.update(_db.nodes)..where((n) => n.id.equals(orderedIds[i])))
          .write(NodesCompanion(sortOrder: Value(i), updatedAt: Value(now)));
    }
    await _syncSummary();
  });

  /// Soft-deletes a node and everything under it, and returns the `deleted`
  /// event id that [undoDelete] needs (AT-008, AT-009, E-003).
  Future<String> delete(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final affected = [node, ...tree.descendantsOf(id)];
    final eventId = _newId();
    await (_db.update(
      _db.nodes,
    )..where((n) => n.id.isIn(affected.map((a) => a.id)))).write(
      NodesCompanion(
        isDeleted: const Value(true),
        deletedByEvent: Value(eventId),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.deleted,
      eventId: eventId,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
      payload: {'count': affected.length},
    );
    await _syncSummary();
    return eventId;
  });

  /// Restores exactly the rows that one delete removed. Anything deleted
  /// separately before it stays deleted (E-003).
  Future<void> undoDelete(String deleteEventId) => _write(() async {
    final rows = await (_db.select(
      _db.nodes,
    )..where((n) => n.deletedByEvent.equals(deleteEventId))).get();
    if (rows.isEmpty) throw const ActionRejected(RejectReason.notFound);
    await (_db.update(
      _db.nodes,
    )..where((n) => n.deletedByEvent.equals(deleteEventId))).write(
      NodesCompanion(
        isDeleted: const Value(false),
        deletedByEvent: const Value(null),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    final ids = rows.map((r) => r.id).toSet();
    final root = rows.firstWhere((r) => !ids.contains(r.parentId));
    final tree = await loadTree();
    await _log(
      EventTypes.restored,
      nodeId: root.id,
      nodeType: NodeType.fromDbName(root.type),
      domainId: tree.domainOf(root.id)?.id,
      groupId: tree.effectiveGroupOf(root.id),
      payload: {'undoes_event_id': deleteEventId},
    );
    await _syncSummary();
  });

  /// Marks a node DONE and returns the `completed` event id, which is the
  /// undo token for [undoComplete] (AT-025). Locked tasks can't be completed
  /// (E-007), and a node with TODO children can't either, so a DONE parent
  /// never holds a TODO child (PRD 7).
  Future<String> markDone(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (!node.type.hasStatus) {
      throw const ActionRejected(RejectReason.noStatus);
    }
    if (node.isDone) throw const ActionRejected(RejectReason.alreadyDone);
    if (tree.isLocked(id)) {
      throw const ActionRejected(RejectReason.lockedTask);
    }
    if (tree.hasTodoChildren(id)) {
      throw const ActionRejected(RejectReason.hasTodoChildren);
    }
    final now = utcMillis(_clock);
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        status: Value(NodeStatus.done.dbName),
        completedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final eventId = _newId();
    await _log(
      EventTypes.completed,
      eventId: eventId,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
    );
    await _syncSummary();
    return eventId;
  });

  /// Undo after completing (AT-025, E-001): the item is TODO again and its
  /// card comes back as if the tap never happened, so it gets no new
  /// `surfaced` event. The `completed` event stays in the log and a
  /// `completion_undone` event points at it. Any ancestor marked DONE in
  /// the meantime reopens too, so a DONE parent never holds a TODO child.
  Future<void> undoComplete(String completedEventId) => _write(() async {
    final event = await (_db.select(
      _db.events,
    )..where((e) => e.eventId.equals(completedEventId))).getSingleOrNull();
    if (event == null ||
        event.eventType != EventTypes.completed ||
        event.nodeId == null) {
      throw const ActionRejected(RejectReason.notFound);
    }
    final tree = await loadTree();
    final node = tree[event.nodeId!];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (!node.isDone) throw const ActionRejected(RejectReason.notDone);
    final doneAncestors = tree.ancestorsOf(node.id).where((a) => a.isDone);
    final reopened = [node.id, ...doneAncestors.map((a) => a.id)];
    await (_db.update(_db.nodes)..where((n) => n.id.isIn(reopened))).write(
      NodesCompanion(
        status: Value(NodeStatus.todo.dbName),
        completedAt: const Value(null),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.completionUndone,
      nodeId: node.id,
      nodeType: node.type,
      domainId: tree.domainOf(node.id)?.id,
      groupId: tree.effectiveGroupOf(node.id),
      payload: {
        'undoes_event_id': completedEventId,
        if (reopened.length > 1)
          'reopened_ancestors': reopened.skip(1).toList(),
      },
    );
    await _syncSummary(suppress: {node.id});
  });

  /// Sets [id] aside until [until] (PRD 7): it and everything under it
  /// leave the Summary until then (check 5), and the next item takes its
  /// place (AT-033). Any node can be set aside, from a card or the
  /// Explorer (AT-041). [level] is the scope chosen on a card (AT-036),
  /// [preset] is null for a custom time, and [remind] is the Remind me
  /// switch. Undo of a set aside is [wakeNow] (M3 wireframe choice).
  Future<void> setAside(
    String id,
    DateTime until, {
    Preset? preset,
    SetAsideLevel level = SetAsideLevel.item,
    bool remind = true,
  }) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (!isValidWakeTime(until, _clock.now())) {
      throw const ActionRejected(RejectReason.pastWakeTime);
    }
    final wakeAt = until.toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        snoozeUntil: Value(wakeAt),
        remindOnWake: Value(remind),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.setAside,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
      payload: {
        'wake_at': wakeAt,
        'preset': preset?.logName ?? Preset.customLogName,
        'remind': remind,
        'level': level.name,
      },
    );
    await _syncSummary();
  });

  /// Moves the wake time of something already set aside (PRD 8.3,
  /// AT-049). Logged as another `set_aside`, keeping Remind me as it was,
  /// with the time it replaced.
  Future<void> changeWakeTime(String id, DateTime until, {Preset? preset}) =>
      _write(() async {
        final tree = await loadTree();
        final node = tree[id];
        if (node == null) throw const ActionRejected(RejectReason.notFound);
        final previous = node.snoozeUntil;
        if (previous == null || !previous.isAfter(_clock.now())) {
          throw const ActionRejected(RejectReason.notSetAside);
        }
        if (!isValidWakeTime(until, _clock.now())) {
          throw const ActionRejected(RejectReason.pastWakeTime);
        }
        final wakeAt = until.toUtc().millisecondsSinceEpoch;
        await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
          NodesCompanion(
            snoozeUntil: Value(wakeAt),
            updatedAt: Value(utcMillis(_clock)),
          ),
        );
        await _log(
          EventTypes.setAside,
          nodeId: id,
          nodeType: node.type,
          domainId: tree.domainOf(id)?.id,
          groupId: tree.effectiveGroupOf(id),
          payload: {
            'wake_at': wakeAt,
            'preset': preset?.logName ?? Preset.customLogName,
            'remind': node.remindOnWake,
            'level': SetAsideLevel.item.name,
            'previous_wake_at': previous.millisecondsSinceEpoch,
          },
        );
        await _syncSummary();
      });

  /// Wakes a set-aside item straight away (PRD 7, AT-048): it shows on the
  /// Summary now, if nothing else hides it, and leaves the Set-Aside page.
  Future<void> wakeNow(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final until = node.snoozeUntil;
    if (until == null || !until.isAfter(_clock.now())) {
      throw const ActionRejected(RejectReason.notSetAside);
    }
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        snoozeUntil: const Value(null),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.woke,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
      payload: {
        'cause': WakeCause.wakeNow,
        'wake_at': until.millisecondsSinceEpoch,
      },
    );
    await _syncSummary();
  });

  /// Catches the log up with time passing, with no user action: on app
  /// start, on resume and when the Summary's next change is due (PRD 6).
  Future<void> recompute() => _write(() async {});

  /// Sets a DONE node back to TODO, together with every DONE ancestor
  /// (PRD 7, AT-027). Reopening an earlier task makes it current again, so
  /// later tasks re-lock but keep their progress (AT-028).
  Future<void> reopen(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (!node.type.hasStatus) {
      throw const ActionRejected(RejectReason.noStatus);
    }
    if (!node.isDone) throw const ActionRejected(RejectReason.notDone);
    final doneAncestors = tree.ancestorsOf(id).where((a) => a.isDone);
    final reopened = [id, ...doneAncestors.map((a) => a.id)];
    await (_db.update(_db.nodes)..where((n) => n.id.isIn(reopened))).write(
      NodesCompanion(
        status: Value(NodeStatus.todo.dbName),
        completedAt: const Value(null),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.reopened,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
      payload: {'reopened_ancestors': reopened.skip(1).toList()},
    );
    await _syncSummary();
  });

  /// Reopens [nodeId] and its DONE ancestors, because a TODO child was just
  /// added or moved under it (E-008). Does nothing if none are DONE.
  Future<void> _reopenDoneChain(
    Tree tree,
    String nodeId, {
    required String cause,
    required String childId,
  }) async {
    final chain = [tree[nodeId]!, ...tree.ancestorsOf(nodeId)];
    final done = chain.where((n) => n.isDone).toList();
    if (done.isEmpty) return;
    await (_db.update(
      _db.nodes,
    )..where((n) => n.id.isIn(done.map((d) => d.id)))).write(
      NodesCompanion(
        status: Value(NodeStatus.todo.dbName),
        completedAt: const Value(null),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.reopened,
      nodeId: done.first.id,
      nodeType: done.first.type,
      domainId: tree.domainOf(done.first.id)?.id,
      groupId: tree.effectiveGroupOf(done.first.id),
      payload: {
        'reopened_ancestors': done.skip(1).map((d) => d.id).toList(),
        'cause': cause,
        'child_id': childId,
      },
    );
  }

  /// Runs [body] in one transaction, after first catching up with time
  /// passing since the last write, so an action never takes the credit for
  /// a wake that happened before it (E-002).
  Future<T> _write<T>(Future<T> Function() body) => _db.transaction(() async {
    await _catchUp();
    return body();
  });

  /// Records what time alone changed since the last write. Each item whose
  /// wake time has passed gets an automatic `woke` event dated with that
  /// time (AT-060), and each card that appeared because of it gets
  /// `surfaced` dated with the moment it really became visible: the latest
  /// wake time on it or its ancestors (E-002).
  ///
  /// The item was awake from its wake time with no write (PRD 5). Here,
  /// once its `woke` is logged, `snooze_until` is cleared, so each wake is
  /// logged once and later checks only look at fresh ones. The dates are
  /// worked out before clearing.
  Future<void> _catchUp() async {
    final tree = await loadTree();
    final now = _clock.now().toUtc();
    final passed = [
      for (final node in tree.nodes)
        if (node.snoozeUntil case final until? when !until.isAfter(now)) node,
    ];
    if (passed.isEmpty) return;
    passed.sort((a, b) => a.snoozeUntil!.compareTo(b.snoozeUntil!));
    for (final node in passed) {
      await _log(
        EventTypes.woke,
        nodeId: node.id,
        nodeType: node.type,
        domainId: tree.domainOf(node.id)?.id,
        groupId: tree.effectiveGroupOf(node.id),
        payload: {'cause': WakeCause.automatic},
        occurredAt: node.snoozeUntil!.millisecondsSinceEpoch,
      );
    }
    await _syncSummary(
      tree: tree,
      visibleAt: (id) {
        DateTime? latest;
        for (final n in [tree[id]!, ...tree.ancestorsOf(id)]) {
          final until = n.snoozeUntil;
          if (until == null || until.isAfter(now)) continue;
          if (latest == null || until.isAfter(latest)) latest = until;
        }
        // Nothing woke on its path, as after an upgrade: it shows from now.
        return latest ?? now;
      },
    );
    await (_db.update(_db.nodes)
          ..where((n) => n.id.isIn(passed.map((p) => p.id))))
        .write(const NodesCompanion(snoozeUntil: Value(null)));
  }

  SimpleSelectStatement<$NodesTable, NodeRow> _liveNodes() =>
      _db.select(_db.nodes)..where((n) => n.isDeleted.equals(false));

  Future<void> _shift(String id, int by) async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final siblings = node.parentId == null
        ? tree.roots
        : tree.childrenOf(node.parentId!);
    final index = siblings.indexWhere((s) => s.id == id);
    await reorder(id, index + by);
  }

  Future<TreeNode> _requireNode(String id) async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    return node;
  }

  /// One past the highest order among all children, deleted ones included,
  /// so a restored node never shares a position with a newer one.
  Future<int> _nextSortOrder(String? parentId) async {
    final maxOrder = _db.nodes.sortOrder.max();
    final query = _db.selectOnly(_db.nodes)..addColumns([maxOrder]);
    query.where(
      parentId == null
          ? _db.nodes.parentId.isNull()
          : _db.nodes.parentId.equals(parentId),
    );
    final result = await query.getSingle();
    final current = result.read(maxOrder);
    return current == null ? 0 : current + 1;
  }

  /// Recomputes the Summary and records what newly appeared, inside the
  /// same transaction as the change that caused it (tech plan 4.5): one
  /// `surfaced` event per new card, and `summary_visible` kept in step, so
  /// a crash between the two can never log an appearance twice.
  ///
  /// [suppress] names cards an undo restored: they get no new event and keep
  /// their original surfaced time (E-001). [visibleAt] gives when each card
  /// really became visible, for cards that came back while the app was
  /// closed (E-002); otherwise it is now. [tree] saves a reload when the
  /// caller has the current one.
  Future<void> _syncSummary({
    Set<String> suppress = const {},
    Tree? tree,
    DateTime Function(String id)? visibleAt,
  }) async {
    tree ??= await loadTree();
    final summary = computeSummary(tree, now: _clock.now().toUtc());
    final previousRows = await (_db.select(
      _db.summaryVisible,
    )..where((v) => v.isDeleted.equals(false))).get();
    final previous = {for (final r in previousRows) r.nodeId};
    final current = summary.cards.map((c) => c.id).toList();
    final diff = diffVisible(
      previous: previous,
      current: current,
      suppress: suppress,
    );
    final now = utcMillis(_clock);
    int at(String id) => visibleAt?.call(id).millisecondsSinceEpoch ?? now;
    for (final id in diff.appeared) {
      final node = tree[id]!;
      await _log(
        EventTypes.surfaced,
        nodeId: id,
        nodeType: node.type,
        domainId: tree.domainOf(id)?.id,
        groupId: tree.effectiveGroupOf(id),
        occurredAt: at(id),
      );
    }
    for (final id in current) {
      if (previous.contains(id)) continue;
      final keepTime = suppress.contains(id);
      await _db
          .into(_db.summaryVisible)
          .insert(
            SummaryVisibleCompanion.insert(
              nodeId: id,
              surfacedAt: at(id),
              createdAt: now,
              updatedAt: now,
            ),
            onConflict: DoUpdate(
              (old) => SummaryVisibleCompanion(
                surfacedAt: keepTime ? const Value.absent() : Value(at(id)),
                isDeleted: const Value(false),
                updatedAt: Value(now),
              ),
            ),
          );
    }
    if (diff.disappeared.isNotEmpty) {
      await (_db.update(
        _db.summaryVisible,
      )..where((v) => v.nodeId.isIn(diff.disappeared))).write(
        SummaryVisibleCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> _log(
    String eventType, {
    String? eventId,
    required String nodeId,
    required NodeType nodeType,
    String? domainId,
    String? groupId,
    Map<String, Object?> payload = const {},
    int? occurredAt,
  }) async {
    final now = utcMillis(_clock);
    await _db
        .into(_db.events)
        .insert(
          EventsCompanion.insert(
            eventId: eventId ?? _newId(),
            eventType: eventType,
            nodeId: Value(nodeId),
            nodeType: Value(nodeType.dbName),
            domainId: Value(domainId),
            groupId: Value(groupId),
            occurredAt: occurredAt ?? now,
            // The offset at that moment, which differs from now's after a
            // daylight-saving change (E-002).
            tzOffsetMinutes: occurredAt == null
                ? tzOffsetMinutes(_clock)
                : tzOffsetMinutesAt(_clock, occurredAt),
            payload: Value(jsonEncode(payload)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  static TreeNode _toTreeNode(NodeRow row) => TreeNode(
    id: row.id,
    parentId: row.parentId,
    type: NodeType.fromDbName(row.type),
    title: row.title,
    notes: row.notes,
    status: NodeStatus.fromDbName(row.status),
    sortOrder: row.sortOrder,
    groupId: row.groupId,
    snoozeUntil: row.snoozeUntil == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.snoozeUntil!, isUtc: true),
    remindOnWake: row.remindOnWake,
    isRecurring: row.recurrence != null,
  );
}
