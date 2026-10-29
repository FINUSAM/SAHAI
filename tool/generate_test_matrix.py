"""Regenerates docs/tech-plan/test-matrix.md from the acceptance test sheet.

Run from the repo root whenever the sheet changes:

    python tool/generate_test_matrix.py

Needs Python 3 and openpyxl (pip install openpyxl). The levels and notes for
each test live in the L table below; a new test ID in the sheet must be added
there too, or the script stops with an error.
"""
import sys
import openpyxl

sys.stdout.reconfigure(encoding='utf-8')
src = sys.argv[1] if len(sys.argv) > 1 else 'docs/tests/Sahai_Acceptance_Tests_v1.xlsx'
out = sys.argv[2] if len(sys.argv) > 2 else 'docs/tech-plan/test-matrix.md'
L = {  # id: (levels, note)
1:("U, I","Repository create per type; restart persistence on device"),
2:("U, W","Allowed-children rule in engine; add menu per node"),
3:("W","No checkmark / Mark done on domain and stream"),
4:("U, I","Reorder action; order survives restart"),
5:("U, I","Soft order for subtasks and stream items; survives restart"),
6:("U, W","Move action validates parent type"),
7:("U, W","Lock rule in engine; lock replaces the checkmark (E-007)"),
8:("U, W","Cascade delete + undo token (E-003); snackbar Undo"),
9:("U","Every row under it flagged is_deleted (E-003); hidden everywhere"),
10:("U","UUID format; updated_at UTC and changes on edit"),
11:("CI, D","CI permission check on release APK; owner checks app info"),
12:("U, D","Generated migration tests from every schema; pre-migration copy; install-over on device"),
13:("U, W",""),14:("U, W",""),15:("U, W",""),16:("U, W","Task stays TODO, shown for sign-off"),
17:("U, W",""),18:("U",""),19:("U, W","Empty-project prompt card"),20:("U, W",""),21:("U",""),
22:("U, W",""),23:("U","Property-style test over random action sequences"),24:("U",""),
25:("U, W","Also checks completion_undone (E-001)"),26:("W","Fake timer advances 5 s"),
27:("U, W","Ancestor reopen in one transaction"),28:("U","Later task keeps progress"),
29:("W","Path sheet and Open in tree route"),30:("U",""),31:("U","Plus E-002 wake-time test"),32:("U",""),
33:("U, W",""),34:("U, W","Fake clock passes 5 PM; nextChangeAt timer fires"),35:("U",""),
36:("W","Scope dropdown per card type"),37:("U",""),38:("U",""),39:("U, W","Set-Aside page lists Freelance"),
40:("U",""),41:("U, W",""),42:("U","Fake clock: Tue Nov 3, 3 PM"),43:("U","Fake clock: Wed Nov 4, 1:30 AM"),
44:("U, W",""),45:("W","Picker blocks past times"),46:("U, W","Includes recurring items waiting for their show date (E-005)"),47:("U","Also applies to waiting recurring items (E-005)"),48:("U, W",""),49:("U, W",""),
50:("U, D","Planner groups same-time wakes; app-closed delivery on device"),
51:("U, D","Named notification; tap opens item (deep link)"),
52:("U, D",""),53:("U, D","Planner skips remind_on_wake = false"),
54:("U, D","Planner skips items hidden by ancestor"),
55:("W, D","Permission requested on first set aside (fake permission service); real prompt on Android 13+"),
56:("U, D",""),57:("D","Phone restart"),58:("D","Exact alarm permission and timing"),
59:("U",""),60:("U",""),
61:("U","Fake clock: Nov 1 -> Nov 2 at day start"),62:("U, W","Due label"),63:("U, W",""),64:("U",""),
65:("U",""),66:("U",""),67:("U",""),68:("U",""),69:("U",""),70:("U, W","Also checks completion_undone (E-001)"),
71:("U, W",""),72:("U",""),73:("U","Nov 30 and Feb 28, 2027"),74:("U",""),75:("U",""),76:("U",""),
77:("U, W",""),78:("U, D","Planner uses reminder time, not day start"),79:("U, D","Due reminder ignores set-aside ancestors"),
80:("U",""),81:("U, D","Time-zone switch in-process; real switch on device"),82:("U",""),
83:("U, W",""),84:("U, W",""),85:("U",""),86:("U",""),87:("U, W",""),88:("U, W",""),89:("U",""),
90:("U",""),91:("U",""),92:("U","Slots never touch sort_order"),93:("I","Arrangement survives restart"),94:("U",""),
95:("U, W, D","Airplane mode on device"),96:("U, W",""),97:("U, I","Edit survives restart"),98:("W",""),
99:("D","Home-screen widget"),100:("D","Share sheet from Chrome / WhatsApp"),101:("U, W",""),102:("W",""),
103:("W",""),104:("U",""),
105:("W, I",""),106:("U, W","Practice step leaves no changes"),107:("W",""),108:("W",""),109:("U, W",""),
110:("U","Fake clock 3:30 AM, day start 3 AM"),111:("D","adb bmgr backup, reinstall, restore"),
112:("U, W","Fake database size"),113:("U","Compaction into event_daily_summaries (E-004)"),
114:("U, D","Engine benchmark on dev machine from M2; profile build on mid-range phone"),
115:("D","Every feature in airplane mode"),116:("W, D","Semantics labels and button alternatives; TalkBack pass on device"),
117:("W, D","Largest text scale on every screen"),118:("U, D",""),119:("U","Transaction rollback test"),
120:("W, D","Fake platform channel; real email app on device"),
121:("D","Play testing track"),122:("D","Play Console and About screen"),123:("D","Data safety form review"),124:("D","Launcher and store listing"),
}
ws = openpyxl.load_workbook(src, data_only=True)['Tests']
rows = [r for r in ws.iter_rows(min_row=2, values_only=True) if r[0]]
missing = [r[0] for r in rows if int(r[0][3:]) not in L]
assert not missing, f'Add levels for {missing} to L'
names = {"M1":"Foundations","M2":"Core loop","M3":"Set aside","M4":"Recurring items","M5":"Groups and order","M6":"Capture","M7":"Polish and safety","M8":"Release prep"}
o = []
o.append("# Acceptance test matrix\n")
o.append("Maps every acceptance test in [`Sahai_Acceptance_Tests_v1.xlsx`](../tests/Sahai_Acceptance_Tests_v1.xlsx) to the automated test levels that will cover it, plus any check that needs a real device. Generated from the sheet on 2026-10-30. If the sheet changes, this file is updated in the same PR.\n")
o.append("## Levels\n")
o.append("| Code | Level | Runs |\n|---|---|---|")
o.append("| **U** | Unit test: engine, actions, repositories (in-memory SQLite), planner, migrations | Every PR (CI) |")
o.append("| **W** | Widget test: one screen with fake providers | Every PR (CI) |")
o.append("| **I** | Integration test (`integration_test`) on an emulator or phone | Before a milestone merges into `main` |")
o.append("| **CI** | Automated check in the CI pipeline (not a Dart test) | Every PR |")
o.append("| **D** | Manual check on a real device, listed in the PR | Per PR and before release |\n")
o.append("Every automated test that covers an acceptance test is named with its ID, e.g. `AT-034 waking subtask takes its place back`. **D** means some part of the test can only be confirmed on a phone. The automated levels still cover the logic.\n")
cnt = {}
for r in rows:
    lv = L[int(r[0].split('-')[1])][0]
    for k in [x.strip() for x in lv.split(',')]:
        cnt[k] = cnt.get(k,0)+1
o.append("## Totals\n")
o.append(f"124 tests. Tests that include each level: U {cnt.get('U',0)} · W {cnt.get('W',0)} · I {cnt.get('I',0)} · CI {cnt.get('CI',0)} · D {cnt.get('D',0)}. Tests that need **only** a real device: {sum(1 for r in rows if L[int(r[0][3:])][0]=='D')}.\n")
o.append("## Extra tests from PRD edits\n")
o.append("| ID | Milestone | Level | Test |\n|---|---|---|---|")
o.append("| E-001 | M2 | U | Undo of a completion writes `completion_undone` linking the `completed` event; the restored card gets no new `surfaced` event |")
o.append("| E-001 | M4 | U | Undo of a recurring completion writes `completion_undone` with the restored due date |")
o.append("| E-002 | M3 | U | An item that wakes while the app is closed gets a `surfaced` event at its wake time, written at the next recompute |")
o.append("| E-003 | M1 | U | Undo of a project delete restores only rows flagged by that delete; a task deleted earlier on its own stays deleted |")
o.append("| E-004 | M7 | U | Compaction moves events older than 12 months into `event_daily_summaries` with correct counts, in one transaction |")
o.append("| E-005 | M4 | U, W | A paid bill is listed on the Set-Aside page until its show date; Wake now shows it with its real due label and leaves the schedule unchanged |")
o.append("| E-007 | M1 | U, W | A locked task offers no checkmark or Mark done action until the task before it is done |\n")
cur = None
for r in rows:
    tid, m, area, sec, scen, prio, by = r[0], r[1], r[2], r[3], r[4], r[8], r[9]
    if m != cur:
        cur = m
        o.append(f"\n## {m} {names[m]}\n")
        o.append("| ID | Scenario | PRD § | Priority | Checked by | Levels | Notes |\n|---|---|---|---|---|---|---|")
    lv, note = L[int(tid[3:])]
    o.append(f"| {tid} | {scen} | {sec} | {prio} | {by} | {lv} | {note} |")
open(out,'w',encoding='utf-8',newline='\n').write('\n'.join(o)+'\n')
print(cnt)
