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

The [Ice Cave index](ice-cave/index.txt) links all 11 source destination
maps in both easy and hard variants. Each of the 22 files shows its
generated 80×70 terrain, source vault ID, every exit coordinate, and the
exact outside test gate. Easy fixtures use Dungeon:1; hard fixtures use a
generated Dungeon:14 floor. Ordinary Ice Cave entrances start at D:11.
Regenerate the set with:

```sh
CRAWL_ICE_CAVE_SNAPSHOT_DIR="$PWD/docs/level-snapshots/ice-cave" \
  go test -run '^TestIceCaveAllSourceMapsPopulate$' \
  -count=1 ./internal/game
```

The [Wizard Lab index](wizlab/index.txt) shows all 15 source rooms, every
authored return arch, and the exact Dungeon:1 test gate. It uses the same
terrain-only view as the other portal snapshots. Regenerate it with:

```sh
CRAWL_WIZLAB_SNAPSHOT_DIR="$PWD/docs/level-snapshots/wizlab" \
  go test -run '^TestWizlabAllSourceMapsPopulate$' \
  -count=1 ./internal/game
```

The [Desolation index](desolation/index.txt) shows all three source-authored
floors after ruin selection. Each 80×70 terrain snapshot lists every
Desolation return arch and the exact Dungeon:1 test gate it reaches. The
test gate keeps export fast; live entrances appear in eligible Elf and
Vaults floors. Regenerate the set with:

```sh
CRAWL_DESOLATION_SNAPSHOT_DIR="$PWD/docs/level-snapshots/desolation" \
  go test -run '^TestDesolationAllSourceMapsPopulate$' \
  -count=1 ./internal/game
```
