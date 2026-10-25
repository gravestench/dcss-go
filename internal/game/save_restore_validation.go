package game

import (
	"fmt"

	"crawl/internal/save"
	"github.com/gravestench/akara"
)

type savedPlayerValidation struct {
	nextAut     int64
	alive       bool
	pendingStat bool
}

// savedEntityValidator owns bookkeeping only for one restore attempt.
// Each record is checked before its entity ID is registered in Akara.
type savedEntityValidator struct {
	game     *Game
	snapshot save.Snapshot
	seen     map[uint64]bool
	records  map[uint64]save.EntityRecord

	player        savedPlayerValidation
	playerCount   int
	activeLevelID int
}

func (g *Game) validateAndRegisterSavedEntities(snapshot save.Snapshot) error {
	validator := savedEntityValidator{
		game:     g,
		snapshot: snapshot,

		seen:    make(map[uint64]bool),
		records: make(map[uint64]save.EntityRecord),
	}

	return validator.validate()
}

func (v *savedEntityValidator) validate() error {
	for _, record := range v.snapshot.Entities {
		if record.ID == v.snapshot.PlayerID && record.Position != nil {
			v.activeLevelID = record.Position.LevelID

			break
		}
	}

	if v.activeLevelID == 0 {
		return fmt.Errorf("saved player has no active level")
	}

	for _, record := range v.snapshot.Entities {
		if err := v.validateRecord(record); err != nil {
			return err
		}
	}

	for _, record := range v.snapshot.Entities {
		if record.ReservedBy == nil {
			continue
		}

		owner := record.ReservedBy.Owner
		ownerRecord, found := v.records[uint64(owner)]

		if !found ||
			ownerRecord.ReservedBy != nil ||
			ownerRecord.Item == nil {
			return fmt.Errorf("item %d has dead or reserved reservation owner %d", record.ID, owner)
		}
	}

	return v.validateFinalState()
}

func (v *savedEntityValidator) validateRecord(record save.EntityRecord) error {
	if record.ID == 0 || v.seen[record.ID] {
		return fmt.Errorf("duplicate or zero entity ID %d", record.ID)
	}

	v.seen[record.ID] = true
	v.records[record.ID] = record

	if err := v.validateItemRole(record); err != nil {
		return err
	}

	if err := v.validateCharacterRole(record); err != nil {
		return err
	}

	if err := v.validateMonsterRole(record); err != nil {
		return err
	}

	if err := v.validateActorState(record); err != nil {
		return err
	}

	return v.game.world.CreateEntityWithID(akara.Entity(record.ID))
}

func (v *savedEntityValidator) validateItemRole(record save.EntityRecord) error {
	if record.Item != nil {
		if err := validateSavedItem(record); err != nil {
			return err
		}
	} else if record.CarriedBy != nil ||
		record.ReservedBy != nil ||
		record.Equipped != nil ||
		record.Corpse != nil {
		return fmt.Errorf("non-item %d has item location or equipment slot", record.ID)
	}

	if record.Actor == nil &&
		record.Item == nil &&
		len(record.Dynamic) == 0 {
		return fmt.Errorf("entity %d has no actor or item role", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateCharacterRole(record save.EntityRecord) error {
	if record.Player != nil && record.AI != nil {
		return fmt.Errorf("entity %d is both player and monster", record.ID)
	}

	if record.Player != nil {
		validated, err := v.game.validateSavedPlayer(record, v.snapshot.PlayerID)

		if err != nil {
			return err
		}

		v.playerCount++
		v.player = validated
	} else if record.Attributes != nil ||
		record.Skills != nil ||
		record.SkillTraining != nil ||
		record.Magic != nil ||
		record.PlayerTurn != nil ||
		record.Progression != nil ||
		record.Durations != nil ||
		record.Regeneration != nil ||
		record.Poison != nil ||
		record.Equipment != nil {
		return fmt.Errorf("non-player entity %d has character components", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateMonsterRole(record save.EntityRecord) error {
	if record.AI == nil {
		return nil
	}

	if record.Actor == nil ||
		record.Health == nil ||
		record.Position == nil ||
		record.MonsterEnergy == nil ||
		record.PlayerTurn != nil {
		return fmt.Errorf("invalid monster entity %d", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateActorState(record save.EntityRecord) error {
	if record.Actor != nil &&
		(record.Health == nil ||
			record.Combatant == nil || record.Position == nil) {
		return fmt.Errorf("invalid actor %d", record.ID)
	}

	if record.Combatant != nil && record.Actor == nil {
		return fmt.Errorf("invalid combat stats for entity %d", record.ID)
	}

	if record.Actor != nil &&
		record.Player == nil && record.AI == nil {
		return fmt.Errorf("actor %d has no player or monster role", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateFinalState() error {
	if v.playerCount != 1 {
		return fmt.Errorf("save requires exactly one player, found %d", v.playerCount)
	}

	// A player-action award pauses before the monster phase, leaving the
	// next turn clock in the future. An allied kill during the monster phase
	// can prompt at the completed turn boundary, when the clocks are equal.
	if v.player.alive {
		if v.player.pendingStat {
			if v.player.nextAut < v.snapshot.CurrentAut {
				return fmt.Errorf("invalid pending player turn clock")
			}
		} else if v.player.nextAut != v.snapshot.CurrentAut {
			return fmt.Errorf("save clock does not match the next player turn")
		}
	}

	return nil
}
