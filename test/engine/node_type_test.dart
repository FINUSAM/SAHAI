import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';

void main() {
  group('AT-002 only valid children can be added', () {
    test('domain offers stream or project', () {
      expect(NodeType.domain.allowedChildren, {
        NodeType.stream,
        NodeType.project,
      });
    });

    test('stream offers stream item only', () {
      expect(NodeType.stream.allowedChildren, {NodeType.streamItem});
    });

    test('project offers task only', () {
      expect(NodeType.project.allowedChildren, {NodeType.task});
    });

    test('task offers subtask only', () {
      expect(NodeType.task.allowedChildren, {NodeType.subtask});
    });

    test('subtask and stream item offer nothing', () {
      expect(NodeType.subtask.allowedChildren, isEmpty);
      expect(NodeType.streamItem.allowedChildren, isEmpty);
    });

    test('only domains sit at the top level', () {
      for (final type in NodeType.values) {
        expect(canHaveChild(null, type), type == NodeType.domain);
      }
    });

    test('allowed children and parent types agree', () {
      for (final parent in NodeType.values) {
        for (final child in NodeType.values) {
          expect(
            canHaveChild(parent, child),
            child.parentType == parent,
            reason: '$parent -> $child',
          );
        }
      }
    });
  });

  test('AT-003 domains and streams have no status', () {
    expect(NodeType.domain.hasStatus, isFalse);
    expect(NodeType.stream.hasStatus, isFalse);
    for (final type in [
      NodeType.project,
      NodeType.task,
      NodeType.subtask,
      NodeType.streamItem,
    ]) {
      expect(type.hasStatus, isTrue, reason: '$type');
    }
  });

  test('database names round-trip', () {
    for (final type in NodeType.values) {
      expect(NodeType.fromDbName(type.dbName), type);
    }
    expect(NodeStatus.fromDbName('todo'), NodeStatus.todo);
    expect(NodeStatus.fromDbName('done'), NodeStatus.done);
    expect(NodeStatus.fromDbName(null), isNull);
  });
}
