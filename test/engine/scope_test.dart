import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';
import 'package:sahai/engine/scope.dart';

import 'engine_helpers.dart';

/// The scope dropdown's choices for each card type (PRD 7).
void main() {
  final tree = sampleTree().build();

  List<(String, SetAsideLevel)> scopes(String id) => [
    for (final o in setAsideScopes(tree, id)) (o.node.id, o.level),
  ];

  test('AT-036 scope options match the card type, the item first', () {
    expect(scopes('s1.1'), [
      ('s1.1', SetAsideLevel.item),
      ('t1', SetAsideLevel.task),
      ('relaunch', SetAsideLevel.project),
      ('biztras', SetAsideLevel.domain),
    ]);
    expect(scopes('t1'), [
      ('t1', SetAsideLevel.item),
      ('relaunch', SetAsideLevel.project),
      ('biztras', SetAsideLevel.domain),
    ]);
    expect(scopes('relaunch'), [
      ('relaunch', SetAsideLevel.item),
      ('biztras', SetAsideLevel.domain),
    ]);
    expect(scopes('A'), [
      ('A', SetAsideLevel.item),
      ('admin', SetAsideLevel.stream),
      ('biztras', SetAsideLevel.domain),
    ]);
  });

  test('a node from the Explorer can only set itself aside', () {
    expect(scopes('biztras'), [('biztras', SetAsideLevel.item)]);
    expect(tree['biztras']!.type, NodeType.domain);
  });

  test('an unknown id has no options', () {
    expect(setAsideScopes(tree, 'missing'), isEmpty);
  });
}
