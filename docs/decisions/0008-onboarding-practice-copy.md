# 0008: The onboarding practice runs the real screens on a temporary in-memory copy

- **Status:** Accepted
- **Date:** 2026-11-20
- **Decided by:** FINUSAM, 2026-11-20 (approved in the M7 PR 1 checklist, before any code)
- **Related:** M7; PRD 8.1, 9; AT-106; M7 frames 6 to 8 in [`docs/design/m7-polish/`](../design/m7-polish/); [plan 0009](../plans/0009-m7-polish.md) step 9b; #54

## Context

Onboarding step 4 lets the user practise the three moves on what they just made: tick off with Undo, set aside with a preset, and Wake now on the Set-Aside page (PRD 8.1). AT-106 says the practice changes nothing, and the approved wireframe choice is stricter: nothing in it is written to the database or the activity log, not even a `surfaced` event, so the Phase 2 planner never learns from practice.

The practice should use the real Summary and Set-Aside screens, so the user sees exactly what they will use later. But those screens read and write through the app's providers, which point at `sahai.sqlite`. Every action writes in a transaction with its event.

## Decision

The practice opens a second `SahaiDatabase` on `NativeDatabase.memory()`. It copies in only the rows onboarding just made (the area holding the project, the project, its task and the two subtasks), plus the user's settings, so preset times and the day start match.

The real Summary and Set-Aside screens then run inside their own `ProviderContainer`. Its overrides point the database at the copy, switch reminders off, and reuse the clock. Because the container has no parent, every provider in it, such as the tree, the Summary and the actions, reads and writes the copy.

When the practice ends, by Wake now, Skip or Back, the container is disposed and the copy is closed and thrown away. Nothing is deleted from the real database, because nothing was written to it.

A `PracticeScope` widget marks the practice. Inside it, the Settings button is hidden and Open in tree shows a short message instead, since both would leave the copy. The scope also places the coach box at the top of the two screens.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Write to the real database, then undo or delete afterwards | No second database | Leaves events in the log, or needs hard deletes, which the log rules forbid; a crash midway leaves practice data behind | Breaks AT-106 and the approved "writes nothing" choice |
| Practice screens drawn by hand, with fake cards | Nothing to isolate | Not the real screens; two copies of the card and Set-Aside layouts to keep in step | The user should practise on what they'll use |
| A nested `ProviderScope` overriding the database | Less code | Riverpod reads providers not declared as scoped from the parent, so the tree and Summary would still use the real database | Unsafe without marking every provider as scoped |
| A second router for the practice | Navigation stays inside the practice | Two routers compete for Android's back button | More moving parts than hiding two exits |

No new package: `drift/native.dart` is part of drift, already used by the tests and, underneath, by `drift_flutter`.

## Consequences

- The practice can never write to `sahai.sqlite`; a test checks the real nodes and events are unchanged after a full practice run.
- The copy holds only what onboarding made, so the practice Summary shows just the new project, even on a replay with other data.
- Screens used in the practice must not navigate away without checking `PracticeScope`. Today that's the Settings button and Open in tree on the Summary and Set-Aside pages. A new exit added to those screens later needs the same check.
- Reversing it means removing `PracticeView` and `PracticeScope`; nothing is stored.
