package character

import "testing"

func TestOrdinaryMonsterExperienceMatchesSourceIntegerStages(t *testing.T) {
	for _, tc := range []struct {
		name string
		in   OrdinaryMonsterXPInput
		want int
	}{
		{
			name: "rat floor",
			in: OrdinaryMonsterXPInput{
				HitDice:      1,
				MaxHP:        4,
				Speed:        10,
				Modifier:     1,
				AttackDamage: [4]int{3},
			},
			want: 1,
		},
		{
			name: "quokka speed",
			in: OrdinaryMonsterXPInput{
				HitDice:      1,
				MaxHP:        8,
				Speed:        12,
				Modifier:     10,
				AttackDamage: [4]int{5},
			},
			want: 2,
		},
		{
			name: "large melee",
			in: OrdinaryMonsterXPInput{
				HitDice:      5,
				MaxHP:        40,
				Speed:        10,
				Modifier:     10,
				AttackDamage: [4]int{15, 25},
			},
			want: 151,
		},
		{
			name: "fast large melee",
			in: OrdinaryMonsterXPInput{
				HitDice:      5,
				MaxHP:        40,
				Speed:        12,
				Modifier:     10,
				AttackDamage: [4]int{15, 25},
			},
			want: 201,
		},
		{
			name: "fast regeneration and slow",
			in: OrdinaryMonsterXPInput{
				HitDice:      5,
				MaxHP:        40,
				Speed:        7,
				Modifier:     10,
				AttackDamage: [4]int{5},
				FastRegen:    true,
			},
			want: 56,
		},
		{
			name: "high value stepdowns",
			in: OrdinaryMonsterXPInput{
				HitDice:  20,
				MaxHP:    100,
				Speed:    10,
				Modifier: 10,
			},
			want: 1209,
		},
		{
			name: "zero modifier skips stage",
			in: OrdinaryMonsterXPInput{
				HitDice:  1,
				MaxHP:    4,
				Speed:    10,
				Modifier: 0,
			},
			want: 2,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := OrdinaryMonsterExperience(tc.in)

			if err != nil || got != tc.want {
				t.Fatalf("XP = %d, %v; want %d", got, err, tc.want)
			}
		})
	}
}

func TestOrdinaryMonsterExperienceRejectsInvalidStats(t *testing.T) {
	base := OrdinaryMonsterXPInput{
		HitDice:  1,
		MaxHP:    4,
		Speed:    10,
		Modifier: 10,
	}

	for _, edit := range []func(*OrdinaryMonsterXPInput){
		func(in *OrdinaryMonsterXPInput) {
			in.HitDice = 0
		},
		func(in *OrdinaryMonsterXPInput) {
			in.MaxHP = 0
		},
		func(in *OrdinaryMonsterXPInput) {
			in.MaxHP = 10001
		},
		func(in *OrdinaryMonsterXPInput) {
			in.Speed = 0
		},
		func(in *OrdinaryMonsterXPInput) {
			in.Modifier = -1
		},
		func(in *OrdinaryMonsterXPInput) {
			in.AttackDamage[3] = -1
		},
	} {
		in := base
		edit(&in)

		if _, err := OrdinaryMonsterExperience(in); err == nil {
			t.Fatalf("accepted invalid stats %+v", in)
		}
	}
}
