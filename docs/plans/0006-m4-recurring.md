# M4 Recurring items

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-11-06 (wireframes). The plan is approved when the owner merges its PR
- **Branches / PRs:** plan and wireframes `docs/m4-plan` (#36); PR 1 `feat/m4-engine` (#37); PR 2 `feat/m4-screens` (#38)
- **PRD sections:** 5, 6, 7 (Recurring items, Notifications), 8.2, 8.3, 8.4, 9, 16 (plus E-001, E-005)
- **Acceptance tests:** AT-061 to AT-082 (22 rows: 17 Must, 5 Should), plus the E-001 and E-005 tests
- **Wireframes:** [`docs/design/m4-recurring/`](../design/m4-recurring/) (approved 2026-11-06)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16)

## Owner decisions for M4

- Two PRs, matching issues #37 and #38. Each leaves `dev` green and usable: after PR 1 nothing changes on the phone, because no screen can create a schedule yet; PR 2 adds the screens and reminders.
- **No schema change.** `nodes.due_on`, `recurrence`, `lead_days` and `snooze_overrides_show`, and the `settings` columns `reminder_minutes` and `default_lead_days`, already exist with the PRD defaults (9:00 AM, 3 days). The database stays at version 2.
- **No new packages and no new permissions.** Recurring reminders go through the M3 planner and the M3 notification permissions.
- **Reminder times are scheduled in UTC, as in M3.** The planner works out the moment of 9:00 AM local when it plans. The time-zone limit this leaves is parked in #74 at the owner's request (2026-11-06), with no milestone: if the phone changes zone, a reminder already scheduled stays at the old local time until the app is next opened. For example, a 9:00 AM reminder set in India fires at 7:30 AM after moving to Dubai. Due dates and card labels aren't affected, because they're worked out in the phone's current zone each time.
- The 11 choices approved with the wireframes (design README, M4 section) are the screen spec.
- The reminder time and the default lead setting keep their PRD defaults until the full Settings screen in M7 (#54). Each item's own "Show before due" is editable from M4.

## Open questions for the owner

Neither blocks merging this plan. Question 1 is needed before PR 1 starts, question 2 before #38 can be called done.

1. **Log events for the new Undos.** Undo on Skip and Undo on Stop repeating were approved with the frames, and PRD 7 says every action can be reversed, but PRD 9 has no event for them, and none for Stop repeating itself. The log is append-only, so these need event types, and that needs a PRD edit the owner approves. Proposed E-011: add `skip_undone` and `repeat_stopped`, with Undo of a stop logged as `repeat_restored`, each undo pointing at the event it cancels, as `completion_undone` does (E-001). Nothing has been added to `PRD_Edits.md` yet.
2. **How a month is tested.** #38's "done when" says the owner runs their real bills through a month on the phone, which would hold up v0.4.0 by a month. Recommended: the simulated month in automated tests (step 11, which #37 needs anyway), plus spot checks on the phone with its date changed, and the real bills carrying on as daily use after the release. That changes what "done" means on #38, so it stays as written until the owner decides. Steps 22 and 23 depend on the answer.

## Estimate

Measured in working sessions like the M3 ones (M3 took 3 PRs over about three days of sessions).

| Part | Estimate | Main uncertainty |
|---|---|---|
| PR 1: engine, actions, log | 2 to 3 sessions | Month-end and interval edge cases; show time and `snooze_until` working together with `snooze_overrides_show` (E-005) |
| PR 2: screens and reminders | 2 to 3 sessions, plus checks on the phone | The planner today announces only what newly appears at a wake moment. Recurring reminders add a local clock time and a due-day reminder that ignores set-aside ancestors |
| Owner testing | Depends on open question 2 | A few days with spot checks, or a month with real bills |

## Checklist

**Plan** (`docs/m4-plan`)

1. [x] Read PRD 5 to 7, 8.2 to 8.4, 9, 16, PRD_Edits (E-001, E-005), tech plan 4.3, 4.4, 7, decision 0005 and AT-061 to AT-082
2. [x] Wireframes (11 frames) approved by the owner; PNGs in `docs/design/m4-recurring/`, choices in the design README
3. [x] This plan; PR for #36. Tick the #36 tasks

**PR 1: engine, actions, log** (`feat/m4-engine`, #37)

4. [ ] Owner answers open question 1; add the approved entry to `PRD_Edits.md`
5. [ ] `lib/engine/recurrence.dart`: schedule model read from and written to the `recurrence` JSON; next due date as a pure function for daily, weekly on chosen weekdays, monthly and yearly, with intervals, a missing month day falling on the last day, and repeat from the due date or the completion's logical date (AT-067 to AT-069, AT-073 to AT-076)
6. [ ] Show time (`due_on` minus `lead_days` at the day-start hour, in the current zone) and due labels in logical days (AT-061 to AT-063, AT-081)
7. [ ] Visibility: every awake recurring item shows, and none blocks the normal items of its stream (AT-064, AT-065); `nextChangeAt` includes show times; the item is awake only when the show time and any `snooze_until` have both passed, unless `snooze_overrides_show` is set (AT-072)
8. [ ] Set-Aside list: waiting recurring items at their effective wake time, listed once, and under a set-aside ancestor when there is one; Wake now and Change time change this occurrence only (E-005)
9. [ ] Actions, each in one transaction with an undo token: complete stores the due date, advances `due_on`, stays TODO and clears `snooze_until` and `snooze_overrides_show` (AT-066, AT-077, AT-082); undo restores them (AT-070, E-001); skip logs `skipped` and no `completed` (AT-071); stop repeating clears the schedule and due date (AT-080); undo of skip and stop per question 1
10. [ ] Unit tests named by AT ID with the fake clock, including the E-001 and E-005 tests
11. [ ] Simulated month: the four PRD 7 bills through a full month and into the next, with the fake clock, including an unpaid HDFC on the 9th, a late payment, a missed cycle and a skip
12. [ ] Update the tech plan notes (7, recurring reminders), matrix, `CHANGELOG.md` and this plan; tick #37; open PR 1

**PR 2: screens and reminders** (`feat/m4-screens`, #38, after PR 1 merges)

13. [ ] Repeat switch and schedule fields in the create and edit forms, stream items only, per frames 2 to 4; first due date filled in with the next matching date and editable; turning Repeat off on a recurring item does the same as Stop repeating
14. [ ] Due line on Summary cards, overdue in bold (frame 1); Skip this occurrence, showing the next date, and Stop repeating in the card sheet (frame 5); snackbars with Undo (frames 6 and 9)
15. [ ] Set-Aside page: waiting bills with show time and due date (frame 7)
16. [ ] Explorer: repeat mark, schedule, due date and "back" date; never shown as DONE (frame 8, AT-077)
17. [ ] Planner: two reminders at the reminder time, on the show day and on the due day if still not done (AT-078); the due-day reminder ignores set-aside ancestors (AT-079); wording and grouping per frame 10; unit tests with the fake clock
18. [ ] Reminder taps: open the card, or the item's sheet with the note when the item isn't on the Summary (frame 11, AT-079)
19. [ ] Accessibility: labels on every new action, 48 dp targets, large-text check
20. [ ] Widget tests for the AT rows the matrix marks W; integration flows in `integration_test/`; list the device-only checks in the PR
21. [ ] Version 0.4.0+4 build for the phone; update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #38; open PR 2
22. [ ] Owner: release build on the phone; AT-061 to AT-081 Founder rows, in the way open question 2 settles. The on-phone suite runs only as `flutter test integration_test --no-uninstall`, after warning the owner

**Release** (owner)

23. [ ] When the M4 Must tests pass on the phone and #38's "done when" is met: close-out docs PR (#40), release PR `dev` → `main` (#39, merge commit), tag `v0.4.0`. Tick #39 and #40

## Changes to the plan

None yet.

## Notes for whoever picks this up

- PRD 16's gate for M4 is that the four credit card bills behave correctly through a full month.
- The show-day reminder arrives at 9:00 AM but the card appears at the start of the day (4:00 AM), so the card can be on the Summary for hours before its reminder. That's what PRD 7 asks for.
- Not decided yet, to settle in step 17: which reminder a bill gets when the user has set it aside past its show day, for example AT-072's Nov 4 at 8 AM. M3's "is back" rule and the recurring rule both seem to apply. Raise it with the owner if the PRD doesn't answer it by then.
- An open-the-app-late gap carries over from M3: opening the app before a late inexact reminder fires may drop that reminder, since the schedule is replaced and past times are skipped.
- Notifications were tested on the OnePlus only in M3 (accepted by the owner, 2026-11-06). AT-078 and AT-079 have the same gap.
- The frames were rendered from the canvas pages with headless Chrome, because the canvas can't export PNGs. All 11 PNGs were viewed in their final form before committing; the live canvas itself was never seen rendering (it froze the browser tab), so the PNGs are the reference if the two differ.
