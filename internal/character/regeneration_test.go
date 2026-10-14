package character

import (
	"fmt"
	"testing"
)

type regenRoll struct {
	bound int
	value int
}

type regenRoller struct {
	rolls []regenRoll
}

func (r *regenRoller) Intn(stream string, bound int) (int, error) {
	if stream != "regeneration" || len(r.rolls) == 0 || r.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected %s/%d; remaining %+v", stream, bound, r.rolls)
	}

	value := r.rolls[0].value
	r.rolls = r.rolls[1:]

	return value, nil
}

func TestOrdinaryHumanFighterRegenerationRates(t *testing.T) {
	state := Vitality{
		HP:    7,
		MaxHP: 18,
		MP:    0,
		MaxMP: 1,
	}

	got, err := Regenerate(&regenRoller{}, state, 10)

	if err != nil || got.HP != 7 || got.HPProgress != 6 || got.MP != 0 || got.MPProgress != 7 {
		t.Fatalf("one turn regen = %+v, %v", got, err)
	}

	for range 16 {
		got, err = Regenerate(&regenRoller{}, got, 10)

		if err != nil {
			t.Fatal(err)
		}
	}

	if got.HP != 8 || got.HPProgress != 2 || got.MP != 1 || got.MPProgress != 5 {
		t.Fatalf("17 turns regen = %+v", got)
	}
}

func TestRegenFullHPAccumulatesButFullMPFreezes(t *testing.T) {
	state := Vitality{
		HP:         18,
		MaxHP:      18,
		MP:         1,
		MaxMP:      1,
		HPProgress: 95,
		MPProgress: 95,
	}

	got, err := Regenerate(&regenRoller{}, state, 10)

	if err != nil || got.HP != 18 || got.HPProgress != 1 || got.MP != 1 || got.MPProgress != 95 {
		t.Fatalf("full vitals regen = %+v, %v", got, err)
	}
}

func TestRegenVariableAutUsesHPThenMPRounding(t *testing.T) {
	rng := &regenRoller{
		rolls: []regenRoll{
			{
				bound: 10,
				value: 0,
			},
			{
				bound: 10,
				value: 9,
			},
		},
	}

	state := Vitality{
		HP:         10,
		MaxHP:      18,
		MP:         0,
		MaxMP:      1,
		HPProgress: 94,
		MPProgress: 94,
	}

	got, err := Regenerate(rng, state, 9)

	if err != nil || got.HP != 11 || got.HPProgress != 0 || got.MP != 1 || got.MPProgress != 0 || len(rng.rolls) != 0 {
		t.Fatalf("9-aut regen = %+v, %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestRegenCanRestoreSeveralPointsAndRejectsBadState(t *testing.T) {
	state := Vitality{
		HP:         10,
		MaxHP:      18,
		MP:         0,
		MaxMP:      3,
		HPProgress: 95,
		MPProgress: 95,
	}

	got, err := Regenerate(&regenRoller{}, state, 200)

	if err != nil || got.HP != 12 || got.HPProgress != 15 || got.MP != 2 || got.MPProgress != 55 {
		t.Fatalf("long action regen = %+v, %v", got, err)
	}

	for _, bad := range []Vitality{
		{
			HP:    -1,
			MaxHP: 18,
			MP:    0,
			MaxMP: 1,
		},
		{
			HP:         18,
			MaxHP:      18,
			MP:         1,
			MaxMP:      1,
			HPProgress: 100,
		},
		{
			HP:         18,
			MaxHP:      18,
			MP:         1,
			MaxMP:      1,
			MPProgress: -1,
		},
	} {
		if _, err := Regenerate(&regenRoller{}, bad, 10); err == nil {
			t.Fatalf("accepted invalid vitality %+v", bad)
		}
	}

	if _, err := Regenerate(&regenRoller{}, state, -1); err == nil {
		t.Fatal("negative aut accepted")
	}
}
