# M4 Recurring items

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-11-06 (wireframes and plan)
- **Branches / PRs:** plan and wireframes `docs/m4-plan` (#36, #75); PR 1 `feat/m4-engine` (#37); PR 2 `feat/m4-screens` (#38)
- **PRD sections:** 5, 6, 7 (Recurring items, Notifications), 8.2, 8.3, 8.4, 9, 16 (plus E-001, E-005, E-011)
- **Acceptance tests:** AT-061 to AT-082 (22 rows: 17 Must, 5 Should), plus the E-001, E-005 and E-011 tests
- **Wireframes:** [`docs/design/m4-recurring/`](../design/m4-recurring/) (approved 2026-11-06)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16)

## Owner decisions for M4

- Two PRs, matching issues #37 and #38. Each leaves `dev` green and usable: after PR 1 nothing changes on the phone, because no screen can create a schedule yet; PR 2 adds the screens and reminders.
- **No schema change.** `nodes.due_on`, `recurrence`, `lead_days` and `snooze_overrides_show`, and the `settings` columns `reminder_minutes` and `default_lead_days`, already exist with the PRD defaults (9:00 AM, 3 days). The database stays at version 2.
- **No new packages and no new permissions.** Recurring reminders go through the M3 planner and the M3 notification permissions.
- **Reminder times are scheduled in UTC, as in M3.** The planner works out the moment of 9:00 AM local when it plans. The owner accepted the time-zone limit this leaves for v1 on 2026-11-06 (#74): if the phone changes zone, a reminder already scheduled stays at the old local time until the app is next opened. For example, a 9:00 AM reminder set in India fires at 7:30 AM after moving to Dubai. Due dates and card labels aren't affected, because they're worked out in the phone's current zone each time.
- The 11 choices approved with the wireframes (design README, M4 section) are the screen spec.
- The reminder time and the default lead setting keep their PRD defaults until the full Settings screen in M7 (#54). Each item's own "Show before due" is editable from M4.

## Questions the owner settled

Both were open when the plan merged, and the owner accepted the recommendations on 2026-11-06.

1. **Log events for the new Undos.** Undo on Skip and Undo on Stop repeating were approved with the frames, but PRD 9 had no event for them, and none for Stop repeating itself. Recorded as [E-011](../PRD_Edits.md#e-011-skip-and-stop-repeating-have-undo-and-the-log-records-them): `skip_undone`, `repeat_stopped` and `repeat_restored`, each undo pointing at the event it cancels.
2. **How a month is tested.** The simulated month in automated tests (step 11), plus spot checks on the phone with its date changed, and the real bills carrying on as daily use after the release. v0.4.0 doesn't wait for a real month. #38's "done when" now says this.

Five more came up while planning PR 2, and the owner settled them on 2026-11-07:

1. **A bill set aside past its show day** keeps its show-day reminder at 9:00 AM, and gets "is back" when it wakes if Remind me is on. I recommended dropping the show-day reminder; the owner chose to keep it. While an ancestor hides the bill, the show-day reminder still doesn't fire, because PRD 7 makes only the due-date reminder the exception.
2. **A bill set aside past its due date** still gets the due-day reminder. Tapping it opens the sheet from frame 11.
3. **No lead days:** the show day and due day are the same, so there is one reminder, "is due today".
4. **A group with different dates** reads "2 items are due", and each line gives its own date.
5. **Screens with no frame:** yearly has In month and On day; daily has no extra field; weekly can have no weekdays chosen, which simply counts weeks.

## Estimate

Measured in working sessions like the M3 ones (M3 took 3 PRs over about three days of sessions).

| Part | Estimate | Main uncertainty |
|---|---|---|
| PR 1: engine, actions, log | 2 to 3 sessions | Month-end and interval edge cases; show time and `snooze_until` working together with `snooze_overrides_show` (E-005) |
| PR 2: screens and reminders | 2 to 3 sessions, plus checks on the phone | The planner today announces only what newly appears at a wake moment. Recurring reminders add a local clock time and a due-day reminder that ignores set-aside ancestors |
| Owner testing | A few days of spot checks with the phone's date changed | Changing the date on the phone may affect other apps while testing |

## Checklist

**Plan** (`docs/m4-plan`)

1. [x] Read PRD 5 to 7, 8.2 to 8.4, 9, 16, PRD_Edits (E-001, E-005), tech plan 4.3, 4.4, 7, decision 0005 and AT-061 to AT-082
2. [x] Wireframes (11 frames) approved by the owner; PNGs in `docs/design/m4-recurring/`, choices in the design README
3. [x] This plan; PR for #36. Tick the #36 tasks

**PR 1: engine, actions, log** (`feat/m4-engine`, #37)

4. [x] Owner answers question 1; add the approved entry to `PRD_Edits.md`
5. [x] `lib/engine/recurrence.dart`: schedule model read from and written to the `recurrence` JSON; next due date as a pure function for daily, weekly on chosen weekdays, monthly and yearly, with intervals, a missing month day falling on the last day, and repeat from the due date or the completion's logical date (AT-067 to AT-069, AT-073 to AT-076)
6. [x] Show time (`due_on` minus `lead_days` at the day-start hour, in the current zone) and due labels in logical days (AT-061 to AT-063, AT-081)
7. [x] Visibility: every awake recurring item shows, and none blocks the normal items of its stream (AT-064, AT-065); `nextChangeAt` includes show times; the item is awake only when the show time and any `snooze_until` have both passed, unless `snooze_overrides_show` is set (AT-072)
8. [x] Set-Aside list: waiting recurring items at their effective wake time, listed once, and under a set-aside ancestor when there is one; Wake now and Change time change this occurrence only (E-005)
9. [x] Actions, each in one transaction with an undo token: complete stores the due date, advances `due_on`, stays TODO and clears `snooze_until` and `snooze_overrides_show` (AT-066, AT-077, AT-082); undo restores them (AT-070, E-001); skip logs `skipped` and no `completed` (AT-071); stop repeating clears the schedule and due date (AT-080); undo of skip and stop (E-011)
10. [x] Unit tests named by AT ID with the fake clock, including the E-001 and E-005 tests
11. [x] Simulated month: the four PRD 7 bills through a full month and into the next, with the fake clock, including an unpaid HDFC on the 9th, a late payment, a missed cycle and a skip
12. [x] Update the tech plan notes (7, recurring reminders), matrix, `CHANGELOG.md` and this plan; tick #37; open PR 1

**PR 2: screens and reminders** (`feat/m4-screens`, #38, after PR 1 merges)

13. [x] Repeat switch and schedule fields in the create and edit forms, stream items only, per frames 2 to 4; first due date filled in with the next matching date and editable; turning Repeat off on a recurring item does the same as Stop repeating
14. [x] Due line on Summary cards, overdue in bold (frame 1); Skip this occurrence, showing the next date, and Stop repeating in the card sheet (frame 5); snackbars with Undo (frames 6 and 9)
15. [x] Set-Aside page: waiting bills with show time and due date (frame 7)
16. [x] Explorer: repeat mark, schedule, due date and "back" date; never shown as DONE (frame 8, AT-077)
17. [x] Planner: two reminders at the reminder time, on the show day and on the due day if still not done (AT-078); the due-day reminder ignores set-aside ancestors (AT-079); wording and grouping per frame 10; unit tests with the fake clock
18. [x] Reminder taps: open the card, or the item's sheet with the note when the item isn't on the Summary (frame 11, AT-079)
19. [x] Accessibility: labels on every new action, 48 dp targets, large-text check
20. [x] Widget tests for the AT rows the matrix marks W; integration flows in `integration_test/`; list the device-only checks in the PR
21. [x] Version 0.4.0+4 build for the phone; update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #38; open PR 2
22. [ ] Owner: release build on the phone; AT-061 to AT-081 Founder rows as spot checks with the phone's date changed (question 2). The on-phone suite runs only as `flutter test integration_test --no-uninstall`, after warning the owner

**Release** (owner)

23. [ ] When the M4 Must tests pass on the phone and #38's "done when" is met: close-out docs PR (#40), release PR `dev` → `main` (#39, merge commit), tag `v0.4.0`. Tick #39 and #40

## Changes to the plan

- 2026-11-06 (PR 1): the owner accepted both open questions. E-011 was added, and #38's "done when" changed to the simulated month plus spot checks.
- 2026-11-06 (PR 1, step 9): added a `setRecurrence` action, which the plan didn't list. The tests and PR 2's form both need a way to give an item a schedule. Like `edit`, it isn't an activity log event in PRD 9.
- 2026-11-07 (PR 2): #77's check was added to this PR, with the owner's approval.
- 2026-11-07 (PR 2, step 13): `create` takes an optional schedule. Creating the item and then calling `setRecurrence` would have logged a false `surfaced` for a moment on a bill still waiting for its show date.
- 2026-11-07 (PR 2): the approved checklist had a fix for Undo of a set aside on a waiting bill. No fix was needed: the Explorer offers Wake now rather than Set aside on a waiting bill, so that Undo can't be reached, and Undo from a Summary card leaves the bill on the Summary. Tests now hold both in place.

## Notes for whoever picks this up

- **PR 1 (2026-11-06):** 304 tests pass (244 before + 60 new). `dart run tool/at_coverage.dart M4` reports 20 of 22; the missing two are the reminders AT-078 and AT-079, for PR 2. Those 20 cover the logic: AT-062, AT-063, AT-070, AT-071 and AT-077 still need their widget tests in PR 2. Nothing changes on the phone: no screen can create a schedule yet. AT-081 is tested only as far as a running test can go, since it can't change the phone's zone. Small choices, all open to change:
  - `TreeNode.wakeAt` is the one rule for when a node comes back, so the Summary, `nextChangeAt`, the Set-Aside list and Wake now all agree.
  - A show time is computed, not stored, so `_catchUp` compares the Summary on every write once any item has a due date. A bill reaching its show date gets `surfaced` dated at that time, as E-002 does, but no `woke`: logging each one exactly once would need a stored record of it.
  - Skip always follows the due date, even when repeating from completion, because nothing was completed.
  - Monthly and yearly schedules step from the month of their base date, so "monthly on the 5th" completed on Nov 3 or Nov 7 from completion both give Dec 5.
  - A card that stays on the Summary across a completion, as in AT-068, gets no new `surfaced`, because it never left. The time from surfaced to done for that occurrence will read long.
  - Undo is refused with `staleUndo` if the occurrence has already moved on.
- **PR 2 (2026-11-07):** the screens and reminders. `dart run tool/at_coverage.dart M4` reports 22 of 22. Small choices, all open to change:
  - A new schedule's Next due is the first matching date on or after today. Daily and plain "every N weeks" schedules have no fixed day, so they start today.
  - Next due follows the schedule fields until the user picks a date, and then stays.
  - Saving an edit only rewrites the schedule if it changed, because saving one ends any Wake now or Change time on this occurrence.
  - A bill woken early by Wake now still gets its reminders on its real show day and due day.
  - The sheet from a reminder tap leaves out Set aside and Stop repeating, as frame 11 does.
  - A domain that wakes on a bill's show day before 9:00 AM gives "is back" and then the show-day reminder.
  - A crossed-out bell can still show on a waiting bill that was once set aside with Remind me off, though its reminders do arrive. It's cosmetic, and left as it is.
- **#77 (2026-11-07):** the test confirms the gap. Opening the app after a reminder's time but before Android delivers it cancels that reminder, and the new schedule leaves it out, because past times are skipped. The plugin's code shows the alarm really is cancelled. The test records today's behaviour, and any fix waits for the owner.

- PRD 16's gate for M4 is that the four credit card bills behave correctly through a full month.
- The show-day reminder arrives at 9:00 AM but the card appears at the start of the day (4:00 AM), so the card can be on the Summary for hours before its reminder. That's what PRD 7 asks for.
- An open-the-app-late gap carries over from M3: opening the app before a late inexact reminder fires may drop that reminder, since the schedule is replaced and past times are skipped. Tracked in #77.
- Notifications were tested on the OnePlus only in M3 (accepted by the owner, 2026-11-06). AT-078 and AT-079 have the same gap.
- The frames were rendered from the canvas pages with headless Chrome, because the canvas can't export PNGs. All 11 PNGs were viewed in their final form before committing; the live canvas itself was never seen rendering (it froze the browser tab), so the PNGs are the reference if the two differ.
