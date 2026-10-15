package game

import (
	"testing"

	"dcrawl-go/internal/modfs"
)

func TestRestoreKeepsEntityWithOnlyLuaComponents(t *testing.T) {
	rules, err := modfs.Load("testdata/turn-counter-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["mod.turns"]

	if _, err := store.Set(entity, map[string]any{
		"count": int64(7),
		"owner": g.player,
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	component, found := loaded.scripts.Components()["mod.turns"].Get(entity)

	if !found {
		t.Fatal("Lua-only entity was omitted from restore")
	}

	count, err := component.Get("count")

	if err != nil {
		t.Fatal(err)
	}

	if count != int64(7) {
		t.Fatalf("restored Lua count = %v, error = %v", count, err)
	}
}
