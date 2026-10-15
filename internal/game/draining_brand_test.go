package game

import (
	"encoding/json"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func TestDrainingBrandLowersSavedPlayerMaxHP(t *testing.T) {
	var g *Game
	var monster akara.Entity

	for seed := uint64(1); seed <= 3 && g == nil; seed++ {
		candidate := newGeneratedTestGame(t, seed)

		for _, entity := range candidate.stores.AI.Entities() {
			actor, _ := candidate.stores.Actors.Get(entity)

			if actor.KindID == "MONS_HOBGOBLIN" {
				g = candidate
				monster = entity
				break
			}
		}
	}

	if g == nil {
		t.Fatal("generated Dungeon has no hobgoblin")
	}

	placePlayerBesideMonster(t, g, monster)

	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_DRAINING"

	health, _ := g.stores.Health.Get(g.player)
	startingMax := health.Max

	for attempt := 0; attempt < 100 && health.Max == startingMax; attempt++ {
		health.Current = health.Max

		if _, err := g.runAction(monster, ecs.Intent{}, 10, "monster"); err != nil {
			t.Fatal(err)
		}
	}

	if health.Max >= startingMax {
		t.Fatal("draining brand did not lower max HP")
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	stored, _ := loaded.stores.Health.Get(loaded.player)
	drain, found := loaded.scripts.Components()["status.drain"].Get(loaded.player)

	if !found {
		t.Fatal("drain component was not restored")
	}

	amount, err := drain.Get("amount")

	if err != nil {
		t.Fatal(err)
	}

	if stored.Max != health.Max ||
		amount != int64(startingMax-health.Max) {
		t.Fatalf("drain changed on restore: live %+v, saved %+v, amount %v",
			health, stored, amount)
	}
}

func TestRestoreRejectsInvalidLuaDrain(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		if snapshot.Entities[index].ID != uint64(g.player) {
			continue
		}

		snapshot.Entities[index].Dynamic = append(
			snapshot.Entities[index].Dynamic,
			save.DynamicComponentRecord{
				Schema: "status.drain",
				Values: map[string]json.RawMessage{
					"amount": json.RawMessage("0"),
				},
			},
		)
		break
	}

	loaded, err := Restore(snapshot)

	if loaded != nil {
		defer loaded.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "invalid player HP drain") {
		t.Fatalf("invalid Lua drain restore error = %v", err)
	}
}
