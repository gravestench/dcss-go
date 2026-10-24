package game

import (
	"testing"

	"crawl/internal/terrain"
)

// A source monster can die before its temporary terrain timer expires.
// The ordinary death phase must release its marker and restore the old
// feature in the same turn, without waiting for another terrain tick.
func TestMonsterDeathReleasesTemporaryTerrain(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	level := g.levels[1]
	cell := firstOpenMonsterCell(t, level)
	original := level.terrain[cell.y][cell.x]

	if err := level.SetCell(cell.x, cell.y, terrain.SealedDoor); err != nil {
		t.Fatal(err)
	}
	marker, err := g.world.CreateEntity()
	if err != nil {
		t.Fatal(err)
	}
	store := g.scripts.Components()["world.temporary_terrain"]
	if _, err := store.Set(marker, map[string]any{
		"source_actor_id":  uint64(rat),
		"source_kind_id":   "MONS_RAT",
		"level_id":         int64(1),
		"x":                int64(cell.x),
		"y":                int64(cell.y),
		"original_feature": string(original),
		"changed_feature":  string(terrain.SealedDoor),
		"expires_aut":      int64(g.currentAut + 500),
	}); err != nil {
		t.Fatal(err)
	}

	health, found := g.stores.Health.Get(rat)
	if !found {
		t.Fatal("rat has no health")
	}
	health.Current = 0
	if _, err := g.stores.Health.Set(rat, *health); err != nil {
		t.Fatal(err)
	}
	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if level.terrain[cell.y][cell.x] != original {
		t.Fatal("dead source left its temporary terrain behind")
	}
	if store.Has(marker) {
		t.Fatal("dead source left its terrain marker behind")
	}
}
