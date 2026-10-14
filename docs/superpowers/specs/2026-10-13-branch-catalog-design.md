# Pinned branch catalog

The next world-content slice imports the complete `TAG_MAJOR_VERSION=34` branch enum and `branches[]` initializer from the pinned C++ revision. The Go game continues to use its fixed two-floor Dungeon while world generation is developed. Gameplay and builds use a committed JSON artifact; `cmd/importbranches` is a developer refresh tool only.

Each branch records its numeric enum identity, parent, entry-depth bounds, own depth, absolute depth, flags, entry/exit/escape features, three names, entry message, floor/rock colors, travel shortcut, rune IDs, ambient noise, and monster death size expression. The importer keeps original source lines and hashes. Numeric order and row identity must match exactly; aliases and `NUM_BRANCHES` are excluded. A field left out by C++ aggregate initialization is stored as an empty expression rather than guessed.

The catalog exposes immutable branch definitions. Runtime loading verifies the pinned source revision, exact identity sequence, and source hashes, so a same-count substituted artifact cannot silently change the world model. The importer rejects unrecognized enum/table rows, malformed initializers, and duplicate identities. Parser tests use small synthetic tables; the committed artifact is checked against the pinned C++ tree.

This slice does not implement map generation, branch entrance placement, branch travel, or rune behavior. Those features will consume the catalog in later slices.
