package monster

import (
	"fmt"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
)

type energyRoller struct {
	value int
	calls int
}

func (r *energyRoller) Intn(stream string, bound int) (int, error) {
	if stream != "monster_energy" || bound != 10 {
		return 0, fmt.Errorf("unexpected energy draw %q/%d", stream, bound)
	}

	r.calls++

	return r.value, nil
}

func TestActionEnergyGrantUsesSourceRandomRounding(t *testing.T) {
	for _, test := range []struct {
		name  string
		speed int
		aut   int
		roll  int
		want  int
		calls int
	}{
		{
			name:  "rat exact grant",
			speed: 10,
			aut:   10,
			want:  10,
		},

		{
			name:  "jackal rounds down",
			speed: 14,
			aut:   9,
			roll:  6,
			want:  12,
			calls: 1,
		},

		{
			name:  "jackal rounds up",
			speed: 14,
			aut:   9,
			roll:  5,
			want:  13,
			calls: 1,
		},

		{
			name:  "minimum one",
			speed: 1,
			aut:   1,
			roll:  9,
			want:  1,
			calls: 1,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			roller := &energyRoller{value: test.roll}
			grant, err := GainActionEnergy(roller, test.speed, test.aut)

			if err != nil ||
				grant != test.want || roller.calls != test.calls {
				t.Fatalf("gain = %d, draws = %d, error = %v", grant, roller.calls, err)
			}
		})
	}
}

func TestActionEnergyRejectsInvalidInputs(t *testing.T) {
	for _, input := range [][2]int{
		{0, 10},
		{10, 0},
		{-1, 10},
	} {
		if _, err := GainActionEnergy(&energyRoller{}, input[0], input[1]); err == nil {
			t.Fatalf("accepted speed %d and aut %d", input[0], input[1])
		}
	}

	if _, err := GainActionEnergy(&energyRoller{value: 10}, 14, 9); err == nil {
		t.Fatal("accepted an out-of-range energy draw")
	}
}

func TestActionEnergyCostUsesResolvedIntent(t *testing.T) {
	usage := content.MonsterEnergy{
		Move:   10,
		Swim:   6,
		Attack: 8,
	}

	for _, test := range []struct {
		intent ecs.IntentKind
		want   int
	}{
		{
			intent: ecs.IntentMove,
			want:   10,
		},

		{
			intent: ecs.IntentMelee,
			want:   8,
		},

		{
			intent: ecs.IntentWait,
			want:   6,
		},
	} {
		cost, err := ActionEnergyCost(usage, test.intent)

		if err != nil ||
			cost != test.want {
			t.Fatalf("intent %d cost = %d, %v; want %d", test.intent, cost, err, test.want)
		}
	}

	if _, err := ActionEnergyCost(usage, ecs.IntentQuaff); err == nil {
		t.Fatal("accepted unsupported monster intent")
	}
}
