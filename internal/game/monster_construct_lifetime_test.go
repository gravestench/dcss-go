package game

import (
	"reflect"
	"testing"
)

// A patrol can outlive both participants before the called beast gets a turn.
func TestCalledBeastSavesAfterCallerAndTargetDeath(t *testing.T) {
	g := newStepGame(t)
	caller, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	target, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["combat.called_beast"].Set(g.player, map[string]any{
		"target_id": int64(target),
		"x":         int64(10),
		"y":         int64(10),
	}); err != nil {
		t.Fatal(err)
	}

	g.world.DestroyEntity(caller)
	g.world.DestroyEntity(target)
	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("dead-target patrol changed during restore")
	}
}

// A portal marker remains saveable in the gap before the next player tick.
func TestMonsterGatewaySavesAfterTentacleDeath(t *testing.T) {
	g := newStepGame(t)
	marker, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	head, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	for _, phase := range []int64{0, 1} {

		if _, err := g.scripts.Components()["magic.summon_gateway"].Set(marker, map[string]any{
			"owner":       marker,
			"level_id":    int64(position.LevelID),
			"x":           int64(position.X),
			"y":           int64(position.Y),
			"phase":       phase,
			"tentacle_id": int64(head),
			"attitude":    "hostile",
		}); err != nil {
			t.Fatal(err)
		}

		g.world.DestroyEntity(head)
		before := g.Snapshot()
		loaded, err := Restore(before)

		if err != nil {
			t.Fatal(err)
		}

		if !reflect.DeepEqual(before, loaded.Snapshot()) {
			t.Fatal("gateway changed during restore")
		}

		loaded.Close()
	}
}
