# Acceptance tests

> **Placeholder.** The owner will add `Sahai_Acceptance_Tests_v1.xlsx` to this folder.

## What the sheet contains

Each acceptance test has:

- an **ID**: `AT-001`, `AT-002`, and so on
- a **milestone** (M1 to M8)
- the **PRD section** it checks

## How the IDs are used

- **Automated tests** that cover an acceptance test are named with its ID, e.g.
  `AT-034 waking subtask takes its place back`. That makes it easy to search the
  code for coverage of any acceptance test.
- **Bug-fix branches** can use the ID: `fix/at-034-wake-order`.
- **Pull requests** list the IDs they cover, and say which ones need manual checking on a real device.
- **Bug reports** include the ID of the failing test, if there is one.

The sheet is owned by the owner, like the PRD. Propose changes through an issue rather than editing it.
