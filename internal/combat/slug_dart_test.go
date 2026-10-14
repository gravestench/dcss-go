package combat

import (
	"fmt"
	"testing"
)

type spellDraw struct {
	bound int
	value int
}

type spellRoller struct {
	draws []spellDraw
}

func (r *spellRoller) Intn(stream string, bound int) (int, error) {
	if stream != "monster_spell" ||
		len(r.draws) == 0 ||
		r.draws[0].bound != bound {
		return 0, fmt.Errorf("unexpected draw %q/%d: %+v", stream, bound, r.draws)
	}

	value := r.draws[0].value

	r.draws = r.draws[1:]

	return value, nil
}

func TestSlugDartShieldPrecedesEvasion(t *testing.T) {
	roller := &spellRoller{
		draws: []spellDraw{
			{
				bound: 23,
				value: 0,
			},

			{
				bound: 20,
				value: 15,
			},

			{
				bound: 21,
				value: 15,
			},
		},
	}

	outcome, err := ResolveSlugDart(roller, 1, Defense{
		EV:           10,
		ShieldClass:  10,
		ShieldBlocks: 1,
	})

	if err != nil ||
		outcome.Kind != Block ||
		outcome.ShieldBlocks != 2 ||
		len(roller.draws) != 0 {
		t.Fatalf("shield result %+v, remaining %+v: %v", outcome, roller.draws, err)
	}
}

func TestSlugDartMissAndArmouredHit(t *testing.T) {
	cases := []struct {
		name    string
		defense Defense
		draws   []spellDraw
		kind    OutcomeKind
		damage  int
	}{
		{
			name: "miss",
			defense: Defense{
				EV: 10,
			},
			draws: []spellDraw{
				{
					bound: 14,
					value: 0,
				},

				{
					bound: 10,
					value: 9,
				},

				{
					bound: 11,
					value: 10,
				},
			},
			kind: Miss,
		},

		{
			name: "armoured hit",
			defense: Defense{
				EV: 1,
				AC: 2,
			},
			draws: []spellDraw{
				{
					bound: 14,
					value: 13,
				},

				{
					bound: 2,
					value: 0,
				},

				{
					bound: 3,
					value: 2,
				},

				{
					bound: 3,
					value: 1,
				},

				{
					bound: 3,
					value: 2,
				},
			},
			kind:   Hit,
			damage: 3,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			roller := &spellRoller{draws: tc.draws}
			outcome, err := ResolveSlugDart(roller, 1, tc.defense)

			if err != nil ||
				outcome.Kind != tc.kind ||
				outcome.Damage != tc.damage ||
				len(roller.draws) != 0 {
				t.Fatalf("result %+v, remaining %+v: %v", outcome, roller.draws, err)
			}
		})
	}
}

func TestSlugDartMonsterPowerExceedsPlayerCap(t *testing.T) {
	roller := &spellRoller{
		draws: []spellDraw{
			{
				bound: 15,
				value: 14,
			},

			{
				bound: 2,
				value: 0,
			},

			{
				bound: 4,
				value: 3,
			},

			{
				bound: 4,
				value: 3,
			},
		},
	}

	outcome, err := ResolveSlugDart(roller, 3, Defense{EV: 1})

	if err != nil ||
		outcome.Kind != Hit ||
		outcome.Damage != 8 ||
		len(roller.draws) != 0 {
		t.Fatalf("HD3 dart %+v, remaining %+v: %v", outcome, roller.draws, err)
	}
}
