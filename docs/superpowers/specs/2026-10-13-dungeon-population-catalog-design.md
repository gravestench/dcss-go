# Pinned Dungeon population catalog

Pinned sources: `crawl-ref/source/tag-version.h`, `mon-pick-data.h:56-195`, and `random-pick.h:116-149` at revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

Import all 125 ordered rows of the tag-34 Dungeon monster population, retaining duplicate monster IDs where the source has multiple depth bands. Each row stores minimum and maximum depth, rarity, curve (`FLAT`, `SEMI`, `PEAK`, `RISE`, `FALL`), monster ID, and source line. A developer-only importer verifies the exact source file hashes for the claimed revision, writes a committed JSON artifact, and supports a byte-exact `-check` mode. Normal gameplay, tests, and builds read the committed artifact without the C++ checkout. Runtime loading checks a pinned artifact hash, row count, source provenance, and that each referenced monster is defined in the committed monster catalog.

The catalog exposes a defensive copy and a pure source-shaped `WeightAtDepth` rule using the 2520 scale from `random-pick.h`. This slice makes the data available for future spawning; it does not alter the fixed rat/quokka scenario or select and place monsters yet.
