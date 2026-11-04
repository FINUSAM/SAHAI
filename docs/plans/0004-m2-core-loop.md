# M2 Core loop

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-11-04
- **Branches / PRs:** PR 1 `feat/m2-engine` → `dev`; PR 2 `feat/m2-summary` → `dev`; a third PR is reserved if needed
- **PRD sections:** 5, 6, 7, 8.2, 9 (plus E-001, E-002)
- **Acceptance tests:** AT-013 to AT-032, plus the E-001 test
- **Wireframes:** [`docs/design/m2-summary/`](../design/m2-summary/) (approved 2026-11-04, PR #12)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16)

## Owner decisions for M2

- M2 is delivered in 2 PRs, with a third reserved. PR 1 is the engine, actions and log with unit tests; PR 2 is the screens. Each leaves `dev` green and usable.
- One database change, schema v2: a new table `summary_visible` holding the node IDs currently on the Summary and when each surfaced. The `surfaced` events and this table are written in the same transaction, so a crash between them can't log the same item twice. First real migration (adds only).
- No new packages and no Android permissions.
- The 10,000-item benchmark is a script (`tool/benchmark.dart`) run on the dev machine with its number recorded here, not a timing assertion in CI.
- Founder daily use starts when PR 2 is on the phone as v0.2.0 (PRD 16).

## Checklist

**Setup**

1. [x] Branch `feat/m2-engine` from `dev`; save this plan

**PR 1: engine, actions, log** (`feat/m2-engine`)

2. [x] Engine `visibility.dart`: one depth-first walk (tech plan 4.2) returning the cards (node, card type, path, hint) and `nextChangeAt` (always null in M2). Awake and set-aside checks built in as always-true so M3 only has to feed them
3. [x] Engine `surfaced.dart`: pure diff of the previous and new card sets returning the newly visible IDs, taking the "became visible at" time as a parameter for E-002 in M3
4. [x] Schema v2: `summary_visible` table, migration step, schema snapshot, generated migration test v1 → v2 with data (AT-012)
5. [x] Actions: `markDone` returns an undo token and logs `completed`; `undoComplete` restores TODO, logs `completion_undone` and suppresses a new `surfaced` for the restored card (E-001); `reopen` re-lock test (AT-028); every action recomputes, diffs, writes `surfaced` events and updates `summary_visible` in the same transaction
6. [x] `summaryProvider` deriving cards from the tree; `EventTypes` gains `surfaced` and `completion_undone`
7. [x] `tool/benchmark.dart` with a 10,000-item generator; run it and record the recompute time below
8. [x] Unit tests named by AT ID: AT-013 to AT-025, AT-027, AT-028, AT-030 to AT-032, E-001 (AT-023 as a random-action-sequence test)
9. [x] Update tech plan 4.5 and section 5, test matrix notes, `CHANGELOG.md`; merge `dev` (PR #12) in; open PR 1

**PR 2: screens** (`feat/m2-summary`, after PR 1 merges)

10. [x] Summary screen per frames 1–6: cards in tree order with type label, path, hint and checkmark; empty state with Open Explorer; empty-project card with Add a task
11. [x] Card sheet per frame 7: title, path chips, notes, Mark done, Open in tree
12. [x] Open in tree per frame 8: `/explorer?node=<id>`, expand ancestors, highlight the row, fade
13. [x] Explorer: Mark done gets the "Done: <title>" Undo snackbar (frame 9); Reopen's menu line names the ancestors that reopen (frame 10)
14. [x] App opens on the Summary tab; Summary placeholder removed
15. [x] Accessibility: labels on every card action, 48 dp targets, large-text check
16. [x] Widget tests: AT-013 to AT-017, AT-019, AT-020, AT-022, AT-025, AT-026, AT-027, AT-029; restart flows added to `integration_test/`
17. [x] Version 0.2.0+2; update `README.md`, `CHANGELOG.md` (0.2.0), matrix and this plan; open PR 2
18. [ ] Owner: release build on the OnePlus, M2 Must tests from the sheet on the phone, daily use starts

**Release** (owner)

19. [ ] When the M2 Must tests pass on the phone: PR `dev` → `main` (merge commit), tag `v0.2.0`

## Changes to the plan

- 2026-11-04: Step 1 branched from `dev` before PR #12 (wireframes, docs only) merged, so coding could start; `dev` is merged in again before PR 1 opens (step 9).

## Notes for whoever picks this up

- **Phone install (2026-11-04, PR 2 build):** The M1 build on the OnePlus had been signed by a GitHub CI runner's throwaway debug key, so no later build could be installed over it. The owner chose to uninstall M1 (losing the M1 test tree) and install M2 fresh; AT-012 could not be checked for M1 → M2 on the phone (it is covered by the automated v1 → v2 upgrade tests). From now on builds come from the owner's PC, which keeps one debug key (`%USERPROFILE%\.android\debug.keystore`), so M3 installs over M2 and AT-012 can be checked for real. Local toolchain: Temurin JDK 17 (matches CI), Android SDK at `C:\Users\finusam\AppData\Local\Android\Sdk` (platform-tools, platform 36, build-tools 36.0.0, NDK 28.2) installed with the Android CLI; Flutter configured with `flutter config --android-sdk` and `--jdk-dir`. `flutter test integration_test` on the OnePlus: 38 passed. Owner tested the M2 release build on the phone: working well.
- **PR 2 (2026-11-04):** 137 tests pass, `at_coverage M2` is 20 of 20. The Explorer's checkmark tooltips keep the raw title ("Mark Write copy done", M1 tests) while the Summary's use the numbered title ("Mark 1. Write copy done"); the "Done: …" snackbar uses the numbered title on both screens. "Open in tree" scrolls to an estimated row position (64 dp per row), not the exact one; a long tree may land a little off. The `CLAUDE.md` status line still says M1 shipped; it changes with the owner's approval when `v0.2.0` is tagged.

- **Benchmark (2026-11-04, dev machine, `dart run tool/benchmark.dart`):** 10,002 nodes, 467 cards, tree build 13 ms, recompute median 0.7 ms, max 2.3 ms. The PRD limit is 50 ms on a mid-range phone (AT-114, checked for real in M7).
- PR 1 (`feat/m2-engine`): 119 tests pass locally (79 from M1 + 40 new). `dart run tool/at_coverage.dart M2` reports 18 of 20; AT-026 and AT-029 are widget-only tests for PR 2.
- The Flutter SDK was not on the development machine at the start of M2; the owner installed it on 2026-11-04 and switched it to the pinned 3.47.3 (`git checkout 3.47.3` in the SDK folder). Git has no author identity in Claude Code's shells, so commits pass it explicitly.
- Upgrading a v1 database starts with an empty `summary_visible` table, so the first action after the upgrade logs a `surfaced` event for every card already on the Summary, dated that moment. A one-time artefact of the upgrade.
- `markDone` now returns the `completed` event id as the undo token; `undoComplete(token)` reverses it. The Explorer still calls `markDone` without using the token; PR 2 adds the snackbar.
- Reorder, move, delete, restore, mark done, undo and reopen all end with the surfaced sync. Edit (title/notes) doesn't, because it can't change which cards show.

- E-002 (a `surfaced` event carries the wake time when the item came back while the app was closed) is M3 work; the diff function takes the time as a parameter so M3 only has to pass it.
- Reordering in the Explorer still doesn't log a `reordered` event (PRD 9 describes it in Summary-ordering terms). To confirm with the owner before M5.
- The dashed placeholders in the wireframes (set-aside clock, recurring card, group header) are wireframe aids only and are not built in M2.
