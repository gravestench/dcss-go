package combat

import "testing"

func starterDelay(speed int, skill string) AttackDelayInput {
	return AttackDelayInput{
		WeaponSpeed:    speed,
		WeaponSkillID:  skill,
		WeaponSkill10:  20,
		ShieldEV:       -50,
		ShieldsSkill10: 30,
	}
}

func TestStartingWeaponsSampleOneSourceDistribution(t *testing.T) {
	for _, tc := range []struct {
		name, skill string
		speed, fast int
	}{
		{
			name:  "rapier",
			skill: "SK_SHORT_BLADES",
			speed: 12,
			fast:  11,
		},
		{
			name:  "flail",
			skill: "SK_MACES_FLAILS",
			speed: 14,
			fast:  13,
		},
		{
			name:  "war axe",
			skill: "SK_AXES",
			speed: 15,
			fast:  14,
		},
		{
			name:  "trident",
			skill: "SK_POLEARMS",
			speed: 13,
			fast:  12,
		},
		{
			name:  "long sword",
			skill: "SK_LONG_BLADES",
			speed: 14,
			fast:  13,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, boundary := range []struct {
				roll, want int
			}{
				{
					roll: 0,
					want: tc.fast,
				},
				{
					roll: 2399,
					want: tc.fast,
				},
				{
					roll: 2400,
					want: tc.fast + 1,
				},
				{
					roll: 3999,
					want: tc.fast + 1,
				},
			} {
				rng := &scriptedRoller{
					rolls: []scriptedRoll{
						{
							bound: 4000,
							value: boundary.roll,
						},
					},
				}
				got, err := PlayerAttackDelay(rng, starterDelay(tc.speed, tc.skill))

				if err != nil || got != boundary.want || len(rng.rolls) != 0 {
					t.Fatalf("roll %d: delay %d, err %v, rolls %+v, want %d", boundary.roll, got, err, rng.rolls, boundary.want)
				}
			}
		})
	}
}

func TestFractionalWeaponSkillCombinesBeforeOneDraw(t *testing.T) {
	in := starterDelay(12, "SK_SHORT_BLADES")
	in.WeaponSkill10 = 21

	for _, tc := range []struct {
		roll, want int
	}{
		{
			roll: 0,
			want: 10,
		},
		{
			roll: 119,
			want: 10,
		},
		{
			roll: 120,
			want: 11,
		},
		{
			roll: 2479,
			want: 11,
		},
		{
			roll: 2480,
			want: 12,
		},
		{
			roll: 3999,
			want: 12,
		},
	} {
		rng := &scriptedRoller{
			rolls: []scriptedRoll{
				{
					bound: 4000,
					value: tc.roll,
				},
			},
		}
		got, err := PlayerAttackDelay(rng, in)

		if err != nil || got != tc.want || len(rng.rolls) != 0 {
			t.Fatalf("roll %d: delay %d, err %v, rolls %+v, want %d", tc.roll, got, err, rng.rolls, tc.want)
		}
	}
}

func TestUnarmedSamplesOneCombinedSourceDistribution(t *testing.T) {
	in := AttackDelayInput{
		Unarmed:        true,
		WeaponSkillID:  "SK_UNARMED_COMBAT",
		WeaponSkill10:  20,
		ShieldEV:       -50,
		ShieldsSkill10: 30,
	}

	for _, tc := range []struct {
		roll, want int
	}{
		{
			roll: 0,
			want: 9,
		},
		{
			roll: 2399,
			want: 9,
		},
		{
			roll: 2400,
			want: 10,
		},
		{
			roll: 8079,
			want: 10,
		},
		{
			roll: 8080,
			want: 11,
		},
		{
			roll: 10799,
			want: 11,
		},
	} {
		rng := &scriptedRoller{
			rolls: []scriptedRoll{
				{
					bound: 10800,
					value: tc.roll,
				},
			},
		}
		got, err := PlayerAttackDelay(rng, in)

		if err != nil || got != tc.want || len(rng.rolls) != 0 {
			t.Fatalf("roll %d: delay %d, err %v, rolls %+v, want %d", tc.roll, got, err, rng.rolls, tc.want)
		}
	}
}

func TestAttackDelayRejectsUnsupportedInput(t *testing.T) {
	for _, in := range []AttackDelayInput{
		starterDelay(0, "SK_AXES"),
		starterDelay(12, "SK_RANGED_WEAPONS"),
		{
			Unarmed:       true,
			WeaponSkillID: "SK_UNARMED_COMBAT",
			WeaponSpeed:   12,
			ShieldEV:      -50,
		},
		{
			Unarmed:       true,
			WeaponSkillID: "SK_UNARMED_COMBAT",
			ShieldEV:      5,
		},
	} {
		if _, err := PlayerAttackDelay(&scriptedRoller{}, in); err == nil {
			t.Fatalf("accepted unsupported delay input %+v", in)
		}
	}
}
