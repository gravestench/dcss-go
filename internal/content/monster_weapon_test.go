package content

import "testing"

func TestCommittedMonsterWeaponsAreCompleteAndCopied(t *testing.T) {
	catalog, err := LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	if len(catalog.primaryMonsterWeapons) != 162 ||
		len(catalog.secondaryMonsterWeapons) != 16 {
		t.Fatalf("incomplete monster weapons: %d primary, %d secondary",
			len(catalog.primaryMonsterWeapons), len(catalog.secondaryMonsterWeapons))
	}

	goblin, found := catalog.MonsterWeapon("MONS_GOBLIN", false)

	if !found ||
		goblin.Weapons[0].ID != "WPN_DAGGER" ||
		goblin.Weapons[1].ID != "WPN_CLUB" {
		t.Fatalf("unexpected goblin choices: %+v", goblin)
	}

	goblin.Weapons[0].ID = "WPN_MACE"

	if again, _ := catalog.MonsterWeapon("MONS_GOBLIN", false); again.Weapons[0].ID != "WPN_DAGGER" {
		t.Fatal("catalog choice mutated through caller")
	}

	pikel, found := catalog.MonsterWeapon("MONS_PIKEL", false)

	if !found || pikel.Brands[0].ID != "SPWPN_FLAMING" {
		t.Fatalf("missing source brand choices: %+v", pikel)
	}

	pikel.Brands[0].ID = "SPWPN_VENOM"

	if again, _ := catalog.MonsterWeapon("MONS_PIKEL", false); again.Brands[0].ID != "SPWPN_FLAMING" {
		t.Fatal("catalog brand mutated through caller")
	}

	if _, found := catalog.MonsterWeapon("MONS_HOBGOBLIN", false); found {
		t.Fatal("invented a hobgoblin table entry")
	}

	secondary, found := catalog.MonsterWeapon("MONS_ORC_KNIGHT", true)

	if !found || secondary.Weapons[1].ID != "NUM_WEAPONS" {
		t.Fatalf("lost secondary no-weapon choice: %+v", secondary)
	}
}
