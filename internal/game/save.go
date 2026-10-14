package game

import (
	"fmt"
	"slices"
	"sort"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func copyComponent[T any](store *akara.Store[T], entity akara.Entity) *T {
	value, found := store.Get(entity)
	if !found {
		return nil
	}
	copy := *value
	return &copy
}

func copySkillsComponent(store *akara.Store[ecs.Skills], entity akara.Entity) *ecs.Skills {
	copy := copyComponent(store, entity)
	if copy != nil {
		copy.Entries = append([]character.Skill(nil), copy.Entries...)
	}
	return copy
}

func validateSavedItem(record save.EntityRecord, catalog content.Catalog, player akara.Entity, occupied map[string]string) error {
	item := record.Item
	kind, err := catalog.Item(item.KindID)
	if err != nil {
		return err
	}
	if err := validateItemProperties(*item, kind); err != nil {
		return fmt.Errorf("item %d has %w", record.ID, err)
	}
	if (record.Position == nil) == (record.CarriedBy == nil) || record.Actor != nil {
		return fmt.Errorf("item %d must have exactly one of position or carrier, never both", record.ID)
	}
	corpseKind := item.KindID == "CORPSE_BODY" || item.KindID == "CORPSE_SKELETON"
	if corpseKind != (record.Corpse != nil) {
		return fmt.Errorf("item %d has mismatched corpse state", record.ID)
	}
	if corpseKind && (record.Position == nil || record.CarriedBy != nil || record.Equipped != nil || item.Quantity != 1 ||
		!isOrdinaryAnimal(record.Corpse.MonsterID) || record.Corpse.Freshness < 1 || record.Corpse.Freshness > 110 ||
		record.Corpse.Appearance < 1 || record.Corpse.Appearance > 255) {
		return fmt.Errorf("item %d has invalid ordinary animal corpse state", record.ID)
	}
	if record.Health != nil || record.Magic != nil || record.Skills != nil || record.Progression != nil || record.Durations != nil || record.Regeneration != nil || record.Combatant != nil || record.Player != nil || record.AI != nil || record.Attributes != nil {
		return fmt.Errorf("item %d has actor components", record.ID)
	}
	if record.Equipped == nil {
		return nil
	}
	if record.CarriedBy == nil || record.CarriedBy.Holder != player || record.Position != nil || kind.Slot == "" || record.Equipped.Slot != kind.Slot {
		return fmt.Errorf("item %d has invalid equipped slot or carrier", record.ID)
	}
	if _, duplicate := occupied[kind.Slot]; duplicate {
		return fmt.Errorf("duplicate equipped slot %s", kind.Slot)
	}
	occupied[kind.Slot] = kind.ID
	return nil
}

func (g *Game) Snapshot() save.Snapshot {
	snapshot := save.Snapshot{Version: save.Version, SourceRevision: g.catalog.SourceRevision(), ScenarioID: g.scenarioID,
		PlayerID: uint64(g.player), CurrentAut: int64(g.currentAut), Seed: g.seed,
		RNG: g.rng.States(), Messages: append([]string(nil), g.messages...)}
	for id, level := range g.levels {
		record := save.LevelRecord{ID: id, Rows: append([]string(nil), level.terrain...), Known: level.KnownRows()}
		if awayAt, away := g.levelAwaySince[id]; away {
			since := int64(awayAt)
			record.AwaySinceAut = &since
		}
		snapshot.Levels = append(snapshot.Levels, record)
	}
	sort.Slice(snapshot.Levels, func(i, j int) bool { return snapshot.Levels[i].ID < snapshot.Levels[j].ID })
	for _, entity := range g.world.Entities() {
		snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
			ID: uint64(entity), Position: copyComponent(g.stores.Positions, entity),
			Actor: copyComponent(g.stores.Actors, entity), Health: copyComponent(g.stores.Health, entity),
			Magic: copyComponent(g.stores.Magic, entity), Skills: copySkillsComponent(g.stores.Skills, entity),
			Progression:  copyComponent(g.stores.Progression, entity),
			Durations:    copyComponent(g.stores.Durations, entity),
			Regeneration: copyComponent(g.stores.Regeneration, entity),
			Combatant:    copyComponent(g.stores.Combat, entity), Player: copyComponent(g.stores.Players, entity),
			Attributes: copyComponent(g.stores.Attributes, entity),
			AI:         copyComponent(g.stores.AI, entity), Item: copyComponent(g.stores.Items, entity),
			Corpse:    copyComponent(g.stores.Corpses, entity),
			CarriedBy: copyComponent(g.stores.CarriedBy, entity),
			Equipped:  copyComponent(g.stores.Equipped, entity),
		})
	}
	sort.Slice(snapshot.Entities, func(i, j int) bool { return snapshot.Entities[i].ID < snapshot.Entities[j].ID })
	return snapshot
}

func (g *Game) Restore(snapshot save.Snapshot) (*Game, error) {
	return Restore(snapshot, g.catalog)
}

// Restore builds a separate game. The caller replaces its live game only after success.
func Restore(snapshot save.Snapshot, catalog content.Catalog) (_ *Game, err error) {
	if snapshot.Version != save.Version {
		return nil, fmt.Errorf("unsupported save version %d", snapshot.Version)
	}
	if err := catalog.Validate(); err != nil {
		return nil, err
	}
	if snapshot.SourceRevision != catalog.SourceRevision() {
		return nil, fmt.Errorf("save source revision %q does not match catalog", snapshot.SourceRevision)
	}
	if snapshot.ScenarioID != "" && snapshot.ScenarioID != ordinaryAnimalScenarioID {
		return nil, fmt.Errorf("unsupported scenario ID %q", snapshot.ScenarioID)
	}
	if snapshot.PlayerID == 0 || snapshot.CurrentAut < 0 || len(snapshot.Levels) == 0 {
		return nil, fmt.Errorf("invalid save header")
	}
	world := akara.NewWorld()
	defer func() {
		if err != nil {
			_ = world.Close()
		}
	}()
	stores := ecs.Register(world)
	g := &Game{world: world, stores: stores, levels: make(map[int]*Level), player: akara.Entity(snapshot.PlayerID),
		catalog: catalog, seed: snapshot.Seed, scenarioID: snapshot.ScenarioID, rng: RestoreRNGStreams(snapshot.Seed, snapshot.RNG),
		scheduler: TurnScheduler{actors: stores.Actors}, currentAut: Aut(snapshot.CurrentAut), levelAwaySince: make(map[int]Aut),
		messages: append([]string(nil), snapshot.Messages...)}
	for _, record := range snapshot.Levels {
		if _, duplicate := g.levels[record.ID]; duplicate {
			return nil, fmt.Errorf("duplicate level %d", record.ID)
		}
		level, levelErr := NewLevel(record.ID, record.Rows, stores.Positions)
		if levelErr != nil {
			return nil, levelErr
		}
		if knownErr := level.LoadKnownRows(record.Known); knownErr != nil {
			return nil, knownErr
		}
		g.levels[record.ID] = level
		if record.AwaySinceAut != nil {
			if *record.AwaySinceAut < 0 || *record.AwaySinceAut > snapshot.CurrentAut {
				return nil, fmt.Errorf("invalid level %d away clock", record.ID)
			}
			g.levelAwaySince[record.ID] = Aut(*record.AwaySinceAut)
		}
	}
	if g.levels[1] == nil || g.levels[2] == nil {
		return nil, fmt.Errorf("save is missing a Dungeon floor")
	}
	if _, _, ok := g.levels[1].FindUniqueTerrain('>'); !ok {
		return nil, fmt.Errorf("Dungeon:1 must have one down stair")
	}
	if _, _, ok := g.levels[2].FindUniqueTerrain('<'); !ok {
		return nil, fmt.Errorf("Dungeon:2 must have one up stair")
	}
	seen := make(map[uint64]bool)
	playerCount := 0
	savedXP := 0
	liveAnimals := map[string]bool{}
	selectedWeaponID := ""
	equippedSlots := map[string]string{}
	var playerNext int64
	var playerAlive bool
	var earliestID uint64
	var earliestAut int64
	for _, record := range snapshot.Entities {
		if record.ID == 0 || seen[record.ID] {
			return nil, fmt.Errorf("duplicate or zero entity ID %d", record.ID)
		}
		seen[record.ID] = true
		if record.Item != nil {
			if snapshot.ScenarioID == "" && record.Corpse != nil && record.Corpse.MonsterID != "MONS_RAT" {
				return nil, fmt.Errorf("legacy fixed Dungeon save has unsupported corpse %s", record.Corpse.MonsterID)
			}
			if err := validateSavedItem(record, catalog, g.player, equippedSlots); err != nil {
				return nil, err
			}
		} else if record.CarriedBy != nil || record.Equipped != nil || record.Corpse != nil {
			return nil, fmt.Errorf("non-item %d has carrier or equipment slot", record.ID)
		}
		if record.Actor == nil && record.Item == nil {
			return nil, fmt.Errorf("entity %d has no actor or item role", record.ID)
		}
		if record.Player != nil && record.AI != nil {
			return nil, fmt.Errorf("entity %d is both player and monster", record.ID)
		}
		if record.Player != nil {
			playerCount++
			if record.Player.Name != "" {
				if nameErr := character.ValidateName(record.Player.Name); nameErr != nil {
					return nil, fmt.Errorf("invalid saved player name: %w", nameErr)
				}
			}
			selectedWeaponID = record.Player.StartingWeaponID
			definition := catalog.Player()
			if record.ID != snapshot.PlayerID || record.Actor == nil || record.Position == nil || record.Health == nil ||
				record.Player.SpeciesID != definition.SpeciesID || record.Player.JobID != definition.JobID || record.Attributes == nil || record.Skills == nil || record.Magic == nil {
				return nil, fmt.Errorf("invalid player entity %d", record.ID)
			}
			profile, profileErr := character.BuildStartProfile(catalog, record.Player.SpeciesID, record.Player.JobID, selectedWeaponID)
			if profileErr != nil {
				return nil, fmt.Errorf("invalid player choice: %w", profileErr)
			}
			if record.Attributes.Strength <= 0 || record.Attributes.Intelligence <= 0 || record.Attributes.Dexterity <= 0 ||
				*record.Attributes != (ecs.Attributes{Strength: profile.Attributes.Strength, Intelligence: profile.Attributes.Intelligence, Dexterity: profile.Attributes.Dexterity}) {
				return nil, fmt.Errorf("invalid player attributes for entity %d", record.ID)
			}
			if !slices.Equal(record.Skills.Entries, profile.Skills) {
				return nil, fmt.Errorf("invalid player skills for entity %d", record.ID)
			}
			if record.Health.Max != profile.MaxHP {
				return nil, fmt.Errorf("invalid player max HP for entity %d", record.ID)
			}
			if record.Magic.Max != profile.MaxMP || record.Magic.Current < 0 || record.Magic.Current > record.Magic.Max {
				return nil, fmt.Errorf("invalid player MP for entity %d", record.ID)
			}
			if record.Progression != nil && (record.Progression.TotalXP < 0 || record.Progression.TotalXP >= 9) {
				return nil, fmt.Errorf("invalid fixed Dungeon experience for entity %d", record.ID)
			}
			if record.Progression != nil {
				savedXP = record.Progression.TotalXP
			}
			if record.Durations != nil && (record.Durations.MightAut < 0 || record.Durations.MightAut > character.MightCapAut) {
				return nil, fmt.Errorf("invalid player might duration for entity %d", record.ID)
			}
			if record.Regeneration != nil && (record.Regeneration.HPProgress < 0 || record.Regeneration.HPProgress >= 100 || record.Regeneration.MPProgress < 0 || record.Regeneration.MPProgress >= 100) {
				return nil, fmt.Errorf("invalid player regeneration counters for entity %d", record.ID)
			}
			playerNext = record.Actor.NextAut
			playerAlive = record.Health.Current > 0
		} else if record.Attributes != nil || record.Skills != nil || record.Magic != nil || record.Progression != nil || record.Durations != nil || record.Regeneration != nil {
			return nil, fmt.Errorf("non-player entity %d has character components", record.ID)
		}
		if record.AI != nil {
			if record.Actor == nil || record.Health == nil || record.Position == nil {
				return nil, fmt.Errorf("invalid monster entity %d", record.ID)
			}
			switch record.AI.Behavior {
			case "wander", "chase":
				if record.AI.TargetX != 0 || record.AI.TargetY != 0 {
					return nil, fmt.Errorf("non-seeking monster %d has a target", record.ID)
				}
			case "seek":
				level := g.levels[record.Position.LevelID]
				if level == nil || !level.Walkable(record.AI.TargetX, record.AI.TargetY) {
					return nil, fmt.Errorf("monster %d has invalid remembered target", record.ID)
				}
			default:
				return nil, fmt.Errorf("monster %d has invalid behavior %q", record.ID, record.AI.Behavior)
			}
			if _, err := catalog.Monster(record.Actor.KindID); err != nil {
				return nil, err
			}
			if !isOrdinaryAnimal(record.Actor.KindID) || (snapshot.ScenarioID == "" && record.Actor.KindID != "MONS_RAT") {
				return nil, fmt.Errorf("unsupported melee attacker %s in fixed Dungeon scenario", record.Actor.KindID)
			}
			definition, definitionErr := catalog.Monster(record.Actor.KindID)
			if definitionErr != nil {
				return nil, definitionErr
			}
			if _, xpErr := character.OrdinaryAnimalExperience(definition, record.Health.Max); xpErr != nil {
				return nil, fmt.Errorf("impossible fixed animal maximum HP %d: %w", record.Health.Max, xpErr)
			}
			if record.Actor.Speed != definition.Speed {
				return nil, fmt.Errorf("fixed animal %s has wrong speed %d", record.Actor.KindID, record.Actor.Speed)
			}
			if liveAnimals[record.Actor.KindID] {
				return nil, fmt.Errorf("duplicate fixed animal %s", record.Actor.KindID)
			}
			liveAnimals[record.Actor.KindID] = true
		}
		if record.Actor != nil && (record.Actor.Speed <= 0 || record.Actor.NextAut < 0 || record.Health == nil || record.Combatant == nil || record.Position == nil) {
			return nil, fmt.Errorf("invalid actor %d", record.ID)
		}
		if record.Combatant != nil && (record.Actor == nil || record.Combatant.ShieldBlocks < 0 || record.Combatant.ShieldBlocks > 100) {
			return nil, fmt.Errorf("invalid combat stats for entity %d", record.ID)
		}
		if record.Actor != nil && record.Player == nil && record.AI == nil {
			return nil, fmt.Errorf("actor %d has no player or monster role", record.ID)
		}
		if record.Actor != nil {
			if record.Actor.NextAut < snapshot.CurrentAut {
				return nil, fmt.Errorf("actor %d deadline precedes save clock", record.ID)
			}
			if earliestID == 0 || record.Actor.NextAut < earliestAut || (record.Actor.NextAut == earliestAut && record.ID < earliestID) {
				earliestID, earliestAut = record.ID, record.Actor.NextAut
			}
		}
		if record.Health != nil && (record.Health.Current < 0 || record.Health.Max <= 0 || record.Health.Current > record.Health.Max) {
			return nil, fmt.Errorf("invalid health for entity %d", record.ID)
		}
		if err := world.CreateEntityWithID(akara.Entity(record.ID)); err != nil {
			return nil, err
		}
	}
	if playerCount != 1 {
		return nil, fmt.Errorf("save requires exactly one player, found %d", playerCount)
	}
	maxEarnedXP := 0
	if !liveAnimals["MONS_RAT"] {
		maxEarnedXP++
	}
	if snapshot.ScenarioID == ordinaryAnimalScenarioID && !liveAnimals["MONS_QUOKKA"] {
		maxEarnedXP += 2
	}
	if savedXP > maxEarnedXP {
		return nil, fmt.Errorf("saved experience exceeds killed fixed animals")
	}
	if equippedSlots["body"] != "ARM_SCALE_MAIL" || equippedSlots["shield"] != "ARM_BUCKLER" {
		return nil, fmt.Errorf("save is missing required Human/Fighter armour slots")
	}
	if selectedWeaponID == "WPN_UNARMED" {
		if equippedSlots["weapon"] != "" {
			return nil, fmt.Errorf("unarmed start has an equipped weapon")
		}
	} else if equippedSlots["weapon"] != selectedWeaponID {
		return nil, fmt.Errorf("selected starting weapon %s disagrees with equipped weapon %s", selectedWeaponID, equippedSlots["weapon"])
	}
	// Between live turns the player is next at the displayed clock. A dead
	// player can retain a later deadline after a monster's killing action.
	if playerAlive && (playerNext != snapshot.CurrentAut || earliestID != snapshot.PlayerID) {
		return nil, fmt.Errorf("save clock does not match the next player turn")
	}
	for _, record := range snapshot.Entities {
		entity := akara.Entity(record.ID)
		if record.Actor != nil {
			if _, err := stores.Actors.Set(entity, *record.Actor); err != nil {
				return nil, err
			}
		}
		if record.Health != nil {
			if _, err := stores.Health.Set(entity, *record.Health); err != nil {
				return nil, err
			}
		}
		if record.Magic != nil {
			if _, err := stores.Magic.Set(entity, *record.Magic); err != nil {
				return nil, err
			}
		}
		if record.Skills != nil {
			if _, err := stores.Skills.Set(entity, ecs.Skills{Entries: append([]character.Skill(nil), record.Skills.Entries...)}); err != nil {
				return nil, err
			}
		}
		if record.Player != nil {
			progress := ecs.Progression{}
			if record.Progression != nil {
				progress = *record.Progression
			}
			if _, err := stores.Progression.Set(entity, progress); err != nil {
				return nil, err
			}
			durations := ecs.Durations{}
			if record.Durations != nil {
				durations = *record.Durations
			}
			if _, err := stores.Durations.Set(entity, durations); err != nil {
				return nil, err
			}
			regeneration := ecs.Regeneration{}
			if record.Regeneration != nil {
				regeneration = *record.Regeneration
			}
			if _, err := stores.Regeneration.Set(entity, regeneration); err != nil {
				return nil, err
			}
		}
		if record.Combatant != nil {
			if _, err := stores.Combat.Set(entity, *record.Combatant); err != nil {
				return nil, err
			}
		}
		if record.Player != nil {
			if _, err := stores.Players.Set(entity, *record.Player); err != nil {
				return nil, err
			}
		}
		if record.Attributes != nil {
			if _, err := stores.Attributes.Set(entity, *record.Attributes); err != nil {
				return nil, err
			}
		}
		if record.AI != nil {
			if _, err := stores.AI.Set(entity, *record.AI); err != nil {
				return nil, err
			}
		}
		if record.Item != nil {
			if _, err := stores.Items.Set(entity, *record.Item); err != nil {
				return nil, err
			}
		}
		if record.Corpse != nil {
			if _, err := stores.Corpses.Set(entity, *record.Corpse); err != nil {
				return nil, err
			}
		}
		if record.Position != nil {
			level, found := g.levels[record.Position.LevelID]
			if !found || !level.Walkable(record.Position.X, record.Position.Y) {
				return nil, fmt.Errorf("entity %d has invalid position %+v", record.ID, *record.Position)
			}
			if record.Actor != nil {
				if err := level.PlaceActor(entity, record.Position.X, record.Position.Y); err != nil {
					return nil, err
				}
			} else if _, err := stores.Positions.Set(entity, *record.Position); err != nil {
				return nil, err
			}
		}
		if record.CarriedBy != nil {
			if record.CarriedBy.Holder != g.player {
				return nil, fmt.Errorf("item %d has unsupported carrier %d", record.ID, record.CarriedBy.Holder)
			}
			if _, err := stores.CarriedBy.Set(entity, *record.CarriedBy); err != nil {
				return nil, err
			}
		}
		if record.Equipped != nil {
			if _, err := stores.Equipped.Set(entity, *record.Equipped); err != nil {
				return nil, err
			}
		}
	}
	playerPosition, positioned := stores.Positions.Get(g.player)
	if !positioned {
		return nil, fmt.Errorf("saved player has no position")
	}
	if _, away := g.levelAwaySince[playerPosition.LevelID]; away {
		return nil, fmt.Errorf("active level %d is marked away", playerPosition.LevelID)
	}
	for _, entity := range stores.Corpses.Entities() {
		position, _ := stores.Positions.Get(entity)
		if position.LevelID != playerPosition.LevelID {
			if _, away := g.levelAwaySince[position.LevelID]; !away {
				return nil, fmt.Errorf("inactive corpse level %d lacks away clock", position.LevelID)
			}
		}
	}
	if _, err := g.fighterDefense(); err != nil {
		return nil, fmt.Errorf("unsupported saved player defense: %w", err)
	}
	if _, err := g.playerAttackDelayInput("MONS_RAT"); err != nil {
		return nil, fmt.Errorf("unsupported saved player attack timing: %w", err)
	}
	if err := registerSystems(g); err != nil {
		return nil, err
	}
	if err := g.refreshVisibility(); err != nil {
		return nil, err
	}
	return g, nil
}
