package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/vault"
)

// An authored player-move marker becomes a saved ECS component, then
// disappears after the player actually steps onto its cell.
func TestSpiderVaultTriggerSurvivesSaveAndFiresOnce(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-force-spider-trigger")

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

	if store == nil || len(store.Entities()) != 1 {
		t.Fatal("source marker did not create one Spider trigger")
	}

	foundRecord := false

	for _, record := range g.levels[1].VaultRecords() {
		if record.Kind == vault.KindMarker &&
			record.Identity == "vault_trigger:spider_nest.warn" {
			foundRecord = !record.Pending
		}
	}

	if !foundRecord {
		t.Fatal("Spider marker was not materialized from DES")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("vault trigger state changed across restore")
	}

	store = restored.scripts.Components()["world.vault_trigger"]
	state, _ := store.Get(store.Entities()[0])
	xValue, _ := state.Get("x")
	yValue, _ := state.Get("y")
	x := int(xValue.(int64))
	y := int(yValue.(int64))
	level := restored.levels[1]
	directions := []struct {
		dx int
		dy int
	}{
		{dx: -1},
		{dx: 1},
		{dy: -1},
		{dy: 1},
	}

	command := Command{Kind: CommandMove}
	foundApproach := false

	for _, direction := range directions {
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

		command.DX = direction.dx
		command.DY = direction.dy
		foundApproach = true
		break
	}

	if !foundApproach {
		t.Fatal("Spider marker has no walkable approach")
	}

	if _, err := restored.Step(command); err != nil {
		t.Fatal(err)
	}

	if len(store.Entities()) != 0 {
		t.Fatal("one-shot Spider trigger remained after player move")
	}

	consumed := restored.Snapshot()
	loaded, err := RestoreWithRules(consumed, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if len(loaded.scripts.Components()["world.vault_trigger"].Entities()) != 0 {
		t.Fatal("consumed Spider trigger reappeared on restore")
	}
}
