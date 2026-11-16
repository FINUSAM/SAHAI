import 'dart:async';
import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/actions/capture_actions.dart';
import 'package:sahai/data/database.dart';

import '../helpers.dart';

// Decision 0007: the app and the capture dialog each open `sahai.sqlite`
// with `shareAcrossIsolates`, which makes them two clients of one drift
// isolate. drift_flutter needs the phone to find that isolate, so this
// builds the same arrangement directly: one DriftIsolate, two clients.
void main() {
  late Directory dir;
  late DriftIsolate server;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sahai_shared');
    final path = '${dir.path}${Platform.pathSeparator}sahai.sqlite';
    server = await DriftIsolate.spawn(() => NativeDatabase(File(path)));
  });

  tearDown(() async {
    await server.shutdownAll();
    await dir.delete(recursive: true);
  });

  Future<SahaiDatabase> client() async =>
      SahaiDatabase(await server.connect(), clock: TestClock().clock);

  test('a capture saved by the dialog shows in the open app\'s list straight '
      'away', () async {
    final app = await client();
    addTearDown(app.close);
    final lists = StreamQueue(CaptureActions(app).watch());
    expect(await lists.next, isEmpty);

    final dialog = await client();
    await CaptureActions(
      dialog,
      clock: TestClock().clock,
    ).add('ask Priya for the template', source: CaptureSource.widget);
    await dialog.close();

    final list = await lists.next.timeout(const Duration(seconds: 5));
    expect(list.map((c) => c.text), ['ask Priya for the template']);
    await lists.cancel();
  });

  test('the dialog closing its connection leaves the app\'s working', () async {
    final app = await client();
    addTearDown(app.close);
    final dialog = await client();
    await CaptureActions(dialog).add('first', source: CaptureSource.share);
    await dialog.close();

    await CaptureActions(app).add('second');
    final texts = await app.select(app.captures).map((c) => c.body).get();
    expect(texts, unorderedEquals(['first', 'second']));
  });
}

/// Reads a stream one value at a time.
class StreamQueue<T> {
  StreamQueue(Stream<T> stream) {
    _sub = stream.listen((v) {
      if (_waiting.isNotEmpty) {
        _waiting.removeAt(0).complete(v);
      } else {
        _ready.add(v);
      }
    });
  }

  late final StreamSubscription<T> _sub;
  final _ready = <T>[];
  final _waiting = <Completer<T>>[];

  Future<T> get next {
    if (_ready.isNotEmpty) return Future.value(_ready.removeAt(0));
    final c = Completer<T>();
    _waiting.add(c);
    return c.future;
  }

  Future<void> cancel() => _sub.cancel();
}
