# M1 Foundations

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-10-30
- **Branches / PRs:** PR 1 `feat/m1-foundation` → `dev`; PR 2 `feat/m1-explorer` → `dev`
- **PRD sections:** 3, 4, 8.4, 10 (plus E-003, E-006, E-007, E-008)
- **Acceptance tests:** AT-001 to AT-012
- **Wireframes:** [`docs/design/m1-explorer/`](../design/m1-explorer/)
- **Test devices:** OnePlus Nord 5 (OxygenOS 16 / Android 16), a Samsung phone (model TBD)

## Owner decisions for M1

- M1 is delivered in 2 PRs (rule change: at most 3 PRs per milestone).
- Basic **Mark done / Reopen** in the Explorer is included in M1, without snackbar Undo. Undo, ancestor-reopen rules and the Summary come in M2.
- Packages approved: `uuid` 4.6.0, `intl` 0.20.3, `flutter_lints` 6.0.0 (dev), plus those in decision records 0002–0004.
- No Android permissions in M1.

## Checklist

**Setup**

1. [x] Rule change in `CLAUDE.md` and `CONTRIBUTING.md`: at most 3 PRs per milestone; document branch protection
2. [x] Save this checklist

**PR 1: Foundation** (`feat/m1-foundation`)

3. [x] Create the Flutter project (`com.finusam.sahai`, Android only, minSdk 26, target/compile 36, version 0.1.0+1, Flutter 3.47.3 pinned)
4. [x] Add packages at exact versions (re-checked on pub.dev)
5. [x] Release manifest guard removing `INTERNET` and `ACCESS_NETWORK_STATE`
6. [x] CI workflow: format, analyze, test, release APK build, network-permission check, `DateTime.now()` check
7. [x] `tool/`: test-matrix generator and AT coverage script
8. [x] Database schema v1 (six PRD tables + `deleted_by_event`, `snooze_overrides_show`), indexes, WAL, schema snapshot, migration test harness, pre-migration copy
9. [x] Engine: tree model, valid-children rule, current-task and lock rule, injected clock
10. [x] Actions (one transaction + log event each): create, edit, reorder, move, cascade delete with Undo, mark done / reopen (basic)
11. [x] Unit tests named by AT ID (plus E-003, E-007); all green locally and in CI
12. [x] Update `README.md` and `CHANGELOG.md`; commit, push, open PR 1 with `gh`
13. [x] After CI has run once: make CI a required check on `dev` and `main` (owner approved 2026-10-30)

**PR 2: Explorer** (`feat/m1-explorer`, after PR 1 merges)

14. [x] App shell: bottom tabs and Settings gear; other tabs show placeholders
15. [x] Explorer screens per frames 2–9
16. [x] Accessibility basics: labels, 48 dp targets, up/down alternative to drag
17. [x] Widget tests (AT-002, AT-003, AT-006, AT-007, AT-008) and integration tests (AT-001, AT-004, AT-005)
18. [ ] Release build on the owner's phone and a real-device checklist (AT-011, AT-012, build your real tree)
19. [ ] Update `README.md`, `CHANGELOG.md` (0.1.0), matrix and this plan; open PR 2 with `gh`

**Release** (owner)

20. [ ] When all M1 Must tests pass on the phone: PR `dev` → `main` (merge commit), tag `v0.1.0`

## Changes to the plan

- 2026-10-30: Step 13 added when branch protection was set up (approved by FINUSAM).
- 2026-10-30: E-008 added before PR 2 (owner chose option b: adding or moving TODO work into a DONE item reopens it).
- 2026-10-30: AT-001, AT-004 and AT-005 restart flows also run as widget tests (closing and reopening a database file), so CI checks them; `integration_test/` reruns all the widget tests on a phone. Adds the Flutter SDK `integration_test` package (approved with item 17).
- 2026-10-30: First CI run failed because the `DateTime.now()` check matched a comment; the check now skips comment lines (approved by FINUSAM).

## Notes for whoever picks this up

- `gh` is installed at `C:\Program Files\GitHub CLI\gh.exe` and signed in as FINUSAM.
- Mark done is refused for a node with TODO children, so a DONE parent never holds a TODO child (PRD 7). Subtasks of a locked task can still be marked done; the PRD doesn't say otherwise.
- The AT coverage script counts an acceptance test as covered once any test names it. Since PR 2, AT-002, 003, 006, 007 and 008 have widget tests, and AT-001, 004 and 005 have widget tests that restart on a database file, which `integration_test/` also runs on a phone.
- No migration tests are generated yet: drift creates them once schema v2 exists. The upgrade path itself is tested with a bumped-version database (AT-012).
- Release APK built locally on 2026-10-30: 46 MB, and its only permission is Android's internal DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION.
- First green CI run on PR #7 (2026-10-30): 42 tests passed, release APK 48.5 MB, no network permissions. CI is now a required check on `dev` and `main` (not strict: a branch doesn't have to be up to date with `dev` before merging).
- PR 2 choices the wireframes leave open: the app opens on the Explorer until the Summary exists (M2); the tree starts collapsed after a restart; a new item opens with an "Add …" line; the Reorder screen saves on Done and Close discards; Mark done has no Undo snackbar in M1 (Undo after completing comes in M2).
- PRD 9 lists a `reordered` event, described with "position and group", which matches the Summary ordering of M5. Reordering in the Explorer doesn't log it yet. To confirm with the owner before M5.
- No phone was connected while building PR 2, so `flutter test integration_test` and the real-device checks (item 18) are for the owner.
