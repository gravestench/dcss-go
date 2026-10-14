package combat

import "testing"

func TestGoblinSlingShotUsesSourcePhaseOrder(t *testing.T) {
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

			{
				bound: 7,
				value: 6,
			},
		},
	}

	shot := MonsterShot{
		HD:            1,
		WeaponDamage:  7,
		NaturalDamage: 1,
	}

	outcome, err := ResolveMonsterShot(roller, shot, Defense{})

	if err != nil ||
		outcome.Kind != Hit ||
		outcome.Damage != 7 ||
		len(roller.rolls) != 0 {
		t.Fatalf("sling shot = %+v, remaining %+v: %v", outcome, roller.rolls, err)
	}
}

func TestGoblinSlingShotCanBeBlockedBeforeDamage(t *testing.T) {
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

			{
				bound: 20,
				value: 19,
			},

			{
				bound: 21,
				value: 20,
			},
		},
	}

	shot := MonsterShot{
		HD:            1,
		WeaponDamage:  7,
		NaturalDamage: 1,
	}

	defense := Defense{ShieldClass: 10}
	outcome, err := ResolveMonsterShot(roller, shot, defense)

	if err != nil ||
		outcome.Kind != Block ||
		outcome.ShieldBlocks != 1 ||
		len(roller.rolls) != 0 {
		t.Fatalf("blocked shot = %+v, remaining %+v: %v", outcome, roller.rolls, err)
	}
}

func TestGoblinSlingShotCanMissEvasion(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 0,
			},

			{
				bound: 24,
				value: 23,
			},

			{
				bound: 25,
				value: 24,
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

	shot := MonsterShot{
		HD:            1,
		WeaponDamage:  7,
		NaturalDamage: 1,
	}

	outcome, err := ResolveMonsterShot(roller, shot, Defense{EV: 12})

	if err != nil ||
		outcome.Kind != Dodge ||
		len(roller.rolls) != 0 {
		t.Fatalf("dodged shot = %+v, remaining %+v: %v", outcome, roller.rolls, err)
	}
}

func TestKoboldStoneThrowUsesProjectileDamage(t *testing.T) {
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

			{
				bound: 2,
				value: 1,
			},
		},
	}

	shot := MonsterShot{
		HD:               1,
		ProjectileDamage: 2,
		NaturalDamage:    1,
	}

	outcome, err := ResolveMonsterShot(roller, shot, Defense{})

	if err != nil ||
		outcome.Kind != Hit ||
		outcome.Damage != 2 ||
		len(roller.rolls) != 0 {
		t.Fatalf("stone throw = %+v, remaining %+v: %v", outcome, roller.rolls, err)
	}
}

func TestKoboldStoneGDRIncludesFirstAttackDamage(t *testing.T) {
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

			{
				bound: 2,
				value: 1,
			},

			{
				bound: 11,
				value: 0,
			},
		},
	}

	shot := MonsterShot{
		HD:               1,
		ProjectileDamage: 2,
		NaturalDamage:    1,
	}

	defense := Defense{
		AC:  10,
		GDR: 34,
	}

	outcome, err := ResolveMonsterShot(roller, shot, defense)

	if err != nil ||
		outcome.Kind != Hit ||
		outcome.Damage != 1 ||
		len(roller.rolls) != 0 {
		t.Fatalf("stone GDR = %+v, remaining %+v: %v", outcome, roller.rolls, err)
	}
}

func TestKoboldPoisonDartRollsDurationInsteadOfDamage(t *testing.T) {
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

			{
				bound: 8,
				value: 7,
			},
		},
	}

	outcome, poison, err := ResolveMonsterPoisonDart(roller, 1, Defense{})

	if err != nil ||
		outcome.Kind != Hit ||
		outcome.Damage != 0 ||
		poison != 13 ||
		len(roller.rolls) != 0 {
		t.Fatalf("poison dart = %+v, poison %d, remaining %+v: %v",
			outcome, poison, roller.rolls, err)
	}
}
