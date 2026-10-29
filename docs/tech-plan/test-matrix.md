# Acceptance test matrix

Maps every acceptance test in [`Sahai_Acceptance_Tests_v1.xlsx`](../tests/Sahai_Acceptance_Tests_v1.xlsx) to the automated test levels that will cover it, plus any check that needs a real device. Generated from the sheet on 2026-10-30. If the sheet changes, this file is updated in the same PR.

## Levels

| Code | Level | Runs |
|---|---|---|
| **U** | Unit test: engine, actions, repositories (in-memory SQLite), planner, migrations | Every PR (CI) |
| **W** | Widget test: one screen with fake providers | Every PR (CI) |
| **I** | Integration test (`integration_test`) on an emulator or phone | Before a milestone merges into `main` |
| **CI** | Automated check in the CI pipeline (not a Dart test) | Every PR |
| **D** | Manual check on a real device, listed in the PR | Per PR and before release |

Every automated test that covers an acceptance test is named with its ID, e.g. `AT-034 waking subtask takes its place back`. **D** means some part of the test can only be confirmed on a phone. The automated levels still cover the logic.

## Totals

124 tests. Tests that include each level: U 97 · W 52 · I 6 · CI 1 · D 28. Tests that need **only** a real device: 10.

## Extra tests from PRD edits

| ID | Milestone | Level | Test |
|---|---|---|---|
| E-001 | M2 | U | Undo of a completion writes `completion_undone` linking the `completed` event; the restored card gets no new `surfaced` event |
| E-001 | M4 | U | Undo of a recurring completion writes `completion_undone` with the restored due date |
| E-002 | M3 | U | An item that wakes while the app is closed gets a `surfaced` event at its wake time, written at the next recompute |
| E-003 | M1 | U | Undo of a project delete restores only rows flagged by that delete; a task deleted earlier on its own stays deleted |
| E-004 | M7 | U | Compaction moves events older than 12 months into `event_daily_summaries` with correct counts, in one transaction |
| E-005 | M4 | U, W | A paid bill is listed on the Set-Aside page until its show date; Wake now shows it with its real due label and leaves the schedule unchanged |


## M1 Foundations

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-001 | Create every node type | 4, 8.4 | Must | Founder | U, I | Repository create per type; restart persistence on device |
| AT-002 | Only valid children can be added | 4 | Must | Founder | U, W | Allowed-children rule in engine; add menu per node |
| AT-003 | Domains and streams have no status | 4, 5 | Must | Founder | W | No checkmark / Mark done on domain and stream |
| AT-004 | Reorder sequential tasks | 8.4 | Must | Founder | U, I | Reorder action; order survives restart |
| AT-005 | Reorder subtasks and stream items | 8.4 | Must | Founder | U, I | Soft order for subtasks and stream items; survives restart |
| AT-006 | Move an item to another parent | 8.4 | Should | Founder | U, W | Move action validates parent type |
| AT-007 | Locked tasks are marked | 4, 8.4 | Must | Founder | U, W | Lock rule in engine; lock marker in Explorer |
| AT-008 | Delete with Undo | 7 | Must | Founder | U, W | Cascade delete + undo token (E-003); snackbar Undo |
| AT-009 | Deleted items vanish but stay in the database | 5, 7 | Must | Developer | U | Every row under it flagged is_deleted (E-003); hidden everywhere |
| AT-010 | Sync-ready fields are set | 3, 10 | Must | Developer | U | UUID format; updated_at UTC and changes on edit |
| AT-011 | No Internet permission in v1 | 3, 13 | Must | Founder | CI, D | CI permission check on release APK; owner checks app info |
| AT-012 | Schema migration keeps data | 13 | Must | Developer | U, D | Generated migration tests from every schema; pre-migration copy; install-over on device |

## M2 Core loop

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-013 | Only the first subtask shows | 6 | Must | Founder | U, W |  |
| AT-014 | A task with no subtasks shows directly | 6 | Must | Founder | U, W |  |
| AT-015 | Next subtask surfaces | 6, 7 | Must | Founder | U, W |  |
| AT-016 | Task surfaces for sign-off | 6, 7 | Must | Founder | U, W | Task stays TODO, shown for sign-off |
| AT-017 | Next task unlocks after sign-off | 6 | Must | Founder | U, W |  |
| AT-018 | Locked tasks never show | 6 | Must | Founder | U |  |
| AT-019 | Empty project prompts for tasks | 6 | Must | Founder | U, W | Empty-project prompt card |
| AT-020 | Project sign-off | 6 | Must | Founder | U, W |  |
| AT-021 | Domains and streams never appear | 6 | Must | Founder | U |  |
| AT-022 | One normal stream item at a time | 6 | Must | Founder | U, W |  |
| AT-023 | At most one card per project | 6 | Must | Founder | U | Property-style test over random action sequences |
| AT-024 | Deleted children don't block the parent | 5, 6 | Must | Founder | U |  |
| AT-025 | Undo a completion | 7 | Must | Founder | U, W | Also checks completion_undone (E-001) |
| AT-026 | Undo window closes | 7 | Should | Founder | W | Fake timer advances 5 s |
| AT-027 | Reopening a child reopens its ancestors | 7 | Must | Founder | U, W | Ancestor reopen in one transaction |
| AT-028 | Reopening an earlier task re-locks later ones | 7 | Must | Founder | U | Later task keeps progress |
| AT-029 | Tapping a card shows its path | 8.2 | Should | Founder | W | Path sheet and Open in tree route |
| AT-030 | Completion is logged | 9 | Must | Developer | U |  |
| AT-031 | Surfacing is logged | 9 | Must | Developer | U | Plus E-002 wake-time test |
| AT-032 | Create, delete, restore and reopen are logged | 9 | Should | Developer | U |  |

## M3 Set aside

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-033 | Setting aside a subtask surfaces the next | 6, 7 | Must | Founder | U, W |  |
| AT-034 | A waking subtask takes its place back | 6 | Must | Founder | U, W | Fake clock passes 5 PM; nextChangeAt timer fires |
| AT-035 | All subtasks set aside darkens the branch | 6 | Must | Founder | U |  |
| AT-036 | Scope options match the card type | 7 | Must | Founder | W | Scope dropdown per card type |
| AT-037 | Scope: its task | 6, 7 | Must | Founder | U |  |
| AT-038 | Scope: its project | 6, 7 | Must | Founder | U |  |
| AT-039 | Scope: its domain | 6, 7 | Must | Founder | U, W | Set-Aside page lists Freelance |
| AT-040 | A set-aside current task stalls its project | 6 | Must | Founder | U |  |
| AT-041 | Set aside from the Explorer | 7, 8.4 | Must | Founder | U, W |  |
| AT-042 | Default preset times | 7 | Must | Founder | U | Fake clock: Tue Nov 3, 3 PM |
| AT-043 | Day starts at 4 AM | 7 | Must | Founder | U | Fake clock: Wed Nov 4, 1:30 AM |
| AT-044 | Past presets are hidden | 7 | Must | Founder | U, W |  |
| AT-045 | Custom picker blocks past times | 7 | Must | Founder | W | Picker blocks past times |
| AT-046 | Set-Aside page lists items | 8.3 | Must | Founder | U, W | Includes recurring items waiting for their show date (E-005) |
| AT-047 | Hidden descendants sit under their ancestor | 8.3 | Should | Founder | U | Also applies to waiting recurring items (E-005) |
| AT-048 | Wake now | 7, 8.3 | Must | Founder | U, W |  |
| AT-049 | Change time | 8.3 | Should | Founder | U, W |  |
| AT-050 | Grouped wake notification | 7 | Must | Founder | U, D | Planner groups same-time wakes; app-closed delivery on device |
| AT-051 | A single waking item is named | 7 | Must | Founder | U, D | Named notification; tap opens item (deep link) |
| AT-052 | Different wake times notify separately | 7 | Should | Founder | U, D |  |
| AT-053 | Remind me off wakes quietly | 7 | Must | Founder | U, D | Planner skips remind_on_wake = false |
| AT-054 | No notification when still hidden | 6, 7 | Must | Founder | U, D | Planner skips items hidden by ancestor |
| AT-055 | Permission asked at first set aside | 7 | Must | Founder | W, D | Permission requested on first set aside (fake permission service); real prompt on Android 13+ |
| AT-056 | Notifications can be turned off | 7, 8.6 | Should | Founder | U, D |  |
| AT-057 | Reminders survive a restart | 7 | Must | Founder | D | Phone restart |
| AT-058 | Exact reminders | 7 | Should | Founder | D | Exact alarm permission and timing |
| AT-059 | Set aside is logged | 9 | Must | Developer | U |  |
| AT-060 | Waking is logged | 9 | Should | Developer | U |  |

## M4 Recurring items

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-061 | Appears 3 days before due | 7 | Must | Founder | U | Fake clock: Nov 1 -> Nov 2 at day start |
| AT-062 | Due today label | 7 | Must | Founder | U, W | Due label |
| AT-063 | Overdue label | 7 | Must | Founder | U, W |  |
| AT-064 | An unpaid bill doesn't hide the next | 6, 7 | Must | Founder | U |  |
| AT-065 | Recurring items never block normal items | 6 | Must | Founder | U |  |
| AT-066 | Completing schedules the next occurrence | 7 | Must | Founder | U |  |
| AT-067 | Paying late keeps the schedule | 7 | Must | Founder | U |  |
| AT-068 | A missed cycle shows straight away | 7 | Must | Founder | U |  |
| AT-069 | Repeat from completion date | 7 | Must | Founder | U |  |
| AT-070 | Undo a recurring completion | 7 | Must | Founder | U, W | Also checks completion_undone (E-001) |
| AT-071 | Skip this occurrence | 7, 9 | Must | Founder | U, W |  |
| AT-072 | Setting aside keeps the schedule | 7 | Must | Founder | U |  |
| AT-073 | Missing month days fall on the last day | 7 | Must | Founder | U | Nov 30 and Feb 28, 2027 |
| AT-074 | Weekly on chosen weekdays | 7 | Should | Founder | U |  |
| AT-075 | Interval schedules | 7 | Should | Founder | U |  |
| AT-076 | Yearly schedules | 7 | Should | Founder | U |  |
| AT-077 | Recurring items never stay DONE | 5, 8.4 | Must | Founder | U, W |  |
| AT-078 | Recurring reminders use the reminder time | 7 | Must | Founder | U, D | Planner uses reminder time, not day start |
| AT-079 | Due reminder fires inside a paused domain | 7 | Must | Founder | U, D | Due reminder ignores set-aside ancestors |
| AT-080 | Stop repeating | 7 | Should | Founder | U |  |
| AT-081 | Due dates follow the phone's time zone | 7 | Should | Founder | U, D | Time-zone switch in-process; real switch on device |
| AT-082 | Recurring completion stores the due date | 9 | Must | Developer | U |  |

## M5 Groups and order

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-083 | Ungrouped cards use the default list | 8.2 | Must | Founder | U, W |  |
| AT-084 | Create a group | 8.2 | Must | Founder | U, W |  |
| AT-085 | Groups are inherited | 8.2 | Must | Founder | U |  |
| AT-086 | The nearest group wins | 8.2 | Must | Founder | U |  |
| AT-087 | Dragging assigns that item only | 8.2 | Must | Founder | U, W |  |
| AT-088 | The next card keeps the same position | 8.2 | Must | Founder | U, W |  |
| AT-089 | A card moving groups goes to the end | 8.2 | Must | Founder | U |  |
| AT-090 | New slots go to the end | 8.2 | Should | Founder | U |  |
| AT-091 | Recurring items keep their position | 8.2 | Should | Founder | U |  |
| AT-092 | Dragging never changes the tree | 8.2 | Must | Founder | U | Slots never touch sort_order |
| AT-093 | Summary order persists | 8.2 | Must | Founder | I | Arrangement survives restart |
| AT-094 | Reorders and group changes are logged | 9 | Should | Developer | U |  |

## M6 Capture

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-095 | Quick capture works offline | 8.5 | Must | Founder | U, W, D | Airplane mode on device |
| AT-096 | Newest captures come first | 8.5 | Must | Founder | U, W |  |
| AT-097 | Edit a capture | 8.5 | Must | Founder | U, I | Edit survives restart |
| AT-098 | Delete a capture with Undo | 8.5 | Must | Founder | W |  |
| AT-099 | Capture from the home-screen widget | 8.5 | Must | Founder | D | Home-screen widget |
| AT-100 | Capture from the share sheet | 8.5 | Must | Founder | D | Share sheet from Chrome / WhatsApp |
| AT-101 | Create a stream item from a capture | 8.5 | Must | Founder | U, W |  |
| AT-102 | Create a project, task or subtask | 8.5 | Must | Founder | W |  |
| AT-103 | Keep a capture to create more | 8.5 | Must | Founder | W |  |
| AT-104 | Capture events are logged | 9 | Should | Developer | U |  |

## M7 Polish and safety

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-105 | Onboarding builds real data | 8.1 | Must | Founder | W, I |  |
| AT-106 | Practice step changes nothing | 8.1 | Must | Founder | U, W | Practice step leaves no changes |
| AT-107 | Skip onboarding | 8.1 | Should | Founder | W |  |
| AT-108 | Replay onboarding | 8.1, 8.6 | Should | Founder | W |  |
| AT-109 | Edited presets apply | 8.6 | Must | Founder | U, W |  |
| AT-110 | Changing Day starts at | 7, 8.6 | Should | Founder | U | Fake clock 3:30 AM, day start 3 AM |
| AT-111 | Auto Backup restores data | 3 | Must | Developer | D | adb bmgr backup, reinstall, restore |
| AT-112 | Database size warning | 3, 8.6 | Should | Developer | U, W | Fake database size |
| AT-113 | Log retention | 9 | Should | Developer | U | Compaction into event_daily_summaries (E-004) |
| AT-114 | Fast with 10,000 items | 13 | Must | Developer | U, D | Engine benchmark on dev machine from M2; profile build on mid-range phone |
| AT-115 | Everything works offline | 13 | Must | Founder | D | Every feature in airplane mode |
| AT-116 | TalkBack support | 13 | Must | Founder | W, D | Semantics labels and button alternatives; TalkBack pass on device |
| AT-117 | Large system font | 13 | Should | Founder | W, D | Largest text scale on every screen |
| AT-118 | Set-aside times survive a time-zone change | 13 | Should | Founder | U, D |  |
| AT-119 | No half-finished changes | 13 | Should | Developer | U | Transaction rollback test |
| AT-120 | Send feedback | 8.6 | Should | Founder | W, D | Fake platform channel; real email app on device |

## M8 Release prep

| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |
|---|---|---|---|---|---|---|
| AT-121 | Testers can install | 2, 16 | Must | Founder | D | Play testing track |
| AT-122 | Privacy policy is linked | 16 | Must | Founder | D | Play Console and About screen |
| AT-123 | Data safety matches the app | 16 | Must | Founder | D | Data safety form review |
| AT-124 | Icon and name | 16 | Should | Founder | D | Launcher and store listing |
