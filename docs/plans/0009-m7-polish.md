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

Approved by the owner's "Proceed" on 2026-11-20. No new package, permission or database change.

5. [x] Confirm the `settings` table is enough and the database stays at version 2. It has `presets` (JSON, unused until now), `day_start_minutes`, `reminder_minutes`, `default_lead_days` and `onboarding_done`, and the row has been made on first launch since version 1
6. [x] Settings actions: preset times (only the times; names and days stay fixed) saved as JSON in `presets`, Reset to defaults, Day starts at (whole hours, 12 to 6 AM), the default Show before due, Reminder time. The set-aside picker uses the saved times. The Summary, presets and reminders react at once (the reminder sync already listens to settings). Settings changes aren't logged (PRD 9). Injected clock throughout
7. [x] Full Settings screen (frames 10, 11, 12, 13): Set aside, Recurring items, Reminders, Summary, Backup and Help, replacing the "coming later" note. The Backup rows wait for PR 2
8. [x] About (frame 15) with the version, where the data lives, what's coming, and Flutter's licences page. Send feedback (frame 17): our own Kotlin in `MainActivity` over a platform channel opens the email app (`ACTION_SENDTO`) with the address and "Sahai feedback (version)", empty body, and a message if no email app is installed. The same channel gives the app version, so no `package_info_plus`. The address is one constant in the code. No manifest change
9. [x] Onboarding (frames 1 to 5, 9 and 16): shown on first run only when there are no areas and onboarding isn't done; each step saves on Next through the existing node actions (their `created` events are real); Skip on every step keeps what was saved; Back changes what was made rather than making it again; Replay from Settings asks first and adds new items
9a. [x] #85: show the year on a due date outside the current year, everywhere a due date appears: the Summary card label, the Explorer repeat line, Next due on the Repeat form, the "Done. Next due…" and "Skipped. Next due…" messages, and reminder text
9b. [x] Practice step (frames 6 to 8) on an in-memory copy: only what onboarding made is copied into a temporary in-memory database, the real Summary and Set-Aside screens run on it with reminders switched off, and it's thrown away at the end. Nothing touches `sahai.sqlite`, the log included (AT-106). Banner, a dashed box for each move, Explorer and Capture dimmed. Decision record 0008
10. [x] Accessibility on the new screens: labels on every action, 48 dp targets, the largest font (frame 18)
11. [x] Unit and widget tests named by AT ID with the fake clock: AT-105 to AT-110 and AT-120 (fake platform channel), #85's dates, and a test that the practice step leaves the real database as it was; an onboarding flow in `integration_test/app_test.dart`, run on the phone only after warning the owner and only with `--no-uninstall`. `flutter analyze`, `dart format` and `flutter test` clean before each commit
12. [x] Update `README.md`, `CHANGELOG.md`, tech plan (Settings, onboarding, the practice copy), the matrix if levels change, and this plan; tick #54 and #85; open PR 1 listing the device checks (AT-105 to AT-110, AT-120)

**PR 2: Auto Backup rules, 20 MB warning, log retention, #86** (`feat/m7-backup-retention`, #55, with #86)

Approved by the owner's "Proceed" on 2026-11-20, with three choices: (A) the branch starts from PR 1's branch while #106 is open, `dev` is merged in once #106 merges (no history rewrite), and PR 2 opens only after that; (B) compaction keeps an event that can still be reopened (E-018 has no time limit), recorded in decision 0009; (C) AT-127: a completion made after a reopen can itself be reopened; the earlier occurrence (Nov 5) never can. No new package or permission.

13. [x] Auto Backup rules, for the owner's approval of the manifest change: `android:allowBackup="true"`, `android:fullBackupContent` (Android 11 and lower) and `android:dataExtractionRules` (12 and higher, cloud backup and device transfer) on `<application>`, with two rule files in `res/xml/`. Include `app_flutter/sahai.sqlite` and `app_flutter/sahai.sqlite-wal` (drift_flutter keeps the database in the app documents folder, Android's `root` domain) and the shared preferences; exclude `sahai.sqlite-shm`, `pre-migration/`, caches and temp files. Checked against Android's documentation. A test reads both files so a rule can't go missing
14. [x] Checkpoint the WAL when the app goes to the background (risk R5), tested with a real temporary database file
15. [x] Database version 3, adding only: `event_daily_summaries` (E-004) and the nullable `due_reminder` column on `nodes` for #87 (E-019; empty means On the day). Generated with `drift_dev make-migrations`, with migration tests from versions 1 and 2; the pre-migration copy still runs
16. [x] Compaction: events older than 12 months become daily counts per logical day (local time, Day starts at), domain, group and event type, and the raw rows go, in one transaction. Events that can still be reopened (E-018) are kept (choice B). Runs once at each app start in the background, after the Summary shows (changed from "at most once a day", which would need another column; the `events_occurred_at` index keeps it cheap). Never reads or logs task content
17. [x] Backup section in Settings (frame 14): "Data on this phone", the size of the database and its WAL against 20 MB with a bar, and the warning above 20 MB. The size can be faked in tests
17a. [x] #86 (E-018): Reopen last completion and Reopen last skip, with their dates ("Done Nov 7, was due Nov 5"), in the Explorer menu and as a shortcut on the Set-Aside page, never on the Summary. Offered only for the latest completion or skip that isn't cancelled, while the due date hasn't moved on since. Restores the occurrence as it was before the tick, logs `reopened` with the event it cancels and the restored due date, in one transaction. Follows the M3 and M4 patterns, no new frames
18. [x] Tests named by AT ID with the fake clock: AT-112 (fake size), AT-113 (13 months of generated events; counts correct, log under 10 MB), AT-125 to AT-127 (with the log event and the limits), the migration tests, and compaction keeping reopenable events. Added to `integration_test/app_test.dart`, not run. AT-111 waits for the close-out, as agreed with the owner (see Notes)
18a. [x] `flutter analyze`, `dart format` and `flutter test` clean; debug APK builds
19. [x] Update `README.md`, `CHANGELOG.md`, tech plan (Auto Backup, compaction, Reopen), matrix, this plan and decision 0009; tick #55 (not its device restore task) and #86's last two tasks; once #106 merges, merge `dev` in and open PR 2 listing the device checks (AT-111, AT-125 to AT-127). Opened as #107

**PR 3: one-off due dates, accessibility pass and 10,000-item speed check** (`feat/m7-due-dates-a11y-speed`, #56, with #87)

Approved by the owner's "Proceed" on 2026-11-20, with three choices: (A) the branch starts from PR 2's branch, which adds the `due_reminder` column, while #107 is open; `dev` is merged in once #107 merges and PR 3 opens after that; (B) AT-114 is a profile-mode integration test that fills its own temporary database in the app's cache folder (never `sahai.sqlite`), run with the close-out phone checks after warning the owner, with `--no-uninstall` and the release build reinstalled with `adb install -r` afterwards; cold start is the in-app time from opening the database to the first Summary frame plus Android's process start from `adb shell am start -W` on the release build; (C) a due date set when an item is created also logs `due_changed` (from none). No new package, permission, database change or PRD edit.

19a. [ ] #87 (E-019) actions, each in one transaction with the injected clock: set, change or clear a due date and Remind me (On the day stored as empty, 1 day, 3 days or 1 week before, or No reminder) on projects, tasks, subtasks and one-off stream items; domains, streams and repeating items are refused. Logs `due_changed` with the old and new dates and the reminder choice, never the text, including when an item is created with a due date (choice C). A stream item with Repeat on keeps using Next due; Stop repeating still clears the due date (AT-080)
19b. [ ] Engine: only repeating items wait for a show date, so a one-off due date never hides an item, brings it onto the Summary, or changes the Summary's contents or order
19c. [ ] Forms (frames 19 to 22): the Due date row on the create and edit forms, the picker with past days greyed, ✕ to clear, and the Remind me sheet with each choice's date, past choices greyed, and the tip about the reminder on the day; hidden while Repeat is on. The capture's Create form gets the same rows (frame 27, AT-132)
19d. [ ] Labels (frames 23 and 24): "Due Nov 20", "Due today", "3 days overdue" with a calendar mark on Summary cards, in the Explorer and in the card sheet, with the year from #85; bills keep the repeat mark. A DONE item shows no label; Undo or Reopen brings it back
19e. [ ] Reminders (frames 25 and 26): the chosen early reminder and the one on the due day at the Reminder time, through set-aside ancestors and earlier steps; grouped when due together; none once done; restored after a restart. Tapping opens the item, or a sheet that says why it's hidden, with Mark done (not when locked, E-007), Change due date and Open in tree
20. [ ] Accessibility pass (AT-116, AT-117): automated tap-target and labelled-button checks on every screen, at normal size and the largest font, with fixes; every swipe and drag has a button alternative. TalkBack itself is checked by the owner on the phone
21. [ ] (merged into 20)
22. [ ] AT-118: set-aside times are stored and compared as moments, tested across offsets (a real zone switch is the owner's phone check); AT-119: a failure forced in the middle of a completion leaves neither the change nor its event
23. [ ] AT-114: the profile-mode speed test from choice B, added but not run
23a. [ ] Tests named by AT ID with the fake clock: AT-128 to AT-133, AT-116 to AT-119, the engine fix; new screen tests added to `integration_test/app_test.dart`, not run
24. [ ] Version 0.7.0+7; `flutter analyze`, `dart format`, `flutter test` clean and the debug APK builds; update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #56 and #87 (not the phone tasks); once #107 merges, merge `dev` in and open PR 3 listing the device checks (AT-114 to AT-118, AT-129, AT-130)

**Close-out and release**

25. [ ] Owner: release build on the phone; the Founder rows AT-105 to AT-110, AT-115 to AT-118, AT-120, AT-125 to AT-133, including a full airplane-mode pass (AT-115) and TalkBack (AT-116). AT-111 as agreed in the Notes. The on-phone suite runs only as `flutter test integration_test --no-uninstall`, after warning the owner, and never from an older version than the one installed
26. [ ] Close-out docs PR (#58), once the check passes: results on the test sheet, this plan, `CLAUDE.md` status
27. [ ] Owner: release PR `dev` → `main` (#57, merge commit), tag `v0.7.0`. Tick #57 and #58, and close #57 and the milestone by hand after tagging

## Changes to the plan

- 2026-11-20 (approved by FINUSAM): the owner gave the feedback address and decided that #85, #86 and #87 are in M7. #85 joins PR 1, #86 joins PR 2 (E-018, AT-125 to AT-127), and #87 joins PR 3 after a design step of its own (4a to 4d). Still three code PRs. The estimate grows by about 3 sessions.
- 2026-11-20 (PR 1, within the approved checklist): a Tonight preset time set earlier than Day starts at, such as 12:30 AM, falls after midnight that night. The morning presets keep the M3 rule, so the existing test "a late day start can hide Tonight and Tomorrow morning" is unchanged. The Exact reminders hint was corrected to say reminders can be up to about an hour late (E-012), as frame 10 shows.
- 2026-11-20 (approved by FINUSAM): #87's design was approved: frames 19 to 27, E-019 and AT-128 to AT-133. PR 3's #87 work is filled in as steps 19a to 19e, and the Remind me column joins PR 2's version 3 migration (step 15), so the database changes once in M7.
- 2026-11-20 (PR 2, within the approved checklist): the backup rules leave out the `-shm` file, `pre-migration/` and caches by listing only what is included, which Android documents as excluding everything else; explicit exclude lines aren't needed. Compaction keeps the latest completion or skip of each repeating item, which can be slightly more than Reopen offers (decision 0009). The Set-Aside page's Reopen shortcut is in the card's sheet, next to Wake now and Change time, as frame 9's other actions are.

## Notes for whoever picks this up

- **AT-111 (backup restore) can lose real data.** It needs a backup, an uninstall and a restore. If the restore fails on the owner's only phone, the data is gone. Before step 25, agree with the owner how to run it: on a second phone or an emulator signed in to a Google account, or on the OnePlus only after a fresh backup has been confirmed. Never run it as a surprise.
- **AT-114 on the phone** needs 10,000 items. They must never go into the owner's real database. Options to agree in step 23: a profile build of the integration test that opens its own temporary database file, or a second device. Remember that installing a test or profile build replaces the release build: reinstall it afterwards with `adb install -r`.
- **The practice step** must not write anything, `surfaced` events included. The engine is pure (tech plan, engine), so the plan is to run it over an in-memory copy of the onboarding tree and show the result in the normal Summary and Set-Aside widgets. If those widgets turn out to be tied to the database, stop and bring the trade-off to the owner rather than writing and then deleting rows.
- **Day starts at and presets** feed `logicalDate` and the preset calculation (tech plan, Logical day). A change must refresh `nextChangeAt` and reschedule reminders, or a reminder could fire at the old time.
- **The 20 MB figure** counts the database file and its WAL, which are what Auto Backup copies; the `-shm` file is excluded from the backup and isn't counted.
