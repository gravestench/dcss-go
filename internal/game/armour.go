package game

import (
	"fmt"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

const armourEquipTurns = 5

// prepareEquipmentCommand validates an armour change before any aut is spent.
// DCSS item-use.cc uses one command turn and four delayed turns for an ordinary
// wear or removal. Swapping occupies ten turns because removal finishes first.
func (g *Game) prepareEquipmentCommand(command Command) (preparedCommand, error) {
	itemID := akara.Entity(command.ItemID)
	item, carried := g.stores.Items.Get(itemID)
	carrier, hasCarrier := g.stores.CarriedBy.Get(itemID)

	if !carried ||
		!hasCarrier || carrier.Holder != g.player {
		return freeCommand(g.noTime("You are not carrying that armour.")), nil
	}

	kind, err := g.catalog.Item(item.KindID)

	if err != nil {
		return preparedCommand{}, err
	}

	if kind.Class != "OBJ_ARMOUR" || kind.Armour == nil {
		return freeCommand(g.noTime("That is not armour.")), nil
	}

	if !supportedArmourSlot(kind.Slot) {
		return freeCommand(g.noTime("Wearing that armour is unavailable in the Go port.")), nil
	}

	if command.Kind == CommandTakeOff {
		if equipped, found := g.stores.Equipped.Get(itemID); !found ||
			equipped.Slot != kind.Slot {
			return freeCommand(g.noTime("You are not wearing that.")), nil
		}

		return equipmentCommand(ecs.EquipmentDelay{
			OldItemID: itemID,
			Slot:      kind.Slot,
			Phase:     "remove",
			Remaining: armourEquipTurns - 1,
		}), nil
	}

	if g.stores.Equipped.Has(itemID) {
		return freeCommand(g.noTime("You are already wearing that.")), nil
	}

	if err := g.validateWearFit(kind); err != nil {
		return freeCommand(g.noTime(err.Error())), nil
	}

	oldItemID := g.equippedInSlot(kind.Slot)
	phase := "wear"

	if oldItemID != 0 {
		phase = "remove"
	}

	return equipmentCommand(ecs.EquipmentDelay{
		ItemID:    itemID,
		OldItemID: oldItemID,
		Slot:      kind.Slot,
		Phase:     phase,
		Remaining: armourEquipTurns - 1,
	}), nil
}

func equipmentCommand(delay ecs.EquipmentDelay) preparedCommand {
	command := spendingCommand(ecs.Intent{Kind: ecs.IntentWait}, 10)

	command.equipment = &delay

	return command
}

func supportedArmourSlot(slot string) bool {
	switch slot {
	case "body", "shield", "head", "cloak", "gloves", "boots":
		return true
	}

	return false
}

func isBarding(kindID string) bool {
	return kindID == "ARM_BARDING" || kindID == "ARM_CENTAUR_BARDING"
}

func (g *Game) validateWearFit(kind content.ItemDef) error {
	player, found := g.stores.Players.Get(g.player)

	if !found {
		return fmt.Errorf("player has no species")
	}

	species, err := g.catalog.Species(player.SpeciesID)

	if err != nil {
		return err
	}

	// The supported Fighter species cannot wear barding in the boots slot.
	// Source: item-use.cc can_wear_armour and _cant_wear_barding_reason.
	if isBarding(kind.ID) {
		return fmt.Errorf("You can't wear that!")
	}

	if err := validateArmourSize(kind, species.Size); err != nil {
		return err
	}

	if kind.Slot != "shield" {
		return nil
	}

	weaponID, err := g.playerWeapon()

	if err != nil ||
		weaponID == 0 {
		return err
	}

	weapon, _ := g.stores.Items.Get(weaponID)
	weaponKind, err := g.catalog.Item(weapon.KindID)

	if err != nil {
		return err
	}

	needsSecondHand, err := weaponNeedsSecondHand(weaponKind, species.Size)

	if err != nil {
		return err
	}

	if needsSecondHand {
		return fmt.Errorf("You cannot use that shield with your weapon.")
	}

	return nil
}

func validateArmourSize(kind content.ItemDef, speciesSize string) error {
	size, err := sourceSizeRank(speciesSize)

	if err != nil {
		return err
	}

	minimum, err := sourceSizeRank(kind.Armour.FitMinID)

	if err != nil {
		return err
	}

	maximum, err := sourceSizeRank(kind.Armour.FitMaxID)

	if err != nil {
		return err
	}

	if size < minimum || size > maximum {
		return fmt.Errorf("That armour does not fit you.")
	}

	return nil
}

func (g *Game) equippedInSlot(slot string) akara.Entity {
	for _, entity := range g.stores.Equipped.Entities() {
		equipped, _ := g.stores.Equipped.Get(entity)
		carrier, carried := g.stores.CarriedBy.Get(entity)

		if carried &&
			carrier.Holder == g.player && equipped.Slot == slot {
			return entity
		}
	}

	return 0
}

// finishEquipmentCommand runs after the monster phase. Equipment protects the
// player only after its final delayed turn, matching delay.cc completion.
func (g *Game) finishEquipmentCommand(
	command Command,
	prepared preparedCommand,
	result StepResult,
) (StepResult, error) {
	if prepared.equipment != nil {
		if _, err := g.stores.Equipment.Set(g.player, *prepared.equipment); err != nil {
			return StepResult{}, err
		}

		if prepared.equipment.Phase == "remove" {
			g.equipmentEvent(&result, "You start removing your armour.")
		} else {
			g.equipmentEvent(&result, "You start putting on your armour.")
		}
	} else if command.Kind == CommandContinueEquipment {
		if err := g.advanceEquipment(&result); err != nil {
			return StepResult{}, err
		}
	}

	result.View = g.View()

	return result, nil
}

func (g *Game) advanceEquipment(result *StepResult) error {
	delay, found := g.stores.Equipment.Get(g.player)

	if !found {
		return fmt.Errorf("player has no equipment delay")
	}

	if delay.Phase == "remove" {
		g.equipmentEvent(result, g.equipmentFinishMessage(
			delay.OldItemID, "You continue taking off your %s.",
		))
	} else {
		g.equipmentEvent(result, g.equipmentFinishMessage(
			delay.ItemID, "You continue putting on your %s.",
		))
	}

	delay.Remaining--

	if delay.Remaining > 0 {
		return nil
	}

	if delay.Phase == "remove" {
		g.stores.Equipped.Remove(delay.OldItemID)
		g.equipmentEvent(result, g.equipmentFinishMessage(
			delay.OldItemID, "You finish taking off your %s.",
		))

		if delay.ItemID != 0 {
			delay.Phase = "wear"
			delay.Remaining = armourEquipTurns
			g.equipmentEvent(result, "You start putting on your armour.")

			return nil
		}

		g.stores.Equipment.Remove(g.player)

		return nil
	}

	if _, err := g.stores.Equipped.Set(delay.ItemID, ecs.Equipped{
		Slot: delay.Slot,
	}); err != nil {
		return err
	}

	g.stores.Equipment.Remove(g.player)
	g.equipmentEvent(result, g.equipmentFinishMessage(
		delay.ItemID, "You finish putting on your %s.",
	))

	return nil
}

func (g *Game) equipmentFinishMessage(itemID akara.Entity, format string) string {
	item, _ := g.stores.Items.Get(itemID)
	kind, _ := g.catalog.Item(item.KindID)

	return fmt.Sprintf(format, kind.Name)
}

func (g *Game) equipmentEvent(result *StepResult, message string) {
	event := Event{
		Kind: "equipment",
		Text: message,
	}

	result.Events = append(result.Events, event)
	g.messages = append(g.messages, message)
}
