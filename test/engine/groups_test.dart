import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/groups.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/order.dart';
import 'package:sahai/engine/tree.dart';
import 'package:sahai/engine/visibility.dart';

TreeNode node(String id, NodeType type, {String? parent, String? group}) =>
    TreeNode(
      id: id,
      parentId: parent,
      type: type,
      title: id,
      status: type.hasStatus ? NodeStatus.todo : null,
      sortOrder: 0,
      groupId: group,
    );

/// Biztras › Website relaunch (project P) › Task 1 › 1.1, 1.2; plus the
/// Client admin stream. [groups] are the groups that exist.
Tree tree({
  String? project,
  String? task,
  String? s11,
  String? s12,
  String? domain,
  Set<String>? groups,
}) => Tree([
  node('biztras', NodeType.domain, group: domain),
  node('p', NodeType.project, parent: 'biztras', group: project),
  node('t1', NodeType.task, parent: 'p', group: task),
  node('s1.1', NodeType.subtask, parent: 't1', group: s11),
  node('s1.2', NodeType.subtask, parent: 't1', group: s12),
  node('admin', NodeType.stream, parent: 'biztras'),
], groupIds: groups);

SummaryCard card(String id, {required String owner, String? group}) =>
    SummaryCard(
      node: node(id, NodeType.subtask),
      kind: CardKind.subtask,
      reason: CardReason.next,
      path: const [],
      ownerId: owner,
      groupId: group,
    );

const laptop = ContextGroup(id: 'laptop', name: 'At laptop', sortOrder: 0);
const errands = ContextGroup(id: 'errands', name: 'Errands', sortOrder: 1);
const home = ContextGroup(id: 'home', name: 'At home', sortOrder: 2);

/// "At laptop: x, y" for each section, "No group" for the default list.
List<String> layout(List<SummarySection> sections) => [
  for (final s in sections)
    '${s.group?.name ?? 'No group'}: ${s.cards.map((c) => c.id).join(', ')}',
];

void main() {
  group('inheritance (PRD 8.2)', () {
    test('AT-085 groups are inherited from the project', () {
      final t = tree(project: 'laptop');
      expect(t.effectiveGroupOf('s1.1'), 'laptop');
      expect(t.effectiveGroupOf('s1.2'), 'laptop');
      expect(t.groupSourceOf('s1.1')?.id, 'p');
      expect(t.effectiveGroupOf('biztras'), isNull);
    });

    test('AT-086 the nearest group wins', () {
      final t = tree(project: 'laptop', s12: 'errands');
      expect(t.effectiveGroupOf('s1.1'), 'laptop');
      expect(t.effectiveGroupOf('s1.2'), 'errands');
      expect(t.groupSourceOf('s1.2')?.id, 's1.2');
    });

    test('inherited group is the parent\'s effective group', () {
      final t = tree(domain: 'home', s12: 'errands');
      expect(t.inheritedGroupOf('s1.2'), 'home');
      expect(t.inheritedGroupOf('biztras'), isNull);
    });
  });

  group('E-013 No group overrides an inherited group', () {
    test('E-013 a node set to No group goes in the default list', () {
      final t = tree(project: 'laptop', s11: noGroup);
      expect(t.effectiveGroupOf('s1.1'), isNull);
      expect(t.groupSourceOf('s1.1'), isNull);
      expect(t.effectiveGroupOf('s1.2'), 'laptop');
    });

    test('E-013 nodes below No group follow it unless set themselves', () {
      final t = tree(project: 'laptop', task: noGroup, s12: 'errands');
      expect(t.effectiveGroupOf('t1'), isNull);
      expect(t.effectiveGroupOf('s1.1'), isNull);
      expect(t.effectiveGroupOf('s1.2'), 'errands');
      expect(t.inheritedGroupOf('s1.1'), isNull);
    });
  });

  group('E-014 a deleted group counts as unset', () {
    test('E-014 items follow the next group up', () {
      final t = tree(
        domain: 'home',
        project: 'laptop',
        s12: 'errands',
        groups: {'home', 'errands'},
      );
      expect(t.effectiveGroupOf('s1.1'), 'home');
      expect(t.effectiveGroupOf('s1.2'), 'errands');
      expect(t.hasGroup('laptop'), isFalse);
      expect(t.hasGroup(noGroup), isTrue);
    });

    test('E-014 with no group above, items go to the default list', () {
      final t = tree(project: 'laptop', groups: {'errands'});
      expect(t.effectiveGroupOf('s1.1'), isNull);
    });

    test('E-014 No group under a deleted group still stops inheritance', () {
      final t = tree(domain: 'home', project: 'laptop', s11: noGroup);
      expect(t.effectiveGroupOf('s1.1'), isNull);
    });
  });

  group('arrangeSummary', () {
    test('AT-083 with no groups every card is in the default list', () {
      final sections = arrangeSummary(
        [card('a', owner: 'p'), card('b', owner: 's')],
        groups: const [],
        slots: const {},
      );
      expect(layout(sections), ['No group: a, b']);
      expect(sections.single.group, isNull);
    });

    test('groups come in their order, the default list last, and empty '
        'groups are left out (AT-084)', () {
      final sections = arrangeSummary(
        [
          card('n', owner: 'n'),
          card('e', owner: 'e', group: 'errands'),
          card('l', owner: 'l', group: 'laptop'),
        ],
        groups: const [errands, home, laptop],
        slots: const {},
      );
      expect(layout(sections), ['At laptop: l', 'Errands: e', 'No group: n']);
    });

    test('cards follow their slot positions within a group', () {
      final sections = arrangeSummary(
        [
          card('x', owner: 'x', group: 'laptop'),
          card('y', owner: 'y', group: 'laptop'),
          card('z', owner: 'z', group: 'laptop'),
        ],
        groups: const [laptop],
        slots: const {
          'x': SummarySlot(ownerId: 'x', groupId: 'laptop', position: 7),
          'y': SummarySlot(ownerId: 'y', groupId: 'laptop', position: 2),
          'z': SummarySlot(ownerId: 'z', groupId: 'laptop', position: 5),
        },
      );
      expect(layout(sections), ['At laptop: y, z, x']);
    });

    test('a card whose slot is in another group goes last, in tree order '
        '(AT-089)', () {
      final sections = arrangeSummary(
        [
          card('moved', owner: 'm', group: 'laptop'),
          card('new', owner: 'n', group: 'laptop'),
          card('x', owner: 'x', group: 'laptop'),
        ],
        groups: const [laptop, errands],
        slots: const {
          'm': SummarySlot(ownerId: 'm', groupId: 'errands', position: 0),
          'x': SummarySlot(ownerId: 'x', groupId: 'laptop', position: 3),
        },
      );
      expect(layout(sections), ['At laptop: x, moved, new']);
    });

    test('a card in an unknown group goes in the default list', () {
      final sections = arrangeSummary(
        [card('a', owner: 'a', group: 'gone')],
        groups: const [laptop],
        slots: const {},
      );
      expect(layout(sections), ['No group: a']);
    });
  });

  group('E-015 movedIds', () {
    test('E-015 one item moved to the top is the only one moved', () {
      expect(movedIds(['a', 'b', 'c', 'd'], ['d', 'a', 'b', 'c']), ['d']);
    });

    test('E-015 one item moved down is the only one moved', () {
      expect(movedIds(['a', 'b', 'c', 'd'], ['b', 'c', 'a', 'd']), ['a']);
    });

    test('E-015 no change moves nothing', () {
      expect(movedIds(['a', 'b', 'c'], ['a', 'b', 'c']), isEmpty);
      expect(movedIds(const [], const []), isEmpty);
    });

    test('E-015 two separate moves give two items', () {
      final moved = movedIds(
        ['a', 'b', 'c', 'd', 'e', 'f'],
        ['f', 'a', 'b', 'd', 'c', 'e'],
      );
      expect(moved, hasLength(2));
      expect(moved, contains('f'));
    });
  });
}
