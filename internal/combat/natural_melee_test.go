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
