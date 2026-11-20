# 0009: Log compaction keeps the events Reopen still needs

- **Status:** Accepted
- **Date:** 2026-11-20
- **Decided by:** FINUSAM (choice B in M7 PR 2's checklist)
- **Related:** M7 PR 2 (#55, #86), PRD 7 and 9, E-004, E-018, AT-113, AT-125 to AT-127

## Context

PRD 9 keeps raw activity log events for 12 months, then compacts them into daily
totals (E-004). E-018 lets a repeating item reopen its last completion or skip
with no time limit, and reopening needs that `completed` or `skipped` event: its
payload holds the due date to bring back.

The two collide on slow schedules. A yearly bill paid in November 2026 is due
again in November 2027. Its completion turns 12 months old a few days before the
next one, while it's still the latest. Compaction would delete it, and
"Reopen last completion" would vanish without warning. A bill left unpaid for
more than a year would lose it too.

## Decision

Compaction keeps the latest `completed` or `skipped` event of each repeating
item that isn't deleted, whatever its age. Everything else older than 12 months
is compacted as PRD 9 says.

- The same query (`latestOccurrenceEvents` in `lib/data/occurrences.dart`)
  decides what compaction keeps and what Reopen can offer, so the two can't
  drift apart.
- Compaction keeps a slightly wider set than Reopen offers: for example, the
  latest completion even after Undo cancelled it. That's at most one event per
  repeating item, and it's harmless, because Reopen also checks that nothing
  cancelled the event and that the due date hasn't moved on.
- Events that cancel a kept event (`completion_undone`, `skip_undone`,
  `reopened`) are compacted normally once they're old. By then the item's due
  date has moved on, so the kept event is no longer offered anyway.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Keep the latest completion or skip of each repeating item | Reopen keeps working with no time limit, as E-018 says; at most one extra row per repeating item | The log isn't strictly "nothing older than 12 months" | **Chosen** |
| Let Reopen disappear once its event is compacted | Compaction stays a single simple rule | A 12-month limit E-018 doesn't have; needs a new PRD edit; the action vanishes silently on yearly items | Conflicts with E-018 |
| Store the restore data on the node instead of reading the event | Independent of the log | A new column and a schema change for data the log already has; two copies to keep in step | More moving parts for no gain |

## Consequences

- The log can hold a handful of events older than 12 months. With one per
  repeating item, the size effect is negligible next to the 10 MB target
  (AT-113's test runs 25 months of heavy use and stays under it).
- If E-018 ever gains a time limit, the query can drop old events and this
  decision is superseded.
