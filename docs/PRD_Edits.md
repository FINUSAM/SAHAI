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

---

## E-003: Deleting a node soft-deletes everything under it, and Undo restores exactly that

- **PRD section:** 5 (Deleted), 7 (Delete), 10 (Data Model)
- **Type:** Clarification, with a data model addition
- **Decided by:** FINUSAM, 2026-10-30
- **Status:** Approved, not yet in PRD.md

**Change**

- Deleting any node sets `is_deleted = true` on that node **and on every node under it**: a domain's streams, stream items, projects, tasks and subtasks; a project's tasks and subtasks; and so on.
- `nodes` gains one column, `deleted_by_event`, holding the `event_id` of the `deleted` event that flagged the row.
- Undo (and the `restored` event) clears `is_deleted` only on rows flagged by that same delete. Anything the user had deleted separately before stays deleted.

**Reason**

- Matches AT-009 ("their rows still exist with is_deleted = true") and makes each row's state clear on its own, which helps Phase 3 sync.
- Recording which delete flagged each row keeps Undo exact (AT-008).

**Affects:** AT-008, AT-009, plus a new automated test: Undo of a project delete doesn't bring back a task that was deleted earlier on its own.

---

## E-004: Compacted activity log summaries live in their own table

- **PRD section:** 9 (Retention), 10 (Data Model)
- **Type:** Addition (seventh table)
- **Decided by:** FINUSAM, 2026-10-30 (delegated to the technical plan)
- **Status:** Approved, not yet in PRD.md

**Change**

- Add a table `event_daily_summaries`: `id`, `day` (local calendar date), `domain_id`, `group_id`, `event_type`, `count`, `created_at`, `updated_at`.
- When raw events pass 12 months, compaction adds their counts to this table and removes the raw rows, in one transaction.

**Reason**

- Keeps `events` strictly one row per real action, so its meaning never changes.
- Summaries have a different shape from events and are easier to query in their own table.

**Affects:** AT-113.

---

## E-005: Recurring items waiting for their show date are listed on the Set-Aside page

- **PRD section:** 7 (Recurring items), 8.3 (Set-Aside Page)
- **Type:** Clarification
- **Decided by:** FINUSAM, 2026-10-30
- **Status:** Approved, not yet in PRD.md

**Change**

- A recurring item waiting for its next show date counts as set aside for the Set-Aside page. It's listed with the other items, soonest first, with title, path, wake time (its show time) and time remaining.
- **Wake now** brings it onto the Summary immediately with its real due label (e.g. "Due Dec 5"). The due date and schedule don't change.
- **Change time** moves only this occurrence's show time, earlier or later. The due date and the schedule after it don't change.
- If the user has also set the occurrence aside, it's listed once, at whichever time is later, because that's when it actually returns.
- If its stream or domain is set aside, it's listed under that ancestor rather than on its own (as in PRD 8.3 and AT-047).

**Reason**

- The Set-Aside page shows everything that's away and when it comes back, including bills between cycles.

**Affects:** AT-046, AT-047, plus a new automated test: a paid bill is listed on the Set-Aside page until its show date, and Wake now shows it with its real due label.

---

## E-006: v1 is English-only

- **PRD section:** 8 (Screens), 13 (Non-functional)
- **Type:** Clarification
- **Decided by:** FINUSAM, 2026-10-30
- **Status:** Approved, not yet in PRD.md

**Change**

- v1's interface is in English only.
- All user-facing text is kept in one place in the code, so translations can be added later without rewriting screens.
- Dates and times are formatted for the phone's locale settings (e.g. 12- or 24-hour clock).

**Affects:** none.
