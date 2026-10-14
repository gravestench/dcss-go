package monster

import (
	"fmt"
	"testing"

	"dcrawl-go/internal/content"
)

type gearRoll struct {
	bound int
	value int
}

type gearRoller struct {
	rolls []gearRoll
}

func (r *gearRoller) Intn(stream string, bound int) (int, error) {
	if stream != "monster_gear" ||
		len(r.rolls) == 0 ||
		r.rolls[0].bound != bound {
		return 0, fmt.Errorf("unexpected gear draw %s/%d", stream, bound)
	}

	value := r.rolls[0].value

	r.rolls = r.rolls[1:]

	return value, nil
}

func TestGoblinLoadoutDrawsDiscardedPlussesBeforeSlingOverride(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 2,
				value: 1,
			},

			{
				bound: 3,
				value: 2,
			},

			{
				bound: 425,
				value: 424,
			},

			{
				bound: 12,
				value: 0,
			},

			{
				bound: 200,
				value: 199,
			},

			{
				bound: 2,
				value: 0,
			},

			{
				bound: 3,
				value: 1,
			},

			{
				bound: 425,
				value: 424,
			},

			{
				bound: 200,
				value: 199,
			},
		},
	}

	loadout, err := RollEarlyHumanoidLoadout(roller, catalog, "MONS_GOBLIN", 1)

	if err != nil {
		t.Fatal(err)
	}

	if loadout.Primary.KindID != "WPN_SLING" ||
		loadout.Alternate.KindID != "WPN_DAGGER" ||
		loadout.Ammunition != (AmmunitionChoice{}) ||
		len(roller.rolls) != 0 {
		t.Fatalf("goblin loadout = %+v, remaining %+v", loadout, roller.rolls)
	}
}

func TestGoblinWithoutSlingKeepsTableWeapon(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 2,
				value: 1,
			},

			{
				bound: 3,
				value: 0,
			},

			{
				bound: 425,
				value: 424,
			},

			{
				bound: 12,
				value: 1,
			},

			{
				bound: 200,
				value: 199,
			},
		},
	}

	loadout, err := RollEarlyHumanoidLoadout(roller, catalog, "MONS_GOBLIN", 1)

	if err != nil {
		t.Fatal(err)
	}

	if loadout.Primary.KindID != "WPN_CLUB" ||
		loadout.Alternate != (StartingWeapon{}) ||
		len(roller.rolls) != 0 {
		t.Fatalf("goblin loadout = %+v, remaining %+v", loadout, roller.rolls)
	}
}

func TestKoboldLoadoutDrawsWeaponThenAmmunition(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 6,
				value: 0,
			},

			{
				bound: 200,
				value: 199,
			},

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

	loadout, err := RollEarlyHumanoidLoadout(roller, catalog, "MONS_KOBOLD", 1)

	if err != nil {
		t.Fatal(err)
	}

	if loadout.Primary.KindID != "WPN_DAGGER" ||
		loadout.Alternate != (StartingWeapon{}) ||
		loadout.Ammunition.KindID != "MI_STONE" ||
		loadout.Ammunition.Quantity != 5 ||
		len(roller.rolls) != 0 {
		t.Fatalf("kobold loadout = %+v, remaining %+v", loadout, roller.rolls)
	}
}

func TestKoboldSwitchRetainsSixUniformPositions(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	want := []string{
		"WPN_DAGGER",
		"WPN_DAGGER",
		"WPN_SHORT_SWORD",
		"WPN_SHORT_SWORD",
		"WPN_CLUB",
		"WPN_WHIP",
	}

	for roll, kindID := range want {
		roller := &gearRoller{
			rolls: []gearRoll{
				{
					bound: 6,
					value: roll,
				},

				{
					bound: 200,
					value: 199,
				},

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

		loadout, err := RollEarlyHumanoidLoadout(roller, catalog, "MONS_KOBOLD", 1)

		if err != nil {
			t.Fatal(err)
		}

		if loadout.Primary.KindID != kindID ||
			loadout.Ammunition != (AmmunitionChoice{}) ||
			len(roller.rolls) != 0 {
			t.Fatalf("kobold draw %d = %+v, remaining %+v", roll, loadout, roller.rolls)
		}
	}
}

func TestEarlyHumanoidLoadoutRejectsUnsupportedMonster(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := RollEarlyHumanoidLoadout(
		&gearRoller{},
		catalog,
		"MONS_HOBGOBLIN",
		1,
	); err == nil {
		t.Fatal("accepted a monster without early humanoid gear rules")
	}
}
