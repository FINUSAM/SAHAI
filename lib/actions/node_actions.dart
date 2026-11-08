import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';
import '../data/settings.dart';
import '../engine/groups.dart';
import '../engine/node_type.dart';
import '../engine/order.dart';
import '../engine/recurrence.dart';
import '../engine/scope.dart';
import '../engine/settings.dart';
import '../engine/surfaced.dart';
import '../engine/time.dart';
import '../engine/tree.dart';
import '../engine/visibility.dart';
import '../shared/ids.dart';
import '../shared/time.dart';

part 'summary_order_actions.dart';

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

  /// A recurring occurrence moved on without a completion (PRD 9, AT-071).
  static const skipped = 'skipped';

  /// Undo after skipping. The `skipped` event stays; this one points at it
  /// (E-011).
  static const skipUndone = 'skip_undone';

  /// The payload holds the schedule that was cleared (E-011).
  static const repeatStopped = 'repeat_stopped';

  /// Undo after stopping repeating; points at the `repeat_stopped` event
  /// (E-011).
  static const repeatRestored = 'repeat_restored';

  /// An order change, on the Summary or in the Explorer (E-015). The payload
  /// holds the old and new position and group (PRD 9).
  static const reordered = 'reordered';

  /// A node's group setting changed (PRD 9). The payload holds the old and
  /// new setting and the old and new effective group.
  static const groupChanged = 'group_changed';
}

// Payload keys for what Undo restores on a recurring item. `due_on` on a
// `completed` event is also what AT-082 asks for.
const _dueOnKey = 'due_on';
const _nextDueOnKey = 'next_due_on';
const _snoozeKey = 'snooze_until';
const _overridesKey = 'snooze_overrides_show';

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

  /// A repeat schedule on anything but a TODO stream item (PRD 7).
  cantRepeat,

  /// Skip or Stop repeating on something with no schedule.
  notRecurring,

  /// Undo after the occurrence has already moved on.
  staleUndo,

  /// A group that doesn't exist, or was deleted.
  noSuchGroup,

  /// A Summary action on a node that isn't a card on the Summary.
  notOnSummary,
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

  /// The non-deleted tree, with the groups that still exist (E-014).
  Future<Tree> loadTree() async => Tree(
    (await _liveNodes().get()).map(_toTreeNode),
    groupIds: {for (final g in await _liveGroupRows()) g.id},
  );

  /// The non-deleted tree, emitted again after every change to the nodes or
  /// the groups, so screens stay up to date without refreshing by hand.
  Stream<Tree> watchTree() => _db
      .customSelect('SELECT 1', readsFrom: {_db.nodes, _db.contextGroups})
      .watch()
      .asyncMap((_) => loadTree());

  /// Creates a node at the end of its parent's children (AT-001, AT-002).
  /// A stream item can start with a repeat [schedule], first due on [dueOn],
  /// in the same step, so it never shows as a normal item first. [leadDays]
  /// is the Settings default if null, as in [setRecurrence]. [group] is the
  /// node's group setting, as in [setGroup], so a new card starts in its
  /// group (AT-090).
  Future<String> create({
    required NodeType type,
    String? parentId,
    required String title,
    String notes = '',
    Schedule? schedule,
    DateTime? dueOn,
    int? leadDays,
    String? group,
  }) {
    assert((schedule == null) == (dueOn == null), 'A schedule needs a date.');
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
      if (schedule != null && type != NodeType.streamItem) {
        throw const ActionRejected(RejectReason.cantRepeat);
      }
      final inherited = parentId == null
          ? null
          : tree.effectiveGroupOf(parentId);
      final setting = _cleanSetting(tree, group, inherited: inherited);
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
              recurrence: Value(schedule?.toJson()),
              dueOn: Value(dueOn == null ? null : formatDueOn(dueOn)),
              leadDays: Value(
                schedule == null
                    ? null
                    : leadDays ?? (await _settings()).defaultLeadDays,
              ),
              groupId: Value(setting),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _log(
        EventTypes.created,
        nodeId: id,
        nodeType: type,
        domainId: type == NodeType.domain ? id : tree.domainOf(parentId!)?.id,
        groupId: switch (setting) {
          null => inherited,
          noGroup => null,
          _ => setting,
        },
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

  /// Moves a node to [newIndex] among its siblings (AT-004, AT-005), and
  /// logs `reordered` if it moved (E-015).
  Future<void> reorder(String id, int newIndex) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final siblings = [
      ...(node.parentId == null ? tree.roots : tree.childrenOf(node.parentId!)),
    ];
    final oldIndex = siblings.indexWhere((s) => s.id == id);
    siblings.removeAt(oldIndex);
    final target = newIndex.clamp(0, siblings.length);
    siblings.insert(target, node);
    final now = utcMillis(_clock);
    for (var i = 0; i < siblings.length; i++) {
      if (siblings[i].sortOrder == i) continue;
      await (_db.update(_db.nodes)..where((n) => n.id.equals(siblings[i].id)))
          .write(NodesCompanion(sortOrder: Value(i), updatedAt: Value(now)));
    }
    if (target != oldIndex) {
      await _logTreeReorder(tree, node, oldIndex, target);
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
  /// AT-005). [orderedIds] must be exactly the current children. Each node
  /// the user moved gets a `reordered` event (E-015): the fewest that explain
  /// the new order, so the ones that only shifted to make room get none.
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
    final before = [for (final s in siblings) s.id];
    for (final id in movedIds(before, orderedIds)) {
      await _logTreeReorder(
        tree,
        tree[id]!,
        before.indexOf(id),
        orderedIds.indexOf(id),
      );
    }
    await _syncSummary();
  });

  /// One `reordered` event for an Explorer move. The group doesn't change,
  /// so old and new group are the same (E-015).
  Future<void> _logTreeReorder(
    Tree tree,
    TreeNode node,
    int oldIndex,
    int newIndex,
  ) {
    final group = tree.effectiveGroupOf(node.id);
    return _log(
      EventTypes.reordered,
      nodeId: node.id,
      nodeType: node.type,
      domainId: tree.domainOf(node.id)?.id,
      groupId: group,
      payload: {
        _viewKey: _explorerView,
        _oldPositionKey: oldIndex,
        _newPositionKey: newIndex,
        _oldGroupKey: group,
        _newGroupKey: group,
      },
    );
  }

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
    if (node.isRecurring) return _completeOccurrence(tree, node);
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
    final occurrence = jsonDecode(event.payload) as Map<String, Object?>;
    if (occurrence.containsKey(_dueOnKey)) {
      await _restoreOccurrence(occurrence, node);
      await _log(
        EventTypes.completionUndone,
        nodeId: node.id,
        nodeType: node.type,
        domainId: tree.domainOf(node.id)?.id,
        groupId: tree.effectiveGroupOf(node.id),
        payload: {
          'undoes_event_id': completedEventId,
          _dueOnKey: occurrence[_dueOnKey],
        },
      );
      await _syncSummary(suppress: {node.id});
      return;
    }
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

  /// Gives a TODO stream item a repeat schedule, or replaces it (PRD 7).
  /// [dueOn] is the first due date and [leadDays] how many days early it
  /// shows, the Settings default if null. Not an activity log event in
  /// PRD 9, like [edit].
  Future<void> setRecurrence(
    String id,
    Schedule schedule, {
    required DateTime dueOn,
    int? leadDays,
  }) => _write(() async {
    final node = await _requireNode(id);
    if (node.type != NodeType.streamItem || !node.isTodo) {
      throw const ActionRejected(RejectReason.cantRepeat);
    }
    final settings = await _settings();
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        recurrence: Value(schedule.toJson()),
        dueOn: Value(formatDueOn(dueOn)),
        leadDays: Value(leadDays ?? settings.defaultLeadDays),
        snoozeOverridesShow: const Value(false),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _syncSummary();
  });

  /// Moves a recurring item to its next occurrence without logging a
  /// completion (AT-071), and returns the `skipped` event id, the undo
  /// token for [undoSkip] (E-011). The next one follows the due date
  /// whatever the schedule repeats from, since nothing was completed.
  Future<String> skipOccurrence(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (!node.isRecurring) {
      throw const ActionRejected(RejectReason.notRecurring);
    }
    final eventId = _newId();
    final next = node.schedule!.nextDue(node.dueOn!);
    await _advanceOccurrence(id, next);
    await _log(
      EventTypes.skipped,
      eventId: eventId,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
      payload: _occurrencePayload(node, next),
    );
    await _syncSummary();
    return eventId;
  });

  /// Undo after skipping (E-011): the occurrence comes back as if the tap
  /// never happened.
  Future<void> undoSkip(String skippedEventId) => _write(() async {
    final event = await _requireEvent(skippedEventId, EventTypes.skipped);
    final tree = await loadTree();
    final node = tree[event.nodeId!];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final occurrence = jsonDecode(event.payload) as Map<String, Object?>;
    await _restoreOccurrence(occurrence, node);
    await _log(
      EventTypes.skipUndone,
      nodeId: node.id,
      nodeType: node.type,
      domainId: tree.domainOf(node.id)?.id,
      groupId: tree.effectiveGroupOf(node.id),
      payload: {
        'undoes_event_id': skippedEventId,
        _dueOnKey: occurrence[_dueOnKey],
      },
    );
    await _syncSummary(suppress: {node.id});
  });

  /// Turns a recurring item into a normal stream item and clears its due
  /// date (PRD 7, AT-080). Returns the `repeat_stopped` event id, the undo
  /// token for [undoStopRepeating] (E-011).
  Future<String> stopRepeating(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (!node.isRecurring) {
      throw const ActionRejected(RejectReason.notRecurring);
    }
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        recurrence: const Value(null),
        dueOn: const Value(null),
        leadDays: const Value(null),
        snoozeOverridesShow: const Value(false),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    final eventId = _newId();
    await _log(
      EventTypes.repeatStopped,
      eventId: eventId,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
      payload: {
        'recurrence': node.schedule!.toJson(),
        _dueOnKey: formatDueOn(node.dueOn!),
        'lead_days': node.leadDays,
        if (node.snoozeOverridesShow) _overridesKey: true,
      },
    );
    await _syncSummary();
    return eventId;
  });

  /// Undo after stopping repeating (E-011): the schedule and due date are
  /// back and the card comes back as if the tap never happened.
  Future<void> undoStopRepeating(String stoppedEventId) => _write(() async {
    final event = await _requireEvent(stoppedEventId, EventTypes.repeatStopped);
    final tree = await loadTree();
    final node = tree[event.nodeId!];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (node.isRecurring) throw const ActionRejected(RejectReason.staleUndo);
    final stopped = jsonDecode(event.payload) as Map<String, Object?>;
    await (_db.update(_db.nodes)..where((n) => n.id.equals(node.id))).write(
      NodesCompanion(
        recurrence: Value(stopped['recurrence']! as String),
        dueOn: Value(stopped[_dueOnKey]! as String),
        leadDays: Value(stopped['lead_days'] as int?),
        snoozeOverridesShow: Value(stopped[_overridesKey] == true),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _log(
      EventTypes.repeatRestored,
      nodeId: node.id,
      nodeType: node.type,
      domainId: tree.domainOf(node.id)?.id,
      groupId: tree.effectiveGroupOf(node.id),
      payload: {'undoes_event_id': stoppedEventId},
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
  /// with the time it replaced. On a recurring item it moves only this
  /// occurrence's show time, earlier or later (E-005).
  Future<void> changeWakeTime(String id, DateTime until, {Preset? preset}) =>
      _write(() async {
        final tree = await loadTree();
        final node = tree[id];
        if (node == null) throw const ActionRejected(RejectReason.notFound);
        final previous = node.wakeAt(await _settings());
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
            snoozeOverridesShow: _overridesShow(node),
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
  /// A recurring item waiting for its show date comes back with its real
  /// due label, and its due date and schedule don't change (E-005).
  Future<void> wakeNow(String id) => _write(() async {
    final tree = await loadTree();
    final node = tree[id];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    final until = node.wakeAt(await _settings());
    if (until == null || !until.isAfter(_clock.now())) {
      throw const ActionRejected(RejectReason.notSetAside);
    }
    await (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
      NodesCompanion(
        snoozeUntil: const Value(null),
        snoozeOverridesShow: _overridesShow(node),
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
  ///
  /// A recurring item's show time is computed, not stored, so nothing marks
  /// it as passed: with any due date in the tree the Summary is always
  /// compared, and a bill that reached its show date gets `surfaced` dated
  /// with that time. It gets no `woke`, because that would need a stored
  /// record of each show time to log it once.
  Future<void> _catchUp() async {
    final tree = await loadTree();
    final now = _clock.now().toUtc();
    final passed = [
      for (final node in tree.nodes)
        if (node.snoozeUntil case final until? when !until.isAfter(now)) node,
    ];
    if (passed.isEmpty && !tree.nodes.any((n) => n.dueOn != null)) return;
    final settings = await _settings();
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
          final until = n.wakeAt(settings);
          if (until == null || until.isAfter(now)) continue;
          if (latest == null || until.isAfter(latest)) latest = until;
        }
        // Nothing woke on its path, as after an upgrade: it shows from now.
        return latest ?? now;
      },
    );
    if (passed.isEmpty) return;
    await (_db.update(_db.nodes)
          ..where((n) => n.id.isIn(passed.map((p) => p.id))))
        .write(const NodesCompanion(snoozeUntil: Value(null)));
  }

  /// Completes a recurring occurrence (PRD 7): the item stays TODO with its
  /// next due date (AT-066, AT-077) and the event stores the date it was due
  /// (AT-082). Repeating from the due date follows the missed date, not the
  /// payment day (AT-067), so a missed cycle shows straight away (AT-068).
  Future<String> _completeOccurrence(Tree tree, TreeNode node) async {
    final schedule = node.schedule!;
    final settings = await _settings();
    final next = schedule.nextDue(
      schedule.repeatFrom == RepeatFrom.dueDate
          ? node.dueOn!
          : logicalDate(
              _clock.now(),
              dayStartMinutes: settings.dayStartMinutes,
            ),
    );
    await _advanceOccurrence(node.id, next);
    final eventId = _newId();
    await _log(
      EventTypes.completed,
      eventId: eventId,
      nodeId: node.id,
      nodeType: node.type,
      domainId: tree.domainOf(node.id)?.id,
      groupId: tree.effectiveGroupOf(node.id),
      payload: _occurrencePayload(node, next),
    );
    await _syncSummary();
    return eventId;
  }

  /// Ending an occurrence also ends any set aside or show-time override on
  /// it, so the next one waits for its own show date (tech plan 4.4).
  Future<void> _advanceOccurrence(String id, DateTime next) =>
      (_db.update(_db.nodes)..where((n) => n.id.equals(id))).write(
        NodesCompanion(
          dueOn: Value(formatDueOn(next)),
          snoozeUntil: const Value(null),
          snoozeOverridesShow: const Value(false),
          updatedAt: Value(utcMillis(_clock)),
        ),
      );

  /// What an event needs to put [node]'s occurrence back on Undo.
  Map<String, Object?> _occurrencePayload(TreeNode node, DateTime next) => {
    _dueOnKey: formatDueOn(node.dueOn!),
    _nextDueOnKey: formatDueOn(next),
    if (node.snoozeUntil case final until?)
      _snoozeKey: until.millisecondsSinceEpoch,
    if (node.snoozeOverridesShow) _overridesKey: true,
  };

  /// Puts back what [_occurrencePayload] saved. An Undo that arrives after
  /// the item has moved on would rewind the wrong occurrence, so it's
  /// refused.
  Future<void> _restoreOccurrence(
    Map<String, Object?> occurrence,
    TreeNode node,
  ) async {
    final dueOn = node.dueOn;
    if (dueOn == null || formatDueOn(dueOn) != occurrence[_nextDueOnKey]) {
      throw const ActionRejected(RejectReason.staleUndo);
    }
    await (_db.update(_db.nodes)..where((n) => n.id.equals(node.id))).write(
      NodesCompanion(
        dueOn: Value(occurrence[_dueOnKey]! as String),
        snoozeUntil: Value(occurrence[_snoozeKey] as int?),
        snoozeOverridesShow: Value(occurrence[_overridesKey] == true),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
  }

  /// Wake now and Change time replace the show time on a recurring item
  /// (E-005); other nodes have none.
  Value<bool> _overridesShow(TreeNode node) =>
      node.isRecurring ? const Value(true) : const Value.absent();

  Future<EventRow> _requireEvent(String eventId, String type) async {
    final event = await (_db.select(
      _db.events,
    )..where((e) => e.eventId.equals(eventId))).getSingleOrNull();
    if (event == null || event.eventType != type || event.nodeId == null) {
      throw const ActionRejected(RejectReason.notFound);
    }
    return event;
  }

  Future<AppSettings> _settings() async => settingsFromRow(
    await (_db.select(
      _db.settingsTable,
    )..where((s) => s.id.equals(1))).getSingleOrNull(),
  );

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
    final summary = computeSummary(
      tree,
      now: _clock.now().toUtc(),
      settings: await _settings(),
    );
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
    await _syncSlots(summary.cards);
  }

  /// Gives every card's owner a slot in the card's group (tech plan 4.6). A
  /// slot already in that group keeps its position, so the next card for
  /// the same owner takes the same place (AT-088, AT-091). A new slot, or
  /// one whose card is now in another group, goes to the end of that group
  /// (AT-089, AT-090). Slots of owners with no card stay as they are, ready
  /// for when a card comes back.
  Future<void> _syncSlots(List<SummaryCard> cards) async {
    final slots = await _liveSlots();
    final ends = <String?, int>{};
    for (final card in cards) {
      final slot = slots[card.ownerId];
      if (slot != null && slot.groupId == card.groupId) continue;
      final position = ends[card.groupId] ??= _endOf(slots, card.groupId);
      ends[card.groupId] = position + 1;
      await _writeSlot(card.ownerId, card.groupId, position);
      slots[card.ownerId] = SummarySlot(
        ownerId: card.ownerId,
        groupId: card.groupId,
        position: position,
      );
    }
  }

  /// One past the last position in [groupId].
  static int _endOf(Map<String, SummarySlot> slots, String? groupId) {
    var end = 0;
    for (final slot in slots.values) {
      if (slot.groupId == groupId && slot.position >= end) {
        end = slot.position + 1;
      }
    }
    return end;
  }

  Future<void> _writeSlot(String ownerId, String? groupId, int position) {
    final now = utcMillis(_clock);
    return _db
        .into(_db.summarySlots)
        .insert(
          SummarySlotsCompanion.insert(
            ownerId: ownerId,
            groupId: Value(groupId),
            position: position,
            createdAt: now,
            updatedAt: now,
          ),
          onConflict: DoUpdate(
            (old) => SummarySlotsCompanion(
              groupId: Value(groupId),
              position: Value(position),
              isDeleted: const Value(false),
              updatedAt: Value(now),
            ),
          ),
        );
  }

  Future<Map<String, SummarySlot>> _liveSlots() async {
    final rows = await (_db.select(
      _db.summarySlots,
    )..where((s) => s.isDeleted.equals(false))).get();
    return {
      for (final r in rows)
        r.ownerId: SummarySlot(
          ownerId: r.ownerId,
          groupId: r.groupId,
          position: r.position,
        ),
    };
  }

  Future<List<ContextGroupRow>> _liveGroupRows() => (_db.select(
    _db.contextGroups,
  )..where((g) => g.isDeleted.equals(false))).get();

  /// [setting] made safe to store on a node whose parent's group is
  /// [inherited]: null (follow the parent), [noGroup], or a group that
  /// exists. "No group" with nothing to override is the same as following
  /// the parent, so it's stored as null (E-013).
  String? _cleanSetting(Tree tree, String? setting, {String? inherited}) {
    if (setting == null) return null;
    if (!tree.hasGroup(setting)) {
      throw const ActionRejected(RejectReason.noSuchGroup);
    }
    return setting == noGroup && inherited == null ? null : setting;
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
    schedule: row.recurrence == null
        ? null
        : Schedule.fromJson(row.recurrence!),
    dueOn: row.dueOn == null ? null : parseDueOn(row.dueOn!),
    leadDays: row.leadDays,
    snoozeOverridesShow: row.snoozeOverridesShow,
  );
}
