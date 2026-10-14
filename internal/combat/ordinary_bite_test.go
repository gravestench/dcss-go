package combat

import (
	"fmt"
	"testing"
)

type scriptedRoll struct {
	bound int
	value int
}

type scriptedRoller struct {
	rolls []scriptedRoll
}

func (s *scriptedRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" || len(s.rolls) == 0 || s.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected roll %q bound %d, remaining %+v", stream, bound, s.rolls)
	}

	value := s.rolls[0].value
	s.rolls = s.rolls[1:]

	return value, nil
}

func ratAttack() AnimalBite {
	return AnimalBite{
		HD:        1,
		Damage:    3,
		TypeID:    "AT_BITE",
		FlavourID: "AF_PLAIN",
	}
}

func TestPoisonBiteKeepsOrdinaryDamageRolls(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 22,
				value: 0,
			},
			{
				bound: 100,
				value: 50,
			},
			{
				bound: 16,
				value: 0,
			},
			{
				bound: 4,
				value: 3,
			},
		},
	}

	attack := AnimalBite{
		HD:        2,
		Damage:    4,
		TypeID:    "AT_BITE",
		FlavourID: "AF_POISON",
	}

	outcome, err := ResolveAnimalBite(roller, attack, Defense{})

	if err != nil || outcome.Kind != Hit ||
		outcome.Damage != 4 ||
		len(roller.rolls) != 0 {
		t.Fatalf("poison bite %+v, %v, rolls %+v", outcome, err, roller.rolls)
	}
}

func TestPoisonBiteRollsSourceTriggerAndAmount(t *testing.T) {
	triggered := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 3,
				value: 0,
			},
			{
				bound: 5,
				value: 4,
			},
		},
	}

	amount, err := PoisonBiteAmount(triggered, 2)

	if err != nil || amount != 8 || len(triggered.rolls) != 0 {
		t.Fatalf("poison amount %d, %v, rolls %+v", amount, err, triggered.rolls)
	}

	missed := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 3,
				value: 1,
			},
		},
	}

	amount, err = PoisonBiteAmount(missed, 2)

	if err != nil || amount != 0 || len(missed.rolls) != 0 {
		t.Fatalf("missed poison %d, %v, rolls %+v", amount, err, missed.rolls)
	}

	if _, err := PoisonBiteAmount(missed, 0); err == nil {
		t.Fatal("accepted poison with zero hit dice")
	}
}

func TestHumanFighterDefenseUsesEquippedScaleMailAndBuckler(t *testing.T) {
	// Source: player.cc armour/evasion/shield formulas; Human is medium size.
	got, err := ProjectFighter(FighterDefense{
		Strength:     16,
		Dexterity:    12,
		ArmourSkill:  3,
		ShieldsSkill: 3,
		Body: ArmourPiece{
			AC: 6,
			EV: -100,
		},
		Shield: ArmourPiece{
			AC: 3,
			EV: -50,
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	if got.EV != 5 ||
		got.AC != 6 ||
		got.ShieldClass != 9 ||
		got.GDR != 25 {
		t.Fatalf("Human/Fighter defense = %+v, want EV 5 AC 6 SH 9 GDR 25", got)
	}
}

func TestFighterDefenseUsesTrainedDodgingSkill(t *testing.T) {
	base := FighterDefense{
		Strength:  16,
		Dexterity: 12,
	}

	before, err := ProjectFighter(base)

	if err != nil {
		t.Fatal(err)
	}

	base.DodgingSkill10 = 100
	trained, err := ProjectFighter(base)

	if err != nil {
		t.Fatal(err)
	}

	if trained.EV <= before.EV {
		t.Fatalf("Dodging skill left EV at %d, starting EV %d", trained.EV, before.EV)
	}
}

func TestFighterDefenseAddsAuxiliaryArmourBeforeRounding(t *testing.T) {
	// player.cc base_ac_with_specific_items sums scaled pieces first.
	got, err := ProjectFighter(FighterDefense{
		Strength:     16,
		Dexterity:    12,
		ArmourSkill:  3,
		ShieldsSkill: 3,
		Body: ArmourPiece{
			AC: 6,
			EV: -100,
		},
		Shield: ArmourPiece{
			AC: 3,
			EV: -50,
		},
		Auxiliary: []ArmourPiece{
			{
				AC:   1,
				Plus: 2,
			},
			{AC: 1},
			{AC: 1},
			{AC: 1},
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	if got.AC != 13 || got.EV != 5 || got.ShieldClass != 9 {
		t.Fatalf("auxiliary defense = %+v, want AC 13 EV 5 SH 9", got)
	}
}

func TestFighterDefenseCountsAuxiliaryEvasionPenalty(t *testing.T) {
	got, err := ProjectFighter(FighterDefense{
		Strength:    16,
		Dexterity:   12,
		ArmourSkill: 3,
		Body: ArmourPiece{
			AC: 6,
			EV: -100,
		},
		Auxiliary: []ArmourPiece{
			{EV: -30},
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	if got.EV != 5 {
		t.Fatalf("auxiliary EV penalty = %d, want 5", got.EV)
	}
}

func TestFighterDefenseRejectsInvalidInputs(t *testing.T) {
	for _, input := range []FighterDefense{
		{
			Strength:  0,
			Dexterity: 12,
		},
		{
			Strength:  16,
			Dexterity: -1,
		},
		{
			Strength:     16,
			Dexterity:    12,
			ShieldBlocks: -1,
		},
		{
			Strength:  16,
			Dexterity: 12,
			Auxiliary: []ArmourPiece{
				{AC: -1},
			},
		},
		{
			Strength:  16,
			Dexterity: 12,
			Auxiliary: []ArmourPiece{
				{EV: 1},
			},
		},
	} {
		if _, err := ProjectFighter(input); err == nil {
			t.Fatalf("accepted invalid defense %+v", input)
		}
	}
}

func TestRatBiteDodgesWithoutShield(t *testing.T) {
	rng := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 0,
			},
			{
				bound: 20,
				value: 5,
			},
			{
				bound: 21,
				value: 5,
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

	got, err := ResolveAnimalBite(rng, ratAttack(), Defense{EV: 10})

	if err != nil ||
		got.Kind != Dodge ||
		got.Damage != 0 ||
		len(rng.rolls) != 0 {
		t.Fatalf("dodge = %+v, %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestRatBiteAutomaticMissAndHit(t *testing.T) {
	miss := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 19,
			},
			{
				bound: 20,
				value: 0,
			},
			{
				bound: 21,
				value: 0,
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
				bound: 15,
				value: 0,
			},
		},
	}

	got, err := ResolveAnimalBite(miss, ratAttack(), Defense{EV: 10})

	if err != nil || got.Kind != Miss || len(miss.rolls) != 0 {
		t.Fatalf("automatic miss = %+v, %v, rolls %+v", got, err, miss.rolls)
	}

	hit := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 0,
			},
			{
				bound: 20,
				value: 19,
			},
			{
				bound: 21,
				value: 20,
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
				bound: 3,
				value: 2,
			},
		},
	}

	got, err = ResolveAnimalBite(hit, ratAttack(), Defense{EV: 10})

	if err != nil ||
		got.Kind != Hit ||
		got.Damage != 3 ||
		len(hit.rolls) != 0 {
		t.Fatalf("automatic hit = %+v, %v, rolls %+v", got, err, hit.rolls)
	}
}

func TestRatShieldBlockPrecedesDodge(t *testing.T) {
	rng := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 0,
			},
			{
				bound: 20,
				value: 5,
			},
			{
				bound: 21,
				value: 5,
			},
			{
				bound: 100,
				value: 10,
			},
			{
				bound: 15,
				value: 0,
			},
			{
				bound: 18,
				value: 17,
			},
			{
				bound: 19,
				value: 18,
			},
		},
	}

	got, err := ResolveAnimalBite(rng, ratAttack(), Defense{
		EV:          10,
		ShieldClass: 9,
	})

	if err != nil ||
		got.Kind != Block ||
		got.ShieldBlocks != 1 ||
		got.Damage != 0 ||
		len(rng.rolls) != 0 {
		t.Fatalf("block = %+v, %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestRatBiteArmourCanAbsorbOrPassDamage(t *testing.T) {
	for _, tc := range []struct {
		name   string
		acRoll int
		want   int
	}{
		{
			name:   "absorbed",
			acRoll: 6,
			want:   0,
		},
		{
			name:   "damaging",
			acRoll: 0,
			want:   3,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{
				rolls: []scriptedRoll{
					{
						bound: 20,
						value: 19,
					},
					{
						bound: 10,
						value: 0,
					},
					{
						bound: 11,
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
					{
						bound: 3,
						value: 2,
					},
					{
						bound: 7,
						value: tc.acRoll,
					},
				},
			}

			got, err := ResolveAnimalBite(rng, ratAttack(), Defense{
				EV:  5,
				AC:  6,
				GDR: 25,
			})

			if err != nil ||
				got.Kind != Hit ||
				got.Damage != tc.want ||
				len(rng.rolls) != 0 {
				t.Fatalf("bite = %+v, %v, rolls %+v", got, err, rng.rolls)
			}
		})
	}
}

func TestQuokkaPlainBiteUsesCataloguedFiveDamage(t *testing.T) {
	roller := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 20,
				value: 19,
			},
			{
				bound: 100,
				value: 10,
			},
			{
				bound: 15,
				value: 14,
			},
			{
				bound: 5,
				value: 4,
			},
		},
	}

	outcome, err := ResolveAnimalBite(roller, AnimalBite{
		HD:        1,
		Damage:    5,
		TypeID:    "AT_BITE",
		FlavourID: "AF_PLAIN",
	}, Defense{})

	if err != nil ||
		outcome.Kind != Hit ||
		outcome.Damage != 5 ||
		len(roller.rolls) != 0 {
		t.Fatalf("quokka bite %+v, %v, remaining rolls %+v", outcome, err, roller.rolls)
	}
}
