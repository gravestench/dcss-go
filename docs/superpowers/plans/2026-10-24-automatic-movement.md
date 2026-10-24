# Automatic Movement Implementation Plan

**Spec:** `docs/superpowers/specs/2026-10-24-automatic-movement-design.md`

- [x] Add Lua `_test.lua` cases for run, rest, long wait, and explore using
  the same view schema that the terminal passes to production.
- [x] Expose observed feature IDs and monster threat in the game view;
  register Lua key routes and the automatic-movement decision policy.
- [x] Add one temporary terminal automation owner and Tea tick. Every
  step calls `Game.Step`; any user key interrupts before another tick.
- [x] Test Lua rules and terminal integration together, build, inspect
  style and diff, commit once, and push `main`.
