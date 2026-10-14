package character

import (
	"fmt"
	"testing"
)

type hasteDraw struct {
	stream string
	bound  int
	value  int
}

type hasteRoller struct {
	draws []hasteDraw
}

func (r *hasteRoller) Intn(stream string, bound int) (int, error) {
	if len(r.draws) == 0 ||
		r.draws[0].stream != stream ||
		r.draws[0].bound != bound {
		return 0, fmt.Errorf("unexpected haste draw %s/%d", stream, bound)
	}

	value := r.draws[0].value
	r.draws = r.draws[1:]

	return value, nil
}

func TestHastePotionCutsNominalTurnsAndCapsRefresh(t *testing.T) {
	for _, test := range []struct {
		name    string
		old     int
		roll    int
		round   int
		want    int
		message string
	}{
		{
			name:    "new haste rounds 40 turns up",
			old:     0,
			roll:    0,
			round:   0,
			want:    270,
			message: "You feel yourself speed up.",
		},

		{
			name:    "new haste rounds 40 turns down",
			old:     0,
			roll:    0,
			round:   2,
			want:    260,
			message: "You feel yourself speed up.",
		},

		{
			name:    "refresh caps at 40 turns",
			old:     350,
			roll:    39,
			round:   2,
			want:    400,
			message: "You feel as though your hastened speed will last longer.",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			rng := &hasteRoller{
				draws: []hasteDraw{
					{
						stream: "potion",
						bound:  40,
						value:  test.roll,
					},

					{
						stream: "potion",
						bound:  3,
						value:  test.round,
					},
				},
			}

			got, message, err := HastePotionDuration(rng, test.old)

			if err != nil ||
				got != test.want ||
				message != test.message ||
				len(rng.draws) != 0 {
				t.Fatalf("haste = %d, %q, %v; remaining draws %+v", got, message, err, rng.draws)
			}
		})
	}
}

func TestHastedActionTimeUsesSourceSixOrSevenAut(t *testing.T) {
	for _, test := range []struct {
		roll int
		want int
	}{
		{
			roll: 0,
			want: 7,
		},

		{
			roll: 2,
			want: 6,
		},
	} {
		rng := &hasteRoller{
			draws: []hasteDraw{
				{
					stream: "speed",
					bound:  3,
					value:  test.roll,
				},
			},
		}

		got, err := PlayerActionTime(rng, true)

		if err != nil ||
			got != test.want || len(rng.draws) != 0 {
			t.Fatalf("speed roll %d = %d, %v", test.roll, got, err)
		}
	}

	got, err := PlayerActionTime(nil, false)

	if err != nil || got != 10 {
		t.Fatalf("unhasted action = %d, %v", got, err)
	}
}

func TestHasteWarnsAndExpiresAfterAFinalFastAction(t *testing.T) {
	rng := &hasteRoller{
		draws: []hasteDraw{
			{
				stream: "speed",
				bound:  2,
				value:  0,
			},
		},
	}

	remaining, message, err := DecayHaste(rng, 65, 7)

	if err != nil ||
		remaining != 48 ||
		message != "Your extra speed is starting to run out." {
		t.Fatalf("warning = %d, %q, %v", remaining, message, err)
	}

	remaining, message, err = DecayHaste(nil, 11, 14)

	if err != nil ||
		remaining != 1 || message != "" {
		t.Fatalf("last active action = %d, %q, %v", remaining, message, err)
	}

	remaining, message, err = DecayHaste(nil, remaining, 6)

	if err != nil ||
		remaining != 0 || message != "You feel yourself slow down." {
		t.Fatalf("expiry = %d, %q, %v", remaining, message, err)
	}
}

func TestHasteRejectsInvalidDurationWithoutDrawing(t *testing.T) {
	rng := &hasteRoller{}

	if _, _, err := HastePotionDuration(rng, -1); err == nil {
		t.Fatal("negative haste accepted")
	}

	if _, _, err := HastePotionDuration(rng, 401); err == nil {
		t.Fatal("over-cap haste accepted")
	}

	if _, _, err := DecayHaste(rng, 1, -1); err == nil {
		t.Fatal("negative action cost accepted")
	}
}
