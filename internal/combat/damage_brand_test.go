package combat

import "testing"

func TestUnresistedWeaponDamageBrandsFollowSourceRolls(t *testing.T) {
	tests := []struct {
		name       string
		brand      string
		damageDone int
		rolls      []scriptedRoll
		want       int
	}{
		{
			name:       "flaming",
			brand:      "SPWPN_FLAMING",
			damageDone: 6,
			rolls: []scriptedRoll{
				{
					bound: 6,
					value: 5,
				},
			},
			want: 3,
		},

		{
			name:       "freezing with one damage has no draw",
			brand:      "SPWPN_FREEZING",
			damageDone: 1,
			want:       1,
		},

		{
			name:       "vorpal",
			brand:      "SPWPN_VORPAL",
			damageDone: 6,
			rolls: []scriptedRoll{
				{
					bound: 6,
					value: 5,
				},
			},
			want: 2,
		},

		{
			name:       "electrocution triggers",
			brand:      "SPWPN_ELECTROCUTION",
			damageDone: 0,
			rolls: []scriptedRoll{
				{
					bound: 4,
					value: 0,
				},

				{
					bound: 13,
					value: 12,
				},
			},
			want: 20,
		},

		{
			name:       "electrocution misses",
			brand:      "SPWPN_ELECTROCUTION",
			damageDone: 6,
			rolls: []scriptedRoll{
				{
					bound: 4,
					value: 1,
				},
			},
		},

		{
			name:       "flaming needs direct damage",
			brand:      "SPWPN_FLAMING",
			damageDone: 0,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			roller := &scriptedRoller{
				rolls: test.rolls,
			}

			got, err := UnresistedWeaponBrandBonus(
				roller,
				test.brand,
				test.damageDone,
			)

			if err != nil {
				t.Fatal(err)
			}

			if got != test.want || len(roller.rolls) != 0 {
				t.Fatalf("bonus = %d, want %d; rolls %+v", got, test.want, roller.rolls)
			}
		})
	}
}
