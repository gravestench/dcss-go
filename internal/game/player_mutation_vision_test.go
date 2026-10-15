package game

import (
	"testing"

	"dcrawl-go/internal/terrain"
)

func TestSightMutationsChangeVisibleTerrainRadius(t *testing.T) {
	g := newStepGame(t)
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player lacks position")
	}

	level := g.levels[position.LevelID]

	for x := position.X + 1; x <= position.X+8; x++ {
		level.terrain[position.Y][x] = terrain.Floor
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	distant := position.Y*level.width + position.X + 8

	if g.visible[distant] {
		t.Fatal("ordinary player sees beyond radius seven")
	}

	mutationStore := g.scripts.Components()["character.mutation"]
	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := mutationStore.Set(mutation, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_DAYSTALKER",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if !g.visible[distant] {
		t.Fatal("Daystalker did not extend actual map sight")
	}

	night, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := mutationStore.Set(night, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_NIGHTSTALKER",
		"acquired":    int64(3),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if g.visible[distant] || g.visible[position.Y*level.width+position.X+6] {
		t.Fatal("Nightstalker did not contract actual map sight")
	}

	if !g.visible[position.Y*level.width+position.X+5] {
		t.Fatal("Nightstalker hid terrain inside the reduced radius")
	}
}

func TestDaystalkerExtendsPlayerProjectileRange(t *testing.T) {
	g := newStepGame(t)
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player lacks position")
	}

	level := g.levels[position.LevelID]

	for x := position.X + 1; x <= position.X+8; x++ {
		level.terrain[position.Y][x] = terrain.Floor
	}

	stone := givePlayerProjectileItem(t, g, "MI_STONE", 2, "")
	command := Command{
		Kind:   CommandThrow,
		ItemID: uint64(stone),
		DX:     8,
	}

	ordinary, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if ordinary.Spent != 0 {
		t.Fatalf("ordinary range-eight throw spent %d aut", ordinary.Spent)
	}

	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		mutation,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_DAYSTALKER",
			"acquired":    int64(1),
		},
	); err != nil {
		t.Fatal(err)
	}

	extended, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if extended.Spent == 0 {
		t.Fatal("Daystalker did not permit a range-eight throw")
	}
}

func TestNightstalkerLimitsNearbyMonsterRegenInhibition(t *testing.T) {
	g := newStepGame(t)
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player lacks position")
	}

	level := g.levels[position.LevelID]

	for x := position.X + 1; x <= position.X+6; x++ {
		level.terrain[position.Y][x] = terrain.Floor
	}

	if err := level.MoveActor(ratID(t, g), position.X+6, position.Y); err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	for _, record := range []struct {
		id    string
		level int64
	}{
		{
			id:    "MUT_INHIBITED_REGENERATION",
			level: 1,
		},

		{
			id:    "MUT_NIGHTSTALKER",
			level: 3,
		},
	} {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		if _, err := store.Set(entity, map[string]any{
			"owner":       g.player,
			"mutation_id": record.id,
			"acquired":    record.level,
		}); err != nil {
			t.Fatal(err)
		}
	}

	health, _ := g.stores.Health.Get(g.player)
	progress, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 5

	progress.HPProgress = 99

	g.turn.Actor = g.player

	updateLuaSystem(t, g, "status.regeneration", 10)

	if health.Current != 6 {
		t.Fatalf("unseen rat inhibited healing at Nightstalker radius: HP=%d", health.Current)
	}
}
