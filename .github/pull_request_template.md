<!--
PR title must follow Conventional Commits (feat:, fix:, chore:, docs:, test:, refactor:).
It becomes the squash-merge commit message. Target branch: dev.
-->

## What and why

<!-- Plain-language summary of the change and the reason for it. -->

## Scope

- **Milestone:** <!-- e.g. M2 Core loop -->
- **PRD sections:** <!-- e.g. 4.1, 4.2 -->
- **Acceptance tests covered:** <!-- e.g. AT-020, AT-034 -->
- **Plan:** <!-- link to docs/plans/NNNN-....md if this is multi-session work, or n/a -->
- **Closes:** <!-- #issue, or n/a -->

## Manual checks on a real device

<!-- Acceptance tests (or parts of them) that can't be automated. List each with the device and Android version used, and the result. -->

| Test ID | Device / Android version | Result |
|---|---|---|
| | | |

## Checklist

- [ ] Milestone, PRD sections and acceptance test IDs are listed above
- [ ] Automated tests added (named with AT IDs where they cover one) and all tests pass
- [ ] Bug fix: a test that failed because of the bug was written first
- [ ] `flutter analyze` is clean and `dart format` makes no changes
- [ ] `README.md`, `CHANGELOG.md` and affected docs are updated
- [ ] Screenshots attached for UI changes (or n/a)
- [ ] No new dependencies or Android permissions, **or** they're listed here with the owner's approval:
  <!-- package / permission: why, license, maintenance status, pinned version, approved on (date) -->
- [ ] No network access, analytics, telemetry or logging of user task content added
- [ ] No secrets, keystores, signing files or `.env` files committed

## Screenshots

<!-- For UI changes: before / after. -->

## Not tested / known gaps

<!-- Be honest: anything untested, unverified, or a guess. -->
