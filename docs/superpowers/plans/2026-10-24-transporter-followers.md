# Transporter Follower Parity Plan

**Goal:** Use one source-style connected follower wave for stairs and
transporters while preserving mode-specific body rules and transfer timing.

**Spec:** `docs/superpowers/specs/2026-10-24-transporter-followers-design.md`

## Tasks

- [x] Add failing Lua cases for transporter energy, status, target, body,
  chain, radius, order, and cap behavior using the production ECS fixture.
- [x] Extract the connected wave from the stair coordinator into a focused
  owner and put travel-mode eligibility beside the existing body checks.
- [x] Have ordinary stairs mark the selected wave and transporters move
  the selected wave after player passage. Keep occupancy search specific
  to the destination type; do not add a second actor registry.
- [x] Run focused stair/transporter Lua and Go tests, build, style and
  whitespace checks. Review the diff, commit the category, and push main.

The focused Lua and Go travel tests and `go build ./...` passed. An optional
full `internal/game` run produced no result after several minutes, so it
was stopped in favor of the focused integration checks.
