# CLAUDE.md

Read at the start of every Claude Code session in this repo. These rules apply to every session, for every person.

## The project

**Sahai (GTD AI)** is an offline-first Android task manager built with Flutter. iOS comes later.

- Android application ID: `com.finusam.sahai`
- Owner: FINUSAM (founder and product owner). Only the owner approves changes to the PRD, these rules, dependencies and permissions.
- Status: pre-development. There is no Flutter project yet. Architecture and packages are decided in the technical plan (`docs/tech-plan/`), not ad hoc.

### Never break these

1. **v1 is fully offline.** There is no `INTERNET` permission and no network calls of any kind.
2. **No analytics or telemetry.** That includes crash reporting, ads and tracking SDKs.
3. **All data stays on the device.**

### Source of truth

| What | Where |
|---|---|
| Product requirements (PRD) | `docs/PRD.md`, owned by the owner. **Never edit it.** |
| Approved PRD changes not yet in the PRD | `docs/PRD_Edits.md`. Read together with the PRD; it wins where they differ |
| Acceptance tests (AT-001 onward, each tagged with milestone and PRD section) | `docs/tests/Sahai_Acceptance_Tests_v1.xlsx` |
| Technical plan | `docs/tech-plan/` |
| Saved checklists for multi-session work | `docs/plans/` |
| Decision records | `docs/decisions/` |
| Wireframes | `docs/design/` |
| Git workflow and definition of done | `CONTRIBUTING.md` |

Milestones: M1 Foundations, M2 Core loop, M3 Set aside, M4 Recurring items, M5 Groups and order, M6 Capture, M7 Polish and safety, M8 Release prep.

## Working rules

### Approval before action
- Before changing anything, explain in plain language what you'll do and why, as a **numbered checklist**. That covers creating or editing files, commands that change state, installing packages, committing, pushing and changing GitHub settings. Then **wait for the reply "Proceed"**.
- Reading files and running read-only commands (`git status`, `git log`, listing files) need no approval.
- Follow the approved checklist exactly and tick items off as you go. If anything needs to change, stop, explain what and why, and wait for a new "Proceed".
- When finished, report against the checklist: what's done, what isn't, and what you couldn't verify.
- For work spanning several sessions (such as a milestone), save the approved checklist in `docs/plans/` and keep it ticked (see `docs/plans/README.md`).
- **Destructive actions need explicit approval for that specific action**: deleting files or data, `git reset`, force pushes, rewriting history, deleting branches.

### Explain clearly
- Use plain language. Explain technical terms when you use them.
- Say honestly when something wasn't tested, doesn't work, or is a guess.

### Follow the PRD
- Before any change, read the relevant PRD section, any entries for it in `docs/PRD_Edits.md`, and its acceptance tests. Where `PRD_Edits.md` differs from the PRD, `PRD_Edits.md` wins.
- Never edit the PRD. If it's unclear, incomplete, or conflicts with the code, stop and ask, or open an issue labelled `prd-question`. Don't guess.
- Add an entry to `PRD_Edits.md` only for a change the owner has explicitly approved (for example, their answer to a PRD question). Never delete entries.

### Tests come with every change
- Every feature or fix includes automated tests: unit tests for logic, widget tests for screens, integration tests for key flows.
- Each acceptance test a change covers gets a matching automated test where possible, named with its ID, e.g. `AT-034 waking subtask takes its place back`. List tests that need a real device in the PR for manual checking.
- Bug fix: first write a test that fails because of the bug, then fix it.
- Code that depends on the date or time must take an injectable clock so tests can fake any date. Never read the system clock directly in logic.
- All tests must pass before committing. Never delete, skip or weaken a test to make it pass without the owner's approval.

### Code quality
- Official Dart and Flutter style. `flutter analyze` and `dart format` must be clean, with no new warnings.
- Small, focused changes: one feature or fix per PR.
- Comments explain *why*, not *what*. No `TODO` without a linked issue (`// TODO(#12): ...`).

### Security and privacy
- Never commit secrets, API keys, keystores, signing files or `.env` files.
- No new dependency or Android permission without the owner's approval. For each proposed package, state why it's needed, its license, and whether it's actively maintained. Pin its version.
- Never log the content of users' tasks or captures.
- Database changes go through versioned migrations that never destroy data.

### Keep docs up to date
- In the same PR as the change, update `README.md`, `CHANGELOG.md` and any affected docs.
- Record significant technical decisions in `docs/decisions/` using `0000-template.md`.
- Change these rules or this file only with the owner's approval.

### Git
- **Never commit directly to `main` or `dev`.** Work on a short-lived branch from `dev` (`feat/m2-summary-engine`, `fix/at-034-wake-order`, `chore/...`, `docs/...`), use Conventional Commits, and open a PR into `dev`. Only the owner merges `dev` into `main` for a release. Full workflow in `CONTRIBUTING.md`.
