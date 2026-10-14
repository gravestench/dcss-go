package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

// validateSavedAdvancement checks authoritative XP, applied levels,
// attributes, and vitals together. A pending manual choice deliberately holds
// the applied level below the level implied by XP.
func validateSavedAdvancement(
	record save.EntityRecord,
	profile character.StartProfile,
	catalog content.Catalog,
) (int, error) {
	progress := ecs.Progression{Level: 1}

	if record.Progression != nil {
		progress = *record.Progression
	}

	if progress.Level < 1 || progress.Level > character.MaxExperienceLevel {
		return 0, fmt.Errorf("invalid player level %d", progress.Level)
	}

	species, err := catalog.Species(record.Player.SpeciesID)

	if err != nil {
		return 0, err
	}

	currentNeeded, err := character.ExperienceNeeded(progress.Level, species.XP)

	if err != nil {
		return 0, err
	}

	if progress.TotalXP < currentNeeded {
		return 0, fmt.Errorf("player XL%d lacks experience", progress.Level)
	}

	earnedLevel, err := character.LevelForExperience(progress.TotalXP, species.XP)

	if err != nil {
		return 0, err
	}

	if progress.PendingStatLevel == 0 {
		if progress.Level != earnedLevel {
			return 0, fmt.Errorf("player level %d disagrees with experience", progress.Level)
		}
	} else {
		pending := progress.PendingStatLevel
		needed, neededErr := character.ExperienceNeeded(pending, species.XP)

		if neededErr != nil ||
			pending != progress.Level+1 ||
			!character.NeedsManualStat(pending) || progress.TotalXP < needed {
			return 0, fmt.Errorf("invalid pending player stat choice at XL%d", pending)
		}
	}

	if err := validateSavedAttributes(
		record, profile, species, progress.Level,
	); err != nil {
		return 0, err
	}

	if err := validateSavedVitals(record, species, progress.Level); err != nil {
		return 0, err
	}

	return progress.TotalXP, nil
}

func validateSavedAttributes(
	record save.EntityRecord,
	profile character.StartProfile,
	species content.SpeciesDef,
	levelApplied int,
) error {
	base := profile.Attributes
	actual := record.Attributes

	if actual.Strength < base.Strength ||
		actual.Intelligence < base.Intelligence ||
		actual.Dexterity < base.Dexterity {
		return fmt.Errorf("invalid player attributes for entity %d", record.ID)
	}

	manualGains := 0
	randomGains := 0

	for level := 2; level <= levelApplied; level++ {
		if character.NeedsManualStat(level) {
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

	if !validStatGains(
		deltas,
		manualGains,
		randomGains,
		species.LevelUpStats,
	) {
		return fmt.Errorf("invalid player attribute gains for entity %d", record.ID)
	}

	return nil
}

func validateSavedVitals(
	record save.EntityRecord,
	species content.SpeciesDef,
	levelApplied int,
) error {
	wantHP, err := character.BaseMaxHP(levelApplied, species, record.Skills.Entries)

	if err != nil {
		return err
	}

	wantMP, err := character.BaseMaxMP(levelApplied, species)

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
// nonnegative points must be exactly the species gains in allowed attributes.
func validStatGains(
	deltas [3]int,
	manualChoices, speciesGains int,
	allowedStats []string,
) bool {
	allowed := [3]bool{}

	for _, stat := range allowedStats {
		switch stat {
		case "str":
			allowed[0] = true

		case "int":
			allowed[1] = true

		case "dex":
			allowed[2] = true
		}
	}

	for strength := 0; strength <= manualChoices; strength++ {
		for intelligence := 0; intelligence <= manualChoices-strength; intelligence++ {
			dexterity := manualChoices - strength - intelligence
			remaining := [3]int{
				deltas[0] - 2*strength,
				deltas[1] - 2*intelligence,
				deltas[2] - 2*dexterity,
			}

			if (!allowed[0] && remaining[0] != 0) ||
				(!allowed[1] && remaining[1] != 0) ||
				(!allowed[2] && remaining[2] != 0) {
				continue
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
