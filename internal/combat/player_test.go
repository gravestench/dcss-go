package combat

import "testing"

func fighterFlailAttack() PlayerAttackInput {
	return PlayerAttackInput{
		Strength:         16,
		Dexterity:        12,
		FightingSkill100: 300,
		WeaponSkill100:   200,
		WeaponSkillID:    "SK_MACES_FLAILS",
		WeaponDamage:     8,
		WeaponHit:        1,
		DefenderEV:       10,
		DefenderAC:       1,
	}
}

func TestPlayerMeleeMissAndAutomaticOverrides(t *testing.T) {
	for _, tc := range []struct {
		name  string
		rolls []scriptedRoll
		want  OutcomeKind
	}{
		{
			name: "ordinary miss",
			rolls: []scriptedRoll{
				{
					bound: 400,
					value: 0,
				},

				{
					bound: 300,
					value: 0,
				},

				{
					bound: 22,
					value: 0,
				},

				{
					bound: 100,
					value: 10,
				},

				{
					bound: 15,
					value: 0,
				},
			},
			want: Miss,
		},

		{
			name: "automatic miss",
			rolls: []scriptedRoll{
				{
					bound: 400,
					value: 0,
				},

				{
					bound: 300,
					value: 0,
				},

				{
					bound: 22,
					value: 21,
				},

				{
					bound: 100,
					value: 0,
				},

				{
					bound: 2,
					value: 0,
				},

				{
					bound: 25,
					value: 0,
				},
			},
			want: Miss,
		},

		{
			name: "automatic hit",
			rolls: []scriptedRoll{
				{
					bound: 400,
					value: 0,
				},

				{
					bound: 300,
					value: 0,
				},

				{
					bound: 22,
					value: 0,
				},

				{
					bound: 100,
					value: 0,
				},

				{
					bound: 2,
					value: 1,
				},

				{
					bound: 15,
					value: 0,
				},

				{
					bound: 10,
					value: 9,
				},

				{
					bound: 201,
					value: 0,
				},

				{
					bound: 301,
					value: 0,
				},

				{
					bound: 2,
					value: 0,
				},

				{
					bound: 2,
					value: 1,
				},
			},
			want: Hit,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: tc.rolls}
			got, err := PlayerMelee(rng, fighterFlailAttack())

			if err != nil ||
				got.Kind != tc.want || len(rng.rolls) != 0 {
				t.Fatalf("attack = %+v, err %v, rolls %+v", got, err, rng.rolls)
			}
		})
	}
}

func TestPlayerMeleeWeaponDamageAndRatArmour(t *testing.T) {
	for _, tc := range []struct {
		name       string
		damageRoll int
		acRoll     int
		want       int
	}{
		{
			name:       "absorbed",
			damageRoll: 1,
			acRoll:     1,
			want:       0,
		},

		{
			name:       "damaging",
			damageRoll: 9,
			acRoll:     0,
			want:       9,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{
				rolls: []scriptedRoll{
					{
						bound: 400,
						value: 300,
					},

					{
						bound: 300,
						value: 200,
					},

					{
						bound: 27,
						value: 26,
					},

					{
						bound: 100,
						value: 10,
					},

					{
						bound: 28,
						value: 0,
					},

					{
						bound: 10,
						value: tc.damageRoll,
					},

					{
						bound: 201,
						value: 200,
					},

					{
						bound: 301,
						value: 300,
					},

					{
						bound: 2,
						value: tc.acRoll,
					},

					{
						bound: 2,
						value: 1,
					},
				},
			}

			got, err := PlayerMelee(rng, fighterFlailAttack())

			if err != nil ||
				got.Kind != Hit ||
				got.Damage != tc.want ||
				len(rng.rolls) != 0 {
				t.Fatalf("attack = %+v, err %v, rolls %+v", got, err, rng.rolls)
			}
		})
	}
}

func TestPlayerMeleeUnarmedUsesNormalFormBaseAndNoWeaponSkillMultiplier(t *testing.T) {
	in := fighterFlailAttack()

	in.Unarmed = true
	in.WeaponSkillID = "SK_UNARMED_COMBAT"
	in.UnarmedSkill256 = 513

	in.WeaponDamage = 0
	in.WeaponHit = 0

	rng := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 400,
				value: 0,
			},

			{
				bound: 300,
				value: 0,
			},

			{
				bound: 23,
				value: 22,
			},

			{
				bound: 100,
				value: 10,
			},

			{
				bound: 26,
				value: 0,
			},

			{
				bound: 256,
				value: 0,
			},

			{
				bound: 7,
				value: 6,
			},

			{
				bound: 301,
				value: 0,
			},

			{
				bound: 2,
				value: 0,
			},

			{
				bound: 2,
				value: 1,
			},
		},
	}

	got, err := PlayerMelee(rng, in)

	if err != nil ||
		got.Kind != Hit ||
		got.Damage != 6 ||
		len(rng.rolls) != 0 {
		t.Fatalf("unarmed attack = %+v, err %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestPlayerMeleeMightBonusAfterDamageAndBeforeArmour(t *testing.T) {
	in := fighterFlailAttack()

	in.Mighty = true

	rng := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 400,
				value: 300,
			},

			{
				bound: 300,
				value: 200,
			},

			{
				bound: 27,
				value: 26,
			},

			{
				bound: 100,
				value: 10,
			},

			{
				bound: 28,
				value: 0,
			},

			{
				bound: 10,
				value: 9,
			},

			{
				bound: 201,
				value: 200,
			},

			{
				bound: 301,
				value: 300,
			},

			{
				bound: 10,
				value: 4,
			},

			{
				bound: 2,
				value: 1,
			},

			{
				bound: 2,
				value: 1,
			},
		},
	}

	got, err := PlayerMelee(rng, in)

	if err != nil ||
		got.Kind != Hit ||
		got.Damage != 13 ||
		len(rng.rolls) != 0 {
		t.Fatalf("mighty hit = %+v, %v; rolls %+v", got, err, rng.rolls)
	}

	rng = &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 400,
				value: 0,
			},

			{
				bound: 300,
				value: 0,
			},

			{
				bound: 22,
				value: 0,
			},

			{
				bound: 100,
				value: 10,
			},

			{
				bound: 15,
				value: 0,
			},
		},
	}

	got, err = PlayerMelee(rng, in)

	if err != nil ||
		got.Kind != Miss || len(rng.rolls) != 0 {
		t.Fatalf("mighty miss = %+v, %v; rolls %+v", got, err, rng.rolls)
	}
}

func TestPlayerMeleeMightRollPrecedesEnchantmentRoll(t *testing.T) {
	in := fighterFlailAttack()

	in.Mighty = true
	in.WeaponPlus = 2

	rng := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 400,
				value: 300,
			},

			{
				bound: 300,
				value: 200,
			},

			{
				bound: 29,
				value: 28,
			},

			{
				bound: 100,
				value: 10,
			},

			{
				bound: 29,
				value: 0,
			},

			{
				bound: 10,
				value: 9,
			},

			{
				bound: 201,
				value: 200,
			},

			{
				bound: 301,
				value: 300,
			},

			{
				bound: 10,
				value: 4,
			},

			{
				bound: 3,
				value: 2,
			},

			{
				bound: 2,
				value: 1,
			},

			{
				bound: 2,
				value: 1,
			},
		},
	}

	got, err := PlayerMelee(rng, in)

	if err != nil ||
		got.Kind != Hit ||
		got.Damage != 15 ||
		len(rng.rolls) != 0 {
		t.Fatalf("enchanted mighty hit = %+v, %v; rolls %+v", got, err, rng.rolls)
	}
}
