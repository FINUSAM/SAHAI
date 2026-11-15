# 0006: Store "No group" as a fixed value in `nodes.group_id`

- **Status:** Accepted
- **Date:** 2026-11-08
- **Decided by:** FINUSAM, 2026-11-07 (E-013, with the M5 wireframes: a stop value, no schema change)
- **Related:** M5; PRD 8.2, 10; [E-013](../PRD_Edits.md#e-013-no-group-can-override-an-inherited-group), [E-014](../PRD_Edits.md#e-014-deleting-a-context-group); [tech plan 4.6](../tech-plan/README.md#46-summary-order-and-groups-prd-82-m5); #42

## Context

A node's group can follow its parent, name a group, or be "No group", which overrides an inherited group (E-013). `nodes.group_id` is one nullable text column, and null already means "follow the parent". The column has no foreign key. The database should stay at version 2 if it can, since every migration is a risk to the owner's data.

## Decision

- `nodes.group_id` holds one of three things: null (follow the parent), the text `none` ("No group"), or a group's UUID. A UUID can never be `none`.
- The engine stops at `none` and returns no group (`Tree.groupSourceOf`). A group id that is deleted or unknown counts as unset, and the search carries on up the tree (E-014).
- "No group" on a node with no group above it is stored as null, because there's nothing to override. That keeps one way to say "in the default list".
- The value is `noGroup` in `lib/engine/groups.dart`. Nothing else should write the text `none`.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| A new boolean column such as `no_group` | Self-explaining | Schema v3 and a migration for one flag; two columns that must agree | More risk for no gain |
| A built-in "No group" row in `context_groups` | A real id | It would show in lists, could be renamed or deleted, and has to exist on every install | More special cases than a fixed value |
| No override (an inheriting card can't leave its group) | Nothing to build | A card dragged to the default list jumps straight back | The owner chose the override (E-013) |

## Consequences

- No schema change: the database stays at version 2.
- Code that looks up a group by `nodes.group_id` must treat `none` as "No group", not as a missing group. `Tree.hasGroup` does this.
- Export and sync (Phase 2 and 3) must carry `none` as it is.
- To reverse: replace `none` with null in one update. Nodes that overrode a group would then follow their parent again.
