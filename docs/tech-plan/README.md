# Sahai v1: Technical plan

- **Status:** Draft for owner review
- **Written:** 2026-10-30
- **Covers:** v1 (Android), milestones M1 to M8
- **Sources:** [`docs/PRD.md`](../PRD.md), [`docs/PRD_Edits.md`](../PRD_Edits.md), [`docs/tests/Sahai_Acceptance_Tests_v1.xlsx`](../tests/) (AT-001 to AT-124)
- **Related:** [test matrix](test-matrix.md), decision records [0001](../decisions/0001-architecture-and-engine.md) to [0005](../decisions/0005-notifications.md)

This plan says **how** v1 will be built. The PRD says **what** it does, and where the two seem to disagree, the PRD (with `PRD_Edits.md`) wins. Nothing here is built yet. Every package listed is a **proposal** until the owner accepts its decision record, and each package is added only in the milestone that needs it.

---

## 1. Constraints that shape everything

| Constraint | Where it comes from | What it means for the code |
|---|---|---|
| Fully offline, no `INTERNET` permission | PRD 3, 13 | No network packages. The release manifest is checked automatically for network permissions (section 9). |
| No analytics, telemetry or crash reporting | PRD 3, 14 | No SDKs of that kind, ever, in v1. |
| Data stays on the device | PRD 3 | One SQLite file. The only off-device copy is Android Auto Backup. |
| Summary is computed, never stored | PRD 6, 10 | The visibility engine is a pure function of the tree and the time. |
| Everything reversible, multi-step writes atomic | PRD 7, 13 | Every user action is one database transaction, including its log event. |
| Fast with 10,000 items | PRD 13 | Recompute < 50 ms, cold start < 2 s. Benchmarked early (M2), not just in M7. |
| Time correctness | PRD 3, 7, 13 | Store UTC; due dates are local calendar dates; a fake clock is used in every time test. |
| Sync-ready | PRD 3 | UUID keys, `updated_at` on every row, soft deletes only. |

---

## 2. Toolchain

| Tool | Version | Notes |
|---|---|---|
| Flutter | **3.47.3** (stable) | Installed on the owner's machine. Pinned: upgrading Flutter is its own PR. |
| Dart | 3.13.3 | Comes with Flutter. |
| JDK | 17 or newer | Android Studio's bundled JDK is fine. `flutter doctor` confirms. |
| Android SDK | Platform 36, build tools | Through Android Studio's SDK Manager. |
| Android `minSdk` | **26** (Android 8.0) | PRD 3. |
| Android `targetSdk` / `compileSdk` | **36** (Android 16) | Google Play has required API 36 for new apps and updates since 2026-08-31. |
| Application ID | `com.finusam.sahai` | |

The Flutter version is also written in `pubspec.yaml` (`environment: flutter:`) so a mismatched machine fails fast. A version manager (FVM) is optional and not required.

---

## 3. Architecture

Three layers, with dependencies pointing inwards only. See [decision 0001](../decisions/0001-architecture-and-engine.md).

```
┌────────────────────────────────────────────────────────────┐
│ UI (Flutter)                                               │
│  screens, widgets, Riverpod providers, go_router           │
├────────────────────────────────────────────────────────────┤
│ Application (Dart)                                         │
│  actions: complete, undo, set aside, delete, reopen, …     │
│  each action = one transaction: write rows + log event     │
│  notification scheduler, recompute triggers                │
├────────────────────────────────────────────────────────────┤
│ Engine (pure Dart: no Flutter, no database)                │  Data (drift / SQLite)
│  visibility rules (PRD 6), recurrence, presets, day start, │  tables, migrations,
│  due labels, slot ordering, surfaced diff                  │  repositories
└────────────────────────────────────────────────────────────┘
```

- **Engine.** Plain Dart functions over plain data. It takes a snapshot of the tree, the current time and the settings, and returns the Summary cards and the next time anything changes. It never reads the clock or the database itself, so every PRD rule can be tested in milliseconds with any date.
- **Data.** drift on SQLite (section 5). Repositories turn rows into engine data and back.
- **Application.** The only place that writes. Each user action runs in one transaction that updates rows, writes the activity log event, and returns an *undo token*: what's needed to reverse it.
- **UI.** Screens watch Riverpod providers. They don't contain rules.

### Folder layout (created in M1)

```
lib/
  main.dart
  app/            app widget, router, theme
  engine/         pure Dart: tree.dart, visibility.dart, recurrence.dart,
                  presets.dart, day_start.dart, due_label.dart, slots.dart
  data/           drift database, tables, migrations, repositories
  actions/        complete, undo, set_aside, delete, reopen, move, capture, …
  notifications/  schedule planner (pure) + platform adapter
  features/       summary/, set_aside/, explorer/, capture/, settings/, onboarding/
  shared/         clock provider, ids, logging, widgets
test/             unit and widget tests (mirrors lib/)
integration_test/ on-device flows
tool/             scripts (AT coverage report, benchmark data generator)
```

---

## 4. The engine

### 4.1 Tree snapshot

The app keeps an in-memory copy of all non-deleted nodes (plus deleted roots, so undo works), loaded once at start and updated after each write. With 10,000 items this is a few MB.

### 4.2 Visibility (PRD 6)

One depth-first walk from each domain, carrying "an ancestor is set aside or deleted" downwards:

1. Skip anything whose ancestor is hidden (check 5).
2. For each project, work out the **current task**: the first task by `sort_order` that is TODO and not deleted, awake or not (PRD 5).
3. A node is a **leaf** if it's TODO, not deleted, and has no TODO non-deleted children. Set-aside children still count as TODO (PRD 5).
4. Apply the type gate (check 6): subtask = lowest-order awake TODO subtask of the current task; task = current task; project = no TODO tasks; stream item = lowest-order awake TODO **non-recurring** item, or any awake recurring item.
5. Resolve the card's **effective group**: the nearest group set on itself or an ancestor (PRD 8.2).

The cost is O(n log n), because sibling lists are sorted. The engine also returns **`nextChangeAt`**: the earliest future wake time, recurring show time or day-start boundary. The app sets a timer for it (AT-034).

### 4.3 Time

- **Clock.** Everything gets the time from an injected `Clock` (`package:clock`). Tests use a fixed or advancing fake clock. Nothing calls `DateTime.now()` directly. There's no standard lint rule for this, so a CI step searches `lib/` for it and fails outside the one clock file.
- **Logical day.** `logicalDate(instant, dayStartHour)` returns the calendar date a moment belongs to. Before the day-start hour (default 4:00 AM), it's still the previous day. This one function drives presets (AT-043, AT-110), due labels (AT-062, AT-063) and recurring show dates (AT-061).
- **Presets.** Computed from the logical day: Tonight = 8 PM, Tomorrow morning = next logical day 8 AM, 3 days later = logical day + 3 at 8 AM, Next week = next Monday 8 AM. Presets in the past are hidden (AT-044). The times are user-editable (M7).
- **Storage.** Instants (`snooze_until`, `created_at`, `updated_at`, `completed_at`, event times) are stored as UTC milliseconds. A set-aside time is an absolute moment, so it survives a time-zone change (AT-118). Due dates are stored as local calendar dates (`YYYY-MM-DD`) and read in the phone's *current* time zone (AT-081).

### 4.4 Recurring items (PRD 7)

- **Schedule.** Stored as JSON in `recurrence`: frequency (daily, weekly, monthly or yearly), interval, weekdays or day-of-month, and repeat-from (due date or completion date).
- **Next due date.** A pure function. A missing month day falls on the last day (AT-073). Repeating from the due date is based on the *missed* due date, not the payment day (AT-067, AT-068). Repeating from completion is based on the completion's logical date (AT-069).
- **Show time.** `due_on − lead_days` at the day-start hour, computed in the current time zone each time rather than stored. A user's own set-aside of an occurrence is stored in `snooze_until` as normal, and the item is awake only when both have passed (AT-072).
- **Completion.** Write a `completed` event that includes the due date (AT-082), advance `due_on`, keep status TODO (AT-077), and clear `snooze_until`. All of this happens in one transaction, with an undo token that restores the old `due_on` (AT-070, E-001).
- **Due labels.** "Due Nov 5", "Due today", "N days overdue", measured in logical days (AT-062, AT-063).

### 4.5 Surfaced events (PRD 9, PRD_Edits E-001 and E-002)

After each recompute, the engine compares the new card set with the previous one. Each newly visible item gets a `surfaced` event.

- **E-002:** `occurred_at` is the moment the item actually became visible. If it came back while the app was closed, that's the wake or show time that caused it, worked out by the engine, not the time the app was opened.
- **E-001:** for Undo of a completion, the action records `completion_undone` (pointing to the `completed` event) and the restored card gets **no** new `surfaced` event.
- The last known card set is stored in `settings` so the comparison works across app restarts.

### 4.6 Summary order and groups (PRD 8.2, M5)

`summary_slots` stores one position per owner: each project, each stream (its non-recurring card), and each recurring item. The next card for the same owner takes the same slot (AT-088). A card that moves to another group goes to the end (AT-089), and new slots go to the end (AT-090). Dragging changes only slots and group settings, never the tree (AT-092).

---

## 5. Data

See [decision 0002](../decisions/0002-database-drift-sqlite.md).

- **Engine:** **drift** on SQLite, opened with `drift_flutter`. Since `sqlite3` 3.x, SQLite is bundled automatically; the old `sqlite3_flutter_libs` package is end-of-life and not used.
- **Threading:** the database runs on a background isolate (a separate Dart thread) so queries never block the UI (PRD 13).
- **File:** `sahai.sqlite` in the app's private files directory.
- **Journal mode:** WAL (write-ahead log), with a full checkpoint each time the app goes to the background. That way the main database file is complete when Android Auto Backup copies it (section 8).

### Tables (PRD 10)

| Table | Notes |
|---|---|
| `nodes` | All six node types in one table, as in PRD 10. `id` is a UUID v4 string. `status` is null for domains and streams. `due_on` is `TEXT YYYY-MM-DD`; `recurrence` is JSON text. Indexes: `(parent_id, status, is_deleted)` and `(snooze_until)`. |
| `context_groups` | As PRD 10. |
| `summary_slots` | As PRD 10. Primary key `owner_id`. |
| `events` | As PRD 9. Append-only: rows are never updated or deleted, except by retention compaction (M7). |
| `captures` | As PRD 10. |
| `settings` | A single row, with typed columns per setting plus `updated_at`. |

Every table has `created_at`/`updated_at` in UTC ms and `is_deleted`. Every write sets `updated_at` (AT-010).

### Transactions and undo

Each action (complete, undo, set aside, wake, delete, restore, reopen, move, reorder, convert a capture) is **one transaction**: change rows, write the event, commit. A force-close mid-way leaves either all of it or none of it (AT-119). The action returns an undo token; the snackbar holds it for 5 seconds (AT-025, AT-026), and Undo runs the reverse action, also as one transaction.

### Migrations

- drift schema versions. Each released schema is exported as a JSON snapshot into the repo (`drift_dev schema dump`).
- Generated tests migrate **from every released version** to the current one and check that the data survives (PRD 13, AT-012).
- **Before any migration**, the database file is copied to `pre-migration/sahai-v{old}-{timestamp}.sqlite`. The newest two copies are kept, and they're excluded from Auto Backup to protect the 25 MB limit.
- Migrations only add tables and columns, or copy data into new shapes. They never drop data.

---

## 6. State and navigation

See [decision 0003](../decisions/0003-state-management-and-navigation.md).

- **Riverpod** (`flutter_riverpod`) provides the database, clock, engine output and actions to screens. Tests swap in fakes with provider overrides.
- **go_router** handles screens and deep links. A notification tap opens `/summary?focus=<nodeId>` (AT-051). The Explorer's "Open in tree" goes to `/explorer?node=<id>` (AT-029).

### When the Summary recomputes (PRD 6)

- after every action (the action invalidates the snapshot provider)
- on app resume (`AppLifecycleListener`), which also re-reads the time zone
- when `nextChangeAt` arrives (a single `Timer`)

---

## 7. Notifications (PRD 7, M3 and M4)

See [decision 0005](../decisions/0005-notifications.md).

The approach is to **plan notifications ahead of time with the engine, and reschedule after every change.**

- The planner (pure Dart) steps the engine forward through upcoming wake and show times. Assuming no further user changes, it finds which items will **newly appear on the Summary** at each moment.
  - One item at a moment produces a named notification ("Call Rahul is back", AT-051).
  - Several produce one grouped notification that lists them (AT-050).
  - Different moments produce separate notifications (AT-052).
  - An item that wakes but stays hidden under a set-aside ancestor produces nothing (AT-054).
  - Items with Remind me off, or all items when notifications are off in Settings, produce nothing (AT-053, AT-056).
- **Recurring items** get two reminders at the reminder time (default 9:00 AM): one on the show day and one on the due day if still not done (AT-078). The due-day reminder ignores set-aside ancestors (AT-079).
- **Rescheduling.** Everything is cancelled and rescheduled after each action, on app start, on resume and after a time-zone change. The phone's own alarm list survives restarts through the plugin's boot receiver (AT-057).
- **Horizon.** The plan covers the next **60 days**, capped at **100 scheduled notifications**. Android allows 500 alarms per app. If the app isn't opened for over 60 days, later reminders aren't scheduled. This is listed as risk R4.
- **Inexact by default.** Reminders may arrive a few minutes late (PRD 7). With "Exact reminders" on, the app asks for Android's alarm permission (`SCHEDULE_EXACT_ALARM`; Android 14 and higher deny it by default and send the user to a system screen) and uses exact scheduling (AT-058).
- **Notification permission.** On Android 13 and higher, `POST_NOTIFICATIONS` is requested the first time the user sets something aside, never at launch (AT-055).

**Packages:** `flutter_local_notifications` (schedule, group, boot restore, exact alarms), `timezone` (time-zone-aware scheduling) and `flutter_timezone` (the phone's current zone name).

---

## 8. Android configuration

### Permissions (final list for v1)

| Permission | Why | When |
|---|---|---|
| `POST_NOTIFICATIONS` | Wake and bill reminders (Android 13+) | Asked at the first set aside |
| `RECEIVE_BOOT_COMPLETED` | Restore scheduled reminders after a restart | Added by the notifications plugin |
| `SCHEDULE_EXACT_ALARM` | Only if "Exact reminders" is on | Asked when the setting is turned on |
| `VIBRATE` | Notification vibration, if the plugin needs it | Added by the plugin |

**No `INTERNET`, no `ACCESS_NETWORK_STATE`.**
- Flutter adds `INTERNET` to the **debug and profile** manifests so hot reload works. That's expected, and those builds are never shipped.
- The **release** manifest gets a `tools:node="remove"` rule for both network permissions, so a plugin can't sneak one in.
- CI inspects the built release APK and fails if any network permission appears (AT-011).

Each permission still needs the owner's approval when it's added, as with packages.

### Auto Backup (PRD 3, M7)

- `android:allowBackup="true"`, with `fullBackupContent` (Android 11 and lower) and `dataExtractionRules` (Android 12 and higher) pointing to rule files.
- The rules **include** `sahai.sqlite` and **exclude** the `-wal`/`-shm` files (complete anyway after the background checkpoint), `pre-migration/`, caches and temp files.
- The database size is shown in Settings, with a warning above 20 MB (AT-112).
- Restore is tested on a real device with `adb shell bmgr` (AT-111).

### Signing and release (M8)

- The upload keystore and `key.properties` stay off the repo (already in `.gitignore`). Play App Signing holds the app signing key.
- Builds are Android App Bundles (`.aab`). `versionName` follows the milestone tag; `versionCode` increases with every upload.

---

## 9. Testing

| Level | Tool | What it covers | Where it runs |
|---|---|---|---|
| **Unit** | `flutter test` | Engine rules, recurrence, presets, labels, notification planner, actions and repositories against an in-memory SQLite database, migrations | Every PR (CI) |
| **Widget** | `flutter test` | Each screen with fake providers: cards, snackbar Undo, pickers, menus, accessibility labels, large fonts | Every PR (CI) |
| **Integration** | `integration_test` | Key flows on an emulator or phone: restart persistence, reorder, complete and undo | Before merging a milestone into `main`, and on demand |
| **Real device (manual)** | Phone | Notifications with the app closed, restarts, widget, share sheet, backup restore, TalkBack, release checks | Listed in each PR; recorded in the AT sheet |

- **Naming:** a test that covers an acceptance test starts with its ID, e.g. `test('AT-034 waking subtask takes its place back', …)`. Tests for PRD edits use the edit ID, e.g. `E-002 …`.
- **Fake clock:** time tests set the clock to the AT sheet's dates (November 2026; Nov 1 is a Sunday) and advance it. Time-zone tests switch the `timezone` location in-process, e.g. Asia/Kolkata to Asia/Dubai (AT-081, AT-118).
- **Coverage report:** a small script in `tool/` lists the AT IDs found in test names and compares them with the matrix, so gaps show up in PRs.
- **Performance:** a generator builds a 10,000-item tree. The engine benchmark runs on the development machine from **M2** as an early warning. The real check (AT-114) is on a mid-range phone with a profile build in M7.
- **Bug fixes:** a failing test comes first (CLAUDE.md).

The full mapping of all 124 tests is in [test-matrix.md](test-matrix.md).

---

## 10. Continuous integration (design only; built in M1)

GitHub Actions, on every PR into `dev` or `main`:

1. Set up Flutter 3.47.3 (from the pinned version).
2. `flutter pub get`
3. `dart format --output=none --set-exit-if-changed .`
4. `flutter analyze` (fails on any warning)
5. `flutter test` (unit and widget)
6. `flutter build apk --release` (debug-signed; no real keys in CI)
7. A permission check on the release APK, which fails on `INTERNET` or `ACCESS_NETWORK_STATE`.
8. A search of `lib/` that fails if `DateTime.now()` is used outside the clock file.

Notes:
- A private repo on GitHub Free gets 2,000 Actions minutes a month. A run should take about 6–10 minutes.
- Integration tests on an emulator are a separate, manually started workflow, so they don't use up the minutes.
- Signed release builds stay manual until M8. Keys never go into CI before then.

---

## 11. Privacy in the code

- **Logging.** One small `log` helper that accepts IDs, types and counts only. There's no way to pass task or capture text, and `avoid_print` is on. Release builds log nothing to the console.
- **No network code.** No HTTP client package is a dependency, and the CI permission check backs this up.
- **Send feedback** (M7) opens the user's email app with an Android `ACTION_SENDTO` intent, using a few lines of our own Kotlin through a platform channel (a bridge from Dart to Android code). Sahai itself sends nothing.

---

## 12. Dependencies (proposed)

Current versions were checked on pub.dev on 2026-10-30. Each package is added only in the milestone shown, after its decision record is accepted, with its exact version pinned in `pubspec.yaml` (no `^` ranges). `pubspec.lock` is committed.

| Package | Version | License | Publisher | Last release | Purpose | From |
|---|---|---|---|---|---|---|
| `drift` | 2.35.3 | MIT | simonbinder.eu | 2026-10-23 | Typed SQLite, migrations | M1 |
| `drift_flutter` | 0.3.1 | MIT | simonbinder.eu | 2026-07-11 | Opens the database on a background isolate | M1 |
| `drift_dev` (dev) | 2.35.2 | MIT | simonbinder.eu | 2026-10-23 | Code generation, schema dumps, migration tests | M1 |
| `build_runner` (dev) | 2.17.1 | BSD-3 | tools.dart.dev | 2026-10-14 | Runs code generation | M1 |
| `flutter_riverpod` | 3.4.3 | MIT | dash-overflow.net | 2026-09-03 | State management | M1 |
| `go_router` | 18.1.2 | BSD-3 | flutter.dev | 2026-10-29 | Navigation, deep links | M1 |
| `clock` | 1.1.3 | Apache-2.0 | tools.dart.dev | 2026-08-28 | Injectable clock for tests | M1 |
| `uuid` | 4.6.0 | MIT | yuli.dev | 2026-07-15 | UUID primary keys | M1 |
| `intl` | 0.20.3 | BSD-3 | dart.dev | 2026-06-25 | Date and time formatting | M1 |
| `flutter_lints` (dev) | 6.0.0 | BSD-3 | flutter.dev | 2025-05-27 | Official lint rules | M1 |
| `flutter_local_notifications` | 22.3.3 | BSD-3 | dexterx.dev | 2026-10-25 | Scheduled, grouped notifications | M3 |
| `timezone` | 0.11.2 | BSD-2 | labs.dart.dev | 2026-10-12 | Time-zone-aware schedules | M3 |
| `flutter_timezone` | 5.1.1 | Apache-2.0 | wolverinebeach.net | 2026-10-03 | Phone's current time zone | M3 |
| `home_widget` | 0.10.0 | BSD-3 | antonborri.es | 2026-09-17 | Home-screen widget (to confirm in an M6 spike) | M6 |
| `receive_sharing_intent` | 1.9.0 | Apache-2.0 | kasem.dev | 2026-06-24 | Share target (or about 40 lines of our own Kotlin, decided in M6) | M6 |

All of these are actively maintained (released within the last 6 months, except `flutter_lints`, the official and stable Flutter lint set) and score 110–160 out of 160 pub points. `sqlite3`, `path_provider` and `path` come in automatically through drift; the lock file pins them.

**Considered and not chosen:** `sqflite` (hand-written SQL, no generated migration tests), `sqlite3_flutter_libs` (end-of-life), `flutter_bloc` (more boilerplate for a two-person team), `very_good_analysis` (stricter than needed; can be revisited), `url_launcher` (a few lines of Kotlin are enough for one email draft).

---

## 13. Milestone breakdown

Before each milestone: wireframes approved (PRD 16), the developer's estimate, and a saved checklist in `docs/plans/`.

| # | Builds | Engine and data work | Key risks / spikes | ATs (Must) |
|---|---|---|---|---|
| **M1** Foundations | Flutter project, CI, lint rules, database and migration setup, Explorer (create, edit, reorder, move, delete with Undo, lock markers) | Tables, UUIDs, `updated_at`, soft delete, clock provider, actions and undo tokens, pre-migration copy | Confirm `sqlite3` 3.x builds on the dev machine and adds no permissions; set up the release-manifest network guard | 12 (11) |
| **M2** Core loop | Visibility engine, Summary, complete with Undo, reopen, card path, activity log | Engine (4.2), surfaced diff (E-001, E-002), events | **10,000-item benchmark now**, not in M7 | 20 (17) |
| **M3** Set aside | Set-aside picker (presets, scope), Explorer set-aside, Set-Aside page, notifications | Logical day, presets, `nextChangeAt` timer, notification planner | Notification behaviour with the app closed differs by phone maker: test on 2+ devices | 28 (22) |
| **M4** Recurring | Schedules, due labels, skip, stop repeating, recurring reminders | Recurrence functions, show-time calculation | Time-zone and month-end edge cases; a full simulated month with the fake clock | 22 (17) |
| **M5** Groups and order | Groups, inheritance, drag between groups, saved positions | Slots (4.6) | Drag-and-drop accessibility needs button alternatives (AT-116) | 12 (9) |
| **M6** Capture | Scratchpad, convert form, widget, share target | Captures, `captured`/`converted` events | Widget quick-add without opening the full app: spike, then a decision record | 10 (9) |
| **M7** Polish and safety | Onboarding, full Settings, backup rules, 20 MB warning, log retention, accessibility, speed check | Retention compaction | Backup restore on a real device; TalkBack pass | 16 (7) |
| **M8** Release prep | Icon, store listing, privacy policy, Data safety form, testing track upload | — | Play Console account type and the 12-tester rule (PRD 2) | 4 (3) |

---

## 14. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | A plugin adds `INTERNET` through manifest merging | `tools:node="remove"` in the release manifest, plus the CI APK check |
| R2 | Summary too slow at 10,000 items | Pure in-memory engine; benchmark from M2; cache the snapshot and update it after each write |
| R3 | Phone makers delay or kill scheduled notifications | Plan ahead with the OS alarm list (no background job needed); test on 2+ brands; "Exact reminders" option |
| R4 | Reminders stop if the app isn't opened for 60+ days | Horizon of 60 days, rescheduled on every open. If this matters, a periodic background job could extend it later (an extra package, so it needs approval) |
| R5 | Auto Backup copies a database mid-write, or goes over 25 MB | WAL checkpoint on background; only the main file is backed up; size warning; log retention |
| R6 | Day-start and time-zone bugs | One `logicalDate` function, table-driven tests with the AT sheet's dates, time-zone switch tests |
| R7 | Migrations lose data | Generated migration tests from every released schema, plus the pre-migration copy |
| R8 | Wireframes aren't ready when a milestone starts | PRD 16 makes them a gate. `docs/design/` is still empty, so M1's Explorer wireframes are needed first |

---

## 15. Open questions for the owner

These need an answer before the milestone shown. I haven't guessed. Once answered, each answer goes into `PRD_Edits.md`.

| # | Question | Why it matters | Suggestion | Needed by |
|---|---|---|---|---|
| Q1 | When a project is deleted, should only the project's row get `is_deleted = true`, or its tasks' rows too? AT-009 says "their rows still exist with is_deleted = true". | Flagging only the deleted node is simplest and makes Undo exact. Flagging every row needs a way to tell "deleted with the parent" from "deleted on its own earlier", so Undo doesn't bring back older deletions. | Flag every row (matching AT-009), and store which delete action flagged it so Undo reverses only that action. This adds one column, `deleted_by_event`, to `nodes`. | M1 |
| Q2 | Where do compacted daily summaries of old log events live? PRD 10 lists six tables; PRD 9 asks for daily summaries. | A seventh table is a schema change to the PRD's model. | Add an `event_daily_summaries` table in M7. | M7 |
| Q3 | Should recurring items that are waiting for their show date appear on the Set-Aside page? PRD 7 calls them "set aside automatically"; PRD 8.3 lists items "set aside directly". | Listing them would put every bill on the Set-Aside page all month. | Don't list them; the Explorer shows each one's next due date. They do appear if the user sets an occurrence aside themselves. | M4 |
| Q4 | Is v1 English-only? | Affects how text is stored in the code. | English only, with all text kept in one place so translation is easy later. | M1 |

### Already answered

| Edit | Answer |
|---|---|
| [E-001](../PRD_Edits.md#e-001-undo-of-a-completion-is-logged-as-completion_undone) | Undo of a completion logs `completion_undone`; the restored card gets no new `surfaced` event |
| [E-002](../PRD_Edits.md#e-002-a-surfaced-event-uses-the-wake-time) | `surfaced` uses the moment the item became visible, even if the app was closed |

### Assumptions (tell me if any are wrong)

- **Moving an item** keeps its type. It can only go under a valid parent type, e.g. a subtask moves to another task, a task to another project, a stream item to another stream, a project or stream to another domain (AT-006).
- **Reordering a task above the current task** makes it the new current task, because the PRD defines the current task by order.
- **Settings live in the database**, not in Android's shared preferences, so one backup file holds everything.
