package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestFlamingMonsterWeaponAddsUnresistedDamage(t *testing.T) {
	ordinary := monsterBrandHitDamage(t, "")
	flaming := monsterBrandHitDamage(t, "SPWPN_FLAMING")

	if flaming <= ordinary {
		t.Fatalf("flaming hit = %d, ordinary hit = %d", flaming, ordinary)
	}
}

func TestElectrocutionCanDamageAfterZeroDirectDamage(t *testing.T) {
	g := newStepGame(t)
	system := newCombatSystem(g)

	system.roller = &combatRoller{
		rolls: []combatRoll{
			{
				bound: 4,
				value: 0,
			},

			{
				bound: 13,
				value: 12,
			},
		},
	}

	victim := &ecs.Health{
		Current: 30,
		Max:     30,
	}

	if err := system.applyMonsterWeaponBrand(
		"SPWPN_ELECTROCUTION",
		0,
		"MONS_GOBLIN",
		"goblin",
		victim,
	); err != nil {
		t.Fatal(err)
	}

	if victim.Current != 10 ||
		len(g.turn.Events) != 1 ||
		g.turn.Events[0].Text != "You are electrocuted!!" {
		t.Fatalf("electrocution left HP %d and events %+v", victim.Current, g.turn.Events)
	}
}

func monsterBrandHitDamage(t *testing.T, brand string) int {
	t.Helper()

	g := newStepGame(t)
	monsterID, err := newOrdinaryMonsterFactory(g).Spawn(
		"MONS_HOBGOBLIN",
		1,
		2,
		1,
	)

	if err != nil {
		t.Fatal(err)
	}

	weaponID := giveTestMonsterWeapon(t, g, monsterID)
	weapon, found := g.stores.Items.Get(weaponID)

	if !found {
		t.Fatal("missing test weapon")
	}

	weapon.Ego = brand
	g.turn.Actor = monsterID

	playerHealth, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("missing player health")
	}

	*playerHealth = ecs.Health{
		Current: 100,
		Max:     100,
	}

	system := newCombatSystem(g)

	system.roller = maximumMeleeRoller{}

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	return 100 - playerHealth.Current
}
