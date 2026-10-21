package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/vault"
)

// Force only selection, then use the bundled Lady DES, Lua hook, live grid,
// movement scheduler, ECS component, and Go save format end to end.
func TestLadyOfLakeTriggerSurvivesSaveAndSpawnsOnce(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-force-lady")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		41,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	store := g.scripts.Components()["world.vault_trigger"]

	if store == nil || len(store.Entities()) < 2 {
		t.Fatal("source Lady map did not create its shared entrance triggers")
	}

	level := g.levels[1]
	targetFound := false

	for _, record := range level.VaultRecords() {
		if record.Kind == vault.KindMarker &&
			record.Identity == "vault_target:merfolk_avatar" {
			targetFound = true
			break
		}
	}

	if !targetFound {
		t.Fatal("source Lady map lost its avatar target marker")
	}

	before := g.Snapshot()
	restored, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Lady trigger target or entrance changed across restore")
	}

	store = restored.scripts.Components()["world.vault_trigger"]
	level = restored.levels[1]
	initialTriggers := len(store.Entities())
	var command Command
	approachFound := false

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		xValue, _ := state.Get("x")
		yValue, _ := state.Get("y")
		x := int(xValue.(int64))
		y := int(yValue.(int64))

		for _, direction := range []struct{ dx, dy int }{
			{dx: -1}, {dx: 1}, {dy: -1}, {dy: 1},
		} {
			fromX := x - direction.dx
			fromY := y - direction.dy

			if !level.Walkable(fromX, fromY) {
				continue
			}

			if _, occupied := level.ActorAt(fromX, fromY); occupied {
				continue
			}

			if err := level.MoveActor(restored.player, fromX, fromY); err != nil {
				t.Fatal(err)
			}

			command = Command{
				Kind: CommandMove,
				DX:   direction.dx,
				DY:   direction.dy,
			}
			approachFound = true
			break
		}

		if approachFound {
			break
		}
	}

	if !approachFound {
		t.Fatal("Lady entrance has no walkable player approach")
	}

	if _, err := restored.Step(command); err != nil {
		t.Fatal(err)
	}

	if len(store.Entities()) != 0 {
		t.Fatalf("Lady left %d of %d shared triggers armed",
			len(store.Entities()), initialTriggers)
	}

	avatars := 0

	for _, entity := range restored.stores.Actors.Entities() {
		actor, _ := restored.stores.Actors.Get(entity)

		if actor.KindID == "MONS_MERFOLK_AVATAR" {
			avatars++
		}
	}

	if avatars != 1 {
		t.Fatalf("Lady spawned %d avatars, want one", avatars)
	}

	consumed := restored.Snapshot()
	loaded, err := RestoreWithRules(consumed, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if len(loaded.scripts.Components()["world.vault_trigger"].Entities()) != 0 {
		t.Fatal("consumed Lady entrances reappeared after restore")
	}

	// Restore must reject a permanent avatar detached from its authored K
	// marker. This proves the delayed-spawn save policy actually ran.
	spawnStore := loaded.scripts.Components()["world.vault_spawn"]
	spawned := spawnStore.Entities()

	if len(spawned) != 1 {
		t.Fatalf("Lady has %d saved avatar origins, want one", len(spawned))
	}

	state, _ := spawnStore.Get(spawned[0])
	levelID, _ := state.Get("level_id")
	vaultID, _ := state.Get("vault_id")
	triggerIndex, _ := state.Get("trigger_index")
	targetY, _ := state.Get("target_y")
	forged := map[string]any{
		"level_id":      levelID,
		"vault_id":      vaultID,
		"trigger_index": triggerIndex,
		"target_x":      int64(0),
		"target_y":      targetY,
	}

	if _, err := spawnStore.Set(spawned[0], forged); err != nil {
		t.Fatal(err)
	}

	if invalid, err := RestoreWithRules(loaded.Snapshot(), rules,
		RestorePolicy{}); err == nil {
		invalid.Close()
		t.Fatal("forged Lady target restored")
	} else if !strings.Contains(err.Error(), "authored target") {
		t.Fatalf("forged Lady target restore error = %v", err)
	}
}
