package game

import (
	"testing"
)

// Maximum rolls make the weapon's added damage observable after Fighter AC.
type maximumMeleeRoller struct{}

func (maximumMeleeRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" || bound < 1 {
		return 0, errUnexpectedMeleeRoll(stream, bound)
	}

	return bound - 1, nil
}

func TestEquippedHobgoblinWeaponChangesMeleeDamage(t *testing.T) {
	attack := func(equipped bool) int {
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

		if equipped {
			weaponID := giveTestMonsterWeapon(t, g, monsterID)
			weapon, _ := g.stores.Items.Get(weaponID)

			weapon.Plus = 10
		}

		fighter, found := g.stores.Health.Get(g.player)

		if !found {
			t.Fatal("player has no health")
		}

		before := fighter.Current

		g.turn.Actor = monsterID

		system := newCombatSystem(g)

		system.roller = maximumMeleeRoller{}

		if err := system.resolveMonsterMelee(fighter); err != nil {
			t.Fatal(err)
		}

		return before - fighter.Current
	}

	unarmed := attack(false)
	armed := attack(true)

	if armed <= unarmed {
		t.Fatalf("equipped dagger dealt %d, bare hit dealt %d", armed, unarmed)
	}
}
