package monster

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// WeaponQuality contains the generated enchantment and brand for one weapon.
// The catalog supplies base damage and accuracy; Akara owns the live item.
type WeaponQuality struct {
	Plus int
	Ego  string
}

// RollOrdinaryWeaponQuality follows makeitem.cc:254-277,368-383,395-480
// for the five fixed weapon kinds available to early goblins and kobolds.
// It excludes gifts, artefacts, demonic weapons, and forced brands.
func RollOrdinaryWeaponQuality(
	roller Roller,
	catalog content.Catalog,
	kindID string,
	depth int,
) (WeaponQuality, error) {
	if roller == nil ||
		depth < 0 ||
		depth >= 350 {
		return WeaponQuality{}, fmt.Errorf("invalid ordinary weapon depth %d", depth)
	}

	switch kindID {
	case "WPN_DAGGER", "WPN_CLUB", "WPN_SHORT_SWORD", "WPN_WHIP", "WPN_SLING":

	default:
		return WeaponQuality{}, fmt.Errorf("unsupported ordinary weapon %s", kindID)
	}

	kind, err := catalog.Item(kindID)

	if err != nil {
		return WeaponQuality{}, err
	}

	if kind.Class != "OBJ_WEAPONS" || kind.Weapon == nil {
		return WeaponQuality{}, fmt.Errorf("missing ordinary weapon properties %s", kindID)
	}

	qualityRoll, err := drawMonsterGear(roller, 200)

	if err != nil {
		return WeaponQuality{}, err
	}

	// Clubs are mundane in items.cc:4059-4074. The source still makes the
	// quality chance draw before it checks that property.
	if qualityRoll >= 51+depth || kindID == "WPN_CLUB" {
		return WeaponQuality{}, nil
	}

	brandRoll, err := drawMonsterGear(roller, 300)

	if err != nil {
		return WeaponQuality{}, err
	}

	brand := "SPWPN_NORMAL"

	if brandRoll < 101+depth {
		brand, err = chooseOrdinaryWeaponBrand(roller, kind.Weapon.BrandWeights)

		if err != nil {
			return WeaponQuality{}, err
		}
	}

	plus, err := RollNiceWeaponPlusses(roller, depth)

	if err != nil {
		return WeaponQuality{}, err
	}

	if brand == "SPWPN_NORMAL" && plus < 3 {
		plus = 0
	}

	quality := WeaponQuality{Plus: plus}

	if brand != "SPWPN_NORMAL" {
		quality.Ego = brand
	}

	return quality, nil
}

// RollNiceWeaponPlusses preserves the source's alternating plus and stop
// draws. Goblin table processing also calls it before the sling override,
// even though that preliminary enchantment is later discarded.
func RollNiceWeaponPlusses(roller Roller, depth int) (int, error) {
	if roller == nil ||
		depth < 0 ||
		depth >= 350 {
		return 0, fmt.Errorf("invalid weapon enchantment depth %d", depth)
	}

	plus := 0

	for range 4 {
		increment, err := drawMonsterGear(roller, 3)

		if err != nil {
			return 0, err
		}

		plus += increment

		stopRoll, err := drawMonsterGear(roller, 425)

		if err != nil {
			return 0, err
		}

		if stopRoll > 35+depth {
			break
		}
	}

	return plus, nil
}

func chooseOrdinaryWeaponBrand(
	roller Roller,
	weights []content.ItemBrandWeight,
) (string, error) {
	total := 0

	for _, weight := range weights {
		if weight.BrandID == "" || weight.Weight < 0 {
			return "", fmt.Errorf("invalid ordinary weapon brand weight %+v", weight)
		}

		total += weight.Weight
	}

	if total == 0 {
		return "SPWPN_NORMAL", nil
	}

	roll, err := drawMonsterGear(roller, total)

	if err != nil {
		return "", err
	}

	for _, weight := range weights {
		if roll < weight.Weight {
			return weight.BrandID, nil
		}

		roll -= weight.Weight
	}

	return "", fmt.Errorf("ordinary weapon brand table failed to select")
}
