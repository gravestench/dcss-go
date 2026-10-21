# Ordinary Shoals vault implementation

**Goal:** Port all 74 source ordinary Shoals definitions as one category.

**Spec:** `docs/superpowers/specs/2026-10-21-shoals-vaults-design.md`

## Tasks

- [x] Add catalog and placement tests that first expose the missing family.
- [x] Split all source ordinary definitions into individually commented DES
  files, preserving the source `MAP` and static directive order.
- [x] Implement all source scripted sites as named Lua hooks, including
  conditional depth rules, decay, merfolk shops, and Davey Jones' ghost.
- [x] Exercise source weighted candidates, live Shoals generation, saved
  history, and a sparse mod-added Shoals vault.
- [x] Update the modding guide and port inventory for the complete category.
- [x] Run the source audit, focused tests, Go compilation, and changed-file
  style checks. The repo-wide
  readability checker still reports pre-existing violations in unrelated
  Go files; the changed Go test file passes gofmt and the line limit.
