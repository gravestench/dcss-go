package character

import (
	"fmt"

	"dcrawl-go/internal/content"
)

type WeaponOption struct {
	ID          string
	Name        string
	Restriction Restriction
}

func goodWeaponUpgrade(id, jobID, size string) string {
	switch id {
	case "WPN_SHORT_SWORD":
		return "WPN_RAPIER"

	case "WPN_MACE":
		return "WPN_FLAIL"

	case "WPN_HAND_AXE":
		return "WPN_WAR_AXE"

	case "WPN_SPEAR":
		if jobID == "JOB_FIGHTER" &&
			(size == "SIZE_TINY" ||
				size == "SIZE_LITTLE" ||
				size == "SIZE_SMALL") {
			return id
		}

		return "WPN_TRIDENT"

	case "WPN_FALCHION":
		return "WPN_LONG_SWORD"

	default:
		return id
	}
}

// WeaponOptions returns source-ordered legal choices without changing game state.
func WeaponOptions(c content.Catalog, speciesID, jobID string) ([]WeaponOption, error) {
	species, err := c.Species(speciesID)

	if err != nil {
		return nil, err
	}

	job, err := c.Job(jobID)

	if err != nil {
		return nil, err
	}

	if !species.Selectable ||
		!job.Selectable || bannedPair(species, jobID) {
		return nil, fmt.Errorf("%s/%s is not a legal normal Dungeon start", speciesID, jobID)
	}

	if job.WeaponChoice == "WCHOICE_NONE" {
		return nil, nil
	}

	var options []WeaponOption
	baseWeapons := []string{
		"WPN_SHORT_SWORD",
		"WPN_MACE",
		"WPN_HAND_AXE",
		"WPN_SPEAR",
		"WPN_FALCHION",
		"WPN_QUARTERSTAFF",
		"WPN_UNARMED",
	}

	for _, base := range baseWeapons {
		id := base

		if job.WeaponChoice == "WCHOICE_GOOD" {
			id = goodWeaponUpgrade(id, jobID, species.Size)
		}

		if hasMutation(species, "MUT_NO_GRASPING") && id != "WPN_UNARMED" {
			continue
		}

		fighterCanUseStaff := jobID == "JOB_FIGHTER" &&
			hasMutation(species, "MUT_QUADRUMANOUS")

		if id == "WPN_QUARTERSTAFF" &&
			jobID != "JOB_GLADIATOR" && !fighterCanUseStaff {
			continue
		}

		option := WeaponOption{
			ID:          id,
			Restriction: Restricted,
		}

		skill := "SK_UNARMED_COMBAT"

		if id == "WPN_UNARMED" {
			option.Name = "unarmed"
		} else {
			item, err := c.Item(id)

			if err != nil {
				return nil, err
			}

			option.Name, skill = item.Name, item.WeaponSkill
		}

		if contains(species.RecommendedWeapons, skill) &&
			!(jobID == "JOB_FIGHTER" &&
				skill == "SK_SHORT_BLADES") {
			option.Restriction = Recommended
		}

		options = append(options, option)
	}

	return options, nil
}

func ValidateWeaponChoice(c content.Catalog, speciesID, jobID, weaponID string) error {
	options, err := WeaponOptions(c, speciesID, jobID)

	if err != nil {
		return err
	}

	for _, option := range options {
		if option.ID == weaponID {
			return nil
		}
	}

	return fmt.Errorf("weapon %s is not a legal choice for %s/%s", weaponID, speciesID, jobID)
}
