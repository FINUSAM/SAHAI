# Changelog

All notable changes to Sahai are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Each v1 milestone is released as a minor version (M1 = v0.1.0 through M8 = v0.8.0),
followed by v1.0.0 for the public release.

## [Unreleased]

### Added
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
