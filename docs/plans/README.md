# Plans: saved checklists

Before changing anything, a Claude Code session proposes a numbered checklist and waits for **"Proceed"** (see [`CLAUDE.md`](../../CLAUDE.md)). For work that spans **more than one session**, such as a milestone or a large feature, the approved checklist is saved here so anyone can pick it up later.

## When to save a plan

- The work will take more than one session, or more than one PR.
- Someone else (or a future session) may need to continue it.

Small, single-session changes don't need a saved plan. The checklist in the conversation and the PR description are enough.

## File naming

```
NNNN-short-name.md
```

- `NNNN` is the next free number: `0001`, `0002`, …
- Example: `0002-m2-core-loop.md`

## Format

```markdown
# M2 Core loop

- **Status:** In progress | Done | Abandoned
- **Approved by:** FINUSAM on 2026-11-02
- **Branch(es) / PRs:** feat/m2-summary-engine (#14)
- **PRD sections:** 4.1, 4.2
- **Acceptance tests:** AT-020 to AT-041

## Checklist

1. [x] Add clock abstraction
2. [ ] Summary engine
3. [ ] ...

## Changes to the plan

- 2026-11-04: Step 3 split in two because ... (approved by FINUSAM)

## Notes for whoever picks this up

- Not verified on a real device yet: AT-031, AT-033.
```

## Rules

- **Tick items as they're done**, in the same commit as the work.
- **The checklist can only change with approval.** Log the change and who approved it under "Changes to the plan".
- **Be honest in the notes.** Record anything untested, unverified or guessed.
- When the work is finished, set the status to **Done**. Don't delete plans: they're the history of how things were built.
