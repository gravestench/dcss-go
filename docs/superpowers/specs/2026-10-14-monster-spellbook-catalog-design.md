# Complete monster spellbook catalog

## Intent and source

The pinned DCSS `mon-spell.h` contains 285 active monster spellbooks.
`mon-mst.h` lists those books in runtime enum order, followed by
`MST_GHOST`, `NUM_MSTYPES`, and `MST_NO_SPELLS`. The current Go artifact
contains only `MST_ENDOPLASM`. Import every active book, retaining the
source order of books and spell slots, each slot's frequency, all flag
bits, and original line numbers. This makes the next monster spell
categories read committed content instead of acquiring handwritten rows.

## Ownership

The `content` catalog owns immutable book definitions. A developer-run Go
importer reads the pinned C++ checkout only on explicit refresh or check.
Normal gameplay, tests, and builds use the committed JSON artifact. The
importer checks the source enum for one-to-one ordered coverage, validates
flags against the pinned `externs.h` vocabulary, and checks every spell ID
against the independently committed spell catalog. The runtime catalog
rechecks artifact structure and spell references when loading. Its accessor returns
deep copies so callers cannot mutate flags or slots.

The two special enum identities remain outside the active-book artifact.
This category changes content availability, not live casting rules.

## Verification

Parser tests cover multiline flag expressions, optional row commas,
duplicate IDs, unknown flags, unknown spell references, and enum mismatches. A pinned
source check proves deterministic output; committed content tests assert
285 books and representative endoplasm, dart slug, wizard, and breath
slots. Full Go test, vet, build, style, and diff checks gate the category
commit and fast-forward to local `main`.
