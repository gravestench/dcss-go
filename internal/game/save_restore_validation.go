package game

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

type savedPlayerValidation struct {
	xp          int
	weaponID    string
	nextAut     int64
	alive       bool
	pendingStat bool
}

type savedMonsterValidation struct {
	liveByKind  map[string]bool
	liveByLevel map[int]int
	liveCount   int
}

func newSavedMonsterValidation() savedMonsterValidation {
	return savedMonsterValidation{
		liveByKind:  make(map[string]bool),
		liveByLevel: make(map[int]int),
	}
}

func (g *Game) validateAndRegisterSavedEntities(
	snapshot save.Snapshot,
	scenarioAnimals []string,
	usesPopulation bool,
) error {
	seen := make(map[uint64]bool)
	player := savedPlayerValidation{}
	playerCount := 0
	monsters := newSavedMonsterValidation()
	equippedSlots := map[string]string{}
	var earliestID uint64
	var earliestAut int64
	activeLevelID := 0

	for _, record := range snapshot.Entities {
		if record.ID == snapshot.PlayerID && record.Position != nil {
			activeLevelID = record.Position.LevelID

			break
		}
	}

	if activeLevelID == 0 {
		return fmt.Errorf("saved player has no active level")
	}

	for _, record := range snapshot.Entities {
		if record.ID == 0 || seen[record.ID] {
			return fmt.Errorf("duplicate or zero entity ID %d", record.ID)
		}

		seen[record.ID] = true

		if record.Item != nil {
			if record.Corpse != nil && !slices.Contains(scenarioAnimals, record.Corpse.MonsterID) {
				return fmt.Errorf("fixed Dungeon save has unsupported corpse %s", record.Corpse.MonsterID)
			}

			if err := validateSavedItem(record, g.catalog, g.player, equippedSlots); err != nil {
				return err
			}
		} else if record.CarriedBy != nil || record.Equipped != nil || record.Corpse != nil {
			return fmt.Errorf("non-item %d has carrier or equipment slot", record.ID)
		}

		if record.Actor == nil && record.Item == nil {
			return fmt.Errorf("entity %d has no actor or item role", record.ID)
		}

		if record.Player != nil && record.AI != nil {
			return fmt.Errorf("entity %d is both player and monster", record.ID)
		}

		if record.Player != nil {
			validated, err := g.validateSavedPlayer(record, snapshot.PlayerID)

			if err != nil {
				return err
			}

			playerCount++
			player = validated
		} else if record.Attributes != nil || record.Skills != nil ||
			record.Magic != nil || record.Progression != nil ||
			record.Durations != nil || record.Regeneration != nil {
			return fmt.Errorf("non-player entity %d has character components", record.ID)
		}

		if record.AI != nil {
			if err := g.validateSavedMonster(record, snapshot.CurrentAut, scenarioAnimals); err != nil {
				return err
			}

			if !usesPopulation && monsters.liveByKind[record.Actor.KindID] {
				return fmt.Errorf("duplicate fixed animal %s", record.Actor.KindID)
			}

			monsters.liveByKind[record.Actor.KindID] = true

			if usesPopulation {
				levelID := record.Position.LevelID
				monsters.liveByLevel[levelID]++
				monsters.liveCount++

				if monsters.liveByLevel[levelID] > initialMonsterBudget(g.levels[levelID], snapshot.ScenarioID) {
					return fmt.Errorf("Dungeon:%d has too many live monsters", levelID)
				}
			}
		}

		if record.Actor != nil &&
			(record.Actor.Speed <= 0 || record.Actor.NextAut < 0 ||
				record.Health == nil || record.Combatant == nil || record.Position == nil) {
			return fmt.Errorf("invalid actor %d", record.ID)
		}

		if record.Combatant != nil &&
			(record.Actor == nil || record.Combatant.ShieldBlocks < 0 ||
				record.Combatant.ShieldBlocks > 100) {
			return fmt.Errorf("invalid combat stats for entity %d", record.ID)
		}

		if record.Actor != nil && record.Player == nil && record.AI == nil {
			return fmt.Errorf("actor %d has no player or monster role", record.ID)
		}

		if record.Actor != nil && record.Position != nil && record.Position.LevelID == activeLevelID {
			if record.Actor.NextAut < snapshot.CurrentAut {
				return fmt.Errorf("actor %d deadline precedes save clock", record.ID)
			}

			if earliestID == 0 || record.Actor.NextAut < earliestAut ||
				(record.Actor.NextAut == earliestAut && record.ID < earliestID) {
				earliestID, earliestAut = record.ID, record.Actor.NextAut
			}
		}

		if record.Health != nil &&
			(record.Health.Current < 0 || record.Health.Max <= 0 ||
				record.Health.Current > record.Health.Max) {
			return fmt.Errorf("invalid health for entity %d", record.ID)
		}

		if err := g.world.CreateEntityWithID(akara.Entity(record.ID)); err != nil {
			return err
		}
	}

	if playerCount != 1 {
		return fmt.Errorf("save requires exactly one player, found %d", playerCount)
	}

	if err := g.validateSavedExperience(player.xp, scenarioAnimals, usesPopulation, monsters); err != nil {
		return err
	}

	if err := validateSavedEquipment(equippedSlots, player.weaponID); err != nil {
		return err
	}

	// A stat prompt pauses before the monster phase at the start of the
	// player's spent turn. Its next deadline is therefore still in the future.
	if player.alive {
		if player.pendingStat {
			if player.nextAut <= snapshot.CurrentAut {
				return fmt.Errorf("invalid pending player turn clock")
			}
		} else if player.nextAut != snapshot.CurrentAut || earliestID != snapshot.PlayerID {
			return fmt.Errorf("save clock does not match the next player turn")
		}
	}

	return nil
}
