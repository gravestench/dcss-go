# Ordinary Swamp vault implementation

**Goal:** Port all 107 source ordinary Swamp definitions as one category.

**Spec:** `docs/superpowers/specs/2026-10-21-ordinary-swamp-vaults-design.md`

## Tasks

- [x] Add a failing production-catalog test for 107 ordinary Swamp maps,
  source-weighted candidates, and named hook execution.
- [x] Split all 107 source definitions into individually named DES files;
  audit MAP bytes, static directives, inherited depth, and constant
  `swamp_ruins` declarations against the pinned source.
- [x] Port scripted choices and controllers to focused Lua handlers; keep
  catalog-time facts static and preserve pending typed source effects.
- [x] Implement the Lady of the Lake's saved movement trigger and cover it
  through source-backed Lua and Go gameplay tests.
- [x] Add a sparse mod-added Swamp map and handler; document the extension
  path and remaining effect gaps in the modding guide and port inventory.
- [x] Run source audit, focused generation/travel/save tests, Go compilation,
  and changed-file style checks; review once, commit to main, and push.
