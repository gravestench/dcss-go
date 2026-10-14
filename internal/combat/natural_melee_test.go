package combat

import "testing"

func TestOrdinaryNaturalHitUsesBiteCombatPhases(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 19,
			},

			{
				bound: 100,
				value: 50,
			},

			{
				bound: 15,
				value: 0,
			},
		},
	}

	attack := NaturalAttack{
		HD:        1,
		Damage:    1,
		TypeID:    "AT_HIT",
		FlavourID: "AF_PLAIN",
	}

	outcome, err := ResolveNaturalAttack(roller, attack, Defense{})

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Kind != Hit ||
		outcome.Damage != 1 ||
		len(roller.rolls) != 0 {
		t.Fatalf("plain hit = %+v, remaining %+v", outcome, roller.rolls)
	}
}

func TestConstrictGrabUsesHitPhasesWithoutDirectDamageRolls(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 19,
			},

			{
				bound: 100,
				value: 50,
			},

			{
				bound: 15,
				value: 0,
			},
		},
	}

	grab := NaturalAttack{
		HD:        1,
		Damage:    1,
		TypeID:    "AT_CONSTRICT",
		FlavourID: "AF_CRUSH",
	}

	outcome, err := ResolveNaturalAttack(roller, grab, Defense{})

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Kind != Hit ||
		outcome.Damage != 0 ||
		len(roller.rolls) != 0 {
		t.Fatalf("grab = %+v, remaining rolls %+v", outcome, roller.rolls)
	}
}

func TestMonsterWeaponAddsAccuracyAndDamageInSourceOrder(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 26,
				value: 25,
			},

			{
				bound: 100,
				value: 50,
			},

			{
				bound: 15,
				value: 0,
			},

			{
				bound: 4,
				value: 3,
			},

			{
				bound: 3,
				value: 2,
			},
		},
	}

	attack := NaturalAttack{
		HD:        1,
		Damage:    1,
		TypeID:    "AT_HIT",
		FlavourID: "AF_PLAIN",

		Weapon: &MeleeWeapon{
			Damage: 4,
			Hit:    4,
			Plus:   2,
		},
	}

	outcome, err := ResolveNaturalAttack(roller, attack, Defense{})

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Kind != Hit ||
		outcome.Damage != 6 ||
		len(roller.rolls) != 0 {
		t.Fatalf("weapon hit = %+v, remaining rolls %+v", outcome, roller.rolls)
	}
}

func TestMonsterWeaponAcceptsSourceShortEnchantmentAbove100(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 125,
				value: 124,
			},

			{
				bound: 100,
				value: 50,
			},

			{
				bound: 15,
				value: 0,
			},

			{
				bound: 4,
				value: 0,
			},

			{
				bound: 102,
				value: 0,
			},
		},
	}

	attack := NaturalAttack{
		HD:        1,
		Damage:    1,
		TypeID:    "AT_HIT",
		FlavourID: "AF_PLAIN",

		Weapon: &MeleeWeapon{
			Damage: 4,
			Hit:    4,
			Plus:   101,
		},
	}

	outcome, err := ResolveNaturalAttack(roller, attack, Defense{})

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Kind != Hit || outcome.Damage != 1 {
		t.Fatalf("source-short enchanted weapon = %+v, %v", outcome, err)
	}
}
