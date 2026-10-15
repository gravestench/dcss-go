package game

import (
	"sort"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestEveryEarlyMeleeBrandCompletesAHit(t *testing.T) {
	catalog := testCatalog(t)
	weaponByBrand := make(map[string]string)

	for _, weaponID := range []string{
		"WPN_CLUB",
		"WPN_WHIP",
		"WPN_DAGGER",
		"WPN_SHORT_SWORD",
	} {
		weapon, err := catalog.Item(weaponID)

		if err != nil {
			t.Fatal(err)
		}

		for _, weight := range weapon.Weapon.BrandWeights {
			if weight.Weight > 0 && weaponByBrand[weight.BrandID] == "" {
				weaponByBrand[weight.BrandID] = weaponID
			}
		}
	}

	brands := make([]string, 0, len(weaponByBrand))

	for brand := range weaponByBrand {
		brands = append(brands, brand)
	}

	sort.Strings(brands)

	for _, brand := range brands {
		t.Run(brand, func(t *testing.T) {
			g := newStepGame(t)
			monster := ratID(t, g)
			actor, _ := g.stores.Actors.Get(monster)

			actor.KindID = "MONS_HOBGOBLIN"
			placePlayerBesideMonster(t, g, monster)

			weaponID := giveTestMonsterItem(t, g, monster,
				weaponByBrand[brand], "weapon", 1)
			weapon, _ := g.stores.Items.Get(weaponID)

			if brand != "SPWPN_NORMAL" {
				weapon.Ego = brand
			}

			monsterHealth, _ := g.stores.Health.Get(monster)
			playerHealth, _ := g.stores.Health.Get(g.player)

			monsterHealth.Current = 100
			monsterHealth.Max = 100
			playerHealth.Max = 100

			for attempt := 0; attempt < 100; attempt++ {
				playerHealth.Current = playerHealth.Max

				events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

				if err != nil {
					t.Fatal(err)
				}

				for _, event := range events {
					if strings.Contains(event.Text, "hobgoblin hits you") {
						return
					}
				}
			}

			t.Fatal("brand did not complete a monster hit")
		})
	}
}

func TestEveryEarlySlingBrandCompletesAShot(t *testing.T) {
	catalog := testCatalog(t)
	sling, err := catalog.Item("WPN_SLING")

	if err != nil {
		t.Fatal(err)
	}

	for _, weight := range sling.Weapon.BrandWeights {
		if weight.Weight <= 0 {
			continue
		}

		t.Run(weight.BrandID, func(t *testing.T) {
			for seed := uint64(1); seed <= 40; seed++ {
				g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

				if err != nil {
					t.Fatal(err)
				}

				monster, launcherID := equipTestGoblinSling(t, g)
				launcher, _ := g.stores.Items.Get(launcherID)

				if weight.BrandID != "SPWPN_NORMAL" {
					launcher.Ego = weight.BrandID
				}

				events, err := g.runAction(monster, ecs.Intent{}, 10, "monster")

				if err != nil {
					g.Close()
					t.Fatal(err)
				}

				g.Close()

				for _, event := range events {
					if strings.Contains(event.Text, "sling bullet hits you") {
						return
					}
				}
			}

			t.Fatal("brand did not complete a monster sling shot")
		})
	}
}
