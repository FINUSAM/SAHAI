part of 'node_actions.dart';

// Payload keys for `reordered` and `group_changed` (PRD 9, AT-094, E-015).
// Positions are places in the list the user saw, counted from 0: a card's
// place in its group on the Summary, or a node's place among its siblings
// in the Explorer. Groups are effective groups, null for the default list.
const _viewKey = 'view';
const _summaryView = 'summary';
const _explorerView = 'explorer';
const _oldPositionKey = 'old_position';
const _newPositionKey = 'new_position';
const _oldGroupKey = 'old_group';
const _newGroupKey = 'new_group';
const _ownerKey = 'owner_id';

// A setting is what's stored on the node: null (follow the parent),
// `noGroup`, or a group id (E-013).
const _oldSettingKey = 'old_setting';
const _newSettingKey = 'new_setting';

// Where the card's slot was, so Undo can put it back exactly.
const _oldSlotGroupKey = 'old_slot_group';
const _oldSlotPositionKey = 'old_slot_position';
const _undoesKey = 'undoes_event_id';

/// What [GroupActions.undoDeleteGroup] needs: the group and where its
/// slots were, so the cards go back to their exact places (E-014).
class GroupDeletion {
  const GroupDeletion._(this.groupId, this.slots);

  final String groupId;
  final List<SummarySlot> slots;
}

/// Context groups, settings on nodes, and the Summary's order (PRD 8.2).
/// Like every action, each is one transaction. Slots never touch the
/// tree's `sort_order` (AT-092).
extension GroupActions on NodeActions {
  /// The Summary in groups and saved order, as the Summary Page shows it.
  Future<List<SummarySection>> loadArrangedSummary() async =>
      _arrange(await loadTree());

  /// The groups that exist, in their order.
  Future<List<ContextGroup>> loadGroups() async =>
      _sortedGroups(await _liveGroupRows());

  /// The groups, emitted again after every change to them.
  Stream<List<ContextGroup>> watchGroups() => (_db.select(
    _db.contextGroups,
  )..where((g) => g.isDeleted.equals(false))).watch().map(_sortedGroups);

  /// Creates a group at the end of the list (AT-084). [icon] is one of the
  /// app's icon names, or null. Not an activity log event in PRD 9.
  Future<String> createGroup(String name, {String? icon}) {
    final cleanName = _cleanName(name);
    return _write(() async {
      final id = _newId();
      final now = utcMillis(_clock);
      final maxOrder = _db.contextGroups.sortOrder.max();
      final query = _db.selectOnly(_db.contextGroups)..addColumns([maxOrder]);
      final current = (await query.getSingle()).read(maxOrder);
      await _db
          .into(_db.contextGroups)
          .insert(
            ContextGroupsCompanion.insert(
              id: id,
              name: cleanName,
              icon: Value(icon),
              sortOrder: current == null ? 0 : current + 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    });
  }

  /// Renames a group and sets its icon, null for none.
  Future<void> editGroup(String id, {required String name, String? icon}) {
    final cleanName = _cleanName(name);
    return _write(() async {
      await _requireGroup(id);
      await (_db.update(
        _db.contextGroups,
      )..where((g) => g.id.equals(id))).write(
        ContextGroupsCompanion(
          name: Value(cleanName),
          icon: Value(icon),
          updatedAt: Value(utcMillis(_clock)),
        ),
      );
    });
  }

  /// Moves a group to [newIndex] in the list, which is its order on the
  /// Summary (frame 12).
  Future<void> reorderGroup(String id, int newIndex) => _write(() async {
    final groups = await loadGroups();
    final index = groups.indexWhere((g) => g.id == id);
    if (index < 0) throw const ActionRejected(RejectReason.noSuchGroup);
    final moved = groups.removeAt(index);
    groups.insert(newIndex.clamp(0, groups.length), moved);
    final now = utcMillis(_clock);
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].sortOrder == i) continue;
      await (_db.update(
        _db.contextGroups,
      )..where((g) => g.id.equals(groups[i].id))).write(
        ContextGroupsCompanion(sortOrder: Value(i), updatedAt: Value(now)),
      );
    }
  });

  Future<void> moveGroupUp(String id) => _shiftGroup(id, -1);

  Future<void> moveGroupDown(String id) => _shiftGroup(id, 1);

  /// Deletes a group, with no "Are you sure?" step (E-014). Nodes keep their
  /// setting, which now counts as unset, so their cards follow the next
  /// group up or go to the default list, at the end. Writes no log events,
  /// because a group isn't a node. Returns what [undoDeleteGroup] needs.
  Future<GroupDeletion> deleteGroup(String id) => _write(() async {
    await _requireGroup(id);
    final slots = [
      for (final slot in (await _liveSlots()).values)
        if (slot.groupId == id) slot,
    ];
    await (_db.update(_db.contextGroups)..where((g) => g.id.equals(id))).write(
      ContextGroupsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    await _syncSummary();
    return GroupDeletion._(id, slots);
  });

  /// Undo after deleting a group (E-014): the group is back, and its cards
  /// are back in their places.
  Future<void> undoDeleteGroup(GroupDeletion deletion) => _write(() async {
    final row = await (_db.select(
      _db.contextGroups,
    )..where((g) => g.id.equals(deletion.groupId))).getSingleOrNull();
    if (row == null) throw const ActionRejected(RejectReason.noSuchGroup);
    if (!row.isDeleted) throw const ActionRejected(RejectReason.staleUndo);
    await (_db.update(
      _db.contextGroups,
    )..where((g) => g.id.equals(deletion.groupId))).write(
      ContextGroupsCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    for (final slot in deletion.slots) {
      await _writeSlot(slot.ownerId, slot.groupId, slot.position);
    }
    await _syncSummary();
  });

  /// Sets [nodeId]'s group [setting]: null to follow its parent, [noGroup],
  /// or a group id (PRD 8.2, E-013). Its cards and those of nodes following
  /// it go to the end of their new group. Logs `group_changed`, and also
  /// `reordered` when the node is a card on the Summary that changes group
  /// (AT-094). Returns the `group_changed` event id, the token for
  /// [undoGroupChange], or null when nothing changed.
  Future<String?> setGroup(String nodeId, String? setting) => _write(() async {
    final tree = await loadTree();
    final node = tree[nodeId];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    return _changeGroup(
      tree,
      node,
      _cleanSetting(tree, setting, inherited: tree.inheritedGroupOf(nodeId)),
    );
  });

  /// Drops a card in another group on the Summary (PRD 8.2): sets
  /// [groupId] on that item only (AT-087), or for the default list, "No
  /// group" when it would otherwise follow a group (E-013). The card goes
  /// to the end of the group. Returns the token for [undoGroupChange], or
  /// null if it was already there.
  Future<String?> moveCardToGroup(String nodeId, String? groupId) => _write(
    () async {
      final tree = await loadTree();
      final node = tree[nodeId];
      if (node == null) throw const ActionRejected(RejectReason.notFound);
      _requireCard(await _arrange(tree), nodeId);
      if (tree.effectiveGroupOf(nodeId) == groupId) return null;
      final setting = groupId ?? noGroup;
      return _changeGroup(
        tree,
        node,
        _cleanSetting(tree, setting, inherited: tree.inheritedGroupOf(nodeId)),
      );
    },
  );

  /// Undo after a group change (frame 4): the setting is back, and the
  /// card is back in its place. Logged as the same events the other way
  /// round, each pointing at the event it undoes.
  Future<void> undoGroupChange(String groupChangedEventId) => _write(() async {
    final event = await _requireEvent(
      groupChangedEventId,
      EventTypes.groupChanged,
    );
    final change = jsonDecode(event.payload) as Map<String, Object?>;
    final tree = await loadTree();
    final node = tree[event.nodeId!];
    if (node == null) throw const ActionRejected(RejectReason.notFound);
    if (node.groupId != change[_newSettingKey]) {
      throw const ActionRejected(RejectReason.staleUndo);
    }
    final restored = change[_oldSettingKey] as String?;
    if (restored != null && !tree.hasGroup(restored)) {
      throw const ActionRejected(RejectReason.noSuchGroup);
    }
    await _changeGroup(
      tree,
      node,
      restored,
      undoes: groupChangedEventId,
      restoreSlot: change.containsKey(_oldSlotPositionKey)
          ? SummarySlot(
              ownerId: change[_ownerKey]! as String,
              groupId: change[_oldSlotGroupKey] as String?,
              position: change[_oldSlotPositionKey]! as int,
            )
          : null,
    );
  });

  /// Moves a card to [newIndex] within its group on the Summary (AT-087,
  /// AT-088) and logs `reordered` (AT-094). Only slots change, never the
  /// tree (AT-092).
  Future<void> reorderCard(String nodeId, int newIndex) => _write(() async {
    final tree = await loadTree();
    final sections = await _arrange(tree);
    final (section, index) = _requireCard(sections, nodeId);
    final cards = [...section.cards];
    final target = newIndex.clamp(0, cards.length - 1);
    if (target == index) return;
    final card = cards.removeAt(index);
    cards.insert(target, card);
    final groupId = section.group?.id;
    await _placeSlot(card.ownerId, groupId, [for (final c in cards) c.ownerId]);
    await _log(
      EventTypes.reordered,
      nodeId: nodeId,
      nodeType: card.node.type,
      domainId: tree.domainOf(nodeId)?.id,
      groupId: groupId,
      payload: {
        _viewKey: _summaryView,
        _ownerKey: card.ownerId,
        _oldPositionKey: index,
        _newPositionKey: target,
        _oldGroupKey: groupId,
        _newGroupKey: groupId,
      },
    );
    await _syncSummary();
  });

  /// The no-drag controls in the card sheet (frame 6, AT-116).
  Future<void> moveCardUp(String nodeId) => _shiftCard(nodeId, -1);

  Future<void> moveCardDown(String nodeId) => _shiftCard(nodeId, 1);

  Future<void> _shiftCard(String nodeId, int by) async {
    final (_, index) = _requireCard(await loadArrangedSummary(), nodeId);
    await reorderCard(nodeId, index + by);
  }

  Future<void> _shiftGroup(String id, int by) async {
    final groups = await loadGroups();
    final index = groups.indexWhere((g) => g.id == id);
    if (index < 0) throw const ActionRejected(RejectReason.noSuchGroup);
    await reorderGroup(id, index + by);
  }

  /// Writes [setting] on [node] and logs it. When the node's own card on
  /// the Summary changes group, its slot moves to the end of the new group,
  /// or back to [restoreSlot] for an Undo, and `reordered` is logged too.
  Future<String?> _changeGroup(
    Tree tree,
    TreeNode node,
    String? setting, {
    String? undoes,
    SummarySlot? restoreSlot,
  }) async {
    if (setting == node.groupId) return null;
    final before = await _arrange(tree);
    final oldGroup = tree.effectiveGroupOf(node.id);
    final card = _findCard(before, node.id);
    final oldSlot = card == null
        ? null
        : (await _liveSlots())[card.$1.cards[card.$2].ownerId];
    await (_db.update(_db.nodes)..where((n) => n.id.equals(node.id))).write(
      NodesCompanion(
        groupId: Value(setting),
        updatedAt: Value(utcMillis(_clock)),
      ),
    );
    final after = await loadTree();
    final newGroup = after.effectiveGroupOf(node.id);
    final eventId = _newId();
    final ownerId = card?.$1.cards[card.$2].ownerId;
    await _log(
      EventTypes.groupChanged,
      eventId: eventId,
      nodeId: node.id,
      nodeType: node.type,
      domainId: tree.domainOf(node.id)?.id,
      groupId: newGroup,
      payload: {
        _oldSettingKey: node.groupId,
        _newSettingKey: setting,
        _oldGroupKey: oldGroup,
        _newGroupKey: newGroup,
        _ownerKey: ?ownerId,
        if (oldSlot != null) ...{
          _oldSlotGroupKey: oldSlot.groupId,
          _oldSlotPositionKey: oldSlot.position,
        },
        _undoesKey: ?undoes,
      },
    );
    if (card != null && ownerId != null && newGroup != oldGroup) {
      if (restoreSlot != null) {
        await _writeSlot(ownerId, restoreSlot.groupId, restoreSlot.position);
      } else {
        await _writeSlot(
          ownerId,
          newGroup,
          NodeActions._endOf(await _liveSlots(), newGroup),
        );
      }
      final moved = _findCard(await _arrange(after), node.id);
      await _log(
        EventTypes.reordered,
        nodeId: node.id,
        nodeType: node.type,
        domainId: tree.domainOf(node.id)?.id,
        groupId: newGroup,
        payload: {
          _viewKey: _summaryView,
          _ownerKey: ownerId,
          _oldPositionKey: card.$2,
          _newPositionKey: moved?.$2,
          _oldGroupKey: oldGroup,
          _newGroupKey: newGroup,
          _undoesKey: ?undoes,
        },
      );
    }
    await _syncSummary();
    return eventId;
  }

  /// Puts [ownerId]'s slot in [groupId] where [visibleOrder] says, among
  /// every slot in the group, including those of owners with no card now,
  /// which keep their order. It goes just before the next visible card, or
  /// just after the previous one when it's last.
  Future<void> _placeSlot(
    String ownerId,
    String? groupId,
    List<String> visibleOrder,
  ) async {
    final all =
        [
          for (final slot in (await _liveSlots()).values)
            if (slot.groupId == groupId && slot.ownerId != ownerId) slot,
        ]..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          return byPosition != 0 ? byPosition : a.ownerId.compareTo(b.ownerId);
        });
    final order = [for (final s in all) s.ownerId];
    final at = visibleOrder.indexOf(ownerId);
    final next = at + 1 < visibleOrder.length ? visibleOrder[at + 1] : null;
    final previous = at > 0 ? visibleOrder[at - 1] : null;
    if (next != null && order.contains(next)) {
      order.insert(order.indexOf(next), ownerId);
    } else if (previous != null && order.contains(previous)) {
      order.insert(order.indexOf(previous) + 1, ownerId);
    } else {
      order.add(ownerId);
    }
    final positionOf = {for (final s in all) s.ownerId: s.position};
    for (var i = 0; i < order.length; i++) {
      if (positionOf[order[i]] == i) continue;
      await _writeSlot(order[i], groupId, i);
    }
  }

  Future<List<SummarySection>> _arrange(Tree tree) async {
    final summary = computeSummary(
      tree,
      now: _clock.now().toUtc(),
      settings: await _settings(),
    );
    return arrangeSummary(
      summary.cards,
      groups: await loadGroups(),
      slots: await _liveSlots(),
    );
  }

  Future<void> _requireGroup(String id) async {
    final row =
        await (_db.select(_db.contextGroups)
              ..where((g) => g.id.equals(id) & g.isDeleted.equals(false)))
            .getSingleOrNull();
    if (row == null) throw const ActionRejected(RejectReason.noSuchGroup);
  }

  static String _cleanName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw const ActionRejected(RejectReason.emptyTitle);
    return clean;
  }

  static List<ContextGroup> _sortedGroups(List<ContextGroupRow> rows) =>
      [
        for (final r in rows)
          ContextGroup(
            id: r.id,
            name: r.name,
            icon: r.icon,
            sortOrder: r.sortOrder,
          ),
      ]..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
}

/// The section holding [nodeId]'s card and its place there, or null when
/// it isn't on the Summary.
(SummarySection, int)? _findCard(List<SummarySection> sections, String nodeId) {
  for (final section in sections) {
    final index = section.cards.indexWhere((c) => c.id == nodeId);
    if (index >= 0) return (section, index);
  }
  return null;
}

(SummarySection, int) _requireCard(
  List<SummarySection> sections,
  String nodeId,
) =>
    _findCard(sections, nodeId) ??
    (throw const ActionRejected(RejectReason.notOnSummary));
