package game

import (
	"testing"

	"crawl/internal/script"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

func TestScriptGridReadsVaultDestroyVeto(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	defer g.Close()

	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	x, y := position.X, position.Y

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "test-vault",
		Identity: `lua:props_marker { veto_destroy="veto", door_restrict="veto" }`,
		X:        x,
		Y:        y,
	}); err != nil {
		t.Fatal(err)
	}

	grid := scriptGrid{levels: g.levels}

	value, ok := grid.MarkerProperty(position.LevelID, x, y, "veto_destroy")

	if !ok ||
		value != "veto" {
		t.Fatalf("authored marker veto = %q, %v", value, ok)
	}

	if _, ok := grid.MarkerProperty(position.LevelID, x+1, y, "veto_destroy"); ok {
		t.Fatal("marker property leaked into neighboring cell")
	}

	if _, ok := grid.MarkerProperty(position.LevelID, x, y, "unknown"); ok {
		t.Fatal("unknown marker property was invented")
	}
}

func TestScriptGridHypotheticalClosedDoorBlocksNoTransSight(t *testing.T) {
	g := newGeneratedTestGame(t, 47)
	defer g.Close()

	cells := make([][]terrain.ID, 7)

	for y := range cells {
		cells[y] = make([]terrain.ID, 7)

		for x := range cells[y] {
			cells[y][x] = terrain.Floor
		}
	}

	level, err := NewLevel(99, cells, g.stores.Positions)

	if err != nil {
		t.Fatal(err)
	}

	grid := scriptGrid{levels: map[int]*Level{99: level}}
	before, err := grid.VisibleNoTrans(99, 1, 3, 7, 5, 3)

	if err != nil {
		t.Fatal(err)
	}

	if !before {
		t.Fatal("open line of sight was not visible")
	}

	after, err := grid.VisibleNoTransWithBlocked(
		99, 1, 3, 7, 5, 3,
		[]script.VisibleCell{{
			X: 3,
			Y: 3,
		}},
	)

	if err != nil {
		t.Fatal(err)
	}

	if after {
		t.Fatal("sight passed through hypothetically closed door")
	}

	if feature, _ := grid.Cell(99, 3, 3); feature != terrain.Floor {
		t.Fatalf("hypothetical blocker changed terrain to %q", feature)
	}
}
