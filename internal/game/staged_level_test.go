package game

import (
	"reflect"
	"testing"
)

// A generated replacement is prepared beside the current world. Rolling
// back discards its grid and ECS entities and restores its RNG draws.
func TestStageGeneratedPanLevelRollback(t *testing.T) {
	g := newGeneratedTestGame(t, 7301)
	beforeLevels := len(g.levels)
	beforeEntities := g.world.Entities()
	beforeRNG := g.rng.States()

	stage, err := g.stageGeneratedLevel("world.generate_pan_region", map[string]any{
		"levels_seen":     0,
		"prior_vault_ids": []any{},
	})

	if err != nil {
		t.Fatal(err)
	}

	if g.levels[stage.levelID] == nil || len(g.levels) != beforeLevels+1 {
		t.Fatal("staged Pan level was not installed for population")
	}

	if err := stage.rollback(); err != nil {
		t.Fatal(err)
	}

	if g.levels[stage.levelID] != nil || len(g.levels) != beforeLevels {
		t.Fatal("rolled-back Pan level survived")
	}

	if !reflect.DeepEqual(g.world.Entities(), beforeEntities) {
		t.Fatal("rolled-back Pan entities survived")
	}

	if !reflect.DeepEqual(g.rng.States(), beforeRNG) {
		t.Fatal("rolled-back Pan generation advanced RNG")
	}
}

// A rejected second-region request must leave the first floor, its actors,
// and all random streams intact before command policy spends any aut.
func TestStageGeneratedPanLevelFailureIsAtomic(t *testing.T) {
	g := newGeneratedTestGame(t, 7302)
	beforeLevels := len(g.levels)
	beforeEntities := g.world.Entities()
	beforeRNG := g.rng.States()

	_, err := g.stageGeneratedLevel("world.generate_pan_region", map[string]any{
		"levels_seen":     -1,
		"prior_vault_ids": []any{},
	})

	if err == nil {
		t.Fatal("invalid Pan region count was accepted")
	}

	if len(g.levels) != beforeLevels ||
		!reflect.DeepEqual(g.world.Entities(), beforeEntities) ||
		!reflect.DeepEqual(g.rng.States(), beforeRNG) {
		t.Fatal("failed Pan generation changed the live game")
	}
}

// A generated unique can claim player history before landing is checked.
// Rejecting that floor must return every pre-existing dynamic component to
// its earlier value, not merely delete actors created on the staged floor.
func TestStageRollbackRestoresExistingDynamicState(t *testing.T) {
	g := newGeneratedTestGame(t, 7304)
	before := g.savedLuaComponents(g.player)

	stage, err := g.stageGeneratedLevel("world.generate_pan_region", map[string]any{
		"levels_seen":     0,
		"prior_vault_ids": []any{},
	})

	if err != nil {
		t.Fatal(err)
	}

	history := g.scripts.Components()["character.unique_history"]
	current, found := history.Get(g.player)

	if !found {
		t.Fatal("player has no unique history")
	}

	values, err := current.Snapshot()

	if err != nil {
		t.Fatal(err)
	}

	values["pan_states"] = map[string]any{
		"MONS_IGNACIO": "allow",
	}

	if _, err := history.Set(g.player, values); err != nil {
		t.Fatal(err)
	}

	if err := stage.rollback(); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(g.savedLuaComponents(g.player), before) {
		t.Fatal("rolled-back Pan floor retained a player unique decision")
	}
}

// A colliding ID is rejected before the replacement transaction owns it.
// Error cleanup must never delete a level that was present on entry.
func TestStageGeneratedLevelKeepsExistingID(t *testing.T) {
	g := newGeneratedTestGame(t, 7303)
	const panFirstID = 2301
	original := g.levels[1]

	g.levels[panFirstID] = original

	_, err := g.stageGeneratedLevel("world.generate_pan_region", map[string]any{
		"levels_seen":     0,
		"prior_vault_ids": []any{},
	})

	if err == nil {
		t.Fatal("duplicate Pan level ID was accepted")
	}

	if g.levels[panFirstID] != original {
		t.Fatal("failed staging deleted the existing level")
	}
}
