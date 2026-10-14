package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func TestScenarioHasTwoFloors(t *testing.T) {
	game, err := NewScenario(1, testCatalog(t), "WPN_RAPIER", "Tester")
	if err != nil {
		t.Fatal(err)
	}
	defer game.Close()
	if len(game.levels) != 2 {
		t.Fatalf("level count = %d, want 2", len(game.levels))
	}
	player, ok := game.stores.Positions.Get(game.player)
	if !ok || *player != (ecs.Position{
		LevelID: 1,
		X:       1,
		Y:       1,
	}) {
		t.Fatalf("player position = %+v", player)
	}
	if id, ok := game.levels[1].ActorAt(4, 1); !ok || !game.stores.AI.Has(id) {
		t.Fatal("rat absent at (4,1)")
	}
	if game.levels[1].terrain[3][7] != '>' || game.levels[2].terrain[1][1] != '<' {
		t.Fatal("stair terrain is wrong")
	}
	items := game.stores.Items.Entities()
	if len(items) != 6 {
		t.Fatalf("item count = %d, want 6", len(items))
	}
	itemPosition, ok := game.stores.Positions.Get(potionID(t, game))
	if !ok || *itemPosition != (ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       2,
	}) {
		t.Fatalf("potion position = %+v", itemPosition)
	}
	healWoundsFound := false
	for _, itemID := range items {
		item, ok := game.stores.Items.Get(itemID)
		if !ok || item.KindID != "POT_HEAL_WOUNDS" {
			continue
		}
		position, located := game.stores.Positions.Get(itemID)
		healWoundsFound = located && *position == (ecs.Position{
			LevelID: 2,
			X:       2,
			Y:       1,
		})
	}
	if !healWoundsFound {
		t.Fatal("heal wounds potion absent from Dungeon:2")
	}
}

func TestLevelRejectsInvalidTerrain(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	positions := ecs.Register(world).Positions
	for _, rows := range [][]string{{"###", "#?#", "###"}, {"###", "##"}} {
		if _, err := NewLevel(1, rows, positions); err == nil {
			t.Fatalf("accepted invalid terrain %q", rows)
		}
	}
}

func TestOccupancyRejectsSecondActor(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()
	positions := ecs.Register(world).Positions
	level, err := NewLevel(1, []string{"###", "#.#", "###"}, positions)
	if err != nil {
		t.Fatal(err)
	}
	first, _ := world.CreateEntity()
	second, _ := world.CreateEntity()
	if err := level.PlaceActor(first, 1, 1); err != nil {
		t.Fatal(err)
	}
	if err := level.PlaceActor(second, 1, 1); err == nil {
		t.Fatal("placed two actors at one cell")
	}
	if positions.Has(second) {
		t.Fatal("failed placement left a position on second actor")
	}
}
