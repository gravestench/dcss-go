package combat

import "testing"

func starterDelay(speed int, skill string) AttackDelayInput {
	return AttackDelayInput{WeaponSpeed: speed, WeaponSkillID: skill,
		WeaponSkill10: 20, ShieldEV: -50, ShieldsSkill10: 30}
}

func TestStartingWeaponsUseSourceSpeedAndBucklerRounding(t *testing.T) {
	for _, tc := range []struct {
		name, skill string
		speed, want int
	}{
		{"rapier", "SK_SHORT_BLADES", 12, 11},
		{"flail", "SK_MACES_FLAILS", 14, 13},
		{"war axe", "SK_AXES", 15, 14},
		{"trident", "SK_POLEARMS", 13, 12},
		{"long sword", "SK_LONG_BLADES", 14, 13},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: []scriptedRoll{{20, 19}}}
			got, err := PlayerAttackDelay(rng, starterDelay(tc.speed, tc.skill))
			if err != nil || got != tc.want || len(rng.rolls) != 0 {
				t.Fatalf("delay = %d, err %v, rolls %+v, want %d", got, err, rng.rolls, tc.want)
			}
		})
	}
}

func TestRapierBucklerPenaltyAndFractionalSkillDrawOrder(t *testing.T) {
	in := starterDelay(12, "SK_SHORT_BLADES")
	rng := &scriptedRoller{rolls: []scriptedRoll{{20, 0}}}
	got, err := PlayerAttackDelay(rng, in)
	if err != nil || got != 12 || len(rng.rolls) != 0 {
		t.Fatalf("buckler-penalized delay = %d, %v, %+v", got, err, rng.rolls)
	}
	in.WeaponSkill10 = 21
	rng = &scriptedRoller{rolls: []scriptedRoll{{20, 0}, {20, 19}}}
	got, err = PlayerAttackDelay(rng, in)
	if err != nil || got != 10 || len(rng.rolls) != 0 {
		t.Fatalf("fractional-skill delay = %d, %v, %+v", got, err, rng.rolls)
	}
}

func TestUnarmedDelayUsesSeparateSkillRoundBeforeShield(t *testing.T) {
	in := AttackDelayInput{Unarmed: true, WeaponSkillID: "SK_UNARMED_COMBAT",
		WeaponSkill10: 20, ShieldEV: -50, ShieldsSkill10: 30}
	for _, tc := range []struct {
		name  string
		rolls []scriptedRoll
		want  int
	}{
		{"fast", []scriptedRoll{{54, 0}, {20, 19}}, 9},
		{"cancelled", []scriptedRoll{{54, 0}, {20, 0}}, 10},
		{"slow", []scriptedRoll{{54, 53}, {20, 0}}, 11},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: tc.rolls}
			got, err := PlayerAttackDelay(rng, in)
			if err != nil || got != tc.want || len(rng.rolls) != 0 {
				t.Fatalf("delay = %d, err %v, rolls %+v", got, err, rng.rolls)
			}
		})
	}
}

func TestAttackDelayRejectsUnsupportedInput(t *testing.T) {
	for _, in := range []AttackDelayInput{
		starterDelay(0, "SK_AXES"),
		starterDelay(12, "SK_RANGED_WEAPONS"),
		{Unarmed: true, WeaponSkillID: "SK_UNARMED_COMBAT", WeaponSpeed: 12, ShieldEV: -50},
		{Unarmed: true, WeaponSkillID: "SK_UNARMED_COMBAT", ShieldEV: 5},
	} {
		if _, err := PlayerAttackDelay(&scriptedRoller{}, in); err == nil {
			t.Fatalf("accepted unsupported delay input %+v", in)
		}
	}
}
