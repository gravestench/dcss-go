package game

import (
	"reflect"
	"strings"
	"testing"
)

func chooseTeleportitisStreams(t *testing.T, g *Game) {
	t.Helper()

	triggered := false

	for state := uint64(0); state < 100000; state++ {
		probe := RestoreRNGStreams(g.seed, map[string]uint64{
			"mutation": state,
		})

		timeRoll, err := probe.Intn("mutation", 100)

		if err != nil {
			t.Fatal(err)
		}

		chanceRoll, err := probe.Intn("mutation", 16)

		if err != nil {
			t.Fatal(err)
		}

		if timeRoll < 10 && chanceRoll == 0 {
			g.rng.states["mutation"] = state
			triggered = true

			break
		}
	}

	if !triggered {
		t.Fatal("could not choose a teleportitis trigger stream")
	}

	for state := uint64(0); state < 100000; state++ {
		probe := RestoreRNGStreams(g.seed, map[string]uint64{
			"teleport": state,
		})

		x, err := probe.Intn("teleport", g.levels[1].width)

		if err != nil {
			t.Fatal(err)
		}

		y, err := probe.Intn("teleport", len(g.levels[1].terrain))

		if err != nil {
			t.Fatal(err)
		}

		trailTurns, err := probe.Intn("teleport", 3)

		if err != nil {
			t.Fatal(err)
		}

		// A one-turn source trail can dissipate in this same field step.
		if x == 3 &&
			y == 1 &&
			trailTurns > 0 {
			g.rng.states["teleport"] = state

			return
		}
	}

	t.Fatal("could not choose a teleportitis destination stream")
}

func TestTeleportitisMovesTowardMonsterAndRestores(t *testing.T) {
	g := newStepGame(t)
	addPlayerMutation(t, g, "MUT_TELEPORT")
	chooseTeleportitisStreams(t, g)

	result, err := g.Step(Command{
		Kind: CommandWait,
	})

	if err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.X != 3 || position.Y != 1 {
		t.Fatalf("teleportitis left player at %d,%d", position.X, position.Y)
	}

	announced := false

	for _, event := range result.Events {
		if strings.Contains(event.Text, "yanked towards") {
			announced = true
		}
	}

	if !announced {
		t.Fatalf("teleportitis had no source message: %+v", result.Events)
	}

	clouds := g.scripts.Components()["world.cloud"]
	foundTrail := false

	for _, entity := range clouds.Entities() {
		state, _ := clouds.Get(entity)
		kind, err := state.Get("kind_id")

		if err != nil {
			t.Fatal(err)
		}

		if kind == "CLOUD_TLOC_ENERGY" {
			foundTrail = true
		}
	}

	if !foundTrail {
		t.Fatal("teleportitis left no translocation cloud")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	loaded, _ := restored.stores.Positions.Get(restored.player)

	if loaded.X != position.X ||
		loaded.Y != position.Y ||
		len(restored.scripts.Components()["world.cloud"].Entities()) == 0 {
		t.Fatal("restore lost teleport destination or translocation cloud")
	}

	if !reflect.DeepEqual(restored.rng.States(), g.rng.States()) {
		t.Fatal("restore changed the teleportitis RNG continuation")
	}
}
