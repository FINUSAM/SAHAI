# M1 Foundations

- **Status:** In progress
- **Approved by:** FINUSAM on 2026-10-30
- **Branches / PRs:** PR 1 `feat/m1-foundation` → `dev`; PR 2 `feat/m1-explorer` → `dev`
- **PRD sections:** 3, 4, 8.4, 10 (plus E-003, E-006, E-007)
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

3. [ ] Create the Flutter project (`com.finusam.sahai`, Android only, minSdk 26, target/compile 36, version 0.1.0+1, Flutter 3.47.3 pinned)
4. [ ] Add packages at exact versions (re-checked on pub.dev)
5. [ ] Release manifest guard removing `INTERNET` and `ACCESS_NETWORK_STATE`
6. [ ] CI workflow: format, analyze, test, release APK build, network-permission check, `DateTime.now()` check
7. [ ] `tool/`: test-matrix generator and AT coverage script
8. [ ] Database schema v1 (six PRD tables + `deleted_by_event`, `snooze_overrides_show`), indexes, WAL, schema snapshot, migration test harness, pre-migration copy
9. [ ] Engine: tree model, valid-children rule, current-task and lock rule, injected clock
10. [ ] Actions (one transaction + log event each): create, edit, reorder, move, cascade delete with Undo, mark done / reopen (basic)
11. [ ] Unit tests named by AT ID (plus E-003, E-007); all green locally and in CI
12. [ ] Update `README.md` and `CHANGELOG.md`; commit, push, open PR 1 with `gh`
13. [ ] After CI has run once: make CI a required check on `dev` and `main` (owner approved 2026-10-30)

**PR 2: Explorer** (`feat/m1-explorer`, after PR 1 merges)

14. [ ] App shell: bottom tabs and Settings gear; other tabs show placeholders
15. [ ] Explorer screens per frames 2–9
16. [ ] Accessibility basics: labels, 48 dp targets, up/down alternative to drag
17. [ ] Widget tests (AT-002, AT-003, AT-006, AT-007, AT-008) and integration tests (AT-001, AT-004, AT-005)
18. [ ] Release build on the owner's phone and a real-device checklist (AT-011, AT-012, build your real tree)
19. [ ] Update `README.md`, `CHANGELOG.md` (0.1.0), matrix and this plan; open PR 2 with `gh`

**Release** (owner)

20. [ ] When all M1 Must tests pass on the phone: PR `dev` → `main` (merge commit), tag `v0.1.0`

## Changes to the plan

- 2026-10-30: Step 13 added when branch protection was set up (approved by FINUSAM).

## Notes for whoever picks this up

- `gh` is installed at `C:\Program Files\GitHub CLI\gh.exe` and signed in as FINUSAM.
