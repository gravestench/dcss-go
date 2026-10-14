package character

import "testing"

func TestOrdinaryMonsterExperienceMatchesSourceIntegerStages(t *testing.T) {
	for _, tc := range []struct {
		name string
		in   OrdinaryMonsterXPInput
		want int
	}{
		{"rat floor", OrdinaryMonsterXPInput{
			HitDice:      1,
			MaxHP:        4,
			Speed:        10,
			Modifier:     1,
			AttackDamage: [4]int{3},
		}, 1},
		{"quokka speed", OrdinaryMonsterXPInput{
			HitDice:      1,
			MaxHP:        8,
			Speed:        12,
			Modifier:     10,
			AttackDamage: [4]int{5},
		}, 2},
		{"large melee", OrdinaryMonsterXPInput{
			HitDice:      5,
			MaxHP:        40,
			Speed:        10,
			Modifier:     10,
			AttackDamage: [4]int{15, 25},
		}, 151},
		{"fast large melee", OrdinaryMonsterXPInput{
			HitDice:      5,
			MaxHP:        40,
			Speed:        12,
			Modifier:     10,
			AttackDamage: [4]int{15, 25},
		}, 201},
		{"fast regeneration and slow", OrdinaryMonsterXPInput{
			HitDice:      5,
			MaxHP:        40,
			Speed:        7,
			Modifier:     10,
			AttackDamage: [4]int{5},
			FastRegen:    true,
		}, 56},
		{"high value stepdowns", OrdinaryMonsterXPInput{
			HitDice:  20,
			MaxHP:    100,
			Speed:    10,
			Modifier: 10,
		}, 1209},
		{"zero modifier skips stage", OrdinaryMonsterXPInput{
			HitDice:  1,
			MaxHP:    4,
			Speed:    10,
			Modifier: 0,
		}, 2},
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
		func(in *OrdinaryMonsterXPInput) { in.HitDice = 0 },
		func(in *OrdinaryMonsterXPInput) { in.MaxHP = 0 },
		func(in *OrdinaryMonsterXPInput) { in.MaxHP = 10001 },
		func(in *OrdinaryMonsterXPInput) { in.Speed = 0 },
		func(in *OrdinaryMonsterXPInput) { in.Modifier = -1 },
		func(in *OrdinaryMonsterXPInput) { in.AttackDamage[3] = -1 },
	} {
		in := base
		edit(&in)
		if _, err := OrdinaryMonsterExperience(in); err == nil {
			t.Fatalf("accepted invalid stats %+v", in)
		}
	}
}
