package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
)

func TestVampiricBrandHealsWoundedMonsterOnHumanHit(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	monster := ratID(t, g)
	actor, _ := g.stores.Actors.Get(monster)

	actor.KindID = "MONS_HOBGOBLIN"
	placePlayerBesideMonster(t, g, monster)

	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_VAMPIRISM"

	monsterHealth, _ := g.stores.Health.Get(monster)

	monsterHealth.Current = 1
	monsterHealth.Max = 10

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Max = 100
	var healedMessage bool

	for attempt := 0; attempt < 100 && monsterHealth.Current == 1; attempt++ {
		playerHealth.Current = 100

		events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			if strings.Contains(event.Text, "draws strength from your wounds") {
				healedMessage = true
			}
		}
	}

	if monsterHealth.Current <= 1 || !healedMessage {
		t.Fatalf("vampiric hit left health %+v, message %t",
			monsterHealth, healedMessage)
	}
}
