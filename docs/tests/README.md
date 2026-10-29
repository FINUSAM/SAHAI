# Acceptance tests

The acceptance test sheet is [`Sahai_Acceptance_Tests_v1.xlsx`](Sahai_Acceptance_Tests_v1.xlsx): 124 tests, AT-001 to AT-124. The **How to use** tab explains the columns, and the **Summary** tab tracks each milestone's progress.

## What the sheet contains

Each acceptance test has:

- an **ID**: `AT-001`, `AT-002`, and so on
- a **milestone** (M1 to M8)
- the **PRD section** it checks
- a **priority** (Must or Should) and who checks it (Founder or Developer)

The [test matrix](../tech-plan/test-matrix.md) maps each test to the automated tests and real-device checks that cover it.

## How the IDs are used

- **Automated tests** that cover an acceptance test are named with its ID, e.g.
  `AT-034 waking subtask takes its place back`. That makes it easy to search the
  code for coverage of any acceptance test.
- **Bug-fix branches** can use the ID: `fix/at-034-wake-order`.
- **Pull requests** list the IDs they cover, and say which ones need manual checking on a real device.
- **Bug reports** include the ID of the failing test, if there is one.

The sheet is owned by the owner, like the PRD. Propose changes through an issue rather than editing it. Approved changes to expected behaviour are recorded in [`PRD_Edits.md`](../PRD_Edits.md) with the tests they affect.
