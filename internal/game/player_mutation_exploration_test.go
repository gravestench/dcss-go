package game

import (
	"reflect"
	"testing"

	"crawl/internal/terrain"
)

func TestExploreRegenHealsOnlyWhenTerrainIsFirstSeen(t *testing.T) {
	g := newStepGame(t)
	addPlayerMutation(t, g, "MUT_EXPLORE_REGEN")
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)

	health.Max = 420
	health.Current = 1
	magic.Max = 270
	magic.Current = 1

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if health.Current != 1 || magic.Current != 1 {
		t.Fatal("repeated sight healed without newly seen terrain")
	}

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if health.Current <= 1 || magic.Current <= 1 {
		t.Fatalf("new terrain did not regenerate HP/MP: %d/%d",
			health.Current, magic.Current)
	}

	beforeHP := health.Current
	beforeMP := magic.Current

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if health.Current != beforeHP || magic.Current != beforeMP {
		t.Fatal("repeat visibility applied Explore Regen twice")
	}
}

func TestActuallySeenCellsSurviveSaveRestore(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	seenCount := 0

	for _, row := range snapshot.Levels[0].Seen {
		for _, seen := range row {
			if seen {
				seenCount++
			}
		}
	}

	if seenCount == 0 {
		t.Fatal("starting sight was not saved as actually seen")
	}

	if snapshot.Levels[0].Known[1][1] == terrain.Unseen ||
		!snapshot.Levels[0].Seen[1][1] {
		t.Fatal("player's starting tile was not remembered and seen")
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("actually seen mask changed across save and restore")
	}
}

func TestPassiveMappingRevealsUnknownTerrainWithoutSeeingIt(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]
	beforeSeen := level.SeenCells()
	addPlayerMutation(t, g, "MUT_PASSIVE_MAPPING")

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(beforeSeen, level.SeenCells()) {
		t.Fatal("passive mapping marked terrain as actually seen")
	}

	known := level.KnownCells()
	seen := level.SeenCells()
	mappedX, mappedY := -1, -1

	for y, row := range known {
		for x, feature := range row {
			if feature != terrain.Unseen && !seen[y][x] {
				mappedX, mappedY = x, y
				break
			}
		}

		if mappedX >= 0 {
			break
		}
	}

	if mappedX < 0 {
		t.Fatal("passive mapping revealed no previously unknown terrain")
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("mapped terrain changed across save and restore")
	}

	mask := make([]bool, level.width*len(level.terrain))

	mask[mappedY*level.width+mappedX] = true

	newlySeen, err := level.Remember(mask)

	if err != nil {
		t.Fatal(err)
	}

	if len(newlySeen) != 1 {
		t.Fatal("seeing mapped terrain did not count as a new sighting")
	}
}

func TestPassiveMappingDoesNotRevealInteriorClearWall(t *testing.T) {
	g := newStepGame(t)
	level, err := NewLevel(99, [][]terrain.ID{
		{
			terrain.RockWall,
			terrain.RockWall,
			terrain.RockWall,
		},

		{
			terrain.RockWall,
			terrain.ClearRockWall,
			terrain.RockWall,
		},

		{
			terrain.RockWall,
			terrain.RockWall,
			terrain.RockWall,
		},
	}, g.stores.Positions)

	if err != nil {
		t.Fatal(err)
	}

	if err := level.MapCell(1, 1); err != nil {
		t.Fatal(err)
	}

	if level.KnownCells()[1][1] != terrain.Unseen {
		t.Fatal("interior transparent wall was mapped despite solid neighbours")
	}

	level.terrain[0][1] = terrain.Floor

	if err := level.MapCell(1, 1); err != nil {
		t.Fatal(err)
	}

	if level.KnownCells()[1][1] != terrain.ClearRockWall {
		t.Fatal("clear wall next to open floor was not mapped")
	}
}
