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
| M4 Recurring items | Due labels, schedule form, Skip and Stop repeating, waiting bills, recurring reminders (11 frames) | **Approved** by FINUSAM, 2026-11-06 | [`m4-recurring/`](m4-recurring/) | [Sahai wireframes: M4 Recurring items](https://claude.ai/artifact/JqARsT6vEsGqa2uMZZEunt) (private to the owner until shared) |
| M5 Groups and order | Grouped Summary, drag and button moves, group picker, Explorer groups, Context groups settings (14 frames) | **Approved** by FINUSAM, 2026-11-07 | [`m5-groups/`](m5-groups/) | [Sahai wireframes: M5 Groups and order](https://claude.ai/artifact/SA1DfAVLoFVkS1njswWto5) (private to the owner until shared) |
| M6 Capture | Capture tab, edit and delete, create from a capture, Remove or Keep, home-screen widget, share target (17 frames) | **Approved** by FINUSAM, 2026-11-15 | [`m6-capture/`](m6-capture/) | [Sahai wireframes: M6 Capture](https://claude.ai/artifact/Syp64TDuh6QAMzxx4bgr69) (private to the owner until shared) |
| M7 Polish and safety | Onboarding with the practice step, full Settings, presets, Day starts at, backup warning, About, Replay, Send feedback, largest font, due dates on one-off items (27 frames) | **Approved** by FINUSAM, 2026-11-20 | [`m7-polish/`](m7-polish/) | [Sahai wireframes: M7 Polish and safety](https://claude.ai/artifact/Ro6sSXNPPUcXdScF6F9GJe) (private to the owner until shared) |

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

## M4 Recurring items

Same style and sample tree as M1 to M3, with the four PRD 7 bills in Finance & Bills. Unless a frame says otherwise it is Monday, Nov 9, 2026, with HDFC due Nov 5 and unpaid.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [Summary with recurring cards](m4-recurring/01-summary.png) | A due line under the path, with overdue in bold; an unpaid bill doesn't hide the next, and recurring cards don't block normal items | AT-061 to AT-065 |
| 2 | [Create form, Repeat off](m4-recurring/02-form-repeat-off.png) | A Repeat switch, on stream items only | — |
| 3 | [Schedule, monthly](m4-recurring/03-schedule-monthly.png) | Every, period, day, next due, repeat from, show before due, and when it will appear | AT-061, AT-067, AT-069, AT-073 |
| 4 | [Schedule, weekly](m4-recurring/04-schedule-weekly.png) | Weekday buttons | AT-074, AT-075 |
| 5 | [Card sheet](m4-recurring/05-card-sheet.png) | The schedule, Skip this occurrence with the next date, Stop repeating | AT-071, AT-080 |
| 6 | [Done with Undo](m4-recurring/06-done-undo.png) | "Done. Next due Dec 5" snackbar with Undo | AT-066, AT-070 |
| 7 | [Set-Aside page, waiting bills](m4-recurring/07-set-aside-waiting.png) | Waiting bills with their show time and due date | E-005 |
| 8 | [Explorer](m4-recurring/08-explorer-recurring.png) | Repeat mark, schedule, due date and "back" date; never DONE | AT-077 |
| 9 | [Stop repeating](m4-recurring/09-stop-repeating.png) | The card loses its due line; "no longer repeats" snackbar with Undo | AT-080 |
| 10 | [Reminders](m4-recurring/10-notifications.png) | The show-day and due-day reminders, and several at once | AT-078 |
| 11 | [Reminder tap, paused domain](m4-recurring/11-reminder-paused-domain.png) | The item's sheet opens directly, with a note saying why it isn't on the Summary | AT-079 |

AT-068, AT-072, AT-076, AT-081 and AT-082 have no frame of their own: they are about dates and logging, and use the labels and sheets above.

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes on 2026-11-06. None changes what the PRD asks for, except that Undo on Skip and on Stop repeating needed log events PRD 9 didn't have: that is [E-011](../PRD_Edits.md#e-011-skip-and-stop-repeating-have-undo-and-the-log-records-them).

- **Repeat** is a switch in the create and edit forms, on stream items only. Turning it on opens the schedule fields below it.
- **Schedule fields:** Every, Period, then On day or weekday buttons, Next due, Repeat from, Show before due, and a line saying when the item appears ("Appears Wed, Dec 2").
- **First due date:** filled in with the next matching date, and the user can change it.
- **Due line:** under the path on the card, with a repeat mark; overdue is in bold. It's a label, not a status.
- **Done snackbar:** "Done. Next due Dec 5" with Undo for 5 seconds.
- **Skip this occurrence** is in the card sheet and shows the date it moves to. It has the same 5-second Undo as Done, worded "Skipped. Next due Dec 5". That snackbar has no frame of its own, because it's frame 6 with different words.
- **Stop repeating** is in the card sheet, with no "Are you sure?" step and a 5-second Undo instead, like Delete: "Pay HDFC card no longer repeats". Turning Repeat off in the edit form does the same thing.
- **Waiting bills on the Set-Aside page** show the day-start time, such as "Sun, Nov 15 4:00 AM", because that's when they really come back, plus their due date. The reminder still arrives at 9:00 AM.
- **Explorer:** a recurring item shows a repeat mark and "Monthly · due Dec 5 · back Dec 2". After it's completed it shows as TODO with its next due date.
- **Reminder wording:** "<title> is due Nov 5" on the show day, "<title> is due today" on the due day, and "2 items are due today" when several arrive at once. Taps work as in M3: a single one opens its card, a grouped one opens the Summary.
- **Reminder tap inside a paused domain:** the item isn't on the Summary, so the app opens its sheet directly, with Mark done and a note such as "Personal is set aside until Tue, Nov 10, so this isn't on the Summary."

### Choices added while building the screens

The owner approved these on 2026-11-07, for cases the frames don't show.

- **Yearly schedules** have In month and On day fields, in the style of On day.
- **Daily schedules** have no extra field.
- **Weekly schedules** can have no weekdays chosen, which simply counts weeks.
- **Grouped reminders with different dates** read "2 items are due", and each line gives its own date. "2 items are due today" stays for when they all are.
- **A bill's own set aside** doesn't stop its reminders. Tapping one opens the sheet from frame 11, naming the bill.

## M5 Groups and order

Same style and sample tree as M1 to M4, with three sample groups: At laptop, Errands and At home. Unless a frame says otherwise it is Monday, Nov 9, 2026. Dashed boxes in Settings mark settings from later milestones. Due lines in these frames leave out M4's small repeat mark; the real cards keep it.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [Summary, no groups](m5-groups/01-summary-no-groups.png) | No groups exist, so the Summary looks as it does today, with no headers | AT-083 |
| 2 | [Summary with groups](m5-groups/02-summary-groups.png) | A header with icon, name and count for each group, and No group last | AT-085, AT-086 |
| 3 | [Dragging a card](m5-groups/03-drag-card.png) | The card lifted; every group, including an empty one, is a place to drop it | AT-087, AT-092 |
| 4 | [Moved, with Undo](m5-groups/04-moved-undo.png) | The card at the end of its new group; "Moved to At laptop" snackbar with Undo | AT-087, AT-094 |
| 5 | [Next card keeps the place](m5-groups/05-next-card.png) | After Mark done, the next subtask takes the same position | AT-088 |
| 6 | [Card sheet](m5-groups/06-card-sheet.png) | Context group, Move up and Move down, "Position 1 of 3 in At laptop": everything drag does, without dragging | AT-116 |
| 7 | [Group picker](m5-groups/07-group-picker.png) | Same as the parent, each group, No group, New group | E-013 |
| 8 | [Form with Context group](m5-groups/08-form-group.png) | A Context group row in the create and edit forms, for every node type | AT-085, AT-090 |
| 9 | [Explorer rows](m5-groups/09-explorer-groups.png) | The group shows only where it's set on that node, or "No group" when that's set | AT-085, AT-086 |
| 10 | [Explorer item menu](m5-groups/10-explorer-menu.png) | A Context group line that says where the group comes from | AT-085 |
| 11 | [Settings](m5-groups/11-settings.png) | A new Summary section with Context groups | AT-084 |
| 12 | [Context groups list](m5-groups/12-groups-list.png) | Groups in Summary order, up and down buttons, how many items each is set on, New group | AT-084 |
| 13 | [Edit group](m5-groups/13-edit-group.png) | Name, optional icon, Delete group. New group is the same without Delete | AT-084 |
| 14 | [Group deleted, with Undo](m5-groups/14-delete-undo.png) | "Deleted At laptop" snackbar with Undo | E-014 |

AT-089, AT-091 and AT-093 have no frame of their own: they are about logic and restarts, and use the screens above.

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes on 2026-11-07. Three change or add to what the PRD says, so they are also PRD edits: "No group" as a real choice is [E-013](../PRD_Edits.md#e-013-no-group-can-override-an-inherited-group), deleting a group is [E-014](../PRD_Edits.md#e-014-deleting-a-context-group) and logging Explorer reorders is [E-015](../PRD_Edits.md#e-015-every-order-change-is-logged).

- **Dragging:** press and hold anywhere on a card to lift it. There is no separate drag handle.
- **No group:** the PRD's "default list". It always comes last, and its header shows only when at least one other group is on the Summary. With no groups showing, the Summary has no headers.
- **Group order:** set only in the Context groups list in Settings, with up and down buttons. Headers on the Summary don't drag.
- **Empty groups:** hidden at rest (AT-084), and shown as dashed drop zones during a drag.
- **Moving to another group:** the card goes to the end of that group, with "Moved to At laptop" and Undo for 5 seconds. Reordering within a group shows no snackbar, because moving the card back undoes it.
- **Undo in the log:** Undo of a move writes the same events the other way round, so M5 needs no new event types.
- **No-drag controls:** Move up and Move down are in the card sheet, and the sheet stays open between taps. The Context group line opens the group picker, which is how a card changes group without dragging.
- **Context group in forms and menus:** a row in the create and edit forms for every node type, and a line in the Explorer item menu.
- **Group picker:** "Same as <parent>" and "No group" appear only when an ancestor has a group. Otherwise there's a single "No group" row that clears the setting. New group is at the bottom.
- **Explorer rows:** a group shows only on the node it's set on, or "No group" when that's set. An inherited group isn't repeated down the tree.
- **Settings:** a new Summary section holds Context groups.
- **Group icons:** a fixed set of nine plus None, drawn in the app, so no new package.
- **Deleting a group:** no "Are you sure?" step, like Delete elsewhere. The Delete row says what happens to the items.
- **Recurring cards:** their sheets keep Skip this occurrence and Stop repeating from M4, alongside the new rows.
- **Collapsing groups:** not in M5. A collapsed group could hide an overdue bill, and neither the PRD nor the acceptance tests ask for it.

## M6 Capture

Same style and sample tree as M1 to M5, with the groups from M5. Unless a frame says otherwise it is Sunday, Nov 15, 2026, early evening. Frames 13 to 17 happen outside the app: on the home screen, and in Chrome. Their home screen, keyboard and share sheet are rough sketches of Android's, not designs.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [Capture, empty](m6-capture/01-capture-empty.png) | The capture box at the top, and what Capture is for | — |
| 2 | [Captures, newest first](m6-capture/02-capture-list.png) | Each capture with its date and time, a Create button and a menu; a long capture shows its first 3 lines | AT-095, AT-096 |
| 3 | [Typing a longer capture](m6-capture/03-typing-long.png) | The box grows as you type; Enter starts a new line and only Save saves | AT-095 |
| 4 | [A new capture goes on top](m6-capture/04-new-capture.png) | Saved straight into the list, newest first | AT-095, AT-096 |
| 5 | [Capture menu](m6-capture/05-capture-menu.png) | The whole text, then Create an item, Edit and Delete | AT-097, AT-098 |
| 6 | [Edit a capture](m6-capture/06-edit-capture.png) | Text only; editing keeps the captured time | AT-097 |
| 7 | [Deleted, with Undo](m6-capture/07-delete-undo.png) | "Capture deleted" snackbar with Undo | AT-098 |
| 8 | [Create from a capture](m6-capture/08-create-form.png) | The capture above the form, not copied in; what to make, where it goes, title, notes, Context group (and Repeat for a stream item) | AT-101, AT-102 |
| 9 | [Where it goes](m6-capture/09-place-picker.png) | Only the places the chosen type can go, with their path and a search box | AT-101, AT-102 |
| 10 | [Remove this capture?](m6-capture/10-remove-dialog.png) | After Save: Keep or Remove | AT-101 to AT-103 |
| 11 | [Kept, to make the next one](m6-capture/11-kept.png) | The capture stays, with "3 items made" | AT-103 |
| 12 | [Last item made, capture removed](m6-capture/12-removed.png) | The capture leaves the list; Undo brings it back | AT-103 |
| 13 | [Home-screen widget](m6-capture/13-widget.png) | A "Capture a thought" bar | AT-099 |
| 14 | [Widget dialog](m6-capture/14-widget-dialog.png) | A small dialog over the home screen: text box, Cancel, Save (E-009) | AT-099 |
| 15 | [Sharing text from Chrome](m6-capture/15-share-sheet.png) | Sahai Capture in Android's share sheet | AT-100 |
| 16 | [Shared text, ready to save](m6-capture/16-shared-dialog.png) | The same dialog with the shared text filled in (E-017) | AT-100 |
| 17 | [Saved, back where you were](m6-capture/17-saved-toast.png) | "Saved to Sahai Capture", without opening the app | AT-099, AT-100 |

AT-104 (capture events in the log) has no frame: the log has no screen.

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes on 2026-11-15. One changes what the PRD says, so it is also a PRD edit: shared text opening the dialog is [E-017](../PRD_Edits.md#e-017-shared-text-opens-the-capture-dialog-filled-in).

- **Capturing in the app:** a box at the top of the Capture tab, so a thought never needs another screen. It grows to about 6 lines, then scrolls. Enter starts a new line, and only Save saves, so a capture can be a whole list. Save is off while the box is empty.
- **Long captures:** a capture has no length limit. The list shows the first 3 lines and "…"; the menu, Edit and the Create form show the whole text.
- **Making items from a capture:** one at a time, by hand. A capture with several things in it is worked through with Keep after each item and Remove after the last. Splitting a capture into items automatically is Phase 2 (E-010).
- **Create button:** on every capture in the list, so making an item starts with one tap. The menu also has Create an item, plus Edit and Delete.
- **Create form:** the capture text sits above the form, greyed and not copied in, and the title starts empty (PRD 8.5). The type comes first, because it decides where the item can go and which fields follow (Repeat for a stream item). After the type comes the place, then the usual title, notes and Context group. Save is off until the type, place and title are filled in.
- **Where it goes:** a list of only the places the chosen type can go, each with its path, plus a search box: domains for a project, projects for a task, tasks for a subtask, streams for a stream item.
- **Remove or Keep:** asked after every Save. Remove has Undo for 5 seconds, which brings back the capture but not the new item.
- **"N items made":** a kept capture shows how many items have been made from it, counted from its `converted` events.
- **Edit and Delete:** editing keeps the captured time, and the list stays in captured order. Delete has no "Are you sure?" step, with Undo for 5 seconds, as elsewhere.
- **Widget:** one "Capture a thought" bar. Tapping it opens the small dialog over whatever is on screen, and Save closes it without opening the app (E-009).
- **Share target:** shared text opens the same dialog, filled in, so it can be trimmed before Save (E-017). Both dialogs end with a short "Saved to Sahai Capture" message.
- **Where a capture came from:** the `captured` event records the app, the widget or a share. It never records the text (tech plan, logging).

## M7 Polish and safety

Same style and sample tree as M1 to M6. Unless a frame says otherwise it is 3:00 PM on Tuesday, Nov 3, the moment M3 used, so the presets show the same times. The onboarding frames use a fresh install: the areas, project, task and subtasks in them are what the user typed, not sample data. Frame 17 is the phone's own email app, sketched, not designed.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 1 | [Welcome](m7-polish/01-welcome.png) | First run only: what Sahai is for, Get started, and Skip | AT-105, AT-107 |
| 2 | [Step 1: name your areas](m7-polish/02-areas.png) | One or two domains, with examples; Skip on every step | AT-105, AT-107 |
| 3 | [Step 2: a project and its first task](m7-polish/03-project.png) | Which area (when there are two), the project and its first task | AT-105 |
| 4 | [Step 2: two subtasks](m7-polish/04-subtasks.png) | Two subtasks in order, and the path being made | AT-105 |
| 5 | [Step 3: Summary reveal](m7-polish/05-reveal.png) | Only the first subtask, and why | AT-105 |
| 6 | [Step 4: tick off, then Undo](m7-polish/06-practice-done.png) | Practice banner; the next subtask takes the place; Undo | AT-106 |
| 7 | [Step 4: set aside](m7-polish/07-practice-set-aside.png) | Set aside with a preset; the second subtask shows | AT-106 |
| 8 | [Step 4: Wake now](m7-polish/08-practice-wake.png) | The Set-Aside page; Wake now brings the first subtask back | AT-106 |
| 9 | [Done: sign-off note](m7-polish/09-finish.png) | The task comes back for sign-off; the practice was undone | AT-105, AT-106 |
| 10 | [Settings, full screen](m7-polish/10-settings.png) | Set aside, Recurring items, Reminders, Summary, Backup, Help | AT-108, AT-109, AT-110, AT-112, AT-120 |
| 11 | [Set-aside presets](m7-polish/11-presets.png) | The four presets and their times; Reset to defaults | AT-109 |
| 12 | [Change Tonight to 9 PM](m7-polish/12-preset-time.png) | Android's time picker in typing mode | AT-109 |
| 13 | [Day starts at](m7-polish/13-day-start.png) | Whole hours from midnight to 6 AM, and what the setting means | AT-110 |
| 14 | [Backup: 20 MB warning](m7-polish/14-backup-warning.png) | Size over 20 MB, and what it means for Android's backup | AT-112 |
| 15 | [About Sahai](m7-polish/15-about.png) | Version, where the data lives, what's coming, licences; privacy policy in M8 | AT-122 (M8) |
| 16 | [Replay onboarding?](m7-polish/16-replay.png) | Replay adds new items next to the existing ones | AT-108 |
| 17 | [Send feedback: email draft](m7-polish/17-feedback.png) | The email app, with only the address and subject filled in | AT-120 |
| 18 | [Settings at the largest font](m7-polish/18-large-font.png) | Rows wrap and values move below their labels; nothing is cut off | AT-117 |

AT-111 (backup restore), AT-113 (log retention), AT-114 (speed), AT-115 (offline), AT-116 (TalkBack), AT-118 (time-zone change) and AT-119 (no half-finished changes) have no frame: they are about behaviour, not screens. AT-116's buttons were drawn in M5; frame 18 covers AT-117.

### Choices approved with these wireframes

The PRD doesn't specify these. The owner approved them along with the wireframes on 2026-11-20. None changes PRD behaviour, so there's no PRD edit.

- **When onboarding shows:** on first run, when there are no areas yet. An install that already has data, such as one updated from 0.6.0, goes straight to the Summary and never sees it uninvited. It can still be replayed from Settings.
- **Each step saves when you tap Next,** and Skip, on every step, keeps what was saved so far (AT-107). Back returns to an earlier step to change what it made, rather than making it again.
- **Steps 1 and 2:** one area is needed and a second is optional; the project, its first task and both subtasks are needed (PRD 8.1). With two areas, step 2 asks which one the project goes in.
- **Practice step:** runs on a temporary copy of what the user just made, with a "Practice: nothing here is saved" banner. Nothing in it is written to the database or the activity log, so AT-106 holds and the Phase 2 planner never learns from practice. Explorer and Capture are dimmed during practice. A dashed box gives each of the three moves in turn.
- **Finish:** explains the sign-off (PRD 8.1), says the practice was undone, and opens the real Summary with the first subtask on it.
- **Replay onboarding:** asks first, then runs the same steps. What is made is added next to the existing data; nothing existing changes.
- **Settings** is one scrolling screen with six sections: Set aside, Recurring items, Reminders, Summary, Backup and Help. Each row says what it does in a line.
- **Presets:** only the times can be changed; the names and days (tomorrow, 3 days, next Monday) stay fixed. Reset to defaults puts back the PRD times. A new time applies to the next set aside; items already set aside keep their time.
- **Day starts at:** whole hours from midnight to 6 AM, default 4 AM.
- **Show before due and Reminder time:** the defaults for new recurring items and the time their reminders arrive (PRD 7, 8.6). Each item can still change its own Show before due.
- **Backup:** Settings shows the size of the data on the phone against 20 MB. Above 20 MB a warning says that Android stops backing up an app over 25 MB without saying so. It doesn't suggest deleting things, because deleted items are kept (soft delete) and wouldn't free space; manual export is Phase 2.
- **Log retention has no setting.** Raw events are kept for 12 months and then compacted into daily totals (PRD 9, E-004), with nothing to configure.
- **About:** the version, where the data lives, what's coming in Phase 2 and Phase 3 in plain words, and the open-source licences. The privacy policy link comes in M8 (AT-122).
- **Send feedback:** opens the phone's email app with the feedback address and the subject "Sahai feedback (0.7.0)". The body is left empty, so nothing about the user's tasks goes in. Sahai sends nothing itself, and the email app sends nothing until the user taps Send.
- **Largest font:** rows wrap rather than cutting text off, and at the largest sizes a row's value moves below its label.

### Due dates on one-off items (#87, E-019)

Frames 19 to 27, approved by the owner on 2026-11-20 as a separate step of M7 (plan 0009, steps 4a to 4d). Unless a frame says otherwise it is Monday, Nov 9, 2026, and the Reminder time is the default 9:00 AM.

| # | Frame | Shows | Acceptance tests |
|---|---|---|---|
| 19 | [New task, no due date](m7-polish/19-due-empty.png) | The optional Due date row on the form: "None. Optional, for a real deadline", with Add | AT-128 |
| 20 | [Pick a due date](m7-polish/20-due-picker.png) | The date picker; days before today are greyed and can't be picked | AT-128 |
| 21 | [Due date set](m7-polish/21-due-set.png) | Fri, Nov 20 with ✕ to clear it; Remind me "3 days before · Tue, Nov 17, 9:00 AM"; a tip about the follow-up on the day | AT-128, AT-130 |
| 22 | [Remind me choices](m7-polish/22-remind-choices.png) | The five choices with their dates; a choice already in the past is greyed | AT-130 |
| 23 | [Summary with due labels](m7-polish/23-due-summary.png) | Overdue, Due today and Due Nov 20 with a calendar mark; a bill keeps its repeat mark; an item without a due date has no label | AT-131 |
| 24 | [Explorer with due labels](m7-polish/24-due-explorer.png) | A project, task, subtask and stream item each with a due label; a locked subtask keeps its label | AT-128, AT-131 |
| 25 | [Reminders](m7-polish/25-due-reminders.png) | The early reminder on Nov 17, the one on the day on Nov 20, and several grouped into one | AT-129, AT-130 |
| 26 | [Reminder tap: item is hidden](m7-polish/26-due-hidden-sheet.png) | Why the item isn't on the Summary, with Mark done, Change due date and Open in tree | AT-129 |
| 27 | [Create from a capture, with a due date](m7-polish/27-due-capture.png) | The capture's Create form with Due date and Remind me | AT-132 |

AT-133 (the `due_changed` event) has no frame: it is about the log, not a screen.

#### Choices approved with these wireframes

Approved by the owner on 2026-11-20, along with the answers to the #87 questions. They change PRD behaviour, so they are recorded in `PRD_Edits.md` as E-019.

- **Which items:** anything that can be ticked off: projects, tasks, subtasks and one-off stream items. Domains and streams never get a due date.
- **Where it's set:** an optional Due date row on the create and edit forms and on the capture's Create form. ✕ clears it. Days before today are greyed in the picker.
- **Look:** the same label as bills: "Due Nov 20", "Due today", "3 days overdue", with the year when it isn't this year (#85). One-off due dates get a calendar mark; bills keep the repeat mark. Overdue is a label, not a status.
- **Remind me:** each item picks one: On the day (the default), 1 day before, 3 days before, 1 week before, or No reminder. A choice already in the past is greyed. Reminders arrive at the Reminder time setting.
- **Follow-up on the day:** an early reminder is followed by one on the due day if the item still isn't done. Nothing arrives once it's done.
- **Breaking through:** the reminder arrives even when the item is hidden by a set-aside area or by waiting its turn behind an earlier step, as a bill's does (AT-079). It is the only thing that breaks through: the item doesn't come onto the Summary because of its due date.
- **Reminder tap:** opens the item. If it's hidden, a sheet says why, with Mark done, Change due date and Open in tree. A locked item's sheet has no Mark done (E-007).
- **Completing:** removes the label and stops the reminders. Undo or Reopen brings both back.
- **Repeating stream items:** an item with Repeat on uses its schedule's Next due, not a separate due date. Stop repeating still clears the due date, so AT-080 is unchanged.
- **Logging:** setting, changing or clearing a due date, or changing Remind me, logs `due_changed` with the old and new dates and the reminder choice, never the item's text.
