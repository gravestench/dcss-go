package game

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
)

// A queued ordinary retribution belongs to saved player worship, so replay
// after restoration spends the same event on the same god-time firing.
func TestQueuedOrdinaryWrathContinuesAfterRestore(t *testing.T) {
	g := newStepGame(t)
	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player lacks worship state")
	}

	for field, value := range map[string]any{
		"penance":            map[string]any{"GOD_SIF_MUNA": int64(8)},
		"wrath_count":        int64(1),
		"wrath_xp_remaining": int64(4),
		"next_god_time_aut":  int64(g.currentAut) + 10,
	} {
		if err := worship.Set(field, value); err != nil {
			t.Fatal(err)
		}
	}

	before := g.Snapshot()
	loaded, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("restore changed queued wrath before its god-time check")
	}

	liveResult, liveErr := g.Step(Command{Kind: CommandWait})
	loadedResult, loadedErr := loaded.Step(Command{Kind: CommandWait})

	if liveErr != nil || loadedErr != nil {
		t.Fatalf("wrath wait errors: live=%v restored=%v",
			liveErr, loadedErr)
	}

	if !reflect.DeepEqual(liveResult.Events, loadedResult.Events) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("queued wrath diverged after restore")
	}

	state, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("wrath removed player worship state")
	}

	count, err := state.Get("wrath_count")

	if err != nil {
		t.Fatal(err)
	}

	if count != int64(0) {
		t.Fatalf("god time left %v queued wrath events", count)
	}
}

// The ordinary kill path, not a test policy call, must feed the same saved
// wrath queue that god time later consumes.
func TestCreditedRatKillQueuesOrdinaryWrath(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	worship, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("player lacks worship state")
	}

	if err := worship.Set("penance", map[string]any{
		"GOD_TROG": int64(8),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)
	health.Current = 1

	playerHealth, _ := g.stores.Health.Get(g.player)
	playerHealth.Current = 100
	playerHealth.Max = 100

	for attempt := 0; attempt < 100 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(rat) {
		t.Fatal("rat survived 100 attacks")
	}

	state, found := g.scripts.Components()["religion.worship"].Get(g.player)

	if !found {
		t.Fatal("kill removed worship state")
	}

	count, err := state.Get("wrath_count")

	if err != nil {
		t.Fatal(err)
	}

	if count != int64(1) {
		t.Fatalf("credited kill queued %v wrath events, want one", count)
	}
}

// A forged negative counter cannot change future wrath probability after
// restore; both counters have a nonnegative source domain.
func TestRestoreRejectsNegativeOrdinaryWrathCounter(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	found := false

	for entityIndex := range snapshot.Entities {
		for partIndex := range snapshot.Entities[entityIndex].Dynamic {
			part := &snapshot.Entities[entityIndex].Dynamic[partIndex]

			if part.Schema != "religion.worship" {
				continue
			}

			part.Values["wrath_count"] = json.RawMessage(`-1`)
			found = true
		}
	}

	if !found {
		t.Fatal("snapshot has no saved worship state")
	}

	loaded, err := Restore(snapshot)

	if loaded != nil {
		loaded.Close()
	}

	if err == nil || !strings.Contains(err.Error(), "invalid worship piety state") {
		t.Fatalf("negative wrath count restored: %v", err)
	}
}
