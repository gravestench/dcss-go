# Ball python constriction implementation plan

**Goal:** Make source ball pythons playable on generated D:1–2 with their
second grab attack and persistent constriction behavior.

**Architecture:** The catalog holds immutable monster data. One optional
Akara component on the player holds the live grip link and escape attempts.
Pure combat and escape rules take projections; ordered systems apply attack,
damage, release, and state changes. Terrain remains a dense level grid.

**Source:** Pinned C++ commit
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f` and the adjacent design
spec.

**Style:** Keep Go lines at most 120 columns, prefer 80, separate logical
groups with blank lines, and expand multi-field literals.

## Tasks

1. Add failing source-backed tests for the committed ball-python definition,
   rolled HP, XP, and generated D:1–2 population. Add a validated profile
   and generated-scenario eligibility; preserve the fixed roster.
2. Add failing pure combat tests for the second `AT_CONSTRICT`/`AF_CRUSH`
   attack. Reuse ordinary hit, dodge, and shield phases while skipping
   direct damage and AC rolls for the grab. Keep bite roll order unchanged.
3. Add a player `Constricted` component and failing integration tests for
   grab, immediate post-action damage, later damage, EV -3, and the visible
   `Constr` status. Inject only the required component stores and RNG into
   the combat and constriction systems.
4. Add failing movement tests for source escape dice, failed-attempt time
   spending, attempt accumulation, successful release and five-point
   constrictor energy penalty. Ensure the grip ends on death or separation.
5. Persist and validate the component in Go saves. Test deterministic
   continuation and rejection of dead, distant, wrong-kind, or dangling
   constrictor references. Update the port inventory and ECS roadmap.
6. Run `go test ./...`, `go vet ./...`, `go build ./...`,
   `sh scripts/check-go-style.sh`, and `git diff --check`. Obtain a read-only
   review, fix important findings, commit this category once, and
   fast-forward local Go `main` under the standing integration preference.
