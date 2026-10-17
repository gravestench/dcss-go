package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/terrain"
)

func TestCloudAndCorrosionSaveWithDeadSource(t *testing.T) {
	g := newStepGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	cloud, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["world.cloud"].Set(cloud,
		map[string]any{
			"kind_id":         "CLOUD_FIRE",
			"level_id":        int64(position.LevelID),
			"x":               int64(position.X),
			"y":               int64(position.Y),
			"decay_aut":       int64(80),
			"source_actor_id": uint64(900),
			"kill_category":   "KC_YOU",
			"killer_type":     "KILL_YOU_MISSILE",
		}); err != nil {
		t.Fatal(err)
	}

	corrosion := g.scripts.Components()["character.corrosion"]

	if _, err := corrosion.Set(g.player, map[string]any{
		"remaining_aut": int64(120),
		"stacks":        int64(2),
	}); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("cloud or corrosion changed across save and restore")
	}

	if !loaded.scripts.Components()["character.corrosion"].Has(g.player) {
		t.Fatal("player corrosion was lost on restore")
	}

	if _, err := corrosion.Set(g.player, map[string]any{
		"remaining_aut": int64(0),
		"stacks":        int64(2),
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := Restore(g.Snapshot()); err == nil ||
		!strings.Contains(err.Error(), "corrosion") {
		t.Fatalf("invalid corrosion save was accepted: %v", err)
	}
}

func TestMonsterCloudPoisonStateRestoresWithoutPlayerSource(t *testing.T) {
	g := newZapGame(t)
	monsters := g.stores.MonsterEnergy.Entities()

	if len(monsters) == 0 {
		t.Fatal("scenario has no monster")
	}

	monster := monsters[0]
	poison := g.scripts.Components()["projectile.poison"]

	if _, err := poison.Set(monster,
		map[string]any{
			"degree":        int64(1),
			"remaining_aut": int64(20),
			"max_aut":       int64(20),
			"source":        monster,
			"player_credit": false,
		}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["projectile.poison"].Has(monster) {
		t.Fatal("monster-sourced poison was lost on restore")
	}

	if _, err := poison.Set(monster, map[string]any{
		"degree":        int64(1),
		"remaining_aut": int64(20),
		"max_aut":       int64(20),
		"player_credit": true,
	}); err != nil {
		t.Fatal(err)
	}

	deadSource, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer deadSource.Close()

	if !deadSource.scripts.Components()["projectile.poison"].Has(monster) {
		t.Fatal("poison from a dead cloud source was lost")
	}
}

func TestOverwrittenTemporaryTerrainRestores(t *testing.T) {
	g := newStepGame(t)
	position, _ := g.stores.Positions.Get(g.player)
	current := g.levels[position.LevelID].terrain[position.Y][position.X]
	changed := terrain.ShallowWater

	if changed == current {
		changed = terrain.Floor
	}

	marker, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["world.temporary_terrain"].Set(
		marker, map[string]any{
			"source_kind_id":   "CLOUD_RAIN",
			"level_id":         int64(position.LevelID),
			"x":                int64(position.X),
			"y":                int64(position.Y),
			"original_feature": string(current),
			"changed_feature":  string(changed),
			"expires_aut":      int64(g.currentAut + 500),
		})

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["world.temporary_terrain"].Has(marker) {
		t.Fatal("overwritten temporary terrain marker was lost")
	}
}
