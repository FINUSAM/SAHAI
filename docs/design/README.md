# Design

Wireframes for each milestone's screens. PRD 16 makes approved wireframes a gate: a milestone starts only after its screens are approved.

- If a wireframe and the PRD (with [`PRD_Edits.md`](../PRD_Edits.md)) disagree, the PRD wins. Open a `prd-question` issue rather than guessing.
- Each milestone gets a folder of PNG images (one per frame) plus the link to the editable canvas. Keep images small (PNG or WebP, under about 1 MB each).

## Wireframes

| Milestone | Screens | Status | Images | Canvas |
|---|---|---|---|---|
| M1 Foundations | Explorer (9 frames) | **Approved** by FINUSAM, 2026-10-30 | [`m1-explorer/`](m1-explorer/) | [Sahai wireframes: M1 Explorer](https://claude.ai/artifact/Md4TXCHV3iJ7GG9d3s7kFi) (private to the owner until shared) |

## M1 Explorer

Low-fidelity, grey on purpose: layout and flow only, no visual design yet. Dashed boxes mark controls from later milestones (set aside M3, repeat M4, groups M5), shown only so the layout leaves room for them.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [App shell](m1-explorer/01-app-shell.png) | Bottom tabs and the Settings gear | — |
| 2 | [Explorer, empty](m1-explorer/02-explorer-empty.png) | Fresh install, with "Add a domain" | AT-001 |
| 3 | [Explorer, full tree](m1-explorer/03-explorer-tree.png) | Domains, projects, sequential tasks, subtasks, streams and items; lock on locked tasks; no checkmark on domains or streams | AT-001, AT-003, AT-007 |
| 4 | [Add menu](m1-explorer/04-add-menu.png) | Only valid child types offered | AT-002 |
| 5 | [Create / edit](m1-explorer/05-create-edit.png) | Title and notes; the same screen edits | AT-001, AT-010 |
| 6 | [Node actions](m1-explorer/06-node-actions.png) | Edit, add, mark done, move, move up/down, reorder, delete | AT-004 to AT-006, AT-008 |
| 7 | [Reorder mode](m1-explorer/07-reorder.png) | Drag handles plus up/down buttons | AT-004, AT-005 |
| 8 | [Move to…](m1-explorer/08-move-to.png) | Only valid new parents listed | AT-006 |
| 9 | [Delete with Undo](m1-explorer/09-delete-undo.png) | Item and everything under it removed; snackbar with Undo | AT-008, AT-009 |

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes:

- **Navigation:** four bottom tabs (Summary, Set-Aside, Explorer, Capture), with Settings behind a gear icon at the top right that opens its own screen.
- **Adding:** a "+ Domain" button floats at the bottom right of the Explorer. Everything else is added from an item's "⋮" menu, which only offers valid child types.
- **Locked tasks:** a lock icon replaces the checkmark, so they can't be marked done until they unlock. This changes behaviour, so it's also recorded as [E-007](../PRD_Edits.md#e-007-locked-tasks-cant-be-marked-done-in-the-explorer).
- **Delete:** no "Are you sure?" step; the Undo snackbar is the safety net (PRD 7).
- **Reorder:** drag handles, plus up/down buttons as the accessible alternative (PRD 13). Move up/down is also in each item's menu.
