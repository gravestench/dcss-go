package game

import (
	"reflect"
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

func firstFloorHobgoblin(t *testing.T) (*Game, akara.Entity) {
	t.Helper()

	for seed := uint64(1); seed <= 16; seed++ {
		g := newGeneratedTestGame(t, seed)

		for _, monster := range g.stores.AI.Entities() {
			actor, _ := g.stores.Actors.Get(monster)
			position, _ := g.stores.Positions.Get(monster)

			if actor.KindID == "MONS_HOBGOBLIN" && position.LevelID == 1 {
				return g, monster
			}
		}
	}

	t.Fatal("generated Dungeon:1 has no hobgoblin")

	return nil, 0
}

func TestPainBrandCanProcFromGeneratedHobgoblinTurn(t *testing.T) {
	g, monster := firstFloorHobgoblin(t)
	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_PAIN"

	health, _ := g.stores.Health.Get(g.player)
	var agonized bool

	for attempt := 0; attempt < 150 && !agonized; attempt++ {
		placePlayerBesideMonster(t, g, monster)

		health.Current = health.Max

		for _, entity := range g.stores.MonsterEnergy.Entities() {
			energy, _ := g.stores.MonsterEnergy.Get(entity)

			energy.Points = 0

			if entity == monster {
				energy.Points = 70
			}
		}

		result, err := g.Step(Command{Kind: CommandWait})

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "writhe in agony") {
				agonized = true
			}
		}
	}

	if !agonized {
		t.Fatal("HD 1 hobgoblin never applied the pain brand")
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("pain turn changed across save and restore")
	}
}
