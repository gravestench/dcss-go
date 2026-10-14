package game

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/monster"
	"dcrawl-go/internal/save"
)

func (g *Game) validateSavedPlayer(
	record save.EntityRecord,
	playerID uint64,
) (savedPlayerValidation, error) {
	if record.Player.Name != "" {
		if err := character.ValidateName(record.Player.Name); err != nil {
			return savedPlayerValidation{}, fmt.Errorf("invalid saved player name: %w", err)
		}
	}

	if record.ID != playerID ||
		record.Actor == nil ||
		record.Actor.Speed != 10 ||
		record.Position == nil ||
		record.Health == nil ||
		!character.SupportedFighterStart(
			record.Player.SpeciesID,
			record.Player.JobID,
		) ||
		record.Attributes == nil ||
		record.Skills == nil ||
		record.SkillTraining == nil ||
		record.Magic == nil ||
		record.PlayerTurn == nil ||
		record.PlayerTurn.NextAut < 0 ||
		record.MonsterEnergy != nil {
		return savedPlayerValidation{}, fmt.Errorf("invalid player entity %d", record.ID)
	}

	weaponID := record.Player.StartingWeaponID
	profile, err := character.BuildStartProfile(
		g.catalog, record.Player.SpeciesID, record.Player.JobID, weaponID,
	)

	if err != nil {
		return savedPlayerValidation{}, fmt.Errorf("invalid player choice: %w", err)
	}

	xp := 0

	if record.Progression != nil {
		xp = record.Progression.TotalXP
	}

	// Skill points and levels must be checked before HP projects Fighting.
	if err := validateSavedSkillTraining(record, profile, g.catalog, xp); err != nil {
		return savedPlayerValidation{}, err
	}

	xp, err = validateSavedAdvancement(record, profile, g.catalog)

	if err != nil {
		return savedPlayerValidation{}, err
	}

	if record.Durations != nil &&
		(record.Durations.MightAut < 0 ||
			record.Durations.MightAut > character.MightCapAut) {
		return savedPlayerValidation{}, fmt.Errorf(
			"invalid player might duration for entity %d", record.ID,
		)
	}

	if record.Durations != nil &&
		(record.Durations.HasteAut < 0 ||
			record.Durations.HasteAut > character.HasteCapAut) {
		return savedPlayerValidation{}, fmt.Errorf(
			"invalid player haste duration for entity %d", record.ID,
		)
	}

	if record.Poison != nil &&
		(record.Poison.AmountScaled < 1000 ||
			record.Poison.AmountScaled > 2147483647 ||
			record.Poison.SourceMonsterID != "MONS_ADDER") {
		return savedPlayerValidation{}, fmt.Errorf(
			"invalid player poison for entity %d", record.ID,
		)
	}

	if record.Regeneration != nil &&
		(record.Regeneration.HPProgress < 0 ||
			record.Regeneration.HPProgress >= 100 ||
			record.Regeneration.MPProgress < 0 ||
			record.Regeneration.MPProgress >= 100) {
		return savedPlayerValidation{}, fmt.Errorf(
			"invalid player regeneration counters for entity %d", record.ID,
		)
	}

	return savedPlayerValidation{
		xp:        xp,
		weaponID:  weaponID,
		speciesID: record.Player.SpeciesID,
		nextAut:   record.PlayerTurn.NextAut,
		alive:     record.Health.Current > 0,
		pendingStat: record.Progression != nil &&
			record.Progression.PendingStatLevel != 0,
	}, nil
}

func (g *Game) validateSavedMonster(
	record save.EntityRecord,
	currentAut int64,
	scenarioAnimals []string,
	playerAlive bool,
) error {
	if record.Actor == nil ||
		record.Health == nil ||
		record.Position == nil ||
		record.MonsterEnergy == nil ||
		record.PlayerTurn != nil {
		return fmt.Errorf("invalid monster entity %d", record.ID)
	}

	if record.MonsterEnergy.Points < 0 ||
		(playerAlive &&
			record.MonsterEnergy.Points >= monster.ActionEnergyThreshold) {
		return fmt.Errorf("monster %d has invalid action energy", record.ID)
	}

	if record.Health.Current <= 0 {
		return fmt.Errorf("saved monster %d has no remaining HP", record.ID)
	}

	if err := g.validateSavedMonsterAI(record, currentAut); err != nil {
		return err
	}

	definition, err := g.catalog.Monster(record.Actor.KindID)

	if err != nil {
		return err
	}

	if !slices.Contains(scenarioAnimals, record.Actor.KindID) {
		return fmt.Errorf(
			"unsupported melee attacker %s in fixed Dungeon scenario",
			record.Actor.KindID,
		)
	}

	if _, err := character.OrdinaryAnimalExperience(
		definition, record.Health.Max,
	); err != nil {
		return fmt.Errorf(
			"impossible fixed animal maximum HP %d: %w",
			record.Health.Max, err,
		)
	}

	if record.Actor.Speed != definition.Speed {
		return fmt.Errorf(
			"fixed animal %s has wrong speed %d",
			record.Actor.KindID, record.Actor.Speed,
		)
	}

	return nil
}

func (g *Game) validateSavedMonsterAI(
	record save.EntityRecord,
	currentAut int64,
) error {
	ai := record.AI

	switch ai.Behavior {
	case "chase":
		if ai.TargetX != 0 ||
			ai.TargetY != 0 || ai.MemoryUntilAut != 0 {
			return fmt.Errorf("legacy monster %d has a target or memory", record.ID)
		}

	case "wander":
		level := g.levels[record.Position.LevelID]

		if ai.MemoryUntilAut != 0 ||
			level == nil ||
			(ai.TargetX != 0 ||
				ai.TargetY != 0) &&
				!level.Walkable(ai.TargetX, ai.TargetY) {
			return fmt.Errorf(
				"wandering monster %d has invalid target or memory", record.ID,
			)
		}

	case "seek":
		level := g.levels[record.Position.LevelID]

		if level == nil ||
			!level.Walkable(ai.TargetX, ai.TargetY) ||
			ai.MemoryUntilAut < 0 || ai.MemoryUntilAut > currentAut+550 {
			return fmt.Errorf("monster %d has invalid remembered target", record.ID)
		}

	default:
		return fmt.Errorf(
			"monster %d has invalid behavior %q", record.ID, ai.Behavior,
		)
	}

	return nil
}

func (g *Game) validateSavedExperience(
	savedXP int,
	scenarioAnimals []string,
	usesPopulation bool,
	monsters savedMonsterValidation,
) error {
	maxEarnedXP := 0

	for _, id := range scenarioAnimals {
		if !usesPopulation && monsters.liveByKind[id] {
			continue
		}

		definition, err := g.catalog.Monster(id)

		if err != nil {
			return err
		}

		profile, _ := character.OrdinaryAnimalProfile(id)
		amount, err := character.OrdinaryAnimalExperience(
			definition, profile.MaxHP,
		)

		if err != nil {
			return err
		}

		if usesPopulation {
			maxEarnedXP = max(maxEarnedXP, amount)
		} else {
			maxEarnedXP += amount
		}
	}

	if usesPopulation {
		initialMonsterCount := 0

		for _, level := range g.levels {
			initialMonsterCount += initialActorBudget(level, g.scenarioID)
		}

		maxEarnedXP *= initialMonsterCount - monsters.liveCount
	}

	if savedXP > maxEarnedXP {
		return fmt.Errorf("saved experience exceeds possible Dungeon kills")
	}

	return nil
}

func (g *Game) validateSavedEquipment(slots map[string]string, speciesID string) error {
	species, err := g.catalog.Species(speciesID)

	if err != nil {
		return err
	}

	if slots["head"] == "ARM_HELMET" {
		headgear, err := g.catalog.Item(slots["head"])

		if err != nil {
			return err
		}

		if hardHelmetConflicts(headgear, species) {
			return fmt.Errorf("saved helmet conflicts with horns")
		}
	}

	if slots["weapon"] == "" {
		return nil
	}

	kind, err := g.catalog.Item(slots["weapon"])

	if err != nil {
		return err
	}

	if !supportsWieldedWeapon(kind) {
		return fmt.Errorf("unsupported equipped weapon %s", kind.ID)
	}

	incompatible, err := weaponNeedsSecondHand(kind, species.Size)

	if err != nil {
		return err
	}

	if incompatible && slots["shield"] != "" {
		return fmt.Errorf("equipped weapon %s conflicts with shield", kind.ID)
	}

	return nil
}

func validateSavedStartingWeapon(records []save.EntityRecord, weaponID string) error {
	for _, record := range records {
		if record.Item != nil &&
			record.Item.KindID == weaponID &&
			(record.Position != nil || record.CarriedBy != nil) {
			return nil
		}
	}

	return fmt.Errorf("save is missing selected starting weapon %s", weaponID)
}
