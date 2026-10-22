# Generated Dungeon text snapshots

The [seed 41 index](seed-41/index.txt) lists the stair and portal connections
for one real D:1–15 generation run. Open a `D-XX.txt` file in the same directory
to see that floor's complete 80×70 terrain grid. The row number at the left is
`y`; `x` increases from left to right starting at zero. Connection coordinates
use `(x,y)`.

These are terrain snapshots, so monsters, items, player visibility, and the
player glyph do not obscure the layout. A connection marked `pending` leads to
a branch that this test did not enter; the destination cell is chosen on first
entry. An `unavailable` connection is present in the generated map but cannot
currently be used in the Go port.

To regenerate the sample after a generation change, run from the repository
root:

```sh
CRAWL_LEVEL_SNAPSHOT_DIR=docs/level-snapshots/seed-41 \
  go test -run '^TestGeneratedDungeonReachesDepthFifteen$' \
  -count=1 -timeout 5m ./internal/game
```

Set `CRAWL_LEVEL_SNAPSHOT_DIR` to another directory to inspect a run without
changing this checked-in sample. The test uses seed 41 and travels through real
stairs, so the next floor receives the same live RNG state it would in play.

The [Bailey index](bailey/index.txt) links all 15 source destination maps.
Each file shows the full 80×70 generated terrain, its selected source ID,
the return exit coordinate, and the exact outside gate coordinate used by
the test. The outside example is a Dungeon:1 fixture to keep the export
quick; ordinary Bailey entrances are eligible only on D:7–10. Regenerate
the set from the repository root with:

```sh
CRAWL_BAILEY_SNAPSHOT_DIR="$PWD/docs/level-snapshots/bailey" \
  go test -run '^TestBaileyAllSourceMapsPopulate$' \
  -count=1 ./internal/game
```
