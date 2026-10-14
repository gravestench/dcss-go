package monster

import (
	"fmt"

	"dcrawl-go/internal/content"
)

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
