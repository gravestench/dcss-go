# Eight-Direction Rat Contact and Pursuit

## Source and scope

At pinned C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, `coord.cc:11-25` treats diagonal neighbors as adjacent in grid distance. `mon-act.cc:509-535` sets movement direction from the sign of both target deltas; `mon-act.cc:591-669` then handles terrain and blocked movement. The Go fixed rat currently checks only horizontal and vertical steps, so it cannot bite a diagonally adjacent player or approach on a diagonal.

## Change

Keep the current fixed rat's simple, already-awake chase policy and existing actor scheduling. Given its current target (the player), try the sign of both coordinate deltas first, then horizontal and vertical alternatives if the diagonal is blocked. A target square containing the player produces melee intent; an unoccupied walkable square produces movement. An off-floor rat waits. No component or save change is needed. This is a source-shaped correction to local contact and step direction, not the full DCSS awareness, noise, or pathfinding system.

## Verification

Test diagonal melee, diagonal pursuit, blocked diagonal fallback, cardinal behavior, and off-floor wait. Run full Go tests, vet, build, and read-only branch review before merging into local Go main.
