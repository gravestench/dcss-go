package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

// A live Maurice melee steals gold into a monster-carried item. The same
// wallet and item state must survive the normal snapshot and restore path.
func TestMauriceMeleeStealsGoldAndRestores(t *testing.T) {
	g := newStepGame(t)
	maurice := ratID(t, g)
	actor, found := g.stores.Actors.Get(maurice)

	if !found {
		t.Fatal("scenario monster has no actor")
	}

	actor.KindID = "MONS_MAURICE"
	placePlayerBesideMonster(t, g, maurice)
	playerHealth, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("scenario player has no health")
	}

	if _, err := g.scripts.Components()["character.wallet"].Set(
		g.player,
		map[string]any{
			"gold": int64(500),
		},
	); err != nil {
		t.Fatal(err)
	}

	stolen := false

	for attempt := 0; attempt < 100 && !stolen; attempt++ {
		// Keep the valid character profile intact across repeated rolls.
		playerHealth.Current = playerHealth.Max

		_, err := g.runAction(maurice, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		wallet, found := g.scripts.Components()["character.wallet"].Get(g.player)

		if !found {
			t.Fatal("player wallet vanished")
		}

		gold, err := wallet.Get("gold")

		if err != nil {
			t.Fatal(err)
		}

		stolen = gold != int64(500)
	}

	if !stolen {
		t.Fatal("Maurice did not steal gold in 100 live melee contacts")
	}

	carriedGold := false

	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(entity)
		item, found := g.stores.Items.Get(entity)

		if carrier.Holder == maurice && found &&
			item.KindID == "OBJ_GOLD" {
			carriedGold = true
		}
	}

	if !carriedGold {
		t.Fatal("stolen gold is not carried by Maurice")
	}

	// The fixed scenario's roster records a rat. Restore that catalog ID
	// before saving while leaving the stolen item on its actual carrier.
	actor.KindID = "MONS_RAT"
	energy, found := g.stores.MonsterEnergy.Get(maurice)

	if !found {
		t.Fatal("Maurice has no action energy")
	}

	energy.Points = 80

	if err := g.scheduler.Spend(maurice, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	after := loaded.Snapshot()

	if !reflect.DeepEqual(snapshot.Entities, after.Entities) ||
		!reflect.DeepEqual(snapshot.RNG, after.RNG) {
		t.Fatal("stolen item, wallet, or RNG changed on restore")
	}
}
