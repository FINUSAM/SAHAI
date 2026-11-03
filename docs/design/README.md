# Design

Wireframes for each milestone's screens. PRD 16 makes approved wireframes a gate: a milestone starts only after its screens are approved.

- If a wireframe and the PRD (with [`PRD_Edits.md`](../PRD_Edits.md)) disagree, the PRD wins. Open a `prd-question` issue rather than guessing.
- Each milestone gets a folder of PNG images (one per frame) plus the link to the editable canvas. Keep images small (PNG or WebP, under about 1 MB each).

## Wireframes

| Milestone | Screens | Status | Images | Canvas |
|---|---|---|---|---|
| M1 Foundations | Explorer (9 frames) | **Approved** by FINUSAM, 2026-10-30 | [`m1-explorer/`](m1-explorer/) | [Sahai wireframes: M1 Explorer](https://claude.ai/artifact/Md4TXCHV3iJ7GG9d3s7kFi) (private to the owner until shared) |
| M2 Core loop | Summary, card sheet, Explorer Mark done and Reopen (10 frames) | **Approved** by FINUSAM, 2026-11-04 | [`m2-summary/`](m2-summary/) | [Sahai wireframes: M2 Summary](https://claude.ai/artifact/5mT1TddXtf8N6TvygZgTLV) (private to the owner until shared) |

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

## M2 Summary

Same style and sample tree as M1. Dashed boxes mark controls from later milestones (set aside M3, recurring items M4, groups M5), shown only so the layout leaves room for them. The activity log (PRD 9) has no screen, so it has no frame.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [Summary with cards](m2-summary/01-summary-cards.png) | One card per project and per stream, in tree order; type label, title, path, checkmark; domains and streams never appear | AT-013, AT-014, AT-021, AT-022, AT-023 |
| 2 | [Summary, empty](m2-summary/02-summary-empty.png) | Fresh install, or everything finished; "Open Explorer" | — |
| 3 | [Empty project](m2-summary/03-empty-project.png) | A project with no tasks shows as a prompt with "Add a task"; its checkmark stays | AT-019 |
| 4 | [Task sign-off](m2-summary/04-task-sign-off.png) | All subtasks done; the task stays TODO and says what Mark done unlocks; later tasks hidden | AT-016, AT-018 |
| 5 | [Project sign-off](m2-summary/05-project-sign-off.png) | All tasks DONE or deleted; the project card shows for sign-off | AT-020, AT-024 |
| 6 | [Complete with Undo](m2-summary/06-complete-undo.png) | The next subtask takes the same slot; "Done: …" snackbar with Undo for 5 s | AT-015, AT-017, AT-025, AT-026, AT-030, AT-031 |
| 7 | [Card sheet](m2-summary/07-card-sheet.png) | Tap a card: title, path chips, notes, Mark done, Open in tree | AT-029 |
| 8 | [Open in tree](m2-summary/08-open-in-tree.png) | Explorer with ancestors expanded and the item highlighted | AT-029 |
| 9 | [Explorer: Mark done](m2-summary/09-explorer-mark-done.png) | The same Undo snackbar as the Summary; M1 shipped Mark done without one | AT-025, AT-030 |
| 10 | [Explorer: Reopen](m2-summary/10-explorer-reopen.png) | Item menu for a DONE item; the Reopen line names the DONE ancestors that reopen with it | AT-027, AT-028, AT-032 |

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes on 2026-11-04. None changes PRD behaviour, so there's no PRD edit.

- **Start screen:** the app opens on the Summary tab. M1 opened on the Explorer as a stop-gap.
- **Card anatomy:** a small type label (SUBTASK, TASK, PROJECT, STREAM ITEM), the title, and a path line with every ancestor (Domain › Project › Task). The checkmark is a round outline on the right; tapping anywhere else opens the card sheet.
- **Order in M2:** tree order (domains in their order, then each domain's projects and streams in their order). Manual order and context groups come in M5.
- **Sign-off cards say what happens next:** a task reads "All 2 subtasks done · Mark done to unlock 2. Design pages"; a project reads "All 3 tasks done".
- **Empty project card:** "Add a task" opens the M1 create form with the project as parent. Its checkmark stays available, since PRD 6 makes an empty project a leaf that can be signed off.
- **Undo snackbar:** "Done: <title>" with Undo for 5 seconds, on the Summary and in the Explorer.
- **Card sheet:** title, path chips, notes if any, then Mark done and Open in tree. Set aside (M3) and Context group (M5) are placeholders.
- **Open in tree:** switches to the Explorer, expands the ancestors and highlights the row; the highlight fades after a moment.
- **Reopen:** a line in the Explorer item menu for DONE items; its second line names the ancestors that reopen with it. No confirmation step and no Undo snackbar, because Mark done reverses it.
- **Empty Summary:** "Nothing to show yet", one line of explanation, and an Open Explorer button.
