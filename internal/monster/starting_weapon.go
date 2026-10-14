package monster

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// InitialWeaponChoices preserves the source's primary and optional second
// melee weapon. The chosen kind IDs are immutable; live items belong to Akara.
type InitialWeaponChoices struct {
	Primary   string
	Alternate string
}

// RollInitialWeaponChoices follows mon-gear.cc:987-1037,1302-1332 for the
// early humanoids. This policy chooses kinds only; item quality is separate.
func RollInitialWeaponChoices(
	roller Roller,
	catalog content.Catalog,
	monsterID string,
	depth int,
) (InitialWeaponChoices, error) {
	if roller == nil || depth < 0 {
		return InitialWeaponChoices{}, fmt.Errorf("invalid monster gear depth %d", depth)
	}

	switch monsterID {
	case "MONS_GOBLIN":
		spec, found := catalog.MonsterWeapon(monsterID, false)

		if !found {
			return InitialWeaponChoices{}, fmt.Errorf("goblin weapon table is missing")
		}

		melee, err := chooseWeightedWeapon(roller, spec.Weapons)

		if err != nil {
			return InitialWeaponChoices{}, err
		}

		// The table choice is made before this override, even when discarded.
		slingRoll, err := drawMonsterGear(roller, 12)

		if err != nil {
			return InitialWeaponChoices{}, err
		}

		if slingRoll != 0 || depth == 0 {
			return InitialWeaponChoices{Primary: melee}, nil
		}

		alternate, err := chooseWeightedWeapon(roller, spec.Weapons)

		if err != nil {
			return InitialWeaponChoices{}, err
		}

		return InitialWeaponChoices{
			Primary:   "WPN_SLING",
			Alternate: alternate,
		}, nil

	case "MONS_KOBOLD":
		// mon-gear.cc's switch overrides any declarative table with six
		// equally likely positions, including repeated dagger and sword.
		choices := [...]string{
			"WPN_DAGGER",
			"WPN_DAGGER",
			"WPN_SHORT_SWORD",
			"WPN_SHORT_SWORD",
			"WPN_CLUB",
			"WPN_WHIP",
		}

		roll, err := drawMonsterGear(roller, len(choices))

		if err != nil {
			return InitialWeaponChoices{}, err
		}

		return InitialWeaponChoices{Primary: choices[roll]}, nil

	default:
		return InitialWeaponChoices{}, fmt.Errorf("unsupported starting weapon policy %s", monsterID)
	}
}

func chooseWeightedWeapon(
	roller Roller,
	choices []content.WeightedWeaponChoice,
) (string, error) {
	total := 0

	for _, choice := range choices {
		if choice.Weight <= 0 || choice.ID == "" {
			return "", fmt.Errorf("invalid weighted weapon choice %+v", choice)
		}

		total += choice.Weight
	}

	if total <= 0 {
		return "", fmt.Errorf("empty weighted weapon table")
	}

	roll, err := drawMonsterGear(roller, total)

	if err != nil {
		return "", err
	}

	for _, choice := range choices {
		if roll < choice.Weight {
			if choice.ID == "NUM_WEAPONS" {
				return "", nil
			}

			return choice.ID, nil
		}

		roll -= choice.Weight
	}

	return "", fmt.Errorf("weighted weapon table failed to select")
}

func drawMonsterGear(roller Roller, bound int) (int, error) {
	value, err := roller.Intn("monster_gear", bound)

	if err != nil {
		return 0, err
	}

	if value < 0 || value >= bound {
		return 0, fmt.Errorf("monster gear draw %d outside [0,%d)", value, bound)
	}

	return value, nil
}
