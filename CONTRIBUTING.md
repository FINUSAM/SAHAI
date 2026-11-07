# Contributing to Sahai

This guide covers how work moves from an idea to a release. Claude Code sessions follow the same rules, which are set out in full in [`CLAUDE.md`](CLAUDE.md).

## Before you start

- Read the relevant section of the [PRD](docs/PRD.md), any entries for it in [`docs/PRD_Edits.md`](docs/PRD_Edits.md), and its acceptance tests in [`docs/tests/`](docs/tests/).
- `PRD_Edits.md` lists changes the owner has approved that aren't in the PRD text yet. Read the two together; where they differ, `PRD_Edits.md` wins.
- The PRD belongs to the owner. **Never edit it.** If it's unclear, incomplete or conflicts with the code, ask, or open an issue using the **PRD question** template (label `prd-question`). Don't guess. Once the owner answers, the answer is added to `PRD_Edits.md`.
- Check [`docs/plans/`](docs/plans/) for a saved checklist if you're continuing someone else's work.

## Never break these

1. v1 is fully offline. There is no `INTERNET` permission and no network calls.
2. No analytics, telemetry, crash reporting, ads or tracking SDKs.
3. All data stays on the device.

## Branches

```
feat/m2-summary-engine ─┐
fix/at-034-wake-order ──┼──► dev ──(release)──► main ──► tag v0.x.0
docs/... chore/... ─────┘
```

- **`main`** is always releasable. It changes only when the owner merges `dev` into it for a release. No direct pushes.
- **`dev`** is the integration branch and the repo's default branch. All work arrives through pull requests. No direct pushes.
- **Both are protected on GitHub:** changes only through a PR, no force pushes, no deletion, and the rules apply to admins too. Approvals are set to 0 because the owner's merge is the review (GitHub doesn't let an account approve its own PR). CI must pass before merging once CI exists.
- **Work branches** are short-lived, created from the latest `dev`, and deleted after merging. GitHub deletes the branch on GitHub automatically when its PR is merged (the repo's "Automatically delete head branches" setting); protected branches such as `dev` are never deleted this way:

| Prefix | Use for | Example |
|---|---|---|
| `feat/` | New features, named with the milestone | `feat/m2-summary-engine` |
| `fix/` | Bug fixes, named with the acceptance test or issue | `fix/at-034-wake-order` |
| `test/` | Tests only | `test/m3-set-aside-coverage` |
| `refactor/` | Restructuring with no behaviour change | `refactor/clock-injection` |
| `chore/` | Tooling, config, housekeeping | `chore/repo-setup` |
| `docs/` | Documentation only | `docs/tech-plan` |

Keep PRs focused: a milestone is delivered in **at most 3 PRs**, each leaving `dev` working with CI green. A bug fix outside a milestone is its own PR.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add daily summary engine
fix: restore subtask order after waking (AT-034)
test: cover recurring item edge cases
refactor: inject clock into scheduler
chore: update .gitignore
docs: add decision record for database choice
```

## Pull requests

- Open PRs **into `dev`**. Fill in the [PR template](.github/pull_request_template.md).
- Every PR names its **milestone**, the **PRD sections** and the **acceptance test IDs** it covers.
- Merge with **squash merge**. The PR title becomes the commit message, so it must follow Conventional Commits.
- After merging, GitHub deletes the branch on GitHub. Delete your local copy yourself: `git switch dev`, `git pull`, `git branch -d <branch>` (use `-D` for a squash-merged branch, because git can't tell its commits are in `dev`), then `git fetch --prune` to clear references to deleted branches.

## Definition of done

A change is done when all of these are true:

- [ ] Automated tests for the change are written and passing (unit tests for logic, widget tests for screens, integration tests for key flows).
- [ ] Each covered acceptance test has a matching automated test named with its ID where possible, e.g. `AT-034 waking subtask takes its place back`.
- [ ] The linked acceptance tests pass on a **real device**. Tests that can't be automated are listed in the PR for manual checking.
- [ ] `flutter analyze` is clean and `dart format` makes no changes. No new warnings.
- [ ] `README.md`, `CHANGELOG.md` and any affected docs are updated in the same PR.
- [ ] UI changes include screenshots.
- [ ] The owner approves.

## Testing rules

- **Bug fixes:** first write a test that fails because of the bug, then fix it.
- **Dates and times:** code that depends on the date or time takes an injectable clock, so tests can run as if it were any date.
- **Never** delete, skip or weaken a test to make it pass without the owner's approval.

## Security and privacy

- Never commit secrets, API keys, keystores, signing files or `.env` files. `.gitignore` covers the common ones, but check what you stage.
- No new dependency or Android permission without the owner's approval. For each proposed package, give the reason it's needed, its license and its maintenance status, and pin its version.
- Never log the content of users' tasks or captures.
- Database changes go through versioned migrations that never destroy data.

## Code style

- Official [Dart style](https://dart.dev/effective-dart/style) and Flutter conventions.
- Comments explain *why*, not *what*.
- No `TODO` without a linked issue: `// TODO(#12): handle leap years`.

## Decisions

Record significant technical decisions in [`docs/decisions/`](docs/decisions/), copying [`0000-template.md`](docs/decisions/0000-template.md).

## Tracking

Work is tracked on GitHub so the owner can see progress without reading the plans:

- **Milestones** mirror PRD 16, one per milestone (`M3 Set aside (v0.3.0)` and so on). Each milestone's page shows its open and closed issues and a percentage. A milestone is closed when its version is tagged.
- **Issues** are work packages, not single tasks: a milestone's wireframes and plan, each of its PRs, the owner's phone tests and release, and the close-out docs. Each issue lists the PRD sections and acceptance test IDs it covers, a task list that is ticked as work lands, and a "Done when".
- **Labels** say what kind of work it is (`type: feature`, `type: bug`, `type: chore`, `type: docs`, `type: design`, `type: release`, `type: test`) and who acts: `owner-action` marks things only the owner can do (approvals, phone tests, tagging, Play Console), `prd-question` marks a PRD question for the owner, `blocked` marks waiting.
- **Every PR links its issue** with `Closes #N` in the description, so merging into `dev` closes the issue. GitHub only acts on `Closes` for the default branch, so a closed issue means merged, not yet released. A PR that delivers part of an issue says `Part of #N` and ticks the tasks it covered.
- **Bugs** found on the phone are opened with the bug report template, named with the acceptance test if there is one, and put in the milestone they affect.
- The saved checklists in `docs/plans/` stay the detailed record for a milestone; the issues are the overview.

## Releases

The owner releases at the end of each milestone:

1. Make sure `dev` meets the definition of done for the milestone.
2. In `CHANGELOG.md`, move the "Unreleased" entries under the new version and date.
3. Open a PR from `dev` into `main`, titled e.g. `chore: release v0.2.0 (M2 Core loop)`. Merge it with a **merge commit**, not a squash, so `dev` and `main` keep a shared history.
4. Tag the merge commit on `main` and push the tag:

| Milestone | Tag |
|---|---|
| M1 Foundations | v0.1.0 |
| M2 Core loop | v0.2.0 |
| M3 Set aside | v0.3.0 |
| M4 Recurring items | v0.4.0 |
| M5 Groups and order | v0.5.0 |
| M6 Capture | v0.6.0 |
| M7 Polish and safety | v0.7.0 |
| M8 Release prep | v0.8.0 |
| Public release | v1.0.0 |

5. Close the release issue and the milestone by hand. A release PR goes into `main`, so `Closes` does nothing there.

## Working with Claude Code

Claude Code proposes a numbered checklist before changing anything and waits for **"Proceed"**. Work that spans several sessions has its checklist saved in [`docs/plans/`](docs/plans/). Destructive actions (deleting files, `git reset`, force pushes, rewriting history, deleting branches) always need separate, explicit approval.
