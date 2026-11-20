# M6 Capture

- **Status:** Done (v0.6.0, 2026-11-20)
- **Approved by:** FINUSAM on 2026-11-15 (wireframes and their decisions); each PR's steps by the owner's "Proceed"
- **Branches / PRs:** plan and wireframes `docs/m6-plan` (#47); spike `spike/m6-widget-share` (#48, not merged); PR 1 `feat/m6-captures` (#49, #97); PR 2 `feat/m6-widget-share` (#50, #98); keyboard test fix `fix/capture-dialog-keyboard-test` (#99); close-out `docs/m6-close-out` (#52); release (#51)
- **PRD sections:** 8.5, 9, 10, 13, 16 (plus E-009, E-010, E-017)
- **Acceptance tests:** AT-095 to AT-104 (10 rows: 9 Must, 1 Should)
- **Wireframes:** [`docs/design/m6-capture/`](../design/m6-capture/) (approved 2026-11-15)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16)

## Owner decisions for M6

Settled on 2026-11-15, with the wireframes.

1. **Shared text opens the capture dialog, filled in,** so it can be trimmed before Save ([E-017](../PRD_Edits.md#e-017-shared-text-opens-the-capture-dialog-filled-in)). It's the same dialog the widget opens (E-009).
2. **Every capture in the list has a Create button,** as well as Create an item in its menu.
3. **Remove has Undo** for 5 seconds. It brings back the capture, not the item just made.
4. **A kept capture shows "N items made",** counted from its `converted` events.
5. **The `captured` event records where the capture came from:** the app, the widget or a share. Never the text.
6. **Captures can be long.** The box grows as you type, and Enter starts a new line, so a capture can be a whole list. The list shows the first 3 lines. Items are made from it one at a time, with Keep after each and Remove after the last. Splitting it automatically is Phase 2 (E-010).

Also:

- **Probably no schema change.** The `captures` table and the `events` columns have been in the database since version 1. `converted` events carry the capture's id in their payload, which is enough to count "N items made". Step 8 confirms this before any code is written. If an index or a column does turn out to be needed, that is a migration, and it comes back to the owner first.
- **Packages and the manifest wait for the spike.** `home_widget` 0.10.0 and `receive_sharing_intent` 1.9.0 are only candidates (tech plan, packages). The spike compares each with a few lines of our own Kotlin, and nothing is added without the owner's approval of decision record 0007. No new permissions are expected: a widget and a share target need none.
- Two code PRs, matching #49 and #50, plus the close-out, which makes three. The spike branch is never merged; its decision record lands with PR 1, or with PR 2 if the spike finishes later. PR 1 makes capture work fully inside the app, so `dev` is usable after it.
- The choices approved with the wireframes (design README, M6 section) are the screen spec.

## Estimate

Measured in working sessions like the M5 ones (M5 took 3 PRs, plus 2 bug-fix PRs, over about a week of sessions).

| Part | Estimate | Main uncertainty |
|---|---|---|
| Spike: widget and share | 1 to 2 sessions, on the phone | How the small dialog saves a capture without starting the full app: a second, light Flutter screen that opens the same database, or a little Kotlin that hands the text to the app. Writing to the same SQLite file from two places at once has to be safe |
| PR 1: captures, Capture tab, create form | 2 to 3 sessions | The "Goes in" list for big trees; one transaction for create, `created`, `converted` and the optional Remove |
| PR 2: widget and share target | 2 sessions, plus checks on the phone | Depends on the spike. Phone makers treat widgets and dialogs over other apps differently; OxygenOS is the only test phone |
| Owner testing | A few days of real capturing | The widget and share sheet can only be checked on the phone |

## Checklist

**Plan** (`docs/m6-plan`, #47)

1. [x] Read PRD 8.5, 9, 10, 13 and 16, E-009, E-010, and AT-095 to AT-104
2. [x] Wireframes (17 frames) approved by the owner; PNGs in `docs/design/m6-capture/`, choices in the design README
3. [x] Approved answer added to `PRD_Edits.md` (E-017)
4. [x] This plan; PR for #47. Correct the AT numbers in #48, #49 and #50, and #48's decision record number (0006 is taken, so 0007)

**Spike** (`spike/m6-widget-share`, #48, not merged)

5. [x] On the phone: a home-screen widget whose button opens a small dialog over the current app, where Save stores a capture without opening the full app (E-009). Try `home_widget` 0.10.0 and a plain Android widget with our own Kotlin
6. [x] Share target: compare `receive_sharing_intent` 1.9.0 with an intent filter on the same dialog and a few lines of Kotlin. Check text from Chrome and WhatsApp
7. [x] Decision record `docs/decisions/0007-capture-widget-and-share.md`, covering how the dialog reaches the database. Owner approval for any package (licence, upkeep, pinned version) and every manifest change
   - 2026-11-16: both approaches worked on the phone; the owner chose A (a small Flutter screen). Our own Kotlin was tried first with the owner's agreement, and neither package turned out to be needed. The owner approved the record and its manifest changes the same day (Accepted)

**PR 1: captures, Capture tab, create form** (`feat/m6-captures`, #49)

8. [x] Confirm the existing tables are enough and the database stays at version 2
9. [x] Capture actions, each in one transaction: add (with `captured` and its source), edit (keeps the captured time), delete and Undo (soft delete). Never log capture text
10. [x] Create from a capture: create the node, `created` and `converted` (linking capture and node) in one transaction (PRD 13); Remove with Undo; "N items made"
11. [x] Capture tab (frames 1 to 7): the growing box, newest first, 3-line preview, Create button, menu, Edit, Delete with Undo
12. [x] Create form (frames 8 to 12): type, then "Goes in" with search, then title, notes, Context group and Repeat for a stream item; Remove or Keep
13. [x] Accessibility: labels on every new action, 48 dp targets, large-text check
14. [x] Unit and widget tests named by AT ID with the fake clock (AT-095 to AT-098, AT-101 to AT-104); an integration flow for AT-097's restart
15. [x] Update tech plan, matrix, `README.md`, `CHANGELOG.md` and this plan; tick #49; open PR 1
   - 2026-11-16: no schema change was needed (step 8). The owner approved changing the home shell test that looked for the "Coming in M6" placeholder, and deleting the placeholder screen. TalkBack check: the whole capture row first merged into one item, hiding its buttons; only the text now opens the menu. The screens haven't been seen on the phone yet; that's step 20

**PR 2: widget and share target** (`feat/m6-widget-share`, #50, after PR 1 and decision 0007)

16. [x] The widget and its dialog, as decided (frames 13, 14 and 17)
17. [x] The share target, opening the same dialog filled in (frames 15 to 17, E-017)
18. [x] Tests for what runs in Flutter (the dialog screen and its save); device-only checks listed in the PR (AT-095 in airplane mode, AT-099, AT-100)
19. [x] Version 0.6.0+6 build for the phone; update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #50; open PR 2
   - 2026-11-16: built as decision 0007 says. The owner approved two choices with the checklist: tapping outside the dialog doesn't close it, and the widget is the spike's teal bar. The widget's text is in `res/values/strings.xml`, and its text colour is in `colors.xml`. A test shows a save from a second drift client reaching the app's open list straight away. The phone wasn't connected, so the 0.6.0 build hasn't been installed or tried yet; that, the keyboard and dark mode are step 20

**Close-out and release**

20. [x] Owner: release build on the phone; the AT-095 to AT-103 Founder rows, including the widget and sharing from Chrome and WhatsApp. The on-phone suite runs only as `flutter test integration_test --no-uninstall`, after warning the owner, and never from an older version than the one installed
   - **Phone check (2026-11-17):** the owner ran the 0.6.0 release build on the OnePlus and reported AT-095 to AT-103 passed, including the widget, sharing from Chrome and WhatsApp, the keyboard and dark mode, so all 10 M6 rows of the acceptance sheet are Pass, dated 2026-11-17. AT-104 is a Developer row, covered by its automated tests. The on-phone suite passed 142 of 143: the capture dialog's keyboard test read Flutter's test keyboard, which doesn't exist on a phone. The owner approved changing that test (#99); after it the suite passed 143 of 143. The release build was reinstalled with `adb install -r` both times, with data kept
21. [x] Close-out docs PR (#52), once the check passes: results on the test sheet, this plan, `CLAUDE.md` status
22. [ ] Owner: release PR `dev` → `main` (#51, merge commit), tag `v0.6.0`. Tick #51 and #52, and close #51 and the milestone by hand after tagging

## Changes to the plan

- 2026-11-15 (wireframes): the owner asked whether a capture could hold a long list of things. The frames were redrawn before approval to show it: a growing box, 3-line previews, and one capture worked through with Keep (decision 6).

## Notes for whoever picks this up

- **The issues had the AT numbers wrong** when this plan was written: the widget is AT-099 and the share sheet AT-100, and making items from a capture is AT-101 to AT-103. #48, #49 and #50 were corrected along with this plan.
- **Event shape, proposed for step 9:**
  - `captured` uses the capture's id as `node_id`, `capture` as `node_type`, and `{"source": "app" | "widget" | "share"}` as its payload.
  - `converted` is about the new node, with `{"capture_id": …}` as its payload.
  - PRD 9 lists no events for editing or deleting a capture, so none are written.
- **The dialog outside the app** is the riskiest part of M6. If neither approach in the spike works well on OxygenOS, stop and ask the owner before changing E-009's "without opening the full app".
- **The on-phone suite** replaces the installed app with a test build. Reinstall the release build afterwards with `adb install -r`.
