package game

import (
	"fmt"
	"slices"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// goblinSling projects the live primary weapon. The launched bullet is a
// temporary item derived from Weapon.AmmoID, as in item-prop.cc:2007.
func goblinSling(
	monsterID akara.Entity,
	catalog content.Catalog,
	items *akara.Store[ecs.Item],
	carried *akara.Store[ecs.CarriedBy],
	equipped *akara.Store[ecs.Equipped],
) (akara.Entity, ecs.Item, content.ItemDef, bool, error) {
	for _, itemID := range equipped.Entities() {
		slot, _ := equipped.Get(itemID)

		if slot.Slot != "weapon" {
			continue
		}

		carrier, found := carried.Get(itemID)

		if !found || carrier.Holder != monsterID {
			continue
		}

		item, found := items.Get(itemID)

		if !found {
			return 0, ecs.Item{}, content.ItemDef{}, false,
				fmt.Errorf("goblin weapon %d has no item", itemID)
		}

		kind, err := catalog.Item(item.KindID)

		if err != nil {
			return 0, ecs.Item{}, content.ItemDef{}, false, err
		}

		if err := validateItemProperties(*item, kind); err != nil {
			return 0, ecs.Item{}, content.ItemDef{}, false, err
		}

		if kind.ID != "WPN_SLING" {
			return 0, ecs.Item{}, content.ItemDef{}, false, nil
		}

		if kind.Weapon == nil ||
			!slices.Contains(kind.Weapon.DamageFlags, "DAMV_NON_MELEE") {
			return 0, ecs.Item{}, content.ItemDef{}, false,
				fmt.Errorf("goblin has invalid sling definition")
		}

		if item.Ego != "" &&
			item.Ego != "SPWPN_NORMAL" &&
			item.Ego != "SPWPN_FLAMING" &&
			item.Ego != "SPWPN_FREEZING" &&
			item.Ego != "SPWPN_VORPAL" {
			return 0, ecs.Item{}, content.ItemDef{}, false,
				fmt.Errorf("unsupported goblin sling brand %s", item.Ego)
		}

		return itemID, *item, kind, true, nil
	}

	return 0, ecs.Item{}, content.ItemDef{}, false, nil
}

// chooseGoblinSling follows mon-act.cc:handle_throw. Ordinary launcher users
// decline one attack in five; its tracer runs after that chance draw.
func (s *monsterDecisionSystem) chooseGoblinSling(
	monsterID akara.Entity,
	position ecs.Position,
	player ecs.Position,
	level *Level,
) (ecs.Intent, bool, error) {
	actor, found := s.actors.Get(monsterID)

	if !found ||
		actor.KindID != "MONS_GOBLIN" ||
		adjacentActors(position, player) {
		return ecs.Intent{}, false, nil
	}

	itemID, _, _, armed, err := goblinSling(
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

	roll, err := s.rng.Intn("ai", 5)

	if err != nil {
		return ecs.Intent{}, false, err
	}

	if roll == 0 ||
		!level.ClearProjectilePath(position.X, position.Y, player.X, player.Y) {
		return ecs.Intent{}, false, nil
	}

	return ecs.Intent{
		Kind:   ecs.IntentRanged,
		ItemID: itemID,
	}, true, nil
}

// resolveGoblinSling reads the current launcher at resolution, so a stale
// transient intent cannot fire a removed or replaced ECS item.
func (s *combatSystem) resolveGoblinSling(intent *ecs.Intent) error {
	actor, found := s.actors.Get(s.turn.Actor)

	if !found || actor.KindID != "MONS_GOBLIN" {
		return fmt.Errorf("unsupported ranged attacker %d", s.turn.Actor)
	}

	monsterPosition, monsterLocated := s.positions.Get(s.turn.Actor)
	playerPosition, playerLocated := s.positions.Get(s.player)
	monsterHealth, monsterAlive := s.health.Get(s.turn.Actor)
	playerHealth, playerAlive := s.health.Get(s.player)

	if !monsterLocated ||
		!playerLocated ||
		!monsterAlive ||
		!playerAlive ||
		monsterHealth.Current <= 0 ||
		playerHealth.Current <= 0 ||
		monsterPosition.LevelID != playerPosition.LevelID ||
		adjacentActors(*monsterPosition, *playerPosition) {
		return fmt.Errorf("goblin cannot shoot distant or dead player")
	}

	level := s.levels[monsterPosition.LevelID]

	if level == nil ||
		!level.ClearProjectilePath(
			monsterPosition.X,
			monsterPosition.Y,
			playerPosition.X,
			playerPosition.Y,
		) {
		return fmt.Errorf("goblin has no clear shot")
	}

	itemID, launcher, kind, armed, err := goblinSling(
		s.turn.Actor,
		s.catalog,
		s.items,
		s.carried,
		s.equipped,
	)

	if err != nil {
		return err
	}

	if !armed || intent.ItemID != itemID {
		return fmt.Errorf("goblin has no matching sling")
	}

	projectile, err := s.catalog.Item(kind.Weapon.AmmoID)

	if err != nil {
		return err
	}

	if projectile.Class != "OBJ_MISSILES" || projectile.Missile == nil {
		return fmt.Errorf("sling has invalid projectile %s", projectile.ID)
	}

	definition, err := s.catalog.Monster(actor.KindID)

	if err != nil {
		return err
	}

	defense, err := s.fighter.defense()

	if err != nil {
		return err
	}

	outcome, err := combat.ResolveMonsterShot(s.roller, combat.MonsterShot{
		HD:               definition.HD,
		WeaponDamage:     kind.Weapon.Damage,
		WeaponHit:        kind.Weapon.Hit,
		WeaponPlus:       launcher.Plus,
		ProjectileDamage: projectile.Missile.Damage,
	}, defense)

	if err != nil {
		return err
	}

	state, found := s.combat.Get(s.player)

	if !found {
		return fmt.Errorf("player has no combat state")
	}

	state.ShieldBlocks = outcome.ShieldBlocks
	playerHealth.Current = max(0, playerHealth.Current-outcome.Damage)

	// The source's physical missile path uses ranged_attack, not beam's
	// ordinary spell training or melee_attack's hit training. A successful
	// shield block still calls player::shield_block_succeeded.
	if outcome.Kind == combat.Block {
		if err := s.practiceIncomingShield(outcome, defense); err != nil {
			return err
		}
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: "The goblin shoots a sling bullet.",
	})

	message := "The sling bullet misses you."

	switch outcome.Kind {
	case combat.Block:
		message = "You block the sling bullet."

	case combat.Hit:
		if outcome.Damage == 0 {
			message = "The sling bullet hits you but does no damage."
		} else {
			message = fmt.Sprintf("The sling bullet hits you for %d damage.", outcome.Damage)
		}
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: message,
	})

	if outcome.Kind == combat.Hit &&
		(playerHealth.Current > 0 || brandCanTriggerAfterDeath(launcher.Ego)) {
		return s.applyMonsterWeaponBrand(
			launcher.Ego,
			outcome.Damage,
			actor.KindID,
			"sling bullet",
			playerHealth,
		)
	}

	return nil
}
