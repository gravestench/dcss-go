package combat

import "testing"

func minotaurHeadbutt() HeadbuttInput {
	return HeadbuttInput{
		Level:            1,
		Horns:            2,
		Reflexive:        true,
		Strength:         20,
		Dexterity:        9,
		FightingSkill100: 300,
		FightingSkill30:  90,
		DefenderEV:       5,
		DefenderAC:       2,
	}
}

func TestAuxiliaryHeadbuttTriggerAccuracyAndDamage(t *testing.T) {
	in := minotaurHeadbutt()
	miss := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 100,
				value: 34,
			},

			{
				bound: 20,
				value: 0,
			},

			{
				bound: 30,
				value: 1,
			},
		},
	}

	outcome, err := AuxiliaryHeadbutt(miss, in)

	if err != nil {
		t.Fatal(err)
	}

	if !outcome.Attempted ||
		outcome.Hit ||
		len(miss.rolls) != 0 {
		t.Fatalf("miss = %+v, err %v, rolls %+v", outcome, err, miss.rolls)
	}

	noTrigger := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 100,
				value: 35,
			},
		},
	}

	outcome, err = AuxiliaryHeadbutt(noTrigger, in)

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Attempted || len(noTrigger.rolls) != 0 {
		t.Fatalf("no trigger = %+v, err %v", outcome, err)
	}

	hit := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 100,
				value: 0,
			},

			{
				bound: 20,
				value: 5,
			},

			{
				bound: 30,
				value: 1,
			},

			{
				bound: 17,
				value: 0,
			},

			{
				bound: 13,
				value: 12,
			},

			{
				bound: 301,
				value: 300,
			},

			{
				bound: 3,
				value: 2,
			},
		},
	}

	outcome, err = AuxiliaryHeadbutt(hit, in)

	if err != nil {
		t.Fatal(err)
	}

	if !outcome.Hit ||
		outcome.Damage != 10 ||
		len(hit.rolls) != 0 {
		t.Fatalf("hit = %+v, err %v, rolls %+v", outcome, err, hit.rolls)
	}
}

func TestReflexiveHeadbuttChanceMightAndArmour(t *testing.T) {
	in := minotaurHeadbutt()

	in.Mighty = true

	missedChance := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 100,
				value: 24,
			},
		},
	}

	outcome, err := ReflexiveHeadbutt(missedChance, in)

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Attempted || len(missedChance.rolls) != 0 {
		t.Fatalf("reflexive chance = %+v, err %v", outcome, err)
	}

	hit := &scriptedRoller{
		rolls: []scriptedRoll{
			{
				bound: 100,
				value: 23,
			},

			{
				bound: 13,
				value: 0,
			},

			{
				bound: 301,
				value: 0,
			},

			{
				bound: 10,
				value: 0,
			},

			{
				bound: 3,
				value: 2,
			},
		},
	}

	outcome, err = ReflexiveHeadbutt(hit, in)

	if err != nil {
		t.Fatal(err)
	}

	if !outcome.Hit ||
		outcome.Damage != 0 ||
		len(hit.rolls) != 0 {
		t.Fatalf("armoured hit = %+v, err %v, rolls %+v", outcome, err, hit.rolls)
	}

	in.Horns = 0

	outcome, err = ReflexiveHeadbutt(&scriptedRoller{}, in)

	if err != nil {
		t.Fatal(err)
	}

	if outcome.Attempted {
		t.Fatalf("hornless retaliation = %+v, err %v", outcome, err)
	}
}
