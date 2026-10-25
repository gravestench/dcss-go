# Reserved Level IDs Implementation Plan

> **For agentic workers:** Execute natively. The user approved the
> recommended slice workflow and one commit per contiguous category.

**Goal:** Remove the Abyss/Slime floor ID collision across generation,
travel, and saves.

**Spec:** `docs/superpowers/specs/2026-10-24-reserved-level-ids-design.md`

## Tasks

- [x] Add a failing Lua test enumerating active branch floor IDs and the
  two permanent Abyss IDs.
- [x] Move the special IDs in their Lua and Go owners; guard branch floor
  allocation from entering the reserved range.
- [x] Replace old literal IDs in tests with owner constants and verify
  Slime entry, Abyss paths, save/restore, build, and style. The longer
  Jiyva-to-Slime journey now reaches Slime:5 and exposes a separate
  player XP/level inconsistency during its final restore.
- [x] Commit this complete ID namespace category and push `main`.
