# M5 Groups and order

- **Status:** In progress (plan and wireframes; no app code yet)
- **Approved by:** FINUSAM on 2026-11-07 (wireframes and their decisions). The checklist below still needs the owner's "Proceed" before PR 1 starts
- **Branches / PRs:** plan and wireframes `docs/m5-plan` (#41, #83); PR 1 `feat/m5-engine` (#42, #44); PR 2 `feat/m5-screens` (#43); close-out `docs/m5-close-out` (#46); release (#45)
- **PRD sections:** 6, 8.2, 8.4, 8.6, 9, 10, 13, 16 (plus E-013, E-014, E-015)
- **Acceptance tests:** AT-083 to AT-094 (12 rows: 9 Must, 3 Should), plus the button alternatives of AT-116 (tagged M7) and the E-013, E-014 and E-015 tests
- **Wireframes:** [`docs/design/m5-groups/`](../design/m5-groups/) (approved 2026-11-07)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16)

## Owner decisions for M5

Settled on 2026-11-07, with the wireframes.

1. **"No group" is a real choice** that overrides an inherited group ([E-013](../PRD_Edits.md#e-013-no-group-can-override-an-inherited-group)). Without it, a card dragged out of an inherited group would jump straight back, because a blank group means "follow the parent".
2. **Groups don't collapse in M5.** #43 asked for it, but the PRD and acceptance tests don't, and a collapsed group could hide an overdue bill.
3. **Deleting a group** has no "Are you sure?" step, and a 5-second Undo ([E-014](../PRD_Edits.md#e-014-deleting-a-context-group)).
4. **Every order change is logged,** in the Explorer as well as on the Summary ([E-015](../PRD_Edits.md#e-015-every-order-change-is-logged)). This settles #44.

Also:

- Two code PRs, matching #42 and #43, plus the close-out, which makes three. #44 goes into PR 1. Each leaves `dev` green and usable: after PR 1 nothing changes on the phone, because no screen can create a group yet.
- **Probably no schema change.** `context_groups`, `summary_slots` and `nodes.group_id` have been in the database since version 1, so #42's "schema v3 migration" looks unnecessary. Step 4 confirms this before any code is written. If a change does turn out to be needed, it comes back to the owner first.
- **No new packages and no new permissions.** Drag uses Flutter's own widgets, and the nine group icons are drawn in the app.
- The choices approved with the wireframes (design README, M5 section) are the screen spec.

## Estimate

Measured in working sessions like the M4 ones (M4 took 3 PRs over about two days of sessions).

| Part | Estimate | Main uncertainty |
|---|---|---|
| PR 1: engine, actions, log | 2 to 3 sessions | How a slot follows its owner when the next card is in another group; keeping positions tidy when cards come and go; `reordered` events on every Explorer reorder |
| PR 2: screens | 2 to 3 sessions, plus checks on the phone | Dragging across group headers in a long list, with auto-scroll; empty groups appearing as drop zones during a drag without the list jumping |
| Owner testing | A few days of arranging the real Summary | AT-116's TalkBack pass stays with M7, so only the buttons are checked here |

## Checklist

**Plan** (`docs/m5-plan`, #41)

1. [x] Read PRD 6, 8.2, 8.4, 8.6, 9, 10, 13, 16, tech plan 4.6 and AT-083 to AT-094, AT-116
2. [x] Wireframes (14 frames) approved by the owner; PNGs in `docs/design/m5-groups/`, choices in the design README
3. [x] Approved answers added to `PRD_Edits.md` (E-013 to E-015)
4. [x] This plan; PR for #41 (#83). Tick #41 and correct #42, #43 and #44 to match the decisions

**Before any M5 code merges**

5. [x] `v0.4.0` is tagged (#39, 2026-11-08). Then bring the M5 branches up to date with `dev`

**PR 1: engine, actions, log** (`feat/m5-engine`, #42 and #44)

6. [ ] Confirm that the existing tables are enough and the database stays at version 2. Write the decision record for the "No group" stored value in `docs/decisions/`
7. [ ] `effectiveGroupOf`: stop at the "No group" value and return nothing; treat a deleted group as unset, so the search carries on up the tree (AT-085, AT-086, E-013, E-014)
8. [ ] Slots: one per project, stream and recurring item. The next card for an owner takes the same position when it's in the same group, and goes to the end of the new group when it isn't (AT-088, AT-089); a new slot goes to the end of its group (AT-090); a recurring item returns to its position (AT-091)
9. [ ] Summary cards come out in group order and slot order, with No group last (AT-083). Slots never touch `sort_order` (AT-092)
10. [ ] Group actions, each in one transaction: create, edit, change order, delete with Undo (AT-084, E-014)
11. [ ] Card actions, each in one transaction: set a group on a node, move a card between groups and within one, each with `group_changed` and `reordered` as AT-094 asks; Undo of a move
12. [ ] `reordered` from `reorder`, `moveUp`, `moveDown` and `setChildOrder` in the Explorer (#44, E-015)
13. [ ] Unit tests named by AT ID with the fake clock, including the E-013, E-014 and E-015 tests. Arrangement survives completing items
14. [ ] Update tech plan 4.6, matrix, `CHANGELOG.md` and this plan; tick #42 and #44; open PR 1

**PR 2: screens** (`feat/m5-screens`, #43, after PR 1 merges)

15. [ ] Group headers and No group on the Summary (frames 1 and 2)
16. [ ] Drag within and between groups, with dashed drop zones for empty groups, auto-scroll, and the "Moved to" snackbar with Undo (frames 3 to 5)
17. [ ] Card sheet: Context group, Move up, Move down and the position line; the sheet stays open between taps (frame 6, AT-116)
18. [ ] Group picker (frame 7); Context group row in every create and edit form (frame 8); Explorer rows and item menu (frames 9 and 10)
19. [ ] Settings: Summary section, Context groups list, New group, Edit group, Delete with Undo (frames 11 to 14)
20. [ ] Accessibility: labels on every new action, 48 dp targets, large-text check
21. [ ] Widget tests for the AT rows the matrix marks W; integration flow for AT-093 in `integration_test/`; list the device-only checks in the PR
22. [ ] Version 0.5.0+5 build for the phone; update `README.md`, `CHANGELOG.md`, tech plan, matrix and this plan; tick #43; open PR 2

**Close-out and release**

23. [ ] Owner: release build on the phone; arrange the real Summary and run the AT-083 to AT-094 Founder rows. The on-phone suite runs only as `flutter test integration_test --no-uninstall`, after warning the owner
24. [ ] Close-out docs PR (#46), once the check passes: results on the test sheet, this plan, `CLAUDE.md` status
25. [ ] Owner: release PR `dev` → `main` (#45, merge commit), tag `v0.5.0`. Tick #45 and #46, and close #45 and the milestone by hand after tagging

## Changes to the plan

- 2026-11-08: `v0.4.0` was tagged before this plan merged, so the warning that M5 code must wait for it was removed and step 5 ticked. `dev` was merged into this branch.

## Notes for whoever picks this up

- **Nothing here has been built.** The ideas below are starting points, not decisions, and are open to change.
- **"No group" stored value:** a fixed value in `nodes.group_id` that can't clash with a real group's UUID. The column has no foreign key, so this needs no schema change. Anything that looks up a group by this id must expect it.
- **Drag:** either one flat `ReorderableListView` with the headers as rows, which gives auto-scroll for free, or `LongPressDraggable` with `DragTarget`, which is more work but gives finer control over the drop zones. Try the first one.
- **AT-087 is the case to get right early.** Dragging 1.1 to Errands sets Errands on 1.1 only; the project's slot then follows it. When 1.2 appears under At laptop, it's in a different group from the slot, so it goes to the end of At laptop.
- **`summary_slots` is one row per owner,** so a slot holds one position and one group. Recurring items each have their own, so a stream's normal card and its bills move separately.
- **AT-094 expects both events** on a move between groups: `reordered` with old and new position and group, and `group_changed`.
- **AT-116 is tagged M7.** M5 adds the button alternatives and their labels; the TalkBack pass on the phone stays with #56.
- **The frames were rendered with headless Chrome,** as in M4, and all 14 were checked as images. The final images are the reference if they differ from the live canvas, which hasn't been opened since it was published.
- #80 (a new reminder replacing one in the shade) has no milestone and isn't part of M5.
- **#84** (finishing a repeat-from-completion item early can give back the same due date) is in the M5 milestone but is its own bug-fix PR, not one of M5's three. It needs the owner's answer to its question first, and a failing test before the fix.
