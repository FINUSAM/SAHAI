# PRD edits

Changes and clarifications to [`PRD.md`](PRD.md) that the owner has approved but that aren't in the PRD text yet.

**Read the PRD and this file together.** Where they differ, this file wins, because it's newer.

## Rules

- Each entry needs the owner's explicit approval. Claude adds an entry only for a change the owner has approved, for example the owner's answer to a PRD question.
- Entries are numbered `E-001`, `E-002`, … and are never deleted, so the history stays visible.
- When the owner updates `PRD.md` to include an entry, its status changes to **Merged into PRD.md (date)**.
- If an entry changes what an acceptance test expects, or needs a new test, list it under **Affects**.

**Status values:** Approved, not yet in PRD.md · Merged into PRD.md (date) · Withdrawn (date, reason)

---

## E-001: Undo of a completion is logged as `completion_undone`

- **PRD section:** 9 (Activity Log), with 7 (Complete, Recurring items)
- **Type:** Addition
- **Decided by:** FINUSAM, 2026-10-30
- **Status:** Approved, not yet in PRD.md

**Change**

- Add `completion_undone` to the event types in section 9.
- When the user taps Undo after completing an item, the original `completed` event stays in the log, and a `completion_undone` event is added after it.
- Its payload holds the `event_id` of the `completed` event it cancels. For a recurring item it also holds the due date that was restored.
- Undo restores the previous card as if the tap never happened, so the restored card doesn't get a new `surfaced` event and keeps its original surfaced time. A card that briefly replaced it keeps its own `surfaced` event, because it really did appear.

**Reason**

- The activity log stays append-only (rows are only added, never changed or removed). That keeps it trustworthy and helps Phase 3 sync.
- `reopened` means a deliberate reopen from the Explorer. Keeping undone taps separate stops them from misleading the Phase 2 planner, for example when measuring the time from surfaced to done.
- It mirrors Undo of a delete, which already has its own event (`restored`).

**Affects:** AT-025, AT-070 (an automated test checks the `completion_undone` event in each). AT-032 is unchanged.

---

## E-002: A `surfaced` event uses the wake time

- **PRD section:** 9 (Activity Log), with 6 (recompute triggers)
- **Type:** Clarification
- **Decided by:** FINUSAM, 2026-10-30
- **Status:** Approved, not yet in PRD.md

**Change**

- An item's `surfaced` event records the moment it actually became visible on the Summary, not the moment the app noticed.
- If the item came back while the app was closed, `occurred_at` is the time that made it visible again: its own wake time, an ancestor's wake time, or a recurring item's show date (the start of that day, per "Day starts at"). The event is written when the app next recomputes, but carries that earlier time.
- `tz_offset_minutes` is the local offset at that moment.

**Reason**

- Time-of-day patterns and the time from surfaced to done would be wrong if they used the time the app happened to be opened.

**Affects:** AT-031 (unchanged), plus a new automated test: an item that wakes while the app is closed gets a `surfaced` event at its wake time.
