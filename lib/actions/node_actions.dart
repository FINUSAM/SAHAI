import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';
import '../engine/node_type.dart';
import '../engine/tree.dart';
import '../shared/ids.dart';
import '../shared/time.dart';

/// Activity log event types written by these actions (PRD 9).
abstract final class EventTypes {
  static const created = 'created';
  static const completed = 'completed';
  static const reopened = 'reopened';
  static const deleted = 'deleted';
  static const restored = 'restored';
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
  Future<Tree> loadTree() async {
    final rows = await (_db.select(
      _db.nodes,
    )..where((n) => n.isDeleted.equals(false))).get();
    return Tree(rows.map(_toTreeNode));
  }

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
    return _db.transaction(() async {
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
      return id;
    });
  }

  /// Changes a node's title and notes. Not an activity log event in PRD 9.
  Future<void> edit(String id, {String? title, String? notes}) {
    final cleanTitle = title?.trim();
    if (cleanTitle != null && cleanTitle.isEmpty) {
      throw const ActionRejected(RejectReason.emptyTitle);
    }
    return _db.transaction(() async {
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
  Future<void> reorder(String id, int newIndex) => _db.transaction(() async {
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
  });

  Future<void> moveUp(String id) => _shift(id, -1);

  Future<void> moveDown(String id) => _shift(id, 1);

  /// Moves a node, and everything under it, to the end of [newParentId]'s
  /// children (AT-006). Only a parent of the right type is accepted.
  Future<void> move(String id, String newParentId) => _db.transaction(() async {
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
  });

  /// Soft-deletes a node and everything under it, and returns the `deleted`
  /// event id that [undoDelete] needs (AT-008, AT-009, E-003).
  Future<String> delete(String id) => _db.transaction(() async {
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
    return eventId;
  });

  /// Restores exactly the rows that one delete removed. Anything deleted
  /// separately before it stays deleted (E-003).
  Future<void> undoDelete(String deleteEventId) => _db.transaction(() async {
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
  });

  /// Marks a node DONE. Locked tasks can't be completed (E-007), and a node
  /// with TODO children can't either, so a DONE parent never holds a TODO
  /// child (PRD 7).
  Future<void> markDone(String id) => _db.transaction(() async {
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
    await _log(
      EventTypes.completed,
      nodeId: id,
      nodeType: node.type,
      domainId: tree.domainOf(id)?.id,
      groupId: tree.effectiveGroupOf(id),
    );
  });

  /// Sets a DONE node back to TODO, together with every DONE ancestor
  /// (PRD 7). Undo after completing comes in M2.
  Future<void> reopen(String id) => _db.transaction(() async {
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
  });

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

  Future<void> _log(
    String eventType, {
    String? eventId,
    required String nodeId,
    required NodeType nodeType,
    String? domainId,
    String? groupId,
    Map<String, Object?> payload = const {},
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
            occurredAt: now,
            tzOffsetMinutes: tzOffsetMinutes(_clock),
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
    status: NodeStatus.fromDbName(row.status),
    sortOrder: row.sortOrder,
    groupId: row.groupId,
  );
}
