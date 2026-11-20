# M7 Polish and safety

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-11-20 (wireframes and their choices); each PR's steps by the owner's "Proceed"
- **Branches / PRs:** plan and wireframes `docs/m7-plan` (#53, #103); #87 design `docs/m7-due-dates`; PR 1 `feat/m7-onboarding-settings` (#54, with #85); PR 2 `feat/m7-backup-retention` (#55, with #86); PR 3 `feat/m7-due-dates-a11y-speed` (#56, with #87); close-out (#58); release (#57)
- **PRD sections:** 3, 4, 7, 8.1, 8.6, 9, 10, 13, 14, 16 (plus E-004, E-006, E-007, E-012, E-018, E-019)
- **Acceptance tests:** AT-105 to AT-120 and AT-125 to AT-133 (25 rows: 10 Must, 15 Should)
- **Wireframes:** [`docs/design/m7-polish/`](../design/m7-polish/) (frames 1 to 18 approved 2026-11-20; frames 19 to 27, for #87, approved 2026-11-20)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16)

## Owner decisions for M7

Settled on 2026-11-20, with the wireframes. The full list is in the [design README](../design/README.md#choices-approved-with-these-wireframes-6); in short:

1. **Onboarding shows on first run only when there are no areas,** so an install updated from 0.6.0 goes straight to the Summary. It can be replayed from Settings.
2. **Each step saves on Next,** and Skip keeps what was saved (AT-107).
3. **The practice step runs on a temporary copy.** Nothing is written to the database or the activity log (AT-106), so practice never teaches the Phase 2 planner anything.
4. **Replay adds new items** next to the existing ones and changes nothing that exists.
5. **Presets:** only the times are editable, with Reset to defaults. Items already set aside keep their time.
6. **Day starts at:** whole hours from midnight to 6 AM, default 4 AM.
7. **Backup warning** above 20 MB says plainly what it means, and doesn't suggest deleting, since deleted items are kept.
8. **Log retention has no setting.** Fixed at 12 months (PRD 9, E-004).
9. **Send feedback** fills in only the address and the subject "Sahai feedback (0.7.0)". The body stays empty. The owner gave the address on 2026-11-20. It goes into the code in PR 1, in one constant, and isn't repeated in the docs. The repo is public, so the address is readable there and in the app.
10. **#85 goes into PR 1:** due dates outside the current year show the year ("Due Mar 15, 2028").
11. **#86 goes into M7 (PR 2):** Reopen last completion and Reopen last skip for repeating items, as designed in #86 and recorded in [E-018](../PRD_Edits.md#e-018-a-repeating-items-last-completion-or-skip-can-be-reopened). Tests AT-125 to AT-127.
12. **#87 goes into M7 (PR 3):** due dates on one-off items. This is new scope (PRD 14 lists it as future scope), so it gets its own design step first: the owner's answers, frames on the M7 canvas, an E-019 entry and its acceptance tests (steps 4a to 4d).
13. **#87's design** (2026-11-20): due dates on anything that can be ticked off, set on the forms and the capture's Create form, with the bill label and a per-item Remind me (On the day, 1 day, 3 days or 1 week before, or No reminder) that gets through a set-aside area or a waiting step. Not on the Summary. Logged as `due_changed`. Recorded in [E-019](../PRD_Edits.md#e-019-one-off-items-can-have-a-due-date-with-a-reminder), frames 19 to 27, tests AT-128 to AT-133.

Also:

- **No new packages or permissions are expected.** Send feedback uses a few lines of our own Kotlin through a platform channel (tech plan, Send feedback). The licences page is Flutter's own `showLicensePage`. The Auto Backup rules are manifest attributes and two XML files, with no permission. Every manifest change is listed for the owner in PR 2's checklist.
- **PR 1 needs no database change.** The `settings` table has had `day_start_minutes`, `presets`, `reminder_minutes`, `default_lead_days` and `onboarding_done` since version 1. Step 5 confirms this before any code.
- **PR 2 is database version 3.** It adds the `event_daily_summaries` table (E-004) and a nullable column on `nodes` for #87's Remind me choice, and only adds: no existing table or row changes. It comes with migration tests from version 1 and 2, and the usual pre-migration copy.
- **Compaction deletes raw events older than 12 months** after adding their counts to `event_daily_summaries`, in one transaction. That's the approved retention rule (PRD 9, E-004), not a migration, so CLAUDE.md's rule that migrations never destroy data isn't affected. With the app installed since October 2026, nothing is old enough to be compacted on a real phone until late 2027; the tests use the fake clock.
- Three code PRs, matching #54, #55 and #56, so the rule of at most 3 PRs per milestone still holds. #85, #86 and #87 ride along with the PR whose work is closest: #85 with the screens in PR 1, #86 with the activity-log work in PR 2, and #87 in PR 3 before the accessibility pass, so that pass covers its screens too. Each PR leaves `dev` working.
- **#87 needs one new column.** The due date itself uses the existing `nodes.due_on`, used today only by repeating items. The Remind me choice needs a nullable column, added in PR 2's version 3 migration so the database changes only once in M7.
- **#80** (a new reminder replacing one in the shade) is a bug outside the milestone, so it gets its own fix PR whenever the owner wants it.

## Estimate

Measured in working sessions like the M6 ones (M6 took a spike, 2 code PRs and a test fix over about 5 days).

| Part | Estimate | Main uncertainty |
|---|---|---|
| PR 1: onboarding and full Settings, #85 | 3 sessions | The practice step's temporary copy: the real Summary and Set-Aside screens running on an in-memory tree without touching the database. Changing presets, the day start and the reminder time must reschedule notifications |
| PR 2: backup rules, size warning, log retention, #86 | 3 sessions, plus a check on the phone | The backup rules must match Android's current documentation for both old and new Android versions; the restore check (AT-111) needs a careful plan so real data is never at risk. Reopening a completion must restore the old due date and leave the log consistent with compaction |
| #87 design | 1 session | Answers to the owner's questions, then frames |
| PR 3: #87, accessibility and speed | 4 sessions, partly on the phone | One-off due dates touch the forms, card labels, Explorer and the reminder planner. TalkBack and the largest font on every screen can turn up many small fixes; the 10,000-item check (AT-114) needs a profile build that doesn't touch the real data |
| Owner testing | A few days | AT-111 and AT-115 can only be checked on a phone |

## Checklist

**Plan** (`docs/m7-plan`, #53)

1. [x] Read PRD 3, 8.1, 8.6, 9, 13 and 16, E-004, and AT-105 to AT-120
2. [x] Wireframes (18 frames) approved by the owner; PNGs in `docs/design/m7-polish/`, choices in the design README
3. [x] No PRD edit needed: every approved choice sits inside what the PRD says
4. [x] This plan; PR for #53. Correct #54 and #55 to match it (the Backup section moves to PR 2; no log retention setting)
   - 2026-11-20: the owner's answers on the feedback address, #85, #86 and #87 were added to #103 before it merged: E-018 for #86, AT-125 to AT-127, and the steps below

**#87 design** (`docs/m7-due-dates`, before PR 3)

4a. [x] The owner's answers to the #87 questions, one at a time: which items, where it's set, how it looks, reminders, the Summary, logging
4b. [x] Frames for one-off due dates on the M7 canvas, approved by the owner; PNGs and choices in the design README
4c. [x] E-019 in `PRD_Edits.md` (PRD 4, 7, 9, 10, 14) and its acceptance tests on the sheet, with the matrix regenerated
4d. [x] This plan's PR 3 steps updated to match; PR into `dev`

**PR 1: onboarding and full Settings** (`feat/m7-onboarding-settings`, #54)

5. [ ] Confirm the `settings` table is enough and the database stays at version 2
6. [ ] Settings actions, each in one transaction: preset times, Day starts at (whole hours, 12 to 6 AM), Show before due, Reminder time. The engine, presets and notification planner pick up the change at once, and reminders are rescheduled. Injected clock throughout
7. [ ] Full Settings screen (frames 10, 11, 12, 13), replacing the M3 placeholder rows. The Backup section waits for PR 2
8. [ ] About (frame 15) with the licences page, and Send feedback (frame 17) through our own Kotlin `ACTION_SENDTO` platform channel, with a message if no email app is installed
9. [ ] Onboarding (frames 1 to 9): the first-run check, steps that save through the existing node actions (their `created` events are real), Skip, Back, the practice step on a temporary copy, and Replay (frame 16)
9a. [ ] #85: show the year on a due date outside the current year, everywhere a due date appears: the Summary card label, the Explorer repeat line, Next due on the Repeat form, the "Done. Next due…" and "Skipped. Next due…" messages, and reminder text
10. [ ] Accessibility on the new screens: labels on every action, 48 dp targets, the largest font (frame 18)
11. [ ] Unit and widget tests named by AT ID with the fake clock: AT-105 to AT-110 and AT-120 (fake platform channel), and #85's dates; an integration flow for onboarding through to the real Summary
12. [ ] Update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #54; open PR 1

**PR 2: Auto Backup rules, 20 MB warning, log retention** (`feat/m7-backup-retention`, #55)

13. [ ] Auto Backup rules: `android:allowBackup="true"`, `android:fullBackupContent` (Android 11 and lower) and `android:dataExtractionRules` (12 and higher). Include `sahai.sqlite` and `sahai.sqlite-wal` and the preferences; exclude `sahai.sqlite-shm`, `pre-migration/`, caches and temp files (tech plan, Auto Backup). Checked against Android's documentation; owner approval for the manifest change
14. [ ] Checkpoint the WAL when the app goes to the background (risk R5)
15. [ ] Database version 3: add `event_daily_summaries` (E-004) and the nullable Remind me column on `nodes` (E-019; empty means On the day). Migration tests from versions 1 and 2; the pre-migration copy still runs
16. [ ] Compaction: events older than 12 months, by the logical day in local time, become daily counts per domain, group and event type, and the raw rows go, in one transaction. Runs at app start, at most once a day. Never logs task content
17. [ ] Backup section in Settings (frame 14): the size of the database and its WAL against 20 MB, and the warning above it
17a. [ ] #86 (E-018): Reopen last completion and Reopen last skip on a repeating item, in the Explorer menu and as a shortcut on the Set-Aside page. It brings back the old due date, logs `reopened` naming the event it cancels, and is offered only for the latest completion or skip. In one transaction. Uses the existing design, with no new frames: the menu line and the Set-Aside shortcut follow the M3 and M4 patterns
18. [ ] Tests: AT-112 (fake size), AT-113 (fake clock, generated events; counts correct, log under 10 MB), AT-125 to AT-127 (fake clock, including the log event and the limits), the migration tests; device-only checks listed in the PR (AT-111)
19. [ ] Update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #55; open PR 2

**PR 3: one-off due dates, accessibility pass and 10,000-item speed check** (`feat/m7-due-dates-a11y-speed`, #56)

19a. [ ] #87 (E-019) actions, each in one transaction with the injected clock: set, change or clear a due date and Remind me on projects, tasks, subtasks and one-off stream items, logging `due_changed` with the old and new dates and the reminder choice, never the text. Completing removes the label and Undo or Reopen brings it back. A stream item with Repeat on keeps using Next due; Stop repeating still clears the due date (AT-080)
19b. [ ] Forms (frames 19 to 22 and 27): the Due date row on the create and edit forms and the capture's Create form, the picker with past days greyed, ✕ to clear, and the Remind me sheet with past choices greyed
19c. [ ] Labels (frames 23 and 24): the bill label, with the year from #85, and a calendar mark on Summary cards and in the Explorer. The Summary's contents and order don't change
19d. [ ] Reminders (frames 25 and 26): the notification planner schedules the chosen reminder and the follow-up on the day at the Reminder time, through set-aside ancestors and waiting steps; grouped when due together; cancelled when done; restored after a restart. Tapping opens the item, or the sheet that says why it's hidden (no Mark done when locked, E-007)
19e. [ ] Tests named by AT ID with the fake clock: AT-128 to AT-133, and the migration test for the new column from PR 2. Device checks listed in the PR (AT-129, AT-130)
20. [ ] TalkBack pass over every screen with fixes: every action announced, swipe and drag alternatives from M5 (AT-116)
21. [ ] Largest font on every screen with fixes (AT-117)
22. [ ] AT-118: set-aside times survive a time-zone change (fake clock and zones); AT-119: a failure in the middle of a completion leaves neither the change nor its event (rollback test)
23. [ ] AT-114: a profile build on the phone with 10,000 generated items, measuring cold start (< 2 s) and recompute (< 50 ms). How to do this without touching the real data is agreed with the owner first (see Notes)
24. [ ] Version 0.7.0+7 for the phone; update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #56; open PR 3

**Close-out and release**

25. [ ] Owner: release build on the phone; the Founder rows AT-105 to AT-110, AT-115 to AT-118, AT-120, AT-125 to AT-133, including a full airplane-mode pass (AT-115) and TalkBack (AT-116). AT-111 as agreed in the Notes. The on-phone suite runs only as `flutter test integration_test --no-uninstall`, after warning the owner, and never from an older version than the one installed
26. [ ] Close-out docs PR (#58), once the check passes: results on the test sheet, this plan, `CLAUDE.md` status
27. [ ] Owner: release PR `dev` → `main` (#57, merge commit), tag `v0.7.0`. Tick #57 and #58, and close #57 and the milestone by hand after tagging

## Changes to the plan

- 2026-11-20 (approved by FINUSAM): the owner gave the feedback address and decided that #85, #86 and #87 are in M7. #85 joins PR 1, #86 joins PR 2 (E-018, AT-125 to AT-127), and #87 joins PR 3 after a design step of its own (4a to 4d). Still three code PRs. The estimate grows by about 3 sessions.
- 2026-11-20 (approved by FINUSAM): #87's design was approved: frames 19 to 27, E-019 and AT-128 to AT-133. PR 3's #87 work is filled in as steps 19a to 19e, and the Remind me column joins PR 2's version 3 migration (step 15), so the database changes once in M7.

## Notes for whoever picks this up

- **AT-111 (backup restore) can lose real data.** It needs a backup, an uninstall and a restore. If the restore fails on the owner's only phone, the data is gone. Before step 25, agree with the owner how to run it: on a second phone or an emulator signed in to a Google account, or on the OnePlus only after a fresh backup has been confirmed. Never run it as a surprise.
- **AT-114 on the phone** needs 10,000 items. They must never go into the owner's real database. Options to agree in step 23: a profile build of the integration test that opens its own temporary database file, or a second device. Remember that installing a test or profile build replaces the release build: reinstall it afterwards with `adb install -r`.
- **The practice step** must not write anything, `surfaced` events included. The engine is pure (tech plan, engine), so the plan is to run it over an in-memory copy of the onboarding tree and show the result in the normal Summary and Set-Aside widgets. If those widgets turn out to be tied to the database, stop and bring the trade-off to the owner rather than writing and then deleting rows.
- **Day starts at and presets** feed `logicalDate` and the preset calculation (tech plan, Logical day). A change must refresh `nextChangeAt` and reschedule reminders, or a reminder could fire at the old time.
- **The 20 MB figure** counts the database file and its WAL, which are what Auto Backup copies; the `-shm` file is excluded from the backup and isn't counted.
