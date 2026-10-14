package monster

import "fmt"

// AmmunitionChoice describes the stack a monster receives at creation.
// The live item and its carrier link belong to Akara, not this rule.
type AmmunitionChoice struct {
	KindID   string
	Quantity int
	Ego      string
}

// RollKoboldStartingAmmunition follows mon-gear.cc:1347-1376. A launcher
// suppresses ammunition gifts in the source, but ordinary kobolds cannot
// start with one. The caller must use the monster's absolute depth.
func RollKoboldStartingAmmunition(
	roller Roller,
	depth int,
) (AmmunitionChoice, error) {
	if roller == nil || depth < 0 {
		return AmmunitionChoice{}, fmt.Errorf("invalid kobold ammunition depth %d", depth)
	}

	// C++ evaluates one_chance_in before its depth condition, even on D:1.
	dartRoll, err := drawMonsterGear(roller, 10)

	if err != nil {
		return AmmunitionChoice{}, err
	}

	if dartRoll == 0 && depth > 1 {
		quantityRoll, err := drawMonsterGear(roller, 7)

		if err != nil {
			return AmmunitionChoice{}, err
		}

		return AmmunitionChoice{
			KindID:   "MI_DART",
			Quantity: 2 + quantityRoll,
			Ego:      "poisoned",
		}, nil
	}

	stoneRoll, err := drawMonsterGear(roller, 5)

	if err != nil {
		return AmmunitionChoice{}, err
	}

	if stoneRoll >= 2 {
		return AmmunitionChoice{}, nil
	}

	quantityRoll, err := drawMonsterGear(roller, 5)

	if err != nil {
		return AmmunitionChoice{}, err
	}

	return AmmunitionChoice{
		KindID:   "MI_STONE",
		Quantity: 1 + quantityRoll,
	}, nil
}
