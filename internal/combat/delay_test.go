package combat

import "testing"

func starterDelay(speed int, skill string) AttackDelayInput {
	return AttackDelayInput{WeaponSpeed: speed, WeaponSkillID: skill,
		WeaponSkill10: 20, ShieldEV: -50, ShieldsSkill10: 30}
}

func TestStartingWeaponsSampleOneSourceDistribution(t *testing.T) {
	for _, tc := range []struct {
		name, skill string
		speed, fast int
	}{
		{"rapier", "SK_SHORT_BLADES", 12, 11},
		{"flail", "SK_MACES_FLAILS", 14, 13},
		{"war axe", "SK_AXES", 15, 14},
		{"trident", "SK_POLEARMS", 13, 12},
		{"long sword", "SK_LONG_BLADES", 14, 13},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, boundary := range []struct{ roll, want int }{
				{0, tc.fast}, {2399, tc.fast}, {2400, tc.fast + 1}, {3999, tc.fast + 1},
			} {
				rng := &scriptedRoller{rolls: []scriptedRoll{{4000, boundary.roll}}}
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
	for _, tc := range []struct{ roll, want int }{
		{0, 10}, {119, 10}, {120, 11}, {2479, 11}, {2480, 12}, {3999, 12},
	} {
		rng := &scriptedRoller{rolls: []scriptedRoll{{4000, tc.roll}}}
		got, err := PlayerAttackDelay(rng, in)
		if err != nil || got != tc.want || len(rng.rolls) != 0 {
			t.Fatalf("roll %d: delay %d, err %v, rolls %+v, want %d", tc.roll, got, err, rng.rolls, tc.want)
		}
	}
}

func TestUnarmedSamplesOneCombinedSourceDistribution(t *testing.T) {
	in := AttackDelayInput{Unarmed: true, WeaponSkillID: "SK_UNARMED_COMBAT",
		WeaponSkill10: 20, ShieldEV: -50, ShieldsSkill10: 30}
	for _, tc := range []struct{ roll, want int }{
		{0, 9}, {2399, 9}, {2400, 10}, {8079, 10}, {8080, 11}, {10799, 11},
	} {
		rng := &scriptedRoller{rolls: []scriptedRoll{{10800, tc.roll}}}
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
		{Unarmed: true, WeaponSkillID: "SK_UNARMED_COMBAT", WeaponSpeed: 12, ShieldEV: -50},
		{Unarmed: true, WeaponSkillID: "SK_UNARMED_COMBAT", ShieldEV: 5},
	} {
		if _, err := PlayerAttackDelay(&scriptedRoller{}, in); err == nil {
			t.Fatalf("accepted unsupported delay input %+v", in)
		}
	}
}
