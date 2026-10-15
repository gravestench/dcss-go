package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestAntimagicBrandDrainsPlayerMagicOnDamagingHit(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	monster := ratID(t, g)
	actor, _ := g.stores.Actors.Get(monster)

	actor.KindID = "MONS_HOBGOBLIN"
	placePlayerBesideMonster(t, g, monster)

	weaponID := giveTestMonsterWeapon(t, g, monster)
	weapon, _ := g.stores.Items.Get(weaponID)

	weapon.Ego = "SPWPN_ANTIMAGIC"

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Current = 20
	magic.Max = 20

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 100
	var warning bool

	for attempt := 0; attempt < 100 && magic.Current == 20; attempt++ {
		health.Current = 100

		events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			if strings.Contains(event.Text, "power leaking away") {
				warning = true
			}
		}
	}

	if magic.Current >= 20 || !warning {
		t.Fatalf("antimagic left %d MP, warning %t", magic.Current, warning)
	}
}
