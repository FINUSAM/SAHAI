# M3 Set aside

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-11-04 (wireframes and plan)
- **Branches / PRs:** plan and wireframes `docs/m3-plan` (#30); PR 1 `feat/m3-engine` (#31); PR 2 `feat/m3-screens` (#32); PR 3 `feat/m3-reminders` (#33)
- **PRD sections:** 5, 6, 7 (Set aside, Notifications), 8.3, 8.4, 8.6, 9 (plus E-002, E-005)
- **Acceptance tests:** AT-033 to AT-060 (28 rows: 22 Must, 6 Should), plus the E-002 test
- **Wireframes:** [`docs/design/m3-set-aside/`](../design/m3-set-aside/) (approved 2026-11-04)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16). A second brand is still needed for the notification checks (see Owner decisions)

## Owner decisions for M3

- Three PRs, matching issues #31, #32 and #33. Each leaves `dev` green and usable: after PR 2 the owner can set aside and wake items on the phone without reminders; PR 3 adds reminders.
- **No schema change.** `nodes.snooze_until` and `remind_on_wake`, and the `settings` columns for day start, presets, notifications and exact reminders, already exist from schema v1 with the PRD defaults.
- **PR 1 and PR 2 add no packages and no permissions.** PR 3 needs the owner's approval, asked when PR 3 starts with versions re-checked on pub.dev that day: `flutter_local_notifications`, `timezone`, `flutter_timezone` (decision 0005, tech plan 12), and the permissions `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` (only used when Exact reminders is on) and possibly `VIBRATE` (tech plan 8). The release-manifest guard against network permissions stays.
- The 13 choices approved with the wireframes (design README, M3 section) are the screen spec. None changes PRD behaviour, so there is no PRD edit.
- **Second device:** the tech plan asks for notification delivery with the app closed to be checked on at least two phone brands (risk R3). Open: the owner borrows a second Android phone for the PR 3 checks, or accepts the risk and M3 ships tested on the OnePlus only, noted in the release.

## Estimate

Measured in working sessions like the M2 ones (M2 took 2 PRs over about two days of sessions).

| Part | Estimate | Main uncertainty |
|---|---|---|
| PR 1: engine, actions, log | 1 to 2 sessions | E-002 dating of `woke` and `surfaced` for items that woke while the app was closed |
| PR 2: screens | 2 sessions | Android's date and time pickers can't grey past times, so the time step validates and disables OK |
| PR 3: reminders | 2 to 3 sessions, plus real-time checks on the phone | Phone makers delaying alarms; boot restore; the checks need real waiting (minutes to a restart) |

## Checklist

**Plan** (`docs/m3-plan`)

1. [x] Read PRD 5 to 7, 8.3, 8.4, 8.6, 9, 16, PRD_Edits (E-002, E-005), tech plan 4.2, 4.3, 6, 7, 8, decision 0005 and AT-033 to AT-060
2. [x] Wireframes (14 frames) approved by the owner; PNGs in `docs/design/m3-set-aside/`, choices in the design README
3. [x] This plan; PR closing #30

**PR 1: engine, actions, log** (`feat/m3-engine`, #31)

4. [ ] `lib/engine/time.dart`: `logicalDate(instant, dayStartMinutes)` and the four presets as pure functions of the clock and settings, presets in the past left out (AT-042 to AT-044), using the phone's local zone through `DateTime.toLocal()`
5. [ ] Scope: for a card, the list of nodes it can set aside (the item, then its task, project, stream or domain as PRD 7 lists) (AT-036)
6. [ ] Visibility already honours `snoozeUntil` and ancestors; add tests for AT-033 to AT-035, AT-037 to AT-040, and `nextChangeAt` returning the earliest future wake
7. [ ] Actions `setAside(nodeId, until, {preset, level, remind})`, `changeWakeTime`, `wakeNow`, each in one transaction with the surfaced sync; `set_aside` event with wake time, preset or custom, Remind me and level (AT-059); `woke` with `automatic` or `wake_now` (AT-060); Undo of a set aside = `wakeNow`
8. [ ] Automatic wakes: at each recompute, items whose wake time has passed since the last one get a `woke` (automatic) event, and newly visible items get `surfaced` dated with the time that made them visible (E-002). One transaction
9. [ ] Recompute on resume and at `nextChangeAt` (a single timer in the app layer, injected clock); `summaryProvider` reads the clock at each recompute
10. [ ] Settings read model: day start and notification options from the `settings` row, with the PRD defaults
11. [ ] Unit tests named by AT ID with the fake clock; table-driven preset tests with the sheet's November 2026 dates; the E-002 test (an item that wakes while the app is closed gets `surfaced` at its wake time)
12. [ ] Update tech plan notes, matrix, `CHANGELOG.md`; open PR 1

**PR 2: screens** (`feat/m3-screens`, #32, after PR 1 merges)

13. [ ] Set-aside picker per frames 2 to 4: scope dropdown, presets with times, Custom, Remind me; one tap saves; snackbar with Undo (frame 1)
14. [ ] Custom date and time per frames 5 and 6: past days blocked, a past time on today rejected with OK disabled (AT-045)
15. [ ] Clock on Summary cards and Set aside in the card sheet
16. [ ] Set-Aside page per frames 8 to 10: grouped Today, Tomorrow, Later; time remaining; "Hides N items"; Wake now; sheet with Change time and Open in tree; empty state (AT-046 to AT-049)
17. [ ] Explorer per frames 11 and 12: clock and "Back …" marks, greyed descendants, Set aside…, Wake now and Change set-aside time in the item menu (AT-041)
18. [ ] Accessibility: labels on every new action, 48 dp targets, large-text check
19. [ ] Widget tests: AT-033, AT-036, AT-041, AT-044 to AT-049; integration flows in `integration_test/`
20. [ ] Version 0.3.0+3 build for the phone; update `README.md`, `CHANGELOG.md`, matrix and this plan; open PR 2
21. [ ] Owner: set aside and wake items on the phone (no reminders yet)

**PR 3: reminders** (`feat/m3-reminders`, #33, after PR 2 merges)

22. [ ] Owner approval of the three packages and the permissions above (versions re-checked that day)
23. [ ] Pure planner over the next 60 days, capped at 100 notifications: named single, grouped same-moment, none for Remind me off, notifications off, or items still hidden (AT-050 to AT-054, AT-056); unit tests with the fake clock
24. [ ] Platform adapter: cancel and reschedule after every action, on start, on resume and after a time-zone change; boot restore (AT-057); exact scheduling only with Exact reminders on and the alarm permission granted (AT-058)
25. [ ] Permission asked at the first set aside, never at launch (AT-055, frame 7)
26. [ ] Settings screen per frame 14: Notifications and Exact reminders
27. [ ] Tap opens `/summary?focus=<id>` with the card highlighted; a grouped tap opens the Summary
28. [ ] Release manifest still has no network permission (CI APK check); list the device-only checks in the PR
29. [ ] Update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; open PR 3
30. [ ] Owner: release build on the phone; AT-033 to AT-058 Founder rows on the phone, including app closed and a restart; second brand if available

**Release** (owner)

31. [ ] When the M3 Must tests pass on the phone: close-out docs PR (#35), release PR `dev` → `main` (#34, merge commit), tag `v0.3.0`

## Changes to the plan

None yet.

## Notes for whoever picks this up

- The M2 engine already treats an item with a future `snoozeUntil`, or under an ancestor with one, as hidden, and already returns `nextChangeAt`. PR 1 is mostly time, presets, scope, actions, events and the recompute triggers.
- Android's time picker can't grey out individual past times, so frame 6's rule ("OK disabled until the time is after now") is checked after the pick, in our own dialog step.
- Waking writes nothing to `nodes`; `snooze_until` stays in the past until the next set aside. The `woke` (automatic) event is written by the first recompute after the wake time, dated with the wake time.
- The notification frames are wireframes of Android's own shade; the real look depends on the phone maker.
