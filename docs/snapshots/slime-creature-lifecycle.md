# Slime creature lifecycle text snapshots

These maps show the focused production-Lua rule test's sparse floor. Each
symbol is one cell. The test uses the actual ECS position, health, and blob
schemas; its small grid fixture supplies terrain and occupancy.

## Division near the player

Before (parent size 3, HP 135/180):

```text
 y=19  ...
 y=20  .S@
 y=21  ...
        29 30 31
```

After (parent size 2, HP 90/120; child size 1, HP 45/60):

```text
 y=19  ...
 y=20  .S@
 y=21  ..s
        29 30 31
```

`S` is the parent, `s` the new ECS actor, and `@` the visible foe. The
source action becomes WAIT after division. The child cannot act during the
same scheduled decision.

## Combination at a blocked approach

Before (source size 1, HP 20; target size 2, HP 40):

```text
 y=19  .#
 y=20  sS  -> target to the east
 y=21  .#
        50 51
```

After (survivor size 3, HP 60):

```text
 y=19  .#
 y=20  .S
 y=21  .#
        50 51
```

The two blocked diagonal cells leave the occupied square as the only
shorter route. The source entity is dismissed without death rewards; the
survivor receives its HP, blob count, weighted enchantment duration, and
Arena Duel lineage.
