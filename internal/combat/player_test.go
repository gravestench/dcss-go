package combat

import "testing"

func fighterFlailAttack() PlayerAttackInput {
	return PlayerAttackInput{Strength: 16, Dexterity: 12, FightingSkill100: 300,
		WeaponSkill100: 200, WeaponSkillID: "SK_MACES_FLAILS", WeaponDamage: 8,
		WeaponHit: 1, DefenderEV: 10, DefenderAC: 1}
}

func TestPlayerMeleeMissAndAutomaticOverrides(t *testing.T) {
	for _, tc := range []struct {
		name  string
		rolls []scriptedRoll
		want  OutcomeKind
	}{
		{"ordinary miss", []scriptedRoll{{400, 0}, {300, 0}, {22, 0}, {100, 10}, {15, 0}}, Miss},
		{"automatic miss", []scriptedRoll{{400, 0}, {300, 0}, {22, 21}, {100, 0}, {2, 0}, {25, 0}}, Miss},
		{"automatic hit", []scriptedRoll{{400, 0}, {300, 0}, {22, 0}, {100, 0}, {2, 1}, {15, 0}, {10, 9}, {201, 0}, {301, 0}, {2, 0}, {2, 1}}, Hit},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: tc.rolls}
			got, err := PlayerMelee(rng, fighterFlailAttack())
			if err != nil || got.Kind != tc.want || len(rng.rolls) != 0 {
				t.Fatalf("attack = %+v, err %v, rolls %+v", got, err, rng.rolls)
			}
		})
	}
}

func TestPlayerMeleeWeaponDamageAndRatArmour(t *testing.T) {
	for _, tc := range []struct {
		name                     string
		damageRoll, acRoll, want int
	}{
		{"absorbed", 1, 1, 0},
		{"damaging", 9, 0, 9},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: []scriptedRoll{{400, 300}, {300, 200}, {27, 26}, {100, 10}, {28, 0}, {10, tc.damageRoll}, {201, 200}, {301, 300}, {2, tc.acRoll}, {2, 1}}}
			got, err := PlayerMelee(rng, fighterFlailAttack())
			if err != nil || got.Kind != Hit || got.Damage != tc.want || len(rng.rolls) != 0 {
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
	in.WeaponDamage, in.WeaponHit = 0, 0
	rng := &scriptedRoller{rolls: []scriptedRoll{{400, 0}, {300, 0}, {23, 22}, {100, 10}, {26, 0}, {256, 0}, {7, 6}, {301, 0}, {2, 0}, {2, 1}}}
	got, err := PlayerMelee(rng, in)
	if err != nil || got.Kind != Hit || got.Damage != 6 || len(rng.rolls) != 0 {
		t.Fatalf("unarmed attack = %+v, err %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestPlayerMeleeMightBonusAfterDamageAndBeforeArmour(t *testing.T) {
	in := fighterFlailAttack()
	in.Mighty = true
	rng := &scriptedRoller{rolls: []scriptedRoll{{400, 300}, {300, 200}, {27, 26}, {100, 10}, {28, 0}, {10, 9}, {201, 200}, {301, 300}, {10, 4}, {2, 1}, {2, 1}}}
	got, err := PlayerMelee(rng, in)
	if err != nil || got.Kind != Hit || got.Damage != 13 || len(rng.rolls) != 0 {
		t.Fatalf("mighty hit = %+v, %v; rolls %+v", got, err, rng.rolls)
	}
	rng = &scriptedRoller{rolls: []scriptedRoll{{400, 0}, {300, 0}, {22, 0}, {100, 10}, {15, 0}}}
	got, err = PlayerMelee(rng, in)
	if err != nil || got.Kind != Miss || len(rng.rolls) != 0 {
		t.Fatalf("mighty miss = %+v, %v; rolls %+v", got, err, rng.rolls)
	}
}

func TestPlayerMeleeMightRollPrecedesEnchantmentRoll(t *testing.T) {
	in := fighterFlailAttack()
	in.Mighty = true
	in.WeaponPlus = 2
	rng := &scriptedRoller{rolls: []scriptedRoll{{400, 300}, {300, 200}, {29, 28}, {100, 10}, {29, 0}, {10, 9}, {201, 200}, {301, 300}, {10, 4}, {3, 2}, {2, 1}, {2, 1}}}
	got, err := PlayerMelee(rng, in)
	if err != nil || got.Kind != Hit || got.Damage != 15 || len(rng.rolls) != 0 {
		t.Fatalf("enchanted mighty hit = %+v, %v; rolls %+v", got, err, rng.rolls)
	}
}
