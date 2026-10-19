package game

import (
	"fmt"

	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/save"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

func (g *Game) restoreEntityComponents(records []save.EntityRecord) error {
	for _, record := range records {
		entity := akara.Entity(record.ID)

		if err := g.restoreActorComponents(record, entity); err != nil {
			return err
		}

		if err := g.restoreRoleComponents(record, entity); err != nil {
			return err
		}

		if err := g.restoreLocationComponents(record, entity); err != nil {
			return err
		}
	}

	return nil
}

func (g *Game) restoreActorComponents(
	record save.EntityRecord,
	entity akara.Entity,
) error {
	if record.Actor != nil {
		if _, err := g.stores.Actors.Set(entity, *record.Actor); err != nil {
			return err
		}
	}

	if record.PlayerTurn != nil {
		if _, err := g.stores.PlayerTurn.Set(entity, *record.PlayerTurn); err != nil {
			return err
		}
	}

	if record.MonsterEnergy != nil {
		if _, err := g.stores.MonsterEnergy.Set(entity, *record.MonsterEnergy); err != nil {
			return err
		}
	}

	if record.Health != nil {
		if _, err := g.stores.Health.Set(entity, *record.Health); err != nil {
			return err
		}
	}

	if record.Magic != nil {
		if _, err := g.stores.Magic.Set(entity, *record.Magic); err != nil {
			return err
		}
	}

	if record.Skills != nil {
		savedSkills := ecs.Skills{
			Entries: append([]character.Skill(nil), record.Skills.Entries...),
		}

		if _, err := g.stores.Skills.Set(entity, savedSkills); err != nil {
			return err
		}
	}

	if record.SkillTraining != nil {
		copy := record.SkillTraining.Clone()

		if _, err := g.stores.SkillTraining.Set(entity, copy); err != nil {
			return err
		}
	}

	if record.Player != nil {
		progress := ecs.Progression{Level: 1}

		if record.Progression != nil {
			progress = *record.Progression
		}

		if _, err := g.stores.Progression.Set(entity, progress); err != nil {
			return err
		}

		durations := ecs.Durations{}

		if record.Durations != nil {
			durations = *record.Durations
		}

		if _, err := g.stores.Durations.Set(entity, durations); err != nil {
			return err
		}

		if record.Poison != nil {
			if _, err := g.stores.Poison.Set(entity, *record.Poison); err != nil {
				return err
			}
		}

		if record.Constricted != nil {
			if _, err := g.stores.Constricted.Set(entity, *record.Constricted); err != nil {
				return err
			}
		}

		regeneration := ecs.Regeneration{}

		if record.Regeneration != nil {
			regeneration = *record.Regeneration
		}

		if _, err := g.stores.Regeneration.Set(entity, regeneration); err != nil {
			return err
		}

		if record.Equipment != nil {
			if _, err := g.stores.Equipment.Set(entity, *record.Equipment); err != nil {
				return err
			}
		}
	}

	if record.Combatant != nil {
		if _, err := g.stores.Combat.Set(entity, *record.Combatant); err != nil {
			return err
		}
	}

	return nil
}

func (g *Game) restoreRoleComponents(
	record save.EntityRecord,
	entity akara.Entity,
) error {
	if record.Player != nil {
		if _, err := g.stores.Players.Set(entity, *record.Player); err != nil {
			return err
		}
	}

	if record.Attributes != nil {
		if _, err := g.stores.Attributes.Set(entity, *record.Attributes); err != nil {
			return err
		}
	}

	if record.AI != nil {
		if _, err := g.stores.AI.Set(entity, *record.AI); err != nil {
			return err
		}
	}

	if record.BandFollower != nil {
		if _, err := g.stores.Followers.Set(entity, *record.BandFollower); err != nil {
			return err
		}
	}

	if record.Item != nil {
		if _, err := g.stores.Items.Set(entity, *record.Item); err != nil {
			return err
		}
	}

	if record.Corpse != nil {
		if _, err := g.stores.Corpses.Set(entity, *record.Corpse); err != nil {
			return err
		}
	}

	return nil
}

func (g *Game) restoreLocationComponents(
	record save.EntityRecord,
	entity akara.Entity,
) error {
	if record.Position != nil {
		level, found := g.levels[record.Position.LevelID]

		gateway := found &&
			level.inBounds(record.Position.X, record.Position.Y) &&
			level.terrain[record.Position.Y][record.Position.X] == terrain.MalignGateway
		portalOccupant := record.Item != nil ||
			(record.Actor != nil && record.Actor.KindID == "MONS_ELDRITCH_TENTACLE")

		if !found || (!level.Walkable(record.Position.X, record.Position.Y) &&
			!(gateway && portalOccupant)) {
			return fmt.Errorf("entity %d has invalid position %+v", record.ID, *record.Position)
		}

		if record.Actor != nil {
			if err := level.PlaceActor(entity, record.Position.X, record.Position.Y); err != nil {
				return err
			}
		} else if _, err := g.stores.Positions.Set(entity, *record.Position); err != nil {
			return err
		}
	}

	if record.CarriedBy != nil {
		if _, err := g.stores.CarriedBy.Set(entity, *record.CarriedBy); err != nil {
			return err
		}
	}

	if record.ReservedBy != nil {
		if _, err := g.stores.ReservedBy.Set(entity, *record.ReservedBy); err != nil {
			return err
		}
	}

	if record.Equipped != nil {
		if _, err := g.stores.Equipped.Set(entity, *record.Equipped); err != nil {
			return err
		}
	}

	return nil
}

func (g *Game) validateRestoredPlacement() error {
	if _, err := g.scripts.Policy("save.validate_vault_ids", map[string]any{
		"levels": g.vaultValidationLevels(),
	}); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_shops", map[string]any{
		"scenario_id": g.scenarioID,
		"levels":      g.vaultValidationLevels(),
	}); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_clouds", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_traps", map[string]any{
		"levels": g.vaultValidationLevels(),
	}); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_item_generation", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_artefacts", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_reservations", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_vault_entities", map[string]any{
		"levels": g.vaultValidationLevels(),
	}); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_training", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_player", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_status", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_equipment", nil); err != nil {
		return err
	}

	if _, err := g.scripts.Policy("save.validate_corpses", map[string]any{
		"scenario_id": g.scenarioID,
	}); err != nil {
		return err
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	if _, err := g.scripts.Policy("save.validate_monsters", map[string]any{
		"scenario_id":  g.scenarioID,
		"current_aut":  int64(g.currentAut),
		"player_alive": playerHealth.Current > 0,
		"levels":       scenarioLevelPolicyRecords(g.levels),
	}); err != nil {
		return err
	}

	initialCount := 0

	for _, level := range g.levels {
		initialCount += level.initialActors
	}

	if _, err := g.scripts.Policy("save.validate_experience", map[string]any{
		"scenario_id":   g.scenarioID,
		"initial_count": initialCount,
		"vault_levels":  g.vaultValidationLevels(),
	}); err != nil {
		return err
	}

	playerPosition, positioned := g.stores.Positions.Get(g.player)

	if !positioned {
		return fmt.Errorf("saved player has no position")
	}

	if g.levels[playerPosition.LevelID].awaySinceAut != nil {
		return fmt.Errorf("active level %d is marked away", playerPosition.LevelID)
	}

	for _, entity := range g.stores.Corpses.Entities() {
		position, _ := g.stores.Positions.Get(entity)

		if position.LevelID != playerPosition.LevelID {
			if g.levels[position.LevelID].awaySinceAut == nil {
				return fmt.Errorf("inactive corpse level %d lacks away clock", position.LevelID)
			}
		}
	}

	return nil
}
