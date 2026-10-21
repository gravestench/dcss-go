# Depths Entrance Family Implementation Plan

**Goal:** Make every source Depths entrance map a live D:15 gate.

**Spec:** `docs/superpowers/specs/2026-10-21-depths-entry-family-design.md`

## Tasks

- [x] Pin the eight-map source boundary with a failing Lua catalog test.
- [x] Commit one DES definition per source NAME; port the shared static
  setup and the one named feature hook.
- [x] Audit every MAP row, retained directive, and original script site
  against the pinned source with a tool kept outside this repository.
- [x] Connect the source family to branch-entry selection and preserve its
  keyed D:15 stair through reciprocal travel and save/restore.
- [x] Add a sparse mod candidate and document the Depths entry convention.
- [x] Run the focused Lua and Go gate, compile all Go packages, check style,
  review the category, commit it once on `main`, and push to the fork.
