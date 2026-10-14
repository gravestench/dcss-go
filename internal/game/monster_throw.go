package game

import (
	"fmt"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// koboldMissile reads the source missile slot from the live ECS inventory.
// The current kobold factory issues stones or poisoned darts only.
func koboldMissile(
	monsterID akara.Entity,
	catalog content.Catalog,
	items *akara.Store[ecs.Item],
	carried *akara.Store[ecs.CarriedBy],
	equipped *akara.Store[ecs.Equipped],
) (akara.Entity, ecs.Item, content.ItemDef, bool, error) {
	itemID, item, kind, found, err := equippedMonsterItem(
		monsterID,
		"missile",
		catalog,
		items,
		carried,
		equipped,
	)

	if err != nil {
		return 0, ecs.Item{}, content.ItemDef{}, false, err
	}

	if !found {
		return itemID, item, kind, false, nil
	}

	validStone := kind.ID == "MI_STONE" && item.Ego == ""
	validDart := kind.ID == "MI_DART" && item.Ego == "poisoned"

	if !validStone && !validDart {
		return 0, ecs.Item{}, content.ItemDef{}, false,
			fmt.Errorf("unsupported kobold missile %s/%s", kind.ID, item.Ego)
	}

	if kind.Class != "OBJ_MISSILES" || kind.Missile == nil {
		return 0, ecs.Item{}, content.ItemDef{}, false,
			fmt.Errorf("invalid kobold missile definition %s", kind.ID)
	}

	return itemID, item, kind, true, nil
}

// chooseKoboldThrow follows mon-act.cc:handle_throw's one-in-three chance
// for a monster with throwable missiles and no launcher.
func (s *monsterDecisionSystem) chooseKoboldThrow(
	monsterID akara.Entity,
	position ecs.Position,
	player ecs.Position,
	level *Level,
) (ecs.Intent, bool, error) {
	actor, found := s.actors.Get(monsterID)

	if !found ||
		actor.KindID != "MONS_KOBOLD" ||
		adjacentActors(position, player) {
		return ecs.Intent{}, false, nil
	}

	itemID, _, _, armed, err := koboldMissile(
		monsterID,
		s.catalog,
		s.items,
		s.carried,
		s.equipped,
	)

	if err != nil {
		return ecs.Intent{}, false, err
	}

	if !armed {
		return ecs.Intent{}, false, nil
	}

	roll, err := s.rng.Intn("ai", 3)

	if err != nil {
		return ecs.Intent{}, false, err
	}

	if roll != 0 ||
		!level.ClearProjectilePath(position.X, position.Y, player.X, player.Y) {
		return ecs.Intent{}, false, nil
	}

	return ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: itemID,
	}, true, nil
}

// resolveKoboldThrow copies the missile for the shot. Source mons_throw only
// decrements throwing nets, so stones and darts remain in the ECS stack.
func (s *combatSystem) resolveKoboldThrow(intent *ecs.Intent) error {
	target, err := s.rangedTarget("MONS_KOBOLD")

	if err != nil {
		return err
	}

	itemID, item, kind, armed, err := koboldMissile(
		s.turn.Actor,
		s.catalog,
		s.items,
		s.carried,
		s.equipped,
	)

	if err != nil {
		return err
	}

	if !armed ||
		intent.ItemID != itemID ||
		item.Quantity <= 0 {
		return fmt.Errorf("kobold has no matching missile stack")
	}

	var outcome combat.Outcome
	var poison int

	if kind.ID == "MI_DART" {
		outcome, poison, err = combat.ResolveMonsterPoisonDart(
			s.roller,
			target.definition.HD,
			target.defense,
		)
	} else {
		outcome, err = combat.ResolveMonsterShot(s.roller, combat.MonsterShot{
			HD:               target.definition.HD,
			ProjectileDamage: kind.Missile.Damage,
			NaturalDamage:    target.definition.Attacks[0].Damage,
		}, target.defense)
	}

	if err != nil {
		return err
	}

	state, found := s.combat.Get(s.player)

	if !found {
		return fmt.Errorf("player has no combat state")
	}

	state.ShieldBlocks = outcome.ShieldBlocks
	target.health.Current = max(0, target.health.Current-outcome.Damage)

	if outcome.Kind == combat.Block {
		if err := s.practiceIncomingShield(outcome, target.defense); err != nil {
			return err
		}
	}

	missileName := "stone"

	if kind.ID == "MI_DART" {
		missileName = "poisoned dart"
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: fmt.Sprintf("The kobold throws a %s.", missileName),
	})

	message := fmt.Sprintf("The %s misses you.", missileName)

	switch outcome.Kind {
	case combat.Block:
		message = fmt.Sprintf("You block the %s.", missileName)

	case combat.Hit:
		message = fmt.Sprintf("The %s hits you.", missileName)

		if kind.ID == "MI_STONE" {
			if outcome.Damage == 0 {
				message = "The stone hits you but does no damage."
			} else {
				message = fmt.Sprintf("The stone hits you for %d damage.", outcome.Damage)
			}
		}
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: message,
	})

	if poison > 0 {
		return s.addPlayerPoison(poison, "MONS_KOBOLD")
	}

	return nil
}
