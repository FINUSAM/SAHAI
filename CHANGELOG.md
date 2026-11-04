# Changelog

All notable changes to Sahai are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Each v1 milestone is released as a minor version (M1 = v0.1.0 through M8 = v0.8.0),
followed by v1.0.0 for the public release.

## [Unreleased]

### Added
- Approved M3 Set aside wireframes in `docs/design/m3-set-aside/` (14 frames) and the choices made
  with them; the M3 plan in `docs/plans/0005-m3-set-aside.md`.

## [0.2.0] - 2026-11-04 (M2 Core loop)

### Added
- M2 screens (PR 2 of M2): the Summary is the start screen, showing one card per project and
  stream in tree order with its type, path and sign-off or empty-project hint; a checkmark on
  each card with a 5-second "Done: …" Undo snackbar (also in the Explorer); a card sheet with
  path chips, notes, Mark done and Open in tree, which opens the Explorer at the item with its
  ancestors expanded and the row highlighted for a moment; the Explorer's Reopen line names the
  DONE ancestors it will reopen. Version 0.2.0+2.
- M2 engine (PR 1 of M2): the Summary visibility rules (PRD 6) as a pure Dart engine, with the
  card kinds, sign-off and empty-project hints, and `nextChangeAt` for M3; Undo after completing
  (`completion_undone`, E-001); `surfaced` events written in the same transaction as the change
  that caused them; schema v2 with the `summary_visible` table and the first generated migration
  test (v1 → v2); `tool/benchmark.dart` for the 10,000-item check.
- Approved M2 Summary wireframes in `docs/design/m2-summary/` (10 frames) and the choices made with them.

### Changed
- App icon: an S monogram in the brand colours (off-white on teal) as an adaptive icon with a
  themed-icon layer, replacing the Flutter logo. The app theme is now seeded with the brand teal
  instead of Material indigo. Brand files live in `docs/design/brand/`. Placeholder until the M8
  brand work.
- Auto Backup will include the database's `-wal` file as well as the main file, so a backup is
  complete even if the app was killed before checkpointing (tech plan §5, §8; decision 0002).
- PRD edits E-009 (the v1 home-screen widget opens a text-capture dialog) and E-010 (the Phase 2
  widget records voice; captures list transcriptions and AI proposals with Accept, Fix, Edit, Discard).

## [0.1.0] - 2026-10-30 (M1 Foundations)

### Added
- M1 Explorer: bottom tabs (Summary, Set-Aside and Capture show what is coming), a Settings
  gear, and the Explorer tree from the approved wireframes: add only valid child types, create
  and edit with notes, mark done and reopen, a lock on locked tasks, reorder with drag or arrows,
  move to another parent, and delete with a 5-second Undo. Works with TalkBack and large text.
- PRD edit E-008: adding or moving TODO work into a DONE item reopens it.
- Widget tests for the Explorer, and `integration_test/` to run them on a phone.
- M1 foundation: Flutter Android project (`com.finusam.sahai`, Android 8.0+, target API 36)
  with pinned packages; database schema v1 with a pre-migration backup; tree rules for
  node types and locked tasks; node actions (create, edit, reorder, move, delete with
  undo, mark done, reopen) that each write one activity log event; CI with a check that
  the release APK has no network permissions; test matrix and AT coverage tools.
- PRD (`docs/PRD.md`) and acceptance test sheet (`docs/tests/Sahai_Acceptance_Tests_v1.xlsx`).
- `docs/PRD_Edits.md` for owner-approved PRD changes: E-001 to E-006 (undo logging, surfaced time,
  cascade delete, log summaries table, bills on the Set-Aside page, English-only).
- Technical plan (`docs/tech-plan/README.md`) and acceptance test matrix.
- Decision records 0001–0005 (accepted 2026-10-30).
- Approved M1 Explorer wireframes in `docs/design/m1-explorer/`, and PRD edit E-007 (locked tasks
  can't be marked done in the Explorer).
- Development machine setup steps in `README.md`.
- Repository foundations: `CLAUDE.md` working rules, `README.md`, `CONTRIBUTING.md`
  (git workflow and definition of done), and this changelog.
- `docs/` structure: PRD and acceptance test placeholders, plans, design,
  decision records (with template) and technical plan.
- GitHub pull request template, issue templates (bug report, change request,
  PRD question) and `CODEOWNERS`.
- `.gitignore`, `.gitattributes`, `.editorconfig` and a proprietary `LICENSE`.

### Removed
- Unused Vite/React starter files from the initial commit.
