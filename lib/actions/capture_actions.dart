import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';
import '../shared/ids.dart';
import '../shared/time.dart';
import 'node_actions.dart';

/// Where a capture came from, stored in its `captured` event (M6 decision
/// 5). Never the text itself.
enum CaptureSource {
  app,
  widget,
  share;

  String get dbName => name;
}

/// One capture in the list (PRD 8.5).
class CaptureEntry {
  const CaptureEntry({
    required this.id,
    required this.text,
    required this.capturedAt,
    required this.itemsMade,
  });

  final String id;
  final String text;

  /// When it was captured, in UTC. Editing doesn't change it (AT-097).
  final DateTime capturedAt;

  /// How many items have been made from it, counted from its `converted`
  /// events (M6 decision 4).
  final int itemsMade;
}

/// The only code that changes captures. Each method is one transaction
/// (PRD 13). Editing and deleting a capture aren't activity log events in
/// PRD 9, so only [add] writes one.
class CaptureActions {
  CaptureActions(
    this._db, {
    this._clock = const Clock(),
    this._newId = newUuid,
  });

  final SahaiDatabase _db;
  final Clock _clock;
  final IdGenerator _newId;

  /// The node type stored on a `captured` event, whose node is the capture.
  static const eventNodeType = 'capture';

  /// The `converted` event's payload key for the capture an item came from.
  static const captureIdKey = 'capture_id';

  /// The `captured` event's payload key for [CaptureSource].
  static const sourceKey = 'source';

  /// The non-deleted captures, newest first (AT-096), each with how many
  /// items were made from it. Emits again after any change to captures or
  /// events.
  Stream<List<CaptureEntry>> watch() => _db
      .customSelect(
        'SELECT c.id, c.text, c.created_at, '
        '(SELECT COUNT(*) FROM events e '
        "WHERE e.event_type = '${EventTypes.converted}' AND e.is_deleted = 0 "
        "AND json_extract(e.payload, '\$.$captureIdKey') = c.id) AS made "
        'FROM captures c WHERE c.is_deleted = 0 '
        'ORDER BY c.created_at DESC, c.rowid DESC',
        readsFrom: {_db.captures, _db.events},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            CaptureEntry(
              id: r.read<String>('id'),
              text: r.read<String>('text'),
              capturedAt: DateTime.fromMillisecondsSinceEpoch(
                r.read<int>('created_at'),
                isUtc: true,
              ),
              itemsMade: r.read<int>('made'),
            ),
        ],
      );

  /// Saves [text] as a new capture, with its `captured` event (AT-095,
  /// AT-104). Inner line breaks are kept, so a capture can be a list.
  Future<String> add(
    String text, {
    CaptureSource source = CaptureSource.app,
  }) async {
    final clean = _clean(text);
    return _db.transaction(() async {
      final id = _newId();
      final now = utcMillis(_clock);
      await _db
          .into(_db.captures)
          .insert(
            CapturesCompanion.insert(
              id: id,
              body: clean,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.events)
          .insert(
            EventsCompanion.insert(
              eventId: _newId(),
              eventType: EventTypes.captured,
              nodeId: Value(id),
              nodeType: const Value(eventNodeType),
              occurredAt: now,
              tzOffsetMinutes: tzOffsetMinutes(_clock),
              payload: Value(jsonEncode({sourceKey: source.dbName})),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return id;
    });
  }

  /// Changes the text. The captured time stays, so the list keeps its order
  /// (AT-097).
  Future<void> edit(String id, String text) async {
    final clean = _clean(text);
    return _db.transaction(() async {
      await _require(id);
      await (_db.update(_db.captures)..where((c) => c.id.equals(id))).write(
        CapturesCompanion(
          body: Value(clean),
          updatedAt: Value(utcMillis(_clock)),
        ),
      );
    });
  }

  /// Takes a capture off the list: Delete, and Remove after making an item.
  /// A soft delete, so Undo can bring it back (AT-098).
  Future<void> delete(String id) => _setDeleted(id, deleted: true);

  /// Undo for [delete]. Brings back the capture only; an item made from it
  /// stays (M6 decision 3).
  Future<void> undoDelete(String id) => _setDeleted(id, deleted: false);

  Future<void> _setDeleted(String id, {required bool deleted}) =>
      _db.transaction(() async {
        final row = await _row(id);
        if (row == null || row.isDeleted == deleted) {
          throw const ActionRejected(RejectReason.notFound);
        }
        await (_db.update(_db.captures)..where((c) => c.id.equals(id))).write(
          CapturesCompanion(
            isDeleted: Value(deleted),
            updatedAt: Value(utcMillis(_clock)),
          ),
        );
      });

  String _clean(String text) {
    final clean = text.trim();
    if (clean.isEmpty) throw const ActionRejected(RejectReason.emptyCapture);
    return clean;
  }

  Future<CaptureRow?> _row(String id) => (_db.select(
    _db.captures,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<CaptureRow> _require(String id) async {
    final row = await _row(id);
    if (row == null || row.isDeleted) {
      throw const ActionRejected(RejectReason.notFound);
    }
    return row;
  }
}
