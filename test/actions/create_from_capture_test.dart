import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/capture_actions.dart';
import 'package:sahai/actions/node_actions.dart';
import 'package:sahai/data/database.dart';
import 'package:sahai/engine/node_type.dart';

import '../helpers.dart';

Matcher rejectedWith(RejectReason reason) =>
    throwsA(isA<ActionRejected>().having((e) => e.reason, 'reason', reason));

void main() {
  late TestApp app;
  late NodeActions actions;
  late CaptureActions captures;
  late String domain;
  late String project;

  setUp(() async {
    app = TestApp();
    actions = app.actions;
    var next = 0;
    captures = CaptureActions(
      app.db,
      clock: app.clock.clock,
      newId: () => 'capture-${++next}',
    );
    domain = await actions.create(type: NodeType.domain, title: 'Personal');
    project = await actions.create(
      type: NodeType.project,
      parentId: domain,
      title: 'Paperwork',
    );
  });

  tearDown(() => app.close());

  Future<List<CaptureEntry>> list() => captures.watch().first;

  Future<List<EventRow>> converted() => (app.db.select(
    app.db.events,
  )..where((e) => e.eventType.equals(EventTypes.converted))).get();

  test('the item, created and converted are saved together, and the '
      'capture stays until Remove or Keep', () async {
    final capture = await captures.add('renew passport');

    final task = await actions.create(
      type: NodeType.task,
      parentId: project,
      title: 'Renew passport',
      fromCapture: capture,
    );

    final tree = await actions.loadTree();
    expect(tree[task]!.title, 'Renew passport');
    expect(tree[task]!.parentId, project);
    expect((await converted()).single.nodeId, task);
    expect((await list()).single.id, capture);
  });

  test('a refused create writes no converted event', () async {
    final capture = await captures.add('renew passport');

    // A task can't go straight in a domain.
    expect(
      actions.create(
        type: NodeType.task,
        parentId: domain,
        title: 'Renew passport',
        fromCapture: capture,
      ),
      rejectedWith(RejectReason.invalidParent),
    );
    await pumpEventQueue();

    expect(await converted(), isEmpty);
    expect((await list()).single.itemsMade, 0);
  });

  test(
    'a deleted capture cannot make an item, and nothing is created',
    () async {
      final capture = await captures.add('renew passport');
      await captures.delete(capture);
      final before = (await actions.loadTree()).nodes.length;

      expect(
        actions.create(
          type: NodeType.task,
          parentId: project,
          title: 'Renew passport',
          fromCapture: capture,
        ),
        rejectedWith(RejectReason.notFound),
      );
      await pumpEventQueue();

      expect((await actions.loadTree()).nodes.length, before);
      expect(await converted(), isEmpty);
    },
  );

  test('Remove takes the capture off the list, and Undo brings back the '
      'capture but not the item', () async {
    final capture = await captures.add('renew passport');
    final task = await actions.create(
      type: NodeType.task,
      parentId: project,
      title: 'Renew passport',
      fromCapture: capture,
    );

    await captures.delete(capture);
    expect(await list(), isEmpty);

    await captures.undoDelete(capture);
    final entry = (await list()).single;
    expect(entry.id, capture);
    expect(entry.itemsMade, 1);
    expect((await actions.loadTree())[task], isNotNull);
  });

  test('items made counts only that capture\'s items', () async {
    final first = await captures.add('one');
    final second = await captures.add('two');
    for (final title in ['A', 'B']) {
      await actions.create(
        type: NodeType.task,
        parentId: project,
        title: title,
        fromCapture: first,
      );
    }
    await actions.create(
      type: NodeType.task,
      parentId: project,
      title: 'C',
      fromCapture: second,
    );
    await actions.create(type: NodeType.task, parentId: project, title: 'D');

    final made = {for (final e in await list()) e.text: e.itemsMade};
    expect(made, {'one': 2, 'two': 1});
  });
}
