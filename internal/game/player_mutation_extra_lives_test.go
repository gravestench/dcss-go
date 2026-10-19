package game

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

func extraLifeField(t *testing.T, state *akara.DynamicComponent, field string) any {
	t.Helper()

	value, err := state.Get(field)

	if err != nil {
		t.Fatal(err)
	}

	return value
}

func TestMultiLivedDeathRevivesAfterSave(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	addPlayerMutation(t, g, "MUT_MULTILIVED")

	lives := g.scripts.Components()["character.extra_lives"]
	_, err := lives.Set(g.player, map[string]any{
		"lives":            int64(1),
		"deaths":           int64(0),
		"max_level":        int64(4),
		"last_life_gained": int64(4),
		"pending_revival":  false,
	})

	if err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Current = 1

	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Strength += 3

	for turn := 0; turn < 20 && !g.playerDead(); turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !g.playerDead() {
		t.Fatal("the rat did not kill the one-HP player")
	}

	spent, found := lives.Get(g.player)

	if !found {
		t.Fatal("fatal hit removed extra-life state")
	}

	remaining := extraLifeField(t, spent, "lives")
	deaths := extraLifeField(t, spent, "deaths")
	pending := extraLifeField(t, spent, "pending_revival")

	if remaining != int64(0) ||
		deaths != int64(1) ||
		pending != true {
		t.Fatalf("fatal hit did not spend a life: %+v", spent)
	}

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    4000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	durations, _ := g.stores.Durations.Get(g.player)

	durations.MightAut = 40

	if _, err := g.scripts.Components()["magic.player_status"].Set(
		g.player,
		map[string]any{
			"silence_aut": int64(30),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.agility"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(30),
		},
	); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	bad := g.Snapshot()
	corrupted := false

	for entityIndex := range bad.Entities {
		for componentIndex := range bad.Entities[entityIndex].Dynamic {
			record := &bad.Entities[entityIndex].Dynamic[componentIndex]

			if record.Schema == "character.extra_lives" {
				record.Values["lives"] = json.RawMessage("3")
				corrupted = true
			}
		}
	}

	if !corrupted {
		t.Fatal("snapshot has no saved extra-life state")
	}

	invalid, invalidErr := Restore(bad)

	if invalid != nil {
		invalid.Close()
	}

	if invalidErr == nil ||
		!strings.Contains(invalidErr.Error(), "extra-life") {
		t.Fatalf("invalid saved extra lives were accepted: %v", invalidErr)
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("pending revival changed across save and restore")
	}

	rat := ratID(t, restored)

	if err := restored.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if !restored.world.DestroyEntity(rat) {
		t.Fatal("could not clear the revival test floor")
	}

	result, err := restored.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if result.View.PlayerDead || result.View.PlayerHP != result.View.PlayerMaxHP {
		t.Fatalf("Felid revival health %d/%d, dead %v",
			result.View.PlayerHP, result.View.PlayerMaxHP,
			result.View.PlayerDead)
	}

	if restored.stores.Poison.Has(restored.player) ||
		restored.scripts.Components()["magic.player_status"].Has(
			restored.player) ||
		restored.scripts.Components()["character.agility"].Has(
			restored.player) {
		t.Fatal("revival left a temporary affliction")
	}

	restoredDurations, _ := restored.stores.Durations.Get(restored.player)

	if restoredDurations.MightAut != 0 {
		t.Fatal("revival left the temporary Might duration")
	}

	revived, _ := restored.scripts.Components()["character.extra_lives"].Get(
		restored.player,
	)

	if extraLifeField(t, revived, "pending_revival") != false {
		t.Fatalf("revival stayed pending: %+v", revived)
	}
}
