# Repository setup

- **Status:** Done (awaiting PR merge into `dev`)
- **Approved by:** FINUSAM on 2026-10-30
- **Branch / PR:** `chore/repo-setup` → `dev`
- **PRD sections:** n/a (repo foundations only)
- **Acceptance tests:** n/a

## Checklist

1. [x] Create branch `chore/repo-setup` from `dev`
2. [x] Commit A `chore: add repository housekeeping files`: `.gitignore`, `.gitattributes`, `.editorconfig`, `LICENSE`. Push.
3. [x] Commit B `docs: add CLAUDE.md, README, CONTRIBUTING and CHANGELOG` (feature → `dev` → `main` workflow). Push.
4. [x] Commit C `docs: add docs folder structure`: PRD placeholder, tests, plans (incl. this file), design, decisions + template, tech-plan. Push.
5. [x] Commit D `chore: add GitHub PR and issue templates and CODEOWNERS`. Push.
6. [x] Give the owner the link to open the PR `chore/repo-setup` → `dev`
7. [x] Report against this checklist

## Changes to the plan

- 2026-10-30: GitHub labels, milestones and branch protection were dropped from scope. The owner reports they're already set up.
- 2026-10-30: Workflow changed from "branches → `main`" to "branches → `dev` → `main`" at the owner's request.

## Notes for whoever picks this up

- `gh` (GitHub CLI) isn't installed on the setup machine, so the PR is opened manually.
- The repo is private on a GitHub Free personal account, where branch protection isn't enforced. The "no direct pushes to `main`/`dev`" rule relies on discipline unless the account is upgraded or the repo is made public.
- The issue templates apply the labels `type: bug`, `type: feature` and `prd-question`. If the existing labels are named differently, the templates need updating.
