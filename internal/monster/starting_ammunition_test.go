package monster

import "testing"

func TestKoboldPoisonedDartsRequireDepthTwo(t *testing.T) {
	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 10,
				value: 0,
			},

			{
				bound: 7,
				value: 6,
			},
		},
	}

	choice, err := RollKoboldStartingAmmunition(roller, 2)

	if err != nil {
		t.Fatal(err)
	}

	if choice.KindID != "MI_DART" ||
		choice.Quantity != 8 ||
		choice.Ego != "poisoned" ||
		len(roller.rolls) != 0 {
		t.Fatalf("depth-two ammunition = %+v, remaining %+v", choice, roller.rolls)
	}
}

func TestKoboldDepthOneDiscardsDartRollAndCanCarryStones(t *testing.T) {
	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 10,
				value: 0,
			},

			{
				bound: 5,
				value: 1,
			},

			{
				bound: 5,
				value: 4,
			},
		},
	}

	choice, err := RollKoboldStartingAmmunition(roller, 1)

	if err != nil {
		t.Fatal(err)
	}

	if choice.KindID != "MI_STONE" ||
		choice.Quantity != 5 ||
		choice.Ego != "" ||
		len(roller.rolls) != 0 {
		t.Fatalf("depth-one ammunition = %+v, remaining %+v", choice, roller.rolls)
	}
}

func TestKoboldWithoutAmmunition(t *testing.T) {
	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 10,
				value: 1,
			},

			{
				bound: 5,
				value: 2,
			},
		},
	}

	choice, err := RollKoboldStartingAmmunition(roller, 2)

	if err != nil {
		t.Fatal(err)
	}

	if choice != (AmmunitionChoice{}) || len(roller.rolls) != 0 {
		t.Fatalf("unexpected ammunition %+v, remaining %+v", choice, roller.rolls)
	}
}

func TestKoboldAmmunitionRejectsInvalidDepth(t *testing.T) {
	if _, err := RollKoboldStartingAmmunition(&gearRoller{}, -1); err == nil {
		t.Fatal("accepted negative dungeon depth")
	}
}
