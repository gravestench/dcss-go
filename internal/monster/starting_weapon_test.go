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

func TestGoblinSlingOverrideKeepsDiscardedTableDraw(t *testing.T) {
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
				bound: 12,
				value: 0,
			},

			{
				bound: 2,
				value: 0,
			},
		},
	}

	choices, err := RollInitialWeaponChoices(roller, catalog, "MONS_GOBLIN", 1)

	if err != nil {
		t.Fatal(err)
	}

	if choices.Primary != "WPN_SLING" ||
		choices.Alternate != "WPN_DAGGER" ||
		len(roller.rolls) != 0 {
		t.Fatalf("goblin weapons = %+v, remaining %+v", choices, roller.rolls)
	}
}

func TestGoblinNoSlingUsesCommittedTable(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{
		rolls: []gearRoll{
			{
				bound: 2,
				value: 0,
			},

			{
				bound: 12,
				value: 1,
			},
		},
	}

	choices, err := RollInitialWeaponChoices(roller, catalog, "MONS_GOBLIN", 1)

	if err != nil {
		t.Fatal(err)
	}

	if choices.Primary != "WPN_DAGGER" ||
		choices.Alternate != "" ||
		len(roller.rolls) != 0 {
		t.Fatalf("goblin weapons = %+v, remaining %+v", choices, roller.rolls)
	}
}

func TestKoboldWeaponSwitchHasSixUniformChoices(t *testing.T) {
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
			},
		}

		choices, err := RollInitialWeaponChoices(roller, catalog, "MONS_KOBOLD", 1)

		if err != nil {
			t.Fatal(err)
		}

		if choices.Primary != kindID || choices.Alternate != "" {
			t.Fatalf("kobold draw %d = %+v, want %s", roll, choices, kindID)
		}
	}
}

func TestStartingWeaponPolicyRejectsUnimplementedMonster(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	roller := &gearRoller{}

	if _, err := RollInitialWeaponChoices(roller, catalog, "MONS_HOBGOBLIN", 1); err == nil {
		t.Fatal("accepted a monster without this source weapon policy")
	}
}
