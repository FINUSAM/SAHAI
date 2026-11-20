import 'package:drift/drift.dart';

import 'database.dart';

/// The latest `completed` or `skipped` event of each repeating item that
/// isn't deleted (E-018). Only these can ever be reopened, so log
/// compaction keeps them whatever their age (decision 0009).
Future<List<EventRow>> latestOccurrenceEvents(SahaiDatabase db) => db
    .customSelect(
      '''
      SELECT e.* FROM events e
      JOIN nodes n ON n.id = e.node_id
      WHERE n.recurrence IS NOT NULL AND n.is_deleted = 0
        AND e.event_type IN ('completed', 'skipped')
        AND e.occurred_at = (
          SELECT MAX(e2.occurred_at) FROM events e2
          WHERE e2.node_id = e.node_id
            AND e2.event_type IN ('completed', 'skipped'))
      ''',
      readsFrom: {db.events, db.nodes},
    )
    .asyncMap((row) => db.events.mapFromRow(row))
    .get();

/// Which of [eventIds] a later event has cancelled: an Undo
/// (`completion_undone`, `skip_undone`) or a reopen (`reopened`), each of
/// which names the event it cancels in `undoes_event_id`.
Future<Set<String>> cancelledEventIds(
  SahaiDatabase db,
  Iterable<String> eventIds,
) async {
  final ids = eventIds.toList();
  if (ids.isEmpty) return {};
  final marks = List.filled(ids.length, '?').join(', ');
  final rows = await db
      .customSelect(
        '''
        SELECT json_extract(payload, '\$.undoes_event_id') AS undone
        FROM events
        WHERE event_type IN ('completion_undone', 'skip_undone', 'reopened')
          AND json_extract(payload, '\$.undoes_event_id') IN ($marks)
        ''',
        variables: [for (final id in ids) Variable.withString(id)],
        readsFrom: {db.events},
      )
      .get();
  return {for (final row in rows) row.read<String>('undone')};
}

/// A repeating item's completion or skip that can still be reopened
/// (E-018).
class ReopenableOccurrence {
  const ReopenableOccurrence({
    required this.eventId,
    required this.skipped,
    required this.on,
    required this.dueOn,
  });

  /// The `completed` or `skipped` event that reopening cancels.
  final String eventId;

  /// A skip rather than a completion.
  final bool skipped;

  /// The logical day it was completed or skipped.
  final DateTime on;

  /// The due date reopening brings back.
  final DateTime dueOn;
}
