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
		HD:           1,
		WeaponDamage: 7,
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
		HD:           1,
		WeaponDamage: 7,
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
		HD:           1,
		WeaponDamage: 7,
	}

	outcome, err := ResolveMonsterShot(roller, shot, Defense{EV: 12})

	if err != nil ||
		outcome.Kind != Dodge ||
		len(roller.rolls) != 0 {
		t.Fatalf("dodged shot = %+v, remaining %+v: %v", outcome, roller.rolls, err)
	}
}
