# Technical plan

- **Status:** Done (awaiting PR merge into `dev` and owner review)
- **Approved by:** FINUSAM on 2026-10-30
- **Branch / PR:** `docs/tech-plan` → `dev`
- **PRD sections:** all (the plan covers v1 as a whole)
- **Acceptance tests:** all (AT-001 to AT-124, mapped in `docs/tech-plan/test-matrix.md`)

## Checklist

1. [x] Stash local uncommitted copies of `docs/PRD.md` and the xlsx (`git stash -u`)
2. [x] Switch to `dev` and fast-forward it to GitHub (`89741de`)
3. [x] Create branch `docs/tech-plan` from `dev`
4. [x] Save this checklist as `docs/plans/0002-technical-plan.md`
5. [x] Create `docs/PRD_Edits.md` with entries E-001 and E-002
6. [x] Rule change in `CLAUDE.md` and `CONTRIBUTING.md`: the PRD is read together with `PRD_Edits.md`, which wins where they differ; Claude adds entries only for owner-approved changes. Add `PRD_Edits.md` to the docs tables in `CLAUDE.md` and `README.md`
7. [x] Look up each proposed package on pub.dev (version, license, maintenance)
8. [x] Write `docs/tech-plan/README.md`, referencing E-001 and E-002 and listing open PRD questions
9. [x] Write `docs/tech-plan/test-matrix.md`: all 124 acceptance tests mapped to a test level
10. [x] Write decision records `0001` to `0005` (all **Proposed**) and update the decisions index
11. [x] Update `docs/tests/README.md`, `README.md` "Getting started" and `CHANGELOG.md`
12. [x] Push after each commit and give the owner the PR link into `dev`
13. [x] Report against this checklist
14. [x] Add E-003 to E-006 (owner answers to Q1–Q4) to `docs/PRD_Edits.md`
15. [x] Update the tech plan: §5 (`deleted_by_event`, cascade delete and undo, seventh table), §4.4 (Set-Aside listing for recurring items), §15 (Q1–Q4 answered)
16. [x] Update test matrix notes (AT-008, AT-009, AT-046, AT-047, AT-113) and add E-003, E-004, E-005 tests
17. [x] Update `CHANGELOG.md` and this plan
18. [x] Commit and push to the open PR branch
19. [x] Report back

## Changes to the plan

- 2026-10-30: Committing the PRD and test sheet was dropped. The owner pushed them to `dev` (PR #2).
- 2026-10-30: Added `docs/PRD_Edits.md` and the matching rule change, at the owner's request.
- 2026-10-30: Added steps 14–19 to record the owner's answers to Q1–Q4 as E-003 to E-006 (approved by FINUSAM).

## Notes for whoever picks this up

- Step 1: git reported no local changes, so no stash was created. The working folder was already clean.
- Owner answers recorded as PRD edits: E-001 (`completion_undone` event), E-002 (`surfaced` uses the wake time).
- `sqlite3_flutter_libs` turned out to be end-of-life; drift now gets SQLite from `sqlite3` 3.x. The plan reflects this.
- Q1–Q4 answered (E-003 to E-006). Still open for the owner: accepting decision records 0001–0005, and M1 wireframes (PRD 16 gate).
- E-005 needed one more `nodes` column, `snooze_overrides_show`, so Wake now / Change time can replace a bill's computed show time for one occurrence. It's recorded in the tech plan §4.4 and §5, not in PRD_Edits, because it's an implementation detail.
