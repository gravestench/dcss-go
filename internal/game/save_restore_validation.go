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
	speciesID   string
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

// savedEntityValidator owns bookkeeping only for one restore attempt.
// Each record is checked before its entity ID is registered in Akara.
type savedEntityValidator struct {
	game             *Game
	snapshot         save.Snapshot
	scenarioMonsters []string
	usesPopulation   bool

	seen        map[uint64]bool
	recordsByID map[uint64]save.EntityRecord

	player        savedPlayerValidation
	playerCount   int
	monsters      savedMonsterValidation
	equippedSlots map[string]string

	activeLevelID int
	playerAlive   bool
}

func (g *Game) validateAndRegisterSavedEntities(
	snapshot save.Snapshot,
	scenarioMonsters []string,
	usesPopulation bool,
) error {
	validator := savedEntityValidator{
		game:             g,
		snapshot:         snapshot,
		scenarioMonsters: scenarioMonsters,
		usesPopulation:   usesPopulation,

		seen:        make(map[uint64]bool),
		recordsByID: make(map[uint64]save.EntityRecord),

		monsters:      newSavedMonsterValidation(),
		equippedSlots: make(map[string]string),
	}

	return validator.validate()
}

func (v *savedEntityValidator) validate() error {
	for _, record := range v.snapshot.Entities {
		if record.ID == v.snapshot.PlayerID && record.Position != nil {
			v.activeLevelID = record.Position.LevelID

			if record.Health != nil {
				v.playerAlive = record.Health.Current > 0
			}

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

	if err := v.validateMonsterInventory(); err != nil {
		return err
	}

	if err := v.validateBandLinks(); err != nil {
		return err
	}

	if err := v.validateConstrictLink(); err != nil {
		return err
	}

	return v.validateFinalState()
}

// Monster inventory links are validated after every actor ID is registered,
// because a carried item can appear before its holder in a saved snapshot.
func (v *savedEntityValidator) validateMonsterInventory() error {
	slotsByMonster := make(map[uint64]map[string]bool)

	for _, record := range v.snapshot.Entities {
		if record.CarriedBy == nil ||
			record.CarriedBy.Holder == v.game.player {
			continue
		}

		holderID := uint64(record.CarriedBy.Holder)
		holder, found := v.recordsByID[holderID]

		if !found ||
			holder.Actor == nil ||
			holder.AI == nil ||
			holder.Health == nil ||
			holder.Health.Current <= 0 ||
			holder.Position == nil ||
			record.Item == nil ||
			record.Equipped == nil {
			return fmt.Errorf("item %d has invalid monster carrier %d", record.ID, holderID)
		}

		kind, err := v.game.catalog.Item(record.Item.KindID)

		if err != nil {
			return err
		}

		slot := record.Equipped.Slot

		switch slot {
		case "weapon", "alternate_weapon":
			if kind.Class != "OBJ_WEAPONS" || kind.Weapon == nil {
				return fmt.Errorf("item %d is not a monster weapon", record.ID)
			}

		case "missile":
			if kind.Class != "OBJ_MISSILES" || kind.Missile == nil {
				return fmt.Errorf("item %d is not monster ammunition", record.ID)
			}

		default:
			return fmt.Errorf("item %d has unsupported monster slot %q", record.ID, slot)
		}

		if slotsByMonster[holderID] == nil {
			slotsByMonster[holderID] = make(map[string]bool)
		}

		if slotsByMonster[holderID][slot] {
			return fmt.Errorf("monster %d has duplicate %s slot", holderID, slot)
		}

		slotsByMonster[holderID][slot] = true
	}

	return nil
}

func (v *savedEntityValidator) validateRecord(record save.EntityRecord) error {
	if record.ID == 0 || v.seen[record.ID] {
		return fmt.Errorf("duplicate or zero entity ID %d", record.ID)
	}

	v.seen[record.ID] = true
	v.recordsByID[record.ID] = record

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
		if record.Corpse != nil &&
			!slices.Contains(v.scenarioMonsters, record.Corpse.MonsterID) {
			return fmt.Errorf("fixed Dungeon save has unsupported corpse %s", record.Corpse.MonsterID)
		}

		if err := validateSavedItem(
			record,
			v.game.catalog,
			v.game.player,
			v.equippedSlots,
		); err != nil {
			return err
		}
	} else if record.CarriedBy != nil ||
		record.Equipped != nil ||
		record.Corpse != nil {
		return fmt.Errorf("non-item %d has carrier or equipment slot", record.ID)
	}

	if record.Actor == nil && record.Item == nil {
		return fmt.Errorf("entity %d has no actor or item role", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateCharacterRole(record save.EntityRecord) error {
	if record.Player != nil && record.AI != nil {
		return fmt.Errorf("entity %d is both player and monster", record.ID)
	}

	if record.BandFollower != nil {
		if record.AI == nil ||
			record.Actor == nil ||
			record.Actor.KindID != "MONS_JACKAL" ||
			record.BandFollower.Leader == 0 ||
			uint64(record.BandFollower.Leader) == record.ID {
			return fmt.Errorf("entity %d has an invalid band leader link", record.ID)
		}
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
		record.Constricted != nil ||
		record.Equipment != nil {
		return fmt.Errorf("non-player entity %d has character components", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateMonsterRole(record save.EntityRecord) error {
	if record.AI == nil {
		return nil
	}

	if err := v.game.validateSavedMonster(
		record,
		v.snapshot.CurrentAut,
		v.scenarioMonsters,
		v.playerAlive,
	); err != nil {
		return err
	}

	if !v.usesPopulation && v.monsters.liveByKind[record.Actor.KindID] {
		return fmt.Errorf("duplicate fixed animal %s", record.Actor.KindID)
	}

	v.monsters.liveByKind[record.Actor.KindID] = true

	if !v.usesPopulation {
		return nil
	}

	levelID := record.Position.LevelID
	v.monsters.liveByLevel[levelID]++
	v.monsters.liveCount++

	if v.monsters.liveByLevel[levelID] > initialActorBudget(
		v.game.levels[levelID],
		v.snapshot.ScenarioID,
	) {
		return fmt.Errorf("Dungeon:%d has too many live monsters", levelID)
	}

	return nil
}

func (v *savedEntityValidator) validateActorState(record save.EntityRecord) error {
	if record.Actor != nil &&
		(record.Actor.Speed <= 0 ||
			record.Health == nil ||
			record.Combatant == nil || record.Position == nil) {
		return fmt.Errorf("invalid actor %d", record.ID)
	}

	if record.Combatant != nil &&
		(record.Actor == nil ||
			record.Combatant.ShieldBlocks < 0 ||
			record.Combatant.ShieldBlocks > 100) {
		return fmt.Errorf("invalid combat stats for entity %d", record.ID)
	}

	if record.Actor != nil &&
		record.Player == nil && record.AI == nil {
		return fmt.Errorf("actor %d has no player or monster role", record.ID)
	}

	if record.Health != nil &&
		(record.Health.Current < 0 ||
			record.Health.Max <= 0 ||
			record.Health.Current > record.Health.Max) {
		return fmt.Errorf("invalid health for entity %d", record.ID)
	}

	return nil
}

func (v *savedEntityValidator) validateBandLinks() error {
	for _, record := range v.snapshot.Entities {
		if record.BandFollower == nil {
			continue
		}

		leader, alive := v.recordsByID[uint64(record.BandFollower.Leader)]

		if alive &&
			(leader.Actor == nil ||
				leader.Actor.KindID != "MONS_JACKAL" ||
				leader.Position == nil ||
				leader.Position.LevelID != record.Position.LevelID) {
			return fmt.Errorf("entity %d has an incompatible living band leader", record.ID)
		}
	}

	return nil
}

func (v *savedEntityValidator) validateConstrictLink() error {
	player := v.recordsByID[v.snapshot.PlayerID]
	grip := player.Constricted

	if grip == nil {
		return nil
	}

	python, found := v.recordsByID[uint64(grip.By)]

	if !found ||
		grip.By == 0 ||
		grip.EscapeAttempts < 0 ||
		grip.EscapeAttempts > 1000 ||
		player.Health == nil ||
		player.Health.Current <= 0 ||
		player.Position == nil ||
		python.Actor == nil ||
		python.Actor.KindID != "MONS_BALL_PYTHON" ||
		python.AI == nil ||
		python.Health == nil ||
		python.Health.Current <= 0 ||
		python.Position == nil ||
		!adjacentActors(*player.Position, *python.Position) {
		return fmt.Errorf("player has invalid ball python constriction link")
	}

	return nil
}

func (v *savedEntityValidator) validateFinalState() error {
	if v.playerCount != 1 {
		return fmt.Errorf("save requires exactly one player, found %d", v.playerCount)
	}

	if err := v.game.validateSavedExperience(
		v.player.xp,
		v.scenarioMonsters,
		v.usesPopulation,
		v.monsters,
	); err != nil {
		return err
	}

	if err := v.game.validateSavedEquipment(
		v.equippedSlots,
		v.player.speciesID,
	); err != nil {
		return err
	}

	if err := v.validateEquipmentDelay(); err != nil {
		return err
	}

	if v.player.weaponID != "WPN_UNARMED" {
		if err := validateSavedStartingWeapon(v.snapshot.Entities, v.player.weaponID); err != nil {
			return err
		}
	}

	// A stat prompt pauses before the monster phase at the start of the
	// player's spent turn. Its next turn clock is therefore still in the future.
	if v.player.alive {
		if v.player.pendingStat {
			if v.player.nextAut <= v.snapshot.CurrentAut {
				return fmt.Errorf("invalid pending player turn clock")
			}
		} else if v.player.nextAut != v.snapshot.CurrentAut {
			return fmt.Errorf("save clock does not match the next player turn")
		}
	}

	return nil
}

func (v *savedEntityValidator) validateEquipmentDelay() error {
	player := v.recordsByID[v.snapshot.PlayerID]
	delay := player.Equipment

	if delay == nil {
		return nil
	}

	if delay.Remaining < 1 ||
		delay.Remaining > armourEquipTurns ||
		!supportedArmourSlot(delay.Slot) ||
		(delay.Phase != "wear" && delay.Phase != "remove") {
		return fmt.Errorf("invalid saved equipment delay")
	}

	if delay.Phase == "remove" &&
		delay.Remaining == armourEquipTurns ||
		delay.Phase == "wear" &&
			delay.OldItemID == 0 &&
			delay.Remaining == armourEquipTurns {
		return fmt.Errorf("saved equipment delay has impossible turn count")
	}

	if delay.Phase == "remove" &&
		delay.OldItemID == 0 ||
		delay.Phase == "wear" && delay.ItemID == 0 {
		return fmt.Errorf("saved equipment delay lacks its item")
	}

	if delay.ItemID != 0 && delay.ItemID == delay.OldItemID {
		return fmt.Errorf("saved equipment delay repeats one item")
	}

	for _, id := range []akara.Entity{delay.ItemID, delay.OldItemID} {
		if id == 0 {
			continue
		}

		item, found := v.recordsByID[uint64(id)]

		if !found ||
			item.Item == nil ||
			item.CarriedBy == nil ||
			item.CarriedBy.Holder != v.game.player {
			return fmt.Errorf("saved equipment delay references missing item %d", id)
		}

		kind, err := v.game.catalog.Item(item.Item.KindID)

		if err != nil ||
			kind.Slot != delay.Slot {
			return fmt.Errorf("saved equipment delay has invalid item %d", id)
		}
	}

	old := v.recordsByID[uint64(delay.OldItemID)]
	new := v.recordsByID[uint64(delay.ItemID)]

	if delay.Phase == "remove" &&
		(old.Equipped == nil || old.Equipped.Slot != delay.Slot) {
		return fmt.Errorf("saved removal has no equipped item")
	}

	if delay.Phase == "wear" && new.Equipped != nil {
		return fmt.Errorf("saved wear item is already equipped")
	}

	if delay.Phase == "wear" && v.equippedSlots[delay.Slot] != "" {
		return fmt.Errorf("saved wear slot is still occupied")
	}

	if delay.ItemID != 0 {
		if err := v.validateSavedWearFit(player, new); err != nil {
			return err
		}
	}

	return nil
}

func (v *savedEntityValidator) validateSavedWearFit(
	player save.EntityRecord,
	item save.EntityRecord,
) error {
	kind, err := v.game.catalog.Item(item.Item.KindID)

	if err != nil ||
		kind.Armour == nil {
		return fmt.Errorf("saved wear item is not armour")
	}

	species, err := v.game.catalog.Species(player.Player.SpeciesID)

	if err != nil {
		return err
	}

	if isBarding(kind.ID) {
		return fmt.Errorf("saved wear item is barding for unsupported species")
	}

	if hardHelmetConflicts(kind, species) {
		return fmt.Errorf("saved helmet wear conflicts with horns")
	}

	if err := validateArmourSize(kind, species.Size); err != nil {
		return fmt.Errorf("saved wear item does not fit: %w", err)
	}

	if kind.Slot != "shield" || v.equippedSlots["weapon"] == "" {
		return nil
	}

	weapon, err := v.game.catalog.Item(v.equippedSlots["weapon"])

	if err != nil {
		return err
	}

	conflicts, err := weaponNeedsSecondHand(weapon, species.Size)

	if err != nil {
		return err
	}

	if conflicts {
		return fmt.Errorf("saved shield wear conflicts with equipped weapon")
	}

	return nil
}
