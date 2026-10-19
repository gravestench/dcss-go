package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/modfs"
)

func TestSamePathLuaBrandOverrideChangesCombatAndHash(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/venom-brand-mod")

	if err != nil {
		t.Fatal(err)
	}

	if bundled.Hash() == modded.Hash() {
		t.Fatal("Lua brand override kept the bundled ruleset hash")
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		modded,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	monster := ratID(t, g)
	actor, _ := g.stores.Actors.Get(monster)

	actor.KindID = "MONS_HOBGOBLIN"

	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_VENOM"

	placePlayerBesideMonster(t, g, monster)
	playerHealth, _ := g.stores.Health.Get(g.player)

	for attempt := 0; attempt < 100; attempt++ {
		playerHealth.Current = playerHealth.Max

		events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			if strings.Contains(event.Text, "modded venom takes hold") {
				return
			}
		}
	}

	t.Fatal("same-path Lua brand override never controlled a hit")
}
