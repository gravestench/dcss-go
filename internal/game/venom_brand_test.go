package game

import (
	"reflect"
	"testing"

	"github.com/gravestench/akara"
)

func TestGoblinVenomWeaponPoisonsPlayerAndSurvivesSave(t *testing.T) {
	g := newGeneratedTestGame(t, 73)
	seed, _, _ := seedForEarlyGear(
		t,
		g.catalog,
		"MONS_GOBLIN",
		1,
		"WPN_DAGGER",
		"",
	)

	g.rng = NewRNGStreams(seed)

	level := g.levels[1]
	cell := firstOpenMonsterCell(t, level)
	goblin, err := newOrdinaryMonsterFactory(g).Spawn(
		"MONS_GOBLIN",
		1,
		cell.x,
		cell.y,
	)

	if err != nil {
		t.Fatal(err)
	}

	level.initialActors++
	setMonsterPrimaryBrand(t, g, goblin, "SPWPN_VENOM")

	g.turn.Actor = goblin

	system := newCombatSystem(g)

	system.roller = maximumMeleeRoller{}

	playerHealth, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("missing player health")
	}

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	poison, found := g.stores.Poison.Get(g.player)

	if !found ||
		poison.AmountScaled < 6000 ||
		poison.SourceMonsterID != "MONS_GOBLIN" {
		t.Fatalf("goblin venom = %+v, present %v", poison, found)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("goblin venom state changed on restore")
	}
}

func TestUnportedMonsterBrandRejectsAttackBeforeDamage(t *testing.T) {
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

	weapon.Ego = "SPWPN_ELECTROCUTION"
	g.turn.Actor = monsterID

	playerHealth, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("missing player health")
	}

	beforeHP := playerHealth.Current
	system := newCombatSystem(g)

	system.roller = maximumMeleeRoller{}

	if err := system.resolveMonsterMelee(playerHealth); err == nil {
		t.Fatal("unported electrocution brand attacked as mundane")
	}

	if playerHealth.Current != beforeHP {
		t.Fatal("unported brand changed player health")
	}
}

func TestProtectionWeaponAddsFiveMonsterArmour(t *testing.T) {
	attack := func(brand string) int {
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

		victim, found := g.stores.Health.Get(monsterID)

		if !found {
			t.Fatal("missing monster health")
		}

		beforeHP := victim.Current
		system := newCombatSystem(g)

		system.roller = maximumMeleeRoller{}

		if err := system.resolvePlayerMelee(monsterID, victim); err != nil {
			t.Fatal(err)
		}

		return beforeHP - victim.Current
	}

	ordinary := attack("")
	protected := attack("SPWPN_PROTECTION")

	if protected >= ordinary {
		t.Fatalf("protection damage = %d, ordinary damage = %d", protected, ordinary)
	}
}

func TestAlternateMeleeProtectionAddsArmourBehindSling(t *testing.T) {
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

	giveTestMonsterItem(t, g, monsterID, "WPN_SLING", "weapon", 1)
	daggerID := giveTestMonsterItem(
		t,
		g,
		monsterID,
		"WPN_DAGGER",
		"alternate_weapon",
		1,
	)

	dagger, found := g.stores.Items.Get(daggerID)

	if !found {
		t.Fatal("missing alternate dagger")
	}

	dagger.Ego = "SPWPN_PROTECTION"

	bonus, err := newCombatSystem(g).monsterProtectionAC(monsterID)

	if err != nil {
		t.Fatal(err)
	}

	if bonus != 5 {
		t.Fatalf("alternate protection AC = %d, want 5", bonus)
	}
}

func setMonsterPrimaryBrand(
	t *testing.T,
	g *Game,
	monsterID akara.Entity,
	brand string,
) {
	t.Helper()

	for _, itemID := range g.stores.CarriedBy.Entities() {
		carrier, found := g.stores.CarriedBy.Get(itemID)

		if !found || carrier.Holder != monsterID {
			continue
		}

		slot, found := g.stores.Equipped.Get(itemID)

		if !found || slot.Slot != "weapon" {
			continue
		}

		item, found := g.stores.Items.Get(itemID)

		if !found {
			t.Fatal("monster weapon has no item")
		}

		item.Ego = brand

		return
	}

	t.Fatal("monster has no primary weapon")
}
