package game

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

func petrifySpellSeed(t *testing.T) uint64 {
	t.Helper()

	for seed := uint64(1); seed < 10000; seed++ {
		probe := NewRNGStreams(seed)
		choice, _ := probe.Intn("monster_spell", 200)
		first, _ := probe.Intn("monster_spell", 100)
		second, _ := probe.Intn("monster_spell", 101)

		if choice <= 56 && first+second > 180 {
			return seed
		}
	}

	t.Fatal("no seed casts and lands Basilisk Petrify")

	return 0
}

func basiliskSpellTestGame(t *testing.T) (*Game, akara.Entity) {
	t.Helper()

	g, err := NewScenario(petrifySpellSeed(t), "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)

	actor.KindID = "MONS_BASILISK"
	placePlayerBesideMonster(t, g, rat)

	return g, rat
}

func TestBasiliskPetrifyUsesPlayerResistanceAndSavedStatus(t *testing.T) {
	t.Run("unprotected", func(t *testing.T) {
		g, basilisk := basiliskSpellTestGame(t)
		events, err := g.runAction(basilisk, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		status := g.scripts.Components()["magic.player_petrification"]

		if g.turn.ResolvedIntent != ecs.IntentSpell || !status.Has(g.player) {
			t.Fatalf("Petrify action %+v, intent %d, status %v",
				events, g.turn.ResolvedIntent, status.Has(g.player))
		}

		actor, _ := g.stores.Actors.Get(basilisk)

		actor.KindID = "MONS_RAT"

		if err := g.refreshVisibility(); err != nil {
			t.Fatal(err)
		}

		before := g.Snapshot()
		restored, err := Restore(before)

		if err != nil {
			t.Fatal(err)
		}

		defer restored.Close()

		if !reflect.DeepEqual(before, restored.Snapshot()) {
			t.Fatal("petrifying status changed on save restore")
		}

		for turn := 0; turn < 2; turn++ {
			originalResult, originalErr := g.Step(Command{
				Kind: CommandWait,
			})

			restoredResult, restoredErr := restored.Step(Command{
				Kind: CommandWait,
			})

			if originalErr != nil {
				t.Fatalf("original turn %d: %v", turn, originalErr)
			}

			if restoredErr != nil {
				t.Fatalf("restored turn %d: %v", turn, restoredErr)
			}

			if !reflect.DeepEqual(originalResult, restoredResult) ||
				!reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
				t.Fatalf("petrification diverged after restored turn %d", turn)
			}
		}
	})

	t.Run("mutation immunity", func(t *testing.T) {
		g, basilisk := basiliskSpellTestGame(t)
		addPlayerMutation(t, g, "MUT_PETRIFICATION_RESISTANCE")
		events, err := g.runAction(basilisk, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		status := g.scripts.Components()["magic.player_petrification"]
		message := ""

		for _, event := range events {
			message += event.Text
		}

		if g.turn.ResolvedIntent != ecs.IntentSpell ||
			status.Has(g.player) ||
			!strings.Contains(message, "unaffected") {
			t.Fatalf("immune Petrify action %+v, status %v",
				events, status.Has(g.player))
		}
	})
}

func TestBasiliskPetrificationStagesAndLocksActions(t *testing.T) {
	g, basilisk := basiliskSpellTestGame(t)

	if _, err := g.runAction(basilisk, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].RemoveActor(basilisk); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(basilisk) {
		t.Fatal("could not clear the petrification test floor")
	}

	status := g.scripts.Components()["magic.player_petrification"]
	position, _ := g.stores.Positions.Get(g.player)
	start := *position

	for turn := 0; turn < 2; turn++ {
		result, err := g.Step(Command{Kind: CommandWait})

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 15 {
			t.Fatalf("petrifying wait %d: %+v, %v", turn, result, err)
		}
	}

	if petrified := luaIntFieldOn(t, g, g.player,
		"magic.player_petrification", "petrified_aut"); petrified < 60 {
		t.Fatalf("petrification never completed: %d aut", petrified)
	}

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 || *position != start {
		t.Fatalf("petrified movement %+v, position %+v, err %v",
			result, *position, err)
	}

	if len(result.Events) == 0 ||
		!strings.Contains(result.Events[0].Text, "petrified") {
		t.Fatalf("petrified movement gave no status feedback: %+v",
			result.Events)
	}

	for turn := 0; turn < 15 && status.Has(g.player); turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if status.Has(g.player) {
		t.Fatal("petrification never expired")
	}
}

func TestRestoreRejectsInvalidPlayerPetrification(t *testing.T) {
	g, basilisk := basiliskSpellTestGame(t)

	if _, err := g.runAction(basilisk, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	actor, _ := g.stores.Actors.Get(basilisk)

	actor.KindID = "MONS_RAT"

	bad := g.Snapshot()
	changed := false

	for entityIndex := range bad.Entities {
		for componentIndex := range bad.Entities[entityIndex].Dynamic {
			record := &bad.Entities[entityIndex].Dynamic[componentIndex]

			if record.Schema != "magic.player_petrification" {
				continue
			}

			record.Values["petrifying_aut"] = json.RawMessage("-1")
			changed = true
		}
	}

	if !changed {
		t.Fatal("snapshot has no player petrification")
	}

	loaded, err := Restore(bad)

	if loaded != nil {
		loaded.Close()
	}

	if err == nil {
		t.Fatal("invalid player petrification was accepted")
	}

	if !strings.Contains(err.Error(), "petrification") {
		t.Fatalf("invalid player petrification accepted: %v", err)
	}
}

func TestPetrificationChangesPlayerEvasion(t *testing.T) {
	g := newStepGame(t)
	baseline := g.View().PlayerEV
	status := g.scripts.Components()["magic.player_petrification"]

	if _, err := status.Set(g.player, map[string]any{
		"petrifying_aut": int64(20),
		"petrified_aut":  int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerEV; got >= baseline {
		t.Fatalf("petrifying EV %d did not fall below %d", got, baseline)
	}

	if _, err := status.Set(g.player, map[string]any{
		"petrifying_aut": int64(0),
		"petrified_aut":  int64(60),
	}); err != nil {
		t.Fatal(err)
	}

	if got := g.View().PlayerEV; got != 2 {
		t.Fatalf("petrified Human EV = %d, want 2", got)
	}
}
