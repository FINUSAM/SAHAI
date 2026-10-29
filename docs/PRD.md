# GTD AI (Sahai) — Product Requirements Document

## 1. Summary & Philosophy

Sahai (GTD AI) is an offline-first Android app that keeps deep project structure out of the way and shows only the next step for each project and stream.

Traditional task managers create administrative drag: people spend more time filing and sorting tasks than doing them. Sahai separates the two.

- **Organization is deep.** Work lives in domains, projects, streams, sequential tasks, and soft-ordered subtasks and stream items.
- **Execution is flat.** The Summary Page shows only immediately actionable items, at most one per project and one per stream, plus recurring routines when due, optionally grouped under user-defined context headers.
- **The core is deterministic; AI is optional and non-destructive.** v1 is a fully offline SQLite engine. Later phases add Bring-Your-Own-Key (BYOK) AI that proposes changes but never commits them without the user's approval.

## 2. Target Users & Success Metrics

v1 targets Android users who juggle several areas of work and life and want their data to stay on their own phone.

- **Primary (v1):** people running several streams of responsibility at once, such as a founder with client work and personal admin, who feel buried by long to-do lists.
- **Secondary (v2):** the same users, when they are comfortable creating an API key with OpenAI, Anthropic or Groq to unlock AI capture and planning.

The app collects no usage data, so v1 is validated in stages through direct use and written feedback.

| Stage | How | Done when |
| --- | --- | --- |
| 1. Founder use | The founder uses v1 daily, logs every issue, and reviews the list each week. Fixes ship before the next weekly cycle. | A full week of daily use with no new issues |
| 2. Tester trial | 3 testers install it through a Google Play testing track and use it daily. | Each tester gives a verdict: would they keep using it, and does it cut time spent organizing |
| 3. Production access | A closed test with at least 12 testers opted in for 14 continuous days, if the developer account requires it | Google grants production access |
| 4. Public release | Google Play Console ratings and 30-day retained installers | 4.3 or higher after 100 ratings; retention benchmark set after the first 500 installs |
| All stages | In-app "Send feedback" opens an email the user writes and sends | Reviewed weekly |

Stage 1 repeats weekly until v1 is flawless. Stage 3 applies only to personal Google Play developer accounts created after November 13, 2023 ([Google Play Help](https://support.google.com/googleplay/android-developer/answer/14151465)); without it, 3 testers can give feedback but the app cannot go public.

## 3. Platform, Storage & Data Durability

v1 is a fully offline Android app whose only off-device copy is Android's own backup to the user's Google account.

**Platform**

- Android, built with Flutter. Minimum Android 8.0 (API 26); target SDK is the level Google Play currently requires.
- v1 declares no Internet permission, and every v1 feature works offline. Phase 2 AI features add the permission.
- iOS follows in Phase 2 (section 11).

**Storage**

- One on-device SQLite database. No analytics SDKs, external telemetry or mandatory accounts.
- All timestamps are stored in UTC and shown in local time.

**Android Auto Backup (v1)**

- Enabled with `android:allowBackup="true"`. Include rules are set in both `android:fullBackupContent` (Android 11 and lower) and `android:dataExtractionRules` (Android 12 and higher). They cover the database and preferences and exclude caches and temporary files.
- Android copies this data to the user's own Google account when the phone is idle, charging and on Wi-Fi. It restores automatically on reinstall or on a new Android phone. The developer has no access to these backups.
- Android backs up at most 25 MB per app and silently stops above that. The activity log retention policy (section 9) keeps the database well below this, and Settings warns if the database passes 20 MB.
- Auto Backup is a safety net, not a user-facing backup: users can't see it or pick an older copy. Manual export arrives in Phase 2.

**Sync-ready foundations (built in v1, used in Phase 3)**

- Client-generated UUID primary keys.
- An `updated_at` UTC timestamp on every row.
- Soft deletes (`is_deleted`) everywhere, so deletions can sync and history stays intact.

## 4. Information Architecture

All work sits in one tree: domains hold streams and projects, projects hold sequential tasks, and tasks hold subtasks.

&#91;embedded content: tree model · 9 nodes, 2 on the Summary\]

Task 1 has two subtasks, so only Subtask 1.1 shows. Task 2 stays locked until Task 1 is DONE, and the stream shows only its first item.

| Node | Lives in | Holds | Status | Can appear on the Summary |
| --- | --- | --- | --- | --- |
| Domain | Top level | Streams, projects | None | Never |
| Stream | Domain | Stream items | None | Never (its items can) |
| Stream item | Stream | Nothing | TODO / DONE | One per stream; recurring items whenever due |
| Project | Domain | Tasks | TODO / DONE | When it has no TODO tasks |
| Task | Project | Subtasks (optional) | TODO / DONE | When it is the current task and a leaf |
| Subtask | Task | Nothing | TODO / DONE | One per task |

- **Domain:** a top-level area of responsibility, such as Biztras, Personal or Freelance. It is a container only.
- **Stream:** an ongoing queue with no end, such as household errands.
- **Project:** a multi-step outcome with a defined end.
- **Task:** a sequential step. Task N+1 stays locked until Task N is DONE.
- **Subtask and stream item:** single actions. Soft order decides which one is shown next; it does not mean one depends on another. Users change it by reordering, or skip an item by setting it aside.
- **Recurring stream item:** a stream item that comes back on a schedule, such as a credit card bill due on the 5th of every month. It is the only item with a due date in v1 (section 7).

## 5. Status Model & Vocabulary

Items have two statuses, TODO and DONE; set aside and deleted are a timestamp and a flag, not statuses.

- **TODO / DONE** apply to projects, tasks, subtasks and stream items. Domains and streams have no status.
- **No extra statuses.** There is no In Progress, Waiting, Blocked or Hold.
- **Set aside** means a `snooze_until` time in the future. Any node can carry one, including domains and streams. When the time passes, the item is awake again with no database write.
- **Waiting on someone** means set aside until the follow-up time.
- **Deleted** means `is_deleted` is true. The item and everything under it disappear from every screen but stay in the database.
- **Recurring items** never stay DONE. Completing one logs it and sets the item aside until its next occurrence.

| Term | Meaning |
| --- | --- |
| Awake | Not set aside: `snooze_until` is empty or in the past |
| Current task | The first task in a project's order that is TODO and not deleted, whether awake or set aside |
| Leaf | A TODO, non-deleted item whose children are all DONE or deleted. Set-aside children still count as TODO |
| Card | One item on the Summary Page, labelled subtask, task, project or stream item |

## 6. Summary Visibility Rules

An item appears on the Summary Page only when it passes all six checks below. The Summary is recomputed from these rules and never stored.

1. **Type.** It is a project, task, subtask or stream item. Domains and streams never appear.
2. **Status.** It is TODO and not deleted.
3. **Leaf.** It has no TODO children, ignoring deleted ones.
4. **Awake.** It is not set aside.
5. **Ancestors.** No ancestor is set aside or deleted. A set-aside or deleted domain, stream, project or task hides everything below it.
6. **Gate for its type:**
   - **Subtask:** it belongs to the current task of its project, and it is that task's awake TODO subtask with the lowest soft order.
   - **Task:** it is the current task of its project. When its last subtask is done it does not auto-complete; it appears for sign-off.
   - **Project:** no extra gate. By check 3 it appears once it has no TODO tasks: as a prompt to add tasks when it is empty, or for sign-off when all are DONE.
   - **Stream item:** it is the awake TODO non-recurring item with the lowest soft order in its stream, so recurring items never block it. Recurring items skip this gate: every awake recurring item shows, so an unpaid bill never hides the next one.

**What follows from these rules**

- The Summary shows at most one card per project and one non-recurring card per stream.
- When a set-aside subtask with a lower soft order wakes, it replaces the visible one.
- If the current task is set aside, the project stalls: later tasks stay locked.
- If every remaining subtask of the current task is set aside, nothing from that project shows until one wakes.
- If every remaining item in a stream is set aside, the stream shows nothing.

The app recomputes the Summary after every change, on app resume, and when the next set-aside time passes.

## 7. Actions & Lifecycle

Every action can be reversed: completions and deletions have Undo, DONE items can be reopened, and set-aside items can be woken early.

**Complete**

- The checkmark marks the item DONE. The card leaves and the next item for that project or stream takes its place.
- A snackbar offers Undo for 5 seconds. Undo returns the item to TODO and restores the previous card.

**Reopen**

- Any DONE item can be set back to TODO from the Explorer.
- Reopening an item also reopens every DONE ancestor (subtask, then task, then project), so a DONE parent never holds a TODO child.
- Reopening an earlier task makes it the current task again. Later tasks re-lock but keep their own progress.

**Set aside**

- From a Summary card: the item itself is set aside by default. A dropdown widens it to any parent: a subtask offers its task, project or domain; a task, its project or domain; a project, its domain; a stream item, its stream or domain. Only the chosen node gets the wake time, and everything under it is hidden (section 6, check 5).
- From the Explorer: any node, including a whole project, stream or domain, for example to pause Freelance during a vacation.
- The user picks a quick preset or a custom date and time. Default presets are Tonight (8 PM today), Tomorrow morning (8 AM), 3 days later (8 AM) and Next week (Monday 8 AM); users can change them in Settings. The custom picker can't choose a time in the past.
- Presets follow a "Day starts at" setting, default 4:00 AM. Before that hour the app treats the time as the previous day, so "Tomorrow morning" chosen at 1:30 AM means later that same morning.
- Presets whose time has already passed today, such as "Tonight" at 11 PM, are hidden.
- Items wake automatically at their time, or early through Wake now on the Set-Aside page.

**Delete**

- Deleting from the Explorer is a soft delete with a snackbar Undo. It hides the item and everything under it, and keeps the data for history and sync.

**Recurring items**

Recurring items handle routines with a fixed rhythm, such as bills. In v1 only stream items can recur.

- **Schedule:** daily, weekly on chosen weekdays, monthly on a chosen day, or yearly, each with an optional interval such as every 2 weeks. A day missing from a month, such as the 31st, falls on that month's last day. Due dates are calendar dates in the phone's current time zone, so a bill due on the 5th is due on the 5th wherever the phone is.
- **Repeat from:** the due date, for bills and rent, or the completion date, for something like a haircut every 4 weeks.
- **Show before due:** how many days early the item appears, default 3. Until then it is set aside automatically, waking at the start of that day.
- **Card label:** shows the due date, such as "Due Nov 5", "Due today" or "3 days overdue". Overdue is a label, not a status. "Due today" lasts all of the due day, and "1 day overdue" begins when the next day starts, per the "Day starts at" setting.
- **Complete:** logs the completion, then the item returns to TODO, set aside until its next show date. Undo restores the previous occurrence.
- **Paid late:** when repeating from the due date, the next occurrence follows the missed due date, not the payment day. If that date has already passed, the item shows straight away as overdue.
- **Skip this occurrence:** moves to the next one without logging a completion.
- **Set aside:** pushes back only the current occurrence; the schedule does not change.
- **Stop repeating:** turns it into a normal stream item and clears its due date, since one-off items have no due date in v1.

Example: a Finance & Bills stream in the Personal domain, with the default 3-day lead.

| Stream item | Repeats | Appears on |
| --- | --- | --- |
| Pay HDFC card | Monthly on the 5th | The 2nd |
| Pay SBI card | Monthly on the 12th | The 9th |
| Pay ICICI card | Monthly on the 18th | The 15th |
| Pay Axis card | Monthly on the 25th | The 22nd |

If HDFC is still unpaid on the 9th, SBI appears alongside it rather than behind it.

**Notifications (v1)**

- When a set-aside item wakes and reappears on the Summary, the app notifies. A single item is named, such as "Call Rahul is back", and tapping it opens that item. Items waking at the same time share one notification, such as "3 items are back", which expands to list each title. Items waking at different times notify separately.
- The set-aside picker has a Remind me switch, on by default. With it off, the item comes back to the Summary without a notification.
- An item that wakes but doesn't reappear on the Summary, for example because its domain is still set aside, doesn't notify. Bill due-date reminders are the exception (below).
- Notifications are on by default and can be turned off in Settings.
- On Android 13 and higher, notification permission is requested the first time the user sets something aside, not at first launch.
- Reminders use inexact scheduling by default and may arrive a few minutes late. An optional "Exact reminders" setting requests Android's alarm permission.
- Scheduled reminders are restored after the phone restarts.
- Recurring items notify when they appear and again on their due date if still not done. These arrive at a reminder time setting (default 9:00 AM), not at the day-start hour.
- The due-date reminder still fires when one of the item's ancestors is set aside, so pausing a domain never hides a bill's due date. Tapping it opens the item so it can be marked done.

## 8. Screens

v1 has six screens: Onboarding, Summary, Set-Aside, Explorer, Capture and Settings.

### 8.1 Onboarding

Onboarding has users set up their own first project from real work, and teaches the one-step-at-a-time rule in about two minutes. There is no sample data. It can be skipped at any step and replayed from Settings.

1. **Name your areas.** The user creates one or two domains from their own life or work, such as their company or Personal.
2. **Add something real.** They add one project they are working on now, its first task, and two subtasks. Short prompts with examples guide each entry.
3. **Summary reveal.** Only their first subtask shows, with a short explanation of why.
4. **Try it without changing anything.** Tick off the first subtask, then tap Undo. Set it aside with a preset and watch the second subtask take its place. Open the Set-Aside page and tap Wake now; the first subtask returns. A short note explains that the task reappears for sign-off once all its subtasks are done.

Future AI features are described in Settings › About, not in onboarding.

### 8.2 Summary Page

- Shows the cards allowed by section 6.
- **Context groups** are optional and user-created, with a name and an optional icon. Cards with no group appear in a default list.
- **Group assignment:** a group can be set on any node in the Explorer. A card appears in the group set on itself, or else in the group of its nearest ancestor that has one. Setting "At laptop" on a project puts all its cards there unless an item says otherwise.
- **Dragging a card to another group** sets that group on that item only.
- **Order:** each project, each stream and each recurring item owns one slot, and the manual order is saved per slot. When the next card for a project or stream appears, it takes the same position. If it belongs to a different group, it goes to the end of that group. A new slot appears at the end of its group.
- Dragging never changes the tree order.
- **Card actions:** checkmark (DONE, with Undo), clock (Set aside), and tap (shows the path, such as Domain › Project › Task, with Open in tree). Recurring cards also offer Skip this occurrence.

### 8.3 Set-Aside Page

- Lists every item set aside directly, soonest wake time first. Items hidden only because an ancestor is set aside appear under that ancestor.
- Each card shows the title, path, wake time and time remaining.
- Actions: Wake now and Change time.

### 8.4 Explorer (Tree View)

- Two paths: Domain › Project › Task › Subtask, and Domain › Stream › Stream item.
- Create, edit and delete nodes; reorder tasks, subtasks and stream items; move items between parents.
- Set aside any node, set context groups, set repeat schedules on stream items, and reopen DONE items.
- Locked tasks and set-aside items are visibly marked.

### 8.5 Capture

- **v1:** a fast plain-text scratchpad. Entries are listed newest first, each with the date and time it was captured. Any entry can be edited, or deleted with Undo.
- **Entry points outside the app:** a home-screen widget for quick entry, and an Android share target so text shared from any app lands in Capture.
- **Create from an entry:** the user picks what to make (project, task, subtask or stream item), where it goes and an optional group, and types the name themselves. The capture text is shown above the form for reference but isn't copied in. After saving, the app asks "Remove this capture?": Remove takes it off the list, and Keep leaves it so more items can be created from it.
- **v2:** voice, typed or mixed capture. BYOK AI proposes the items, and the user approves or edits them (section 11).

### 8.6 Settings

- Set-aside presets, "Day starts at", and the default number of days to show recurring items early
- Notifications, exact reminders, and the reminder time for recurring items
- Context groups
- Backup status: database size and the 20 MB warning
- Replay onboarding, About (roadmap), and Send feedback

## 9. Activity Log

The app keeps a local log of what the user does so the Phase 2 planner can learn their habits. The log never leaves the device in v1.

| Field | Meaning |
| --- | --- |
| event\_id | UUID |
| event\_type | One of the types below |
| node\_id, node\_type | The item acted on |
| domain\_id | Its domain at the time |
| group\_id | Its effective context group at the time, if any |
| occurred\_at | UTC timestamp |
| tz\_offset\_minutes | Local offset, so time-of-day patterns stay correct after travel |
| payload | JSON details for the event type |

**Event types**

- `created`, `completed`, `reopened`, `deleted`, and `restored` (an undone delete)
- `surfaced`: the item appeared on the Summary, detected by comparing recomputations
- `set_aside`: the payload holds the wake time, the preset used (or custom), whether Remind me was on and the level chosen (the item, or its task, project, stream or domain)
- `woke`: automatic, or through Wake now
- `reordered`: the payload holds the old and new position and group
- `group_changed`, `captured` and `converted`
- `skipped`: a recurring occurrence was skipped. On recurring items, `completed` also stores the due date, so paying early or late can be measured.

**Computed later, not logged:** time-of-day patterns, time from surfaced to done, and set-aside habits.

**Retention:** raw events are kept for 12 months, then compacted into daily summaries per domain and group. The log stays under 10 MB so the database fits the backup limit.

## 10. Data Model (v1)

Six tables hold everything. The Summary itself is never stored.

| Table | Key fields |
| --- | --- |
| nodes | id, parent\_id, type (domain, stream, stream\_item, project, task, subtask), title, notes, status (TODO/DONE; empty for domains and streams), sort\_order (sequence or soft order), snooze\_until, remind\_on\_wake, due\_on, recurrence (JSON: frequency, interval, days, repeat from), lead\_days, group\_id, completed\_at, is\_deleted, created\_at, updated\_at |
| context\_groups | id, name, icon, sort\_order, is\_deleted, created\_at, updated\_at |
| summary\_slots | owner\_id (a project, stream or recurring item), group\_id, position, updated\_at |
| events | The fields in section 9 |
| captures | id, text, is\_deleted, created\_at, updated\_at. Each item created from a capture is recorded as a converted event linking the two |
| settings | Presets, day start hour, notification options, updated\_at |

Indexes on (parent\_id, status, is\_deleted) and on snooze\_until keep the Summary query fast. Every write that changes more than one row runs in a single transaction.

## 11. Phase 2: BYOK AI, Portability & iOS

Phase 2 adds AI that only proposes changes, manual export and import, and the iOS app.

**AI principles**

- **Bring your own key:** OpenAI, Anthropic or Groq. No server proxy and no subscription.
- **Keys stay safe:** stored in Android Keystore-backed secure storage, never logged and never exported.
- **Propose, never commit:** AI output appears as a staging card the user can edit, accept or reject. Accepted changes apply in one step and can be undone.
- **Consent per feature:** before first use, the app shows what will be sent and to which provider.
- **Send only what's needed:** capture text or audio for parsing; a summary of the activity log and current Summary for the planner.

**Features**

- **Multi-modal capture:** voice, typing, or both at once. Speech-to-text uses Android's on-device recognizer by default, or a BYOK transcription API if the user picks one. Not every provider offers transcription, so it may differ from the parsing provider.
- **AI parsing:** proposes domains, projects, tasks, subtasks, stream items and groups from a brain dump.
- **AI Summary Planner:** suggests a daily order based on the activity log. Suggestions only.
- **Suggested set-aside times** based on past habits.

**Export and import**

- One-tap export of a JSON or SQLite snapshot to a location the user chooses, with optional password encryption. A lost password can't be recovered.
- Import can replace existing data or merge with it, using UUIDs and `updated_at`.
- Export and import are also how users move between Android and iOS.

**iOS**

- iCloud device backup includes app data by default. The database is stored in a backed-up location, matching Android's behavior.

## 12. Phase 3: Multi-device Sync

Phase 3 keeps one dataset across a user's devices without any proprietary server.

- Optional, encrypted sync through the user's own Google Drive app data folder.
- Tablet UI ships together with sync, so a tablet shares the phone's data instead of holding a separate copy.
- Conflict resolution gets its own spec. Device clocks can drift, so it can't rely on wall-clock `updated_at` alone.

## 13. Non-functional Requirements

The app must stay fast, offline and safe with years of data on a mid-range phone.

| Area | Requirement |
| --- | --- |
| Performance | Summary recomputes in under 50 ms with 10,000 items on a mid-range phone. Cold start to Summary in under 2 s. All database work runs off the UI thread. |
| Offline | Every v1 feature works with no network. v1 declares no Internet permission. |
| Data integrity | Multi-step changes (complete and log, set aside and log, convert a capture) run in one transaction. |
| Migrations | Versioned schema migrations, tested from every released version. The database is copied before migrating. No destructive migrations. |
| Accessibility | TalkBack labels on every action. Swipe and drag actions have button alternatives. System font scaling is supported. Touch targets are at least 48 dp. |
| Time | UTC storage and local display, correct across time-zone and daylight-saving changes. |
| Size | Database and log stay under 20 MB in typical use. |

## 14. Non-goals & Future Scope

v1 leaves these out to stay focused on doing, not organizing. Some are permanent choices; the rest are future scope.

**Not planned**

- Extra statuses such as In Progress, Waiting or Blocked.
- Kanban, Gantt or calendar views.
- Collaboration, shared lists or assigning items to other people.
- Proprietary accounts, server-side AI proxies and AI subscriptions.
- Third-party analytics or telemetry.

**Future scope (after v1)**

- Due dates on one-off items and project tasks. Until then, set an item aside to bring it back before it's due.
- Priority levels or flags. Until then, Summary order is manual.
- Recurring tasks inside projects. v1 supports recurring stream items only.
- A guided weekly review.
- Calendar sync with Google or Outlook.
- Web and desktop clients.
- A cap or focus mode for long Summary lists.

## 15. Phasing Matrix

v1 ships the full deterministic engine; Phase 2 adds AI, export and iOS; Phase 3 adds sync and tablets.

| Area | Phase 1 (v1) | Phase 2 | Phase 3 |
| --- | --- | --- | --- |
| Platform | Android (Flutter) | Adds iOS | Adds tablet UI and multi-device use |
| Storage and backup | Local SQLite with Android Auto Backup | Adds iCloud device backup on iOS | Local-first SQLite with sync |
| Sync readiness | UUIDs, `updated_at`, soft deletes | Maintained | Sync through the user's Google Drive |
| Data portability | OS backup only | Manual export and import | Encrypted sync |
| Status engine | TODO / DONE plus set-aside time | Same | Same |
| Leaf engine | Section 6 rules: one card per project and stream, plus recurring items when due | Same | Same, synced |
| Set aside | Presets, custom picker, Set-Aside page, notifications | Adds AI-suggested times | Synced across devices |
| Summary groups | Optional groups with inheritance | Adds AI Summary Planner (suggestions) | Synced |
| Capture | Text scratchpad, widget, share target | Adds voice and mixed input with AI proposals | Capture on any device |
| AI | None | BYOK: OpenAI, Anthropic, Groq | BYOK |
| Activity log | Local only | Feeds the planner, with consent | Local per device |

## 16. v1 Milestones

v1 is built in eight milestones, each ending in a build the founder can install and test.

**Ground rules**

- Every milestone ends with an installable build.
- Wireframes for a milestone's screens are approved before it starts.
- A milestone is done when its "Done when" checks pass. The acceptance test sheet lists the exact checks for each milestone.
- The founder reviews weekly, and bugs go into one shared issue list, such as GitHub Issues.
- A change request mid-build goes into the next milestone, unless it blocks the current one.
- The developer estimates each milestone before work starts.

| # | Milestone | What gets built (PRD sections) | Done when |
| --- | --- | --- | --- |
| M1 | Foundations | Database with UUIDs, `updated_at` and soft deletes; migration setup; Explorer to create, edit, reorder and delete every node type (3, 4, 8.4, 10) | The founder can build their real tree, and locked tasks show as locked |
| M2 | Core loop | Visibility engine, Summary Page, complete with Undo, reopen, activity log (5, 6, 7, 8.2, 9) | The Summary shows exactly the right next steps. Founder daily use starts here |
| M3 | Set aside | Set-aside picker with presets, day-start hour and scope dropdown; Explorer set-aside; Set-Aside page with Wake now; notifications (7, 8.3) | Setting aside, waking and reminders work, including after a phone restart |
| M4 | Recurring items | Schedules, due labels, overdue, skip, recurring reminders (7) | The four credit card bills in section 7 behave correctly through a full month |
| M5 | Groups and order | Context groups with inheritance, drag between groups, saved positions (8.2) | The Summary arrangement survives completing items |
| M6 | Capture | Scratchpad, convert picker, home-screen widget, share target (8.5) | Capture works from anywhere and converts in a few taps |
| M7 | Polish and safety | Onboarding, full Settings, Auto Backup rules, 20 MB warning, log retention, accessibility, 10,000-item speed check (3, 8.1, 8.6, 13) | A fresh install feels finished, and a reinstall restores the data |
| M8 | Release prep | App icon, store listing, privacy policy, Data safety form, upload to a Play testing track | The 3 testers can install it (section 2, stage 2) |

**Why this order**

- Founder daily use starts at M2, as early as possible, so weekly feedback shapes everything after it.
- The activity log also starts in M2, so real usage history builds up for the Phase 2 planner.
- The riskiest logic, the visibility engine, comes first; onboarding and polish come last.
