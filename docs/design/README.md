# Design

Wireframes for each milestone's screens. PRD 16 makes approved wireframes a gate: a milestone starts only after its screens are approved.

- If a wireframe and the PRD (with [`PRD_Edits.md`](../PRD_Edits.md)) disagree, the PRD wins. Open a `prd-question` issue rather than guessing.
- Each milestone gets a folder of PNG images (one per frame) plus the link to the editable canvas. Keep images small (PNG or WebP, under about 1 MB each).

## Wireframes

| Milestone | Screens | Status | Images | Canvas |
|---|---|---|---|---|
| M1 Foundations | Explorer (9 frames) | **Approved** by FINUSAM, 2026-10-30 | [`m1-explorer/`](m1-explorer/) | [Sahai wireframes: M1 Explorer](https://claude.ai/artifact/Md4TXCHV3iJ7GG9d3s7kFi) (private to the owner until shared) |
| M2 Core loop | Summary, card sheet, Explorer Mark done and Reopen (10 frames) | **Approved** by FINUSAM, 2026-11-04 | [`m2-summary/`](m2-summary/) | [Sahai wireframes: M2 Summary](https://claude.ai/artifact/5mT1TddXtf8N6TvygZgTLV) (private to the owner until shared) |
| M3 Set aside | Set-aside picker, Set-Aside page, Explorer set aside, notifications, reminder settings (14 frames) | **Approved** by FINUSAM, 2026-11-04 | [`m3-set-aside/`](m3-set-aside/) | [Sahai wireframes: M3 Set aside](https://claude.ai/artifact/Pyxg2E37pU7pYzF3KhPB12) (private to the owner until shared) |

## Brand

The owner's logo files are in [`brand/`](brand/): the "SAHAI" wordmark (`logo.png`, with the tagline on a paper texture) and a 1024 px adaptive-icon pair (`app_icon_foreground.png`, `app_icon_background.png`) plus their composite (`app_icon.png`).

| | Value | Used by |
|---|---|---|
| Teal | `#0F6469` | App theme seed (`lib/shared/brand.dart`), icon background (`res/values/colors.xml`) |
| Off-white | `#F5F2ED` | Icon S (`res/drawable/ic_launcher_foreground.xml`), logo background |

**Launcher icon (2026-11-04, placeholder):** an S monogram, off-white on teal, drawn by hand as a vector path in the same rounded spirit as the wordmark. It ships as an adaptive icon (`res/mipmap-anydpi-v26/ic_launcher.xml`) with the S reused as the monochrome layer for Android 13 themed icons, plus the five `mipmap-*dpi/ic_launcher.png` fallbacks rendered from the same shape. The wordmark itself is not used as the icon: five letters are unreadable at home-screen size. The wordmark is kept for the splash screen, README and store listing in M8, when the icon gets its final design with the real typeface.

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

## M3 Set aside

Same style and sample tree as M1 and M2. Unless a frame says otherwise it is 3:00 PM on Tuesday, Nov 3, the moment AT-042 uses. Dashed boxes in Settings mark settings from later milestones.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [Summary after setting aside](m3-set-aside/01-summary-set-aside.png) | Clock on every card; the next subtask takes the slot; "Set aside until Wed 8:00 AM" snackbar with Undo | AT-033, AT-040 |
| 2 | [Set-aside picker](m3-set-aside/02-picker.png) | Scope dropdown, presets with their real times, Custom, Remind me on | AT-042, AT-053, AT-059 |
| 3 | [Scope](m3-set-aside/03-scope.png) | This subtask, its task, its project or its domain, each naming the node | AT-036 to AT-039 |
| 4 | [Picker after midnight](m3-set-aside/04-picker-after-midnight.png) | 1:30 AM with the day starting at 4 AM: Tonight hidden, Tomorrow morning is later this morning | AT-043, AT-044 |
| 5 | [Custom: date](m3-set-aside/05-custom-date.png) | Android date picker with past days greyed | AT-045 |
| 6 | [Custom: time in the past](m3-set-aside/06-custom-time-past.png) | "Pick a time after 3:00 PM"; OK disabled | AT-045 |
| 7 | [Permission at the first set aside](m3-set-aside/07-permission.png) | Android's notification prompt, after the first set aside, never at launch | AT-055 |
| 8 | [Set-Aside page](m3-set-aside/08-set-aside-page.png) | Today, Tomorrow, Later; wake time and time remaining; a set-aside stream or domain says what it hides | AT-039, AT-046, AT-047 |
| 9 | [Set-Aside item sheet](m3-set-aside/09-set-aside-sheet.png) | What it hides, Wake now, Change time, Open in tree | AT-047, AT-048, AT-049, AT-060 |
| 10 | [Set-Aside page, empty](m3-set-aside/10-set-aside-empty.png) | "Nothing set aside" | — |
| 11 | [Explorer: set-aside marks](m3-set-aside/11-explorer-marks.png) | Clock and "Back …" on set-aside nodes; everything under them greyed | AT-041 |
| 12 | [Explorer: item menu](m3-set-aside/12-explorer-menu.png) | Wake now and Change set-aside time on a set-aside node; Set aside… on any other | AT-041, AT-048, AT-049 |
| 13 | [Notifications](m3-set-aside/13-notifications.png) | One item named with its path; several at once grouped and expandable | AT-050, AT-051, AT-052, AT-054 |
| 14 | [Settings: reminders](m3-set-aside/14-settings-reminders.png) | Notifications and Exact reminders switches | AT-056, AT-058 |

AT-034, AT-035 and AT-057 have no frame of their own: they are about timing (a waking item takes its place back, a branch goes dark, reminders survive a restart).

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes on 2026-11-04. None changes PRD behaviour, so there's no PRD edit.

- **Clock on every Summary card** opens the set-aside picker. The card sheet's M2 placeholder becomes a Set aside line.
- **One tap on a preset sets the item aside;** there is no Save button. Each preset shows its real time ("Wed 8:00 AM"), so the day-start rule is never a surprise.
- **Scope** is a dropdown at the top of the picker, defaulting to the item itself. Each option names the node it would set aside ("Its project · Website relaunch").
- **Remind me** is a switch at the bottom of the picker, on each time the picker opens (the PRD default). It isn't remembered between uses.
- **Custom date and time** uses Android's date picker, then its time picker. Past days are greyed; a past time on today's date shows "Pick a time after 3:00 PM" and OK stays disabled.
- **Snackbar after setting aside:** "Set aside until Wed 8:00 AM" with Undo for 5 seconds. Undo wakes the item at once and is logged as a Wake now.
- **Notification permission** is asked right after the first set aside is saved, so the item is set aside whatever the answer. Never at launch.
- **Waking needs no database write.** An item is awake the moment its time passes. The automatic `woke` event and the `surfaced` event are written at the next recompute, dated with the wake time, as E-002 already does for `surfaced`.
- **Set-Aside page** is grouped Today, Tomorrow and Later, soonest first. Each card shows the title, path, wake time, time remaining and a Wake now button. A set-aside project, stream or domain is listed once with "Hides 2 items"; its sheet lists them. A crossed-out bell marks items with Remind me off.
- **Set-Aside card sheet:** Wake now, Change time (the same presets and Custom, without the scope) and Open in tree.
- **Explorer:** a set-aside node shows a clock and "Back Mon, Nov 9 8:00 AM", and everything under it is greyed. Its menu offers Wake now and Change set-aside time; any other node offers Set aside…, which opens the picker without the scope dropdown, since the node is chosen directly.
- **Notifications:** one item reads "<title> is back" with its path; several at the same moment read "3 items are back" and expand to list them. Tapping a single one opens the Summary with that card highlighted; tapping a grouped one opens the Summary.
- **Settings** gets its first content: a Reminders section with Notifications and Exact reminders switches. Turning on Exact reminders sends the user to Android's alarm permission screen. Day starts at, the preset times and the bill reminder time keep the PRD defaults until M7 and M4.
