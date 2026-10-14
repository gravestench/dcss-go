package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type pendingItemWield struct {
	actor  akara.Entity
	itemID akara.Entity
}

type wieldSystem struct {
	items   *akara.Store[ecs.Item]
	carried *akara.Store[ecs.CarriedBy]
	intents *akara.Store[ecs.Intent]
	catalog content.Catalog
	turn    *TurnContext
}

func (g *Game) prepareWieldCommand(rawItemID uint64) (preparedCommand, error) {
	current, err := g.playerWeapon()

	if err != nil {
		return preparedCommand{}, err
	}

	itemID := akara.Entity(rawItemID)

	if itemID == current {
		if itemID == 0 {
			return freeCommand(g.noTime("You are already empty-handed.")), nil
		}

		return freeCommand(g.noTime("You are already wielding that.")), nil
	}

	if itemID == 0 {
		return spendingCommand(ecs.Intent{Kind: ecs.IntentWield}, 3), nil
	}

	item, found := g.stores.Items.Get(itemID)
	carrier, carried := g.stores.CarriedBy.Get(itemID)

	if !found || !carried || carrier.Holder != g.player {
		return freeCommand(g.noTime("You are not carrying that item.")), nil
	}

	kind, err := g.catalog.Item(item.KindID)

	if err != nil {
		return preparedCommand{}, err
	}

	if err := validateItemProperties(*item, kind); err != nil {
		return preparedCommand{}, fmt.Errorf("cannot wield item %d: %w", itemID, err)
	}

	if kind.Class != "OBJ_WEAPONS" || kind.Weapon == nil {
		return freeCommand(g.noTime("You cannot wield that item.")), nil
	}

	if !supportsWieldedWeapon(kind) {
		return freeCommand(g.noTime("That weapon's combat is unavailable in the Go port.")), nil
	}

	if g.stores.Equipped.Has(itemID) {
		return freeCommand(g.noTime("You are wearing that item.")), nil
	}

	if incompatible, err := g.weaponConflictsWithShield(kind); err != nil {
		return preparedCommand{}, err
	} else if incompatible {
		return freeCommand(g.noTime("You cannot wield that with only one hand.")), nil
	}

	return spendingCommand(ecs.Intent{
		Kind:   ecs.IntentWield,
		ItemID: itemID,
	}, 5), nil
}

// wieldActionCost follows item-use.cc:1009-1015,1094-1095. Both short
// actions truncate integer division rather than drawing another speed roll.
func wieldActionCost(timeTaken int, itemID akara.Entity) Aut {
	if itemID == 0 {
		return Aut(timeTaken * 3 / 10)
	}

	return Aut(timeTaken / 2)
}

// weaponConflictsWithShield follows basic_hands_reqd and
// is_shield_incompatible in item-prop.cc:1588-1604,2796-2804.
func (g *Game) weaponConflictsWithShield(kind content.ItemDef) (bool, error) {
	shielded := false

	for _, entity := range g.stores.Equipped.Entities() {
		equipped, _ := g.stores.Equipped.Get(entity)
		carrier, carried := g.stores.CarriedBy.Get(entity)

		if carried && carrier.Holder == g.player && equipped.Slot == "shield" {
			shielded = true
			break
		}
	}

	if !shielded {
		return false, nil
	}

	player, found := g.stores.Players.Get(g.player)

	if !found {
		return false, fmt.Errorf("player has no identity")
	}

	species, err := g.catalog.Species(player.SpeciesID)

	if err != nil {
		return false, err
	}

	return weaponNeedsSecondHand(kind, species.Size)
}

func supportsWieldedWeapon(kind content.ItemDef) bool {
	return kind.Class == "OBJ_WEAPONS" && kind.Weapon != nil &&
		combat.SupportsPrimaryWeaponSkill(kind.Weapon.SkillID)
}

func weaponNeedsSecondHand(kind content.ItemDef, size string) (bool, error) {
	playerSize, err := sourceSizeRank(size)

	if err != nil {
		return false, err
	}

	minimumSize, err := sourceSizeRank(kind.Weapon.Min1HSizeID)

	if err != nil {
		return false, err
	}

	return playerSize < minimumSize, nil
}

func sourceSizeRank(id string) (int, error) {
	// These ranks follow the enum order in size-type.h.
	switch id {
	case "SIZE_TINY":
		return 0, nil

	case "SIZE_LITTLE":
		return 1, nil

	case "SIZE_SMALL":
		return 2, nil

	case "SIZE_MEDIUM":
		return 3, nil

	case "SIZE_LARGE":
		return 4, nil

	case "SIZE_GIANT":
		return 5, nil

	case "NUM_SIZE_LEVELS":
		return 6, nil

	default:
		return 0, fmt.Errorf("unknown source size %s", id)
	}
}

func (g *Game) playerWeapon() (akara.Entity, error) {
	var weapon akara.Entity

	for _, entity := range g.stores.Equipped.Entities() {
		equipped, _ := g.stores.Equipped.Get(entity)
		carrier, carried := g.stores.CarriedBy.Get(entity)

		if !carried || carrier.Holder != g.player || equipped.Slot != "weapon" {
			continue
		}

		if weapon != 0 {
			return 0, fmt.Errorf("player has multiple equipped weapons")
		}

		weapon = entity
	}

	return weapon, nil
}

func (s *wieldSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || intent.Kind != ecs.IntentWield {
		return nil
	}

	message := "You are now empty-handed."

	if intent.ItemID != 0 {
		item, found := s.items.Get(intent.ItemID)
		carrier, carried := s.carried.Get(intent.ItemID)

		if !found || !carried || carrier.Holder != s.turn.Actor {
			return fmt.Errorf("wield actor %d has invalid item %d", s.turn.Actor, intent.ItemID)
		}

		kind, err := s.catalog.Item(item.KindID)

		if err != nil {
			return err
		}

		message = "You are now wielding " + itemActionPhrase(kind.Name, 1) + "."
	}

	s.turn.Wield = &pendingItemWield{
		actor:  s.turn.Actor,
		itemID: intent.ItemID,
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "wield",
		Text: message,
	})

	return nil
}

// applyWield changes the equipment relation after Akara's ordered systems.
func (g *Game) applyWield(change pendingItemWield) error {
	if change.actor != g.player {
		return fmt.Errorf("invalid wield actor %d", change.actor)
	}

	current, err := g.playerWeapon()

	if err != nil {
		return err
	}

	if current == change.itemID {
		return fmt.Errorf("item %d is already wielded", change.itemID)
	}

	if change.itemID != 0 {
		if !g.stores.Items.Has(change.itemID) {
			return fmt.Errorf("wield item %d is missing", change.itemID)
		}

		carrier, carried := g.stores.CarriedBy.Get(change.itemID)

		if !carried || carrier.Holder != g.player {
			return fmt.Errorf("wield item %d is not carried", change.itemID)
		}
	}

	if current != 0 {
		g.stores.Equipped.Remove(current)
	}

	if change.itemID == 0 {
		return nil
	}

	_, err = g.stores.Equipped.Set(change.itemID, ecs.Equipped{
		Slot: "weapon",
	})

	return err
}
