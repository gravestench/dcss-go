package combat

import (
	"fmt"
	"testing"
)

type scriptedRoll struct{ bound, value int }

type scriptedRoller struct{ rolls []scriptedRoll }

func (s *scriptedRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" || len(s.rolls) == 0 || s.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected roll %q bound %d, remaining %+v", stream, bound, s.rolls)
	}
	value := s.rolls[0].value
	s.rolls = s.rolls[1:]
	return value, nil
}

func ratAttack() RatAttack {
	return RatAttack{HD: 1, Damage: 3, TypeID: "AT_BITE", FlavourID: "AF_PLAIN"}
}

func TestHumanFighterDefenseUsesEquippedScaleMailAndBuckler(t *testing.T) {
	// Source: player.cc armour/evasion/shield formulas; Human is medium size.
	got, err := ProjectFighter(FighterDefense{
		Strength: 16, Dexterity: 12, ArmourSkill: 3, ShieldsSkill: 3,
		BodyAC: 6, BodyEV: -100, ShieldAC: 3, ShieldEV: -50,
	})
	if err != nil {
		t.Fatal(err)
	}
	if got.EV != 5 || got.AC != 6 || got.ShieldClass != 9 || got.GDR != 25 {
		t.Fatalf("Human/Fighter defense = %+v, want EV 5 AC 6 SH 9 GDR 25", got)
	}
}

func TestFighterDefenseRejectsInvalidAttributesAndBlockCount(t *testing.T) {
	for _, input := range []FighterDefense{
		{Strength: 0, Dexterity: 12},
		{Strength: 16, Dexterity: -1},
		{Strength: 16, Dexterity: 12, ShieldBlocks: -1},
	} {
		if _, err := ProjectFighter(input); err == nil {
			t.Fatalf("accepted invalid defense %+v", input)
		}
	}
}

func TestRatBiteDodgesWithoutShield(t *testing.T) {
	rng := &scriptedRoller{rolls: []scriptedRoll{{20, 0}, {20, 5}, {21, 5}, {100, 10}, {15, 0}}}
	got, err := RatBite(rng, ratAttack(), Defense{EV: 10})
	if err != nil || got.Kind != Dodge || got.Damage != 0 || len(rng.rolls) != 0 {
		t.Fatalf("dodge = %+v, %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestRatBiteAutomaticMissAndHit(t *testing.T) {
	miss := &scriptedRoller{rolls: []scriptedRoll{{20, 19}, {20, 0}, {21, 0}, {100, 0}, {2, 0}, {15, 0}}}
	got, err := RatBite(miss, ratAttack(), Defense{EV: 10})
	if err != nil || got.Kind != Miss || len(miss.rolls) != 0 {
		t.Fatalf("automatic miss = %+v, %v, rolls %+v", got, err, miss.rolls)
	}
	hit := &scriptedRoller{rolls: []scriptedRoll{{20, 0}, {20, 19}, {21, 20}, {100, 0}, {2, 1}, {15, 0}, {3, 2}}}
	got, err = RatBite(hit, ratAttack(), Defense{EV: 10})
	if err != nil || got.Kind != Hit || got.Damage != 3 || len(hit.rolls) != 0 {
		t.Fatalf("automatic hit = %+v, %v, rolls %+v", got, err, hit.rolls)
	}
}

func TestRatShieldBlockPrecedesDodge(t *testing.T) {
	rng := &scriptedRoller{rolls: []scriptedRoll{{20, 0}, {20, 5}, {21, 5}, {100, 10}, {15, 0}, {18, 17}, {19, 18}}}
	got, err := RatBite(rng, ratAttack(), Defense{EV: 10, ShieldClass: 9})
	if err != nil || got.Kind != Block || got.ShieldBlocks != 1 || got.Damage != 0 || len(rng.rolls) != 0 {
		t.Fatalf("block = %+v, %v, rolls %+v", got, err, rng.rolls)
	}
}

func TestRatBiteArmourCanAbsorbOrPassDamage(t *testing.T) {
	for _, tc := range []struct {
		name   string
		acRoll int
		want   int
	}{
		{"absorbed", 6, 0},
		{"damaging", 0, 3},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rng := &scriptedRoller{rolls: []scriptedRoll{{20, 19}, {10, 0}, {11, 0}, {100, 10}, {15, 0}, {3, 2}, {7, tc.acRoll}}}
			got, err := RatBite(rng, ratAttack(), Defense{EV: 5, AC: 6, GDR: 25})
			if err != nil || got.Kind != Hit || got.Damage != tc.want || len(rng.rolls) != 0 {
				t.Fatalf("bite = %+v, %v, rolls %+v", got, err, rng.rolls)
			}
		})
	}
}
