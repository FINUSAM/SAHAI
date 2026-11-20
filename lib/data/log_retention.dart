import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../engine/recurrence.dart';
import '../shared/ids.dart';
import '../shared/time.dart';
import 'database.dart';
import 'occurrences.dart';
import 'settings.dart';

/// How long raw activity log events are kept (PRD 9, E-004).
const retentionMonths = 12;

/// The first logical day whose events are still kept whole: the same date
/// [retentionMonths] before [today]. A day missing from that month, such
/// as Feb 29, falls on the month's last day, as due dates do (PRD 7).
DateTime retentionStart(DateTime today) {
  final month = DateTime(today.year, today.month - retentionMonths);
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(
    month.year,
    month.month,
    today.day > lastDay ? lastDay : today.day,
  );
}

/// The logical day an event belongs to, in the local time it happened
/// (its own offset, so travel doesn't move it) and by [dayStartMinutes].
DateTime eventDay(int occurredAt, int tzOffsetMinutes, int dayStartMinutes) {
  final wall = DateTime.fromMillisecondsSinceEpoch(
    occurredAt,
    isUtc: true,
  ).add(Duration(minutes: tzOffsetMinutes));
  final minutes = wall.hour * 60 + wall.minute;
  final back = minutes < dayStartMinutes ? 1 : 0;
  return DateTime(wall.year, wall.month, wall.day - back);
}

/// Compacts the activity log (PRD 9 retention, E-004): events older than
/// [retentionMonths] become daily counts per logical day, domain, group and
/// event type in `event_daily_summaries`, and the raw rows go, in one
/// transaction. Returns how many events were compacted.
///
/// The latest completion or skip of each repeating item is kept whatever
/// its age, because it can still be reopened and E-018 sets no time limit
/// (decision 0009). It reads only ids, types and times, never task content.
Future<int> compactEventLog(
  SahaiDatabase db, {
  Clock clock = const Clock(),
  IdGenerator newId = newUuid,
}) => db.transaction(() async {
  final settings = await readSettings(db);
  final dayStart = settings.dayStartMinutes;
  final today = eventDay(utcMillis(clock), tzOffsetMinutes(clock), dayStart);
  final keepFrom = retentionStart(today);
  // Every event before this instant is a candidate; two days of slack
  // cover any time zone and day start, and [eventDay] decides exactly.
  final candidatesBefore = DateTime.utc(
    keepFrom.year,
    keepFrom.month,
    keepFrom.day + 2,
  ).millisecondsSinceEpoch;

  final kept = {for (final e in await latestOccurrenceEvents(db)) e.eventId};
  final candidates = await (db.select(
    db.events,
  )..where((e) => e.occurredAt.isSmallerThanValue(candidatesBefore))).get();

  final counts = <_SummaryKey, int>{};
  final compacted = <String>[];
  for (final event in candidates) {
    if (kept.contains(event.eventId)) continue;
    final day = eventDay(event.occurredAt, event.tzOffsetMinutes, dayStart);
    if (!day.isBefore(keepFrom)) continue;
    final key = _SummaryKey(
      formatDueOn(day),
      event.domainId,
      event.groupId,
      event.eventType,
    );
    counts[key] = (counts[key] ?? 0) + 1;
    compacted.add(event.eventId);
  }
  if (compacted.isEmpty) return 0;

  final now = utcMillis(clock);
  for (final MapEntry(:key, value: count) in counts.entries) {
    final existing =
        await (db.select(db.eventDailySummaries)..where(
              (s) =>
                  s.day.equals(key.day) &
                  s.eventType.equals(key.eventType) &
                  s.domainId.equalsNullable(key.domainId) &
                  s.groupId.equalsNullable(key.groupId),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await db
          .into(db.eventDailySummaries)
          .insert(
            EventDailySummariesCompanion.insert(
              id: newId(),
              day: key.day,
              domainId: Value(key.domainId),
              groupId: Value(key.groupId),
              eventType: key.eventType,
              count: count,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (db.update(
        db.eventDailySummaries,
      )..where((s) => s.id.equals(existing.id))).write(
        EventDailySummariesCompanion(
          count: Value(existing.count + count),
          updatedAt: Value(now),
        ),
      );
    }
  }
  // In chunks, to stay under SQLite's limit on query parameters.
  for (var i = 0; i < compacted.length; i += 500) {
    final chunk = compacted.sublist(
      i,
      i + 500 > compacted.length ? compacted.length : i + 500,
    );
    await (db.delete(db.events)..where((e) => e.eventId.isIn(chunk))).go();
  }
  return compacted.length;
});

/// One row of `event_daily_summaries`.
class _SummaryKey {
  const _SummaryKey(this.day, this.domainId, this.groupId, this.eventType);

  final String day;
  final String? domainId;
  final String? groupId;
  final String eventType;

  @override
  bool operator ==(Object other) =>
      other is _SummaryKey &&
      other.day == day &&
      other.domainId == domainId &&
      other.groupId == groupId &&
      other.eventType == eventType;

  @override
  int get hashCode => Object.hash(day, domainId, groupId, eventType);
}
