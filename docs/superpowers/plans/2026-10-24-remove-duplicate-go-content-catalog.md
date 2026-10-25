# Remove the duplicate Go content catalog

The committed Lua definitions under `internal/modfs/builtin/content` are the
runtime authority. The old `internal/content` package embeds generated JSON
that production does not import; only tests still read it. Keep the useful
coverage while removing this second source of truth.

## Implementation

1. Expose a read-only definition lookup on `script.Runtime` that returns a
   detached plain Go value from the effective Lua catalog. Exercise it with
   an overlay test, including a missing ID.
2. Make test fixtures in `internal/game`, `internal/script`, and
   `internal/modfs` read effective Lua definitions. Retain checks for species
   and job count, menu coverage, monster gear counts and references, spell
   scope counts, and early brand effect files. Keep existing game behavior
   tests and mod override tests.
3. Delete `internal/content` and its generated JSON files. Update all job
   comments and the modding guide to reference the Lua contracts. Update the
   port inventory to describe the single authoritative content path.
4. Run the affected package tests, `go test ./...`, build the game and wizard,
   and the repository style gate once for the category. Fix any regressions,
   then commit and push this one category to `main`.

No runtime content semantics should change. The game must still launch from
committed embedded Lua with no C++ checkout or generated JSON dependency.
