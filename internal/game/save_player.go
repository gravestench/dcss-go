package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

// validateSavedHumanAdvancement checks authoritative XP, applied levels,
// attributes, and vitals together. A pending manual choice deliberately holds
// the applied level below the level implied by XP.
func validateSavedHumanAdvancement(
	record save.EntityRecord,
	profile character.StartProfile,
	catalog content.Catalog,
) (int, error) {
	progress := ecs.Progression{Level: 1}

	if record.Progression != nil {
		progress = *record.Progression
	}

	if progress.Level < 1 || progress.Level > character.HumanMaxLevel {
		return 0, fmt.Errorf("invalid player level %d", progress.Level)
	}

	currentNeeded, _ := character.HumanExperienceNeeded(progress.Level)

	if progress.TotalXP < currentNeeded {
		return 0, fmt.Errorf("player XL%d lacks experience", progress.Level)
	}

	earnedLevel, err := character.HumanLevelForExperience(progress.TotalXP)

	if err != nil {
		return 0, err
	}

	if progress.PendingStatLevel == 0 {
		if progress.Level != earnedLevel {
			return 0, fmt.Errorf("player level %d disagrees with experience", progress.Level)
		}
	} else {
		pending := progress.PendingStatLevel
		needed, neededErr := character.HumanExperienceNeeded(pending)

		if neededErr != nil ||
			pending != progress.Level+1 ||
			!character.HumanNeedsManualStat(pending) || progress.TotalXP < needed {
			return 0, fmt.Errorf("invalid pending player stat choice at XL%d", pending)
		}
	}

	species, err := validateSavedHumanAttributes(record, profile, catalog, progress.Level)

	if err != nil {
		return 0, err
	}

	if err := validateSavedHumanVitals(record, species, progress.Level); err != nil {
		return 0, err
	}

	return progress.TotalXP, nil
}

func validateSavedHumanAttributes(
	record save.EntityRecord,
	profile character.StartProfile,
	catalog content.Catalog,
	levelApplied int,
) (content.SpeciesDef, error) {
	base := profile.Attributes
	actual := record.Attributes

	if actual.Strength < base.Strength ||
		actual.Intelligence < base.Intelligence ||
		actual.Dexterity < base.Dexterity {
		return content.SpeciesDef{}, fmt.Errorf("invalid player attributes for entity %d", record.ID)
	}

	species, err := catalog.Species("SP_HUMAN")

	if err != nil {
		return content.SpeciesDef{}, err
	}

	manualGains := 0
	randomGains := 0

	for level := 2; level <= levelApplied; level++ {
		if character.HumanNeedsManualStat(level) {
			manualGains++
		}

		if species.LevelUpStatFrequency > 0 &&
			len(species.LevelUpStats) > 0 &&
			level%species.LevelUpStatFrequency == 0 {
			randomGains++
		}
	}

	deltas := [3]int{
		actual.Strength - base.Strength,
		actual.Intelligence - base.Intelligence,
		actual.Dexterity - base.Dexterity,
	}

	if !validHumanStatGains(deltas, manualGains, randomGains) {
		return content.SpeciesDef{}, fmt.Errorf("invalid player attribute gains for entity %d", record.ID)
	}

	return species, nil
}

func validateSavedHumanVitals(
	record save.EntityRecord,
	species content.SpeciesDef,
	levelApplied int,
) error {
	wantHP, err := character.HumanMaxHP(levelApplied, species, record.Skills.Entries)

	if err != nil {
		return err
	}

	wantMP, err := character.HumanMaxMP(levelApplied, species)

	if err != nil {
		return err
	}

	if record.Health.Max != wantHP {
		return fmt.Errorf("invalid player max HP for entity %d", record.ID)
	}

	if record.Magic.Max != wantMP ||
		record.Magic.Current < 0 || record.Magic.Current > wantMP {
		return fmt.Errorf("invalid player MP for entity %d", record.ID)
	}

	return nil
}

// A manual choice adds two points to one stat. Each species gain adds one.
// Try every distribution of the five possible manual choices; the remaining
// nonnegative points must be exactly the species gains.
func validHumanStatGains(deltas [3]int, manualChoices, speciesGains int) bool {
	for strength := 0; strength <= manualChoices; strength++ {
		for intelligence := 0; intelligence <= manualChoices-strength; intelligence++ {
			dexterity := manualChoices - strength - intelligence
			remaining := [3]int{
				deltas[0] - 2*strength,
				deltas[1] - 2*intelligence,
				deltas[2] - 2*dexterity,
			}

			if remaining[0] >= 0 &&
				remaining[1] >= 0 &&
				remaining[2] >= 0 &&
				remaining[0]+remaining[1]+remaining[2] == speciesGains {
				return true
			}
		}
	}

	return false
}
