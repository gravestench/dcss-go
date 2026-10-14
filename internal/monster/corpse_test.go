package monster

import (
	"fmt"
	"testing"
)

type corpseRoll struct {
	bound, value int
}
type corpseRoller struct {
	rolls []corpseRoll
}

func (r *corpseRoller) Intn(stream string, bound int) (int, error) {
	if stream != "corpse" || len(r.rolls) == 0 || r.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected %s roll %d: %+v", stream, bound, r.rolls)
	}

	value := r.rolls[0].value
	r.rolls = r.rolls[1:]

	return value, nil
}

func TestRatCorpseDropRolls(t *testing.T) {
	for _, tc := range []struct {
		rolls       []corpseRoll
		want        int
		wantDropped bool
	}{
		{
			rolls: []corpseRoll{
				{
					bound: 2,
					value: 1,
				},
			},
			want:        0,
			wantDropped: false,
		},
		{
			rolls: []corpseRoll{
				{
					bound: 2,
					value: 0,
				},
				{
					bound: 255,
					value: 0,
				},
			},
			want:        1,
			wantDropped: true,
		},
		{
			rolls: []corpseRoll{
				{
					bound: 2,
					value: 0,
				},
				{
					bound: 255,
					value: 254,
				},
			},
			want:        255,
			wantDropped: true,
		},
	} {
		r := &corpseRoller{rolls: tc.rolls}
		appearance, dropped, err := RollCorpse(r)

		if err != nil || appearance != tc.want || dropped != tc.wantDropped || len(r.rolls) != 0 {
			t.Fatalf("roll %+v => %d/%v/%v, left %+v", tc.rolls, appearance, dropped, err, r.rolls)
		}
	}
}

func TestRatCorpseDecayAndSkeleton(t *testing.T) {
	r := &corpseRoller{
		rolls: []corpseRoll{
			{
				bound: 255,
				value: 9,
			},
		},
	}
	kind, freshness, appearance, alive, err := AgeCorpse(r, "CORPSE_BODY", 110, 200)

	if err != nil || !alive || kind != "CORPSE_BODY" || freshness != 100 || appearance != 0 {
		t.Fatalf("first decay %q %d %d %v %v", kind, freshness, appearance, alive, err)
	}

	kind, freshness, appearance, alive, err = AgeCorpse(r, kind, freshness, 2000)

	if err != nil || !alive || kind != "CORPSE_SKELETON" || freshness != 110 || appearance != 10 || len(r.rolls) != 0 {
		t.Fatalf("skeleton %q %d %d %v %v", kind, freshness, appearance, alive, err)
	}

	kind, freshness, _, alive, err = AgeCorpse(r, kind, freshness, 2200)

	if err != nil || alive {
		t.Fatalf("expired skeleton %q %d %v %v", kind, freshness, alive, err)
	}
}
