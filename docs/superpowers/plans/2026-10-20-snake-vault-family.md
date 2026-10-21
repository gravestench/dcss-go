# Snake Pit Vault Family Implementation Plan

**Goal:** Port all 76 non-finale Snake definitions and make authored Lair
entrances live.

**Spec:** `docs/superpowers/specs/2026-10-20-snake-vault-family-design.md`

**Architecture:** Source DES files remain authoritative. The effective
vault catalog supplies ordinary Snake maps; the shared branch-entry owner
places a source entrance map at the scheduled Lair stair. Named Lua modules
implement the eight source inline-script sites.

**Technology:** Go, Lua, DES, layered modfs, Akara ECS.

## Global constraints

- Keep every source MAP row and non-script gameplay directive in order.
- Add `DEPTH: Snake` only where source file-level default depth supplied it.
- Keep scripts in named, commented Lua files and original script text as
  commented provenance at its DES position.
- Use stable IDs and deterministic sorted effective-file selection.
- Commit one coherent category on `main` and push `origin/main`.

## Review focus

1. `snake_entry` maps cannot enter ordinary Snake draws.
2. Source default depth cannot leak a Snake map into another branch.
3. The chosen entry's keyed `O` point owns the reciprocal stair.
4. All source script branches preserve their choices and draw order.
5. Snake:4 endings continue to own their whole floor.

### Task 1: Source DES and hooks

- [x] Write tests for effective counts, every map's placement, and script
  outcomes, watching the new coverage fail before adding definitions.
- [x] Add eight entry and 68 ordinary DES files with individual comments.
- [x] Port eight inline-script sites into named Lua handlers.
- [x] Compare MAP rows and directives with the pinned source.

### Task 2: Scheduled entry and mods

- [x] Extend the shared branch-entry owner with Snake source feature data.
- [x] Use the placed keyed stair on the scheduled Lair floor.
- [x] Test reciprocal travel, save/restore, retry, and sparse mod discovery.

### Task 3: Integrated verification

- [x] Run focused Lua and Go tests, compilation, and style checks.
- [x] Update modding guide and port inventory.
- [x] Review the complete category, commit, and push `origin/main`.
