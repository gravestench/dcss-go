package character

import "testing"

func TestHumanPoisonDecayMatchesSourceRateRegions(t *testing.T) {
	tests := []struct {
		name       string
		amount     int
		elapsedAut int
		wantAmount int
		wantDamage int
	}{
		{
			name:       "minimum rate",
			amount:     4000,
			elapsedAut: 10,
			wantAmount: 3000,
			wantDamage: 1,
		},
		{
			name:       "ordinary exponential rate",
			amount:     100000,
			elapsedAut: 10,
			wantAmount: 80000,
			wantDamage: 20,
		},
		{
			name:       "maximum rate",
			amount:     500000,
			elapsedAut: 10,
			wantAmount: 450000,
			wantDamage: 50,
		},
		{
			name:       "partial action",
			amount:     2000,
			elapsedAut: 5,
			wantAmount: 1500,
			wantDamage: 1,
		},
		{
			name:       "status ends below one point",
			amount:     1000,
			elapsedAut: 10,
			wantAmount: 0,
			wantDamage: 1,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			amount, damage, err := DecayHumanPoison(
				test.amount,
				test.elapsedAut,
			)

			if err != nil || amount != test.wantAmount || damage != test.wantDamage {
				t.Fatalf(
					"decay = %d amount, %d damage, %v; want %d, %d",
					amount,
					damage,
					err,
					test.wantAmount,
					test.wantDamage,
				)
			}
		})
	}
}

func TestHumanPoisonDecayRejectsInvalidInputs(t *testing.T) {
	for _, input := range []struct {
		amount int
		aut    int
	}{
		{
			amount: 999,
			aut:    10,
		},
		{
			amount: 2147483648,
			aut:    10,
		},
		{
			amount: 1000,
			aut:    0,
		},
	} {
		if _, _, err := DecayHumanPoison(input.amount, input.aut); err == nil {
			t.Fatalf("accepted poison %d over %d aut", input.amount, input.aut)
		}
	}
}
