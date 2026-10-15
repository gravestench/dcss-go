package game

import (
	"reflect"
	"testing"
)

func poweredByDeathState(t *testing.T, g *Game) (int64, int64) {
	t.Helper()

	store := g.scripts.Components()["character.powered_by_death"]
	state, found := store.Get(g.player)

	if !found {
		t.Fatal("player lacks Powered by Death state")
	}

	strength, err := state.Get("strength")

	if err != nil {
		t.Fatal(err)
	}

	remaining, err := state.Get("remaining_aut")

	if err != nil {
		t.Fatal(err)
	}

	return strength.(int64), remaining.(int64)
}

func TestPoweredByDeathRegeneratesAndContinuesAfterSave(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	moveRatToOtherFloor(t, g)

	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		mutation,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_POWERED_BY_DEATH",
			"acquired":    int64(2),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.powered_by_death"].Set(
		g.player,
		map[string]any{
			"strength":      int64(2),
			"remaining_aut": int64(40),
		},
	); err != nil {
		t.Fatal(err)
	}

	health, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("player lacks health")
	}

	health.Current = max(1, health.Max-5)

	before := health.Current

	first, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	strength, remaining := poweredByDeathState(t, g)

	if strength != 2 || remaining != 40-int64(first.Spent) {
		t.Fatalf("Powered by Death after turn = %d/%d", strength, remaining)
	}

	if health.Current <= before {
		t.Fatalf("Powered by Death did not heal: %d to %d", before, health.Current)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Powered by Death changed across save and restore")
	}

	second, err := restored.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	strength, after := poweredByDeathState(t, restored)

	if strength != 2 || after != remaining-int64(second.Spent) {
		t.Fatalf("restored Powered by Death = %d/%d", strength, after)
	}
}

func TestPlayerKillActivatesPoweredByDeath(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	mutation, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["character.mutation"].Set(
		mutation,
		map[string]any{
			"owner":       g.player,
			"mutation_id": "MUT_POWERED_BY_DEATH",
			"acquired":    int64(3),
		},
	); err != nil {
		t.Fatal(err)
	}

	rat := ratID(t, g)
	ratHealth, found := g.stores.Health.Get(rat)

	if !found {
		t.Fatal("fixture rat lacks health")
	}

	ratHealth.Current = 1

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 12 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(rat) {
		t.Fatal("player did not kill the one-HP fixture rat")
	}

	strength, remaining := poweredByDeathState(t, g)

	if strength <= 0 ||
		strength > 3 ||
		remaining <= 0 ||
		remaining > 50 {
		t.Fatalf("kill Powered by Death state = %d/%d", strength, remaining)
	}
}
