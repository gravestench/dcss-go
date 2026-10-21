# Lair vault family implementation

**Goal:** Port all 116 source Lair definitions as one complete content
category, including entrances, ordinary maps, and endings.

**Spec:** `docs/superpowers/specs/2026-10-21-lair-vault-family-design.md`

## Tasks

- [x] Add production-catalog tests that fail while the 116 source maps and
  three Lair selection stages are absent.
- [x] Split source definitions into committed, individually named DES files;
  run a one-off source audit for MAP bytes, static directives, and original
  script positions. Do not commit the importer or audit script.
- [x] Port every executable source site into focused Lua handlers and shared
  source helpers. Preserve pending effects as typed level data.
- [x] Integrate Lair entry selection and keyed stairs with the saved branch
  schedule; integrate Lair:5 primary and paired small endings.
- [x] Add sparse mod-added entry, ordinary, and ending definitions; document
  extension paths and remaining gameplay gaps.
- [x] Run source audit, focused Lua placement and Go travel/save tests,
  compile all Go packages, inspect changed-file style, review the category,
  then commit and push it on `main`.
