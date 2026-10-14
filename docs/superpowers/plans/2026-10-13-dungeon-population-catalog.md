# Dungeon population catalog plan

1. Test parsing a small Dungeon table with duplicate IDs and malformed rows, and test all five depth curves at boundaries.
2. Add validated artifact and catalog APIs, a developer importer/CLI, then generate and commit all 125 pinned rows. Pin runtime artifact bytes and validate all monster references.
3. Update the port inventory; run importer check, full tests/vet/build, whole-branch review, one category commit, and local main merge.
