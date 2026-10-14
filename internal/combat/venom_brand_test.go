package combat

import "testing"

func TestVenomBrandPoisonAmountFollowsSourceDrawOrder(t *testing.T) {
	tests := []struct {
		name       string
		damageDone int
		rolls      []scriptedRoll
		want       int
	}{
		{
			name:       "one in four misses",
			damageDone: 4,
			rolls: []scriptedRoll{
				{
					bound: 4,
					value: 0,
				},
			},
		},

		{
			name:       "positive hit adds both source rolls",
			damageDone: 6,
			rolls: []scriptedRoll{
				{
					bound: 4,
					value: 1,
				},

				{
					bound: 8,
					value: 7,
				},

				{
					bound: 9,
					value: 8,
				},
			},
			want: 21,
		},

		{
			name:       "zero damage still poisons",
			damageDone: 0,
			rolls: []scriptedRoll{
				{
					bound: 4,
					value: 3,
				},

				{
					bound: 8,
					value: 7,
				},
			},
			want: 13,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			roller := &scriptedRoller{
				rolls: test.rolls,
			}

			got, err := VenomBrandPoisonAmount(roller, test.damageDone)

			if err != nil {
				t.Fatal(err)
			}

			if got != test.want || len(roller.rolls) != 0 {
				t.Fatalf("venom amount = %d, %v; remaining rolls %+v", got, err, roller.rolls)
			}
		})
	}
}
