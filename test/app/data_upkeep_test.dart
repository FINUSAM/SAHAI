import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/engine/node_type.dart';

import '../helpers.dart';
import '../widget_helpers.dart';

/// Risk R5: the write-ahead log is folded back into the main file when the
/// app goes to the background, so the `-wal` file is usually empty.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sahai_upkeep');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  testSahai('going to the background empties the -wal file', (tester) async {
    final path = '${dir.path}${Platform.pathSeparator}sahai.sqlite';
    final app = TestApp(executor: NativeDatabase(File(path)));
    await pumpSahai(tester, app: app);
    await app.actions.create(type: NodeType.domain, title: 'Personal');
    await tester.pumpAndSettle();
    final wal = File('$path-wal');
    expect(wal.lengthSync(), greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();

    expect(wal.lengthSync(), 0);
    expect(File(path).lengthSync(), greaterThan(0));
  });
}
