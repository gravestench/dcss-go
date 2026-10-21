package game

import (
	"bytes"
	"encoding/json"
	"math"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/vault"
)

func fogMachineSnapshot(t *testing.T) (save.Snapshot, modfs.Ruleset) {
	t.Helper()

	rules, err := modfs.Load("testdata/vault-force-fog")

	if err != nil {
		t.Fatal(err)
	}

	game, err := NewDungeonGameWithRules(
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

	defer game.Close()

	if game.levels[1].VaultID() != "dpeg_arrival_fog" {
		t.Fatalf("arrival = %q", game.levels[1].VaultID())
	}

	machines := game.scripts.Components()["world.fog_machine"].Entities()

	if len(machines) == 0 {
		t.Fatal("source marker did not create a fog machine")
	}

	if len(game.scripts.Components()["world.cloud"].Entities()) == 0 {
		t.Fatal("source entry burst did not create clouds")
	}

	var realized bool

	for _, record := range game.levels[1].VaultRecords() {
		if record.Kind == vault.KindMarker &&
			strings.HasPrefix(record.Identity, "lua:fog_machine") {
			realized = !record.Pending
		}
	}

	if !realized {
		t.Fatal("source fog marker stayed pending")
	}

	for range 15 {
		if _, err := game.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	return game.Snapshot(), rules
}

func TestAuthoredFogMachineEntryTurnAndSave(t *testing.T) {
	snapshot, rules := fogMachineSnapshot(t)
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	before, _ := json.Marshal(snapshot)
	after, _ := json.Marshal(restored.Snapshot())

	if !bytes.Equal(before, after) {
		t.Fatal("restore changed fog clocks, clouds, or RNG")
	}

	if len(restored.scripts.Components()["world.fog_machine"].Entities()) == 0 {
		t.Fatal("fog machine disappeared on restore")
	}

	forged := cloneVaultSnapshot(t, snapshot)

	for entityIndex := range forged.Entities {
		for stateIndex := range forged.Entities[entityIndex].Dynamic {
			state := &forged.Entities[entityIndex].Dynamic[stateIndex]

			if state.Schema == "world.fog_machine" {
				state.Values["pow_max"] = json.RawMessage("999")
				_, err := RestoreWithRules(forged, rules, RestorePolicy{})

				if err == nil || !strings.Contains(err.Error(), "fog machine") {
					t.Fatalf("forged fog power accepted: %v", err)
				}

				return
			}
		}
	}

	t.Fatal("saved fog machine component missing")
}

func TestAuthoredFogMachineEmitsOutsidePlayerView(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-force-fog")

	if err != nil {
		t.Fatal(err)
	}

	game, err := NewDungeonGameWithRules(41,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	store := game.scripts.Components()["world.fog_machine"]
	machine := store.Entities()[0]
	state, _ := store.Get(machine)
	xValue, _ := state.Get("x")
	yValue, _ := state.Get("y")
	x := int(xValue.(int64))
	y := int(yValue.(int64))

	for _, entity := range game.scripts.Components()["world.cloud"].Entities() {
		game.world.DestroyEntity(entity)
	}

	level := game.levels[1]
	moved := false

	for yCandidate := 1; yCandidate < len(level.terrain) && !moved; yCandidate++ {
		for xCandidate := 1; xCandidate < level.width && !moved; xCandidate++ {
			if math.Abs(float64(xCandidate-x)) < 12 ||
				math.Abs(float64(yCandidate-y)) < 12 ||
				!level.Walkable(xCandidate, yCandidate) {
				continue
			}

			moved = level.MoveActor(game.player, xCandidate, yCandidate) == nil
		}
	}

	if !moved {
		t.Fatal("no distant walkable player cell")
	}

	if err := state.Set("countdown_aut", int64(1)); err != nil {
		t.Fatal(err)
	}

	if _, err := game.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	clouds := game.scripts.Components()["world.cloud"].Entities()

	if len(clouds) == 0 {
		t.Fatal("offscreen fog source did not emit")
	}

	for _, cloud := range clouds {
		cell, _ := game.scripts.Components()["world.cloud"].Get(cloud)
		cloudX, _ := cell.Get("x")
		cloudY, _ := cell.Get("y")

		if math.Abs(float64(int(cloudX.(int64))-x)) > 5 ||
			math.Abs(float64(int(cloudY.(int64))-y)) > 5 {
			t.Fatal("fog cloud escaped the authored source area")
		}
	}
}
