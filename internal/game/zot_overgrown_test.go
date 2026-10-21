package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
)

// The bundled overgrown map owns the target coordinates; a focused mod
// changes only selection so the source event can be reached on D:1.
func TestZotOvergrownCountdownSurvivesSave(t *testing.T) {
	rules, err := modfs.Load("testdata/vault-force-zot-overgrown")

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

	store := g.scripts.Components()["world.zot_overgrown"]

	if store == nil || len(store.Entities()) < 2 {
		t.Fatal("source Zot map did not materialize its controller and targets")
	}

	var markerX, markerY int
	var controllerFound bool

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		role, _ := state.Get("role")

		if role == "controller" {
			x, _ := state.Get("x")
			y, _ := state.Get("y")
			markerX = int(x.(int64))
			markerY = int(y.(int64))
			controllerFound = true
			break
		}
	}

	if !controllerFound {
		t.Fatal("source Zot map has no saved LOS controller")
	}

	level := g.levels[1]
	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max
	started := false

	for radius := 0; radius <= 3 && !started; radius++ {
		for y := markerY - radius; y <= markerY+radius && !started; y++ {
			for x := markerX - radius; x <= markerX+radius && !started; x++ {
				if !level.Walkable(x, y) {
					continue
				}

				if _, occupied := level.ActorAt(x, y); occupied {
					continue
				}

				if err := level.MoveActor(g.player, x, y); err != nil {
					t.Fatal(err)
				}

				if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
					t.Fatal(err)
				}

				for _, entity := range store.Entities() {
					state, _ := store.Get(entity)
					role, _ := state.Get("role")

					if role == "controller" {
						active, _ := state.Get("started")
						started = active.(bool)
					}
				}
			}
		}
	}

	if !started {
		t.Fatal("player LOS did not start the saved Zot countdown")
	}

	var deadline int64

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		role, _ := state.Get("role")

		if role == "controller" {
			next, _ := state.Get("next_aut")
			deadline = next.(int64)
		}
	}

	if deadline <= int64(g.currentAut)+20 {
		t.Fatalf("source countdown deadline %d is too early", deadline)
	}

	// Spend real player turns to reach the middle of the source countdown.
	// The saved component must retain the same absolute deadline.
	midpoint := (int64(g.currentAut) + deadline) / 2

	for int64(g.currentAut) < midpoint {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	health.Max = 18
	health.Current = 18

	before := g.Snapshot()
	restored, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatalf("restore overgrown countdown: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Zot overgrown controller changed across restore")
	}

	restoredHealth, _ := restored.stores.Health.Get(restored.player)
	restoredHealth.Max = 10000
	restoredHealth.Current = restoredHealth.Max

	for int64(restored.currentAut) <= deadline+10 {
		if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	converted := false
	restoredStore := restored.scripts.Components()["world.zot_overgrown"]

	for _, entity := range restoredStore.Entities() {
		state, _ := restoredStore.Get(entity)
		role, _ := state.Get("role")

		if role == "controller" {
			count, _ := state.Get("count")
			converted = count.(int64) > 0
		}
	}

	if !converted {
		t.Fatal("restored source countdown did not convert a marked plant")
	}
}
