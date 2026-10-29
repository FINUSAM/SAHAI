# Technical plan

- **Status:** In progress
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
11. [ ] Update `docs/tests/README.md`, `README.md` "Getting started" and `CHANGELOG.md`
12. [ ] Push after each commit and give the owner the PR link into `dev`
13. [ ] Report against this checklist

## Changes to the plan

- 2026-10-30: Committing the PRD and test sheet was dropped. The owner pushed them to `dev` (PR #2).
- 2026-10-30: Added `docs/PRD_Edits.md` and the matching rule change, at the owner's request.

## Notes for whoever picks this up

- Step 1: git reported no local changes, so no stash was created. The working folder was already clean.
- Owner answers recorded as PRD edits: E-001 (`completion_undone` event), E-002 (`surfaced` uses the wake time).
