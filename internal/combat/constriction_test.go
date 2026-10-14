package combat

import "testing"

func TestConstrictDamageUsesACThenMonsterSpeed(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 4,
				value: 0,
			},

			{
				bound: 12,
				value: 0,
			},
		},
	}

	damage, err := ConstrictDamage(roller, 1, 6, 12)

	if err != nil ||
		damage != 1 ||
		len(roller.rolls) != 0 {
		t.Fatalf("constriction damage = %d, %v; rolls %+v", damage, err, roller.rolls)
	}
}

func TestConstrictEscapeAccumulatesAttemptDice(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 13,
				value: 12,
			},

			{
				bound: 13,
				value: 12,
			},

			{
				bound: 13,
				value: 12,
			},

			{
				bound: 13,
				value: 12,
			},

			{
				bound: 13,
				value: 12,
			},

			{
				bound: 4,
				value: 0,
			},

			{
				bound: 9,
				value: 0,
			},

			{
				bound: 9,
				value: 0,
			},

			{
				bound: 9,
				value: 0,
			},

			{
				bound: 9,
				value: 0,
			},

			{
				bound: 9,
				value: 0,
			},
		},
	}

	escaped, err := RollConstrictEscape(roller, 1, 1)

	if err != nil ||
		!escaped ||
		len(roller.rolls) != 0 {
		t.Fatalf("escape = %v, %v; rolls %+v", escaped, err, roller.rolls)
	}
}
