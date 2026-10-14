package monster

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// StartingWeapon is the source choice and quality for one monster item.
type StartingWeapon struct {
	KindID  string
	Quality WeaponQuality
}

// EarlyHumanoidLoadout is a pure creation result. The game factory turns
// these choices into Akara item entities owned by the new monster.
type EarlyHumanoidLoadout struct {
	Primary    StartingWeapon
	Alternate  StartingWeapon
	Ammunition AmmunitionChoice
}

// RollEarlyHumanoidLoadout follows mon-gear.cc's weapon, second weapon, and
// ammunition phases in that order. It also consumes goblins' discarded
// preliminary plus draws before the sling override.
func RollEarlyHumanoidLoadout(
	roller Roller,
	catalog content.Catalog,
	monsterID string,
	depth int,
) (EarlyHumanoidLoadout, error) {
	if roller == nil ||
		depth < 0 ||
		depth >= 350 {
		return EarlyHumanoidLoadout{}, fmt.Errorf("invalid early humanoid gear depth %d", depth)
	}

	switch monsterID {
	case "MONS_GOBLIN":
		primary, err := rollGoblinWeapon(roller, catalog, depth, false)

		if err != nil {
			return EarlyHumanoidLoadout{}, err
		}

		loadout := EarlyHumanoidLoadout{Primary: primary}

		if primary.KindID == "WPN_SLING" {
			loadout.Alternate, err = rollGoblinWeapon(roller, catalog, depth, true)

			if err != nil {
				return EarlyHumanoidLoadout{}, err
			}
		}

		return loadout, nil

	case "MONS_KOBOLD":
		kindID, err := rollKoboldWeaponKind(roller)

		if err != nil {
			return EarlyHumanoidLoadout{}, err
		}

		quality, err := RollOrdinaryWeaponQuality(roller, catalog, kindID, depth)

		if err != nil {
			return EarlyHumanoidLoadout{}, err
		}

		ammunition, err := RollKoboldStartingAmmunition(roller, depth)

		if err != nil {
			return EarlyHumanoidLoadout{}, err
		}

		return EarlyHumanoidLoadout{
			Primary: StartingWeapon{
				KindID:  kindID,
				Quality: quality,
			},
			Ammunition: ammunition,
		}, nil

	default:
		return EarlyHumanoidLoadout{}, fmt.Errorf("unsupported early humanoid %s", monsterID)
	}
}

func rollGoblinWeapon(
	roller Roller,
	catalog content.Catalog,
	depth int,
	meleeOnly bool,
) (StartingWeapon, error) {
	spec, found := catalog.MonsterWeapon("MONS_GOBLIN", false)

	if !found ||
		spec.Plus.Odds != 0 ||
		len(spec.Brands) != 0 ||
		spec.GoodChance != 0 {
		return StartingWeapon{}, fmt.Errorf("unsupported goblin weapon specification")
	}

	kindID, err := chooseWeightedWeapon(roller, spec.Weapons)

	if err != nil {
		return StartingWeapon{}, err
	}

	if kindID == "" {
		return StartingWeapon{}, fmt.Errorf("goblin weapon table chose no item")
	}

	// _apply_weapon_spec rolls these plusses, but make_mons_weapon discards
	// them because this specification does not force the item instance.
	if _, err := RollNiceWeaponPlusses(roller, depth); err != nil {
		return StartingWeapon{}, err
	}

	if !meleeOnly {
		slingRoll, err := drawMonsterGear(roller, 12)

		if err != nil {
			return StartingWeapon{}, err
		}

		if slingRoll == 0 && depth > 0 {
			kindID = "WPN_SLING"
		}
	}

	quality, err := RollOrdinaryWeaponQuality(roller, catalog, kindID, depth)

	if err != nil {
		return StartingWeapon{}, err
	}

	return StartingWeapon{
		KindID:  kindID,
		Quality: quality,
	}, nil
}

func rollKoboldWeaponKind(roller Roller) (string, error) {
	// mon-gear.cc:1017-1024 gives six equally likely switch positions.
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
		return "", err
	}

	return choices[roll], nil
}
