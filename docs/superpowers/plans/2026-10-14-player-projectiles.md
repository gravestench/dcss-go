# Player projectile implementation plan

The approved Lua-first runtime boundary and
`../specs/2026-10-14-player-projectiles-design.md` govern this slice. Execute
the connected domain natively in the current isolated worktree, then commit
it as one category after integrated verification. The user's standing
instruction to proceed with recommended designs supplies the execution
choice for this goal. Convert the whole projectile rule path directly into
Lua in this pass. Do not add a compatibility adapter, parallel Go handler,
per-missile host callback, or temporary fallback. The branch may fail to
compile while the connected changes are underway.

## 1. Specify observable behavior first

Add game and terminal tests for a Human Fighter firing each launcher family,
throwing a carried stack, selecting and canceling a target, hitting or missing
an early Dungeon monster, killing one, landing or destroying a projectile,
and restoring the state. Add focused source-roll tests for attack delay,
accuracy, damage, darts, nets, and brands. Observe the tests fail for missing
behavior before changing the implementation.

## 2. Complete the generic command and grid seam

Add a target cell and selected item to the ranged command and intent. Expose
a grid ray from the level service to Lua only if the existing clear-path
query cannot express first collision and landing. Keep this service unaware
of DCSS item IDs, effects, and actors beyond occupancy. Extend the existing
terminal screen model with the fire/throw item and target states.

## 3. Implement one Lua projectile action

Put eligibility, timing, trajectory, hit, damage, effect, stack, landing,
practice, and message policies in focused Lua modules. Register one player
ranged system in the existing attack phase. Replace any old rule implementation
in the same pass instead of calling it through a bridge. Keep the monster shot
path on the same reusable roll and collision primitives where the rules
coincide; do not preserve duplicate mechanics solely for compatibility.

## 4. Integrate lifecycle and presentation

Route `f` and `F` through the command, aim view, and Lua presentation policy.
Keep all no-time checks ahead of scheduling. Preserve deterministic RNG
streams and atomic item changes. Extend save validation only for new
authoritative component state; use existing item and position records when
possible. Update help and the port inventory to state exact coverage.

## 5. Verify and integrate

Run focused behavior tests while implementing, then the complete Go suite,
`go vet ./...`, `go build ./...`, `sh scripts/check-go-style.sh`,
`python3 scripts/export-catalog-lua.py --check`, and `git diff --check` once
the whole domain is assembled. Review the branch, commit the contiguous
player projectile category, fast-forward local Go `main`, and rerun the full
suite from merged `main`.
