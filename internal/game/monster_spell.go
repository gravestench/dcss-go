package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

// monsterSpellSystem resolves a chosen spell before movement and melee.
// The intent is transient; the caster's ECS state is authoritative.
type monsterSpellSystem struct {
	player akara.Entity

	actors    *akara.Store[ecs.Actor]
	positions *akara.Store[ecs.Position]
	health    *akara.Store[ecs.Health]
	combat    *akara.Store[ecs.Combatant]
	intents   *akara.Store[ecs.Intent]

	levels  map[int]*Level
	catalog content.Catalog
	roller  monster.Roller
	fighter playerCombat
	turn    *TurnContext
}

func newMonsterSpellSystem(g *Game) *monsterSpellSystem {
	return &monsterSpellSystem{
		player: g.player,

		actors:    g.stores.Actors,
		positions: g.stores.Positions,
		health:    g.stores.Health,
		combat:    g.stores.Combat,
		intents:   g.stores.Intents,

		levels:  g.levels,
		catalog: g.catalog,
		roller:  g.rng,
		fighter: newPlayerCombat(g),
		turn:    &g.turn,
	}
}

func (s *monsterSpellSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || intent.Kind != ecs.IntentSpell {
		return nil
	}

	actor, found := s.actors.Get(s.turn.Actor)

	if !found {
		return fmt.Errorf("monster %d has unsupported spell intent", s.turn.Actor)
	}

	definition, err := s.catalog.Monster(actor.KindID)

	if err != nil {
		return err
	}

	if _, err := s.catalog.Spell(intent.SpellID); err != nil {
		return err
	}

	book, err := s.catalog.MonsterSpellbook(definition.SpellbookID)

	if err != nil ||
		len(book) != 1 ||
		book[0].SpellID != intent.SpellID {
		return fmt.Errorf("%s has invalid spell book: %v", actor.KindID, err)
	}

	casterPosition, casterLocated := s.positions.Get(s.turn.Actor)
	playerPosition, playerLocated := s.positions.Get(s.player)
	casterHealth, casterAlive := s.health.Get(s.turn.Actor)
	playerHealth, playerAlive := s.health.Get(s.player)

	if !casterLocated ||
		!playerLocated ||
		!casterAlive ||
		!playerAlive ||
		casterHealth.Current <= 0 ||
		playerHealth.Current <= 0 ||
		casterPosition.LevelID != playerPosition.LevelID {
		return fmt.Errorf("monster cannot cast on distant or dead player")
	}

	switch actor.KindID {
	case "MONS_ENDOPLASM":
		if intent.SpellID != "SPELL_FREEZE" ||
			!adjacentActors(*casterPosition, *playerPosition) {
			return fmt.Errorf("endoplasm cannot Freeze distant player")
		}

		return s.resolveFreeze(definition, playerHealth)

	case "MONS_DART_SLUG":
		level := s.levels[casterPosition.LevelID]

		if intent.SpellID != "SPELL_SLUG_DART" ||
			level == nil ||
			!level.ClearProjectilePath(
				casterPosition.X,
				casterPosition.Y,
				playerPosition.X,
				playerPosition.Y,
			) {
			return fmt.Errorf("dart slug has no clear shot")
		}

		return s.resolveSlugDart(definition, playerHealth)
	}

	return fmt.Errorf("monster %s has unsupported spell %s", actor.KindID, intent.SpellID)
}

func (s *monsterSpellSystem) resolveFreeze(
	definition content.MonsterDef,
	playerHealth *ecs.Health,
) error {
	damage, err := monster.FreezeDamage(s.roller, definition.HD)

	if err != nil {
		return err
	}

	playerHealth.Current = max(0, playerHealth.Current-damage)
	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: "You are frozen.",
	})

	return nil
}

func (s *monsterSpellSystem) resolveSlugDart(
	definition content.MonsterDef,
	playerHealth *ecs.Health,
) error {
	defense, err := s.fighter.defense()

	if err != nil {
		return err
	}

	outcome, err := combat.ResolveSlugDart(s.roller, definition.HD, defense)

	if err != nil {
		return err
	}

	state, found := s.combat.Get(s.player)

	if !found {
		return fmt.Errorf("player has no combat state")
	}

	state.ShieldBlocks = outcome.ShieldBlocks
	playerHealth.Current = max(0, playerHealth.Current-outcome.Damage)

	message := "The slug dart misses you."

	switch outcome.Kind {
	case combat.Block:
		message = "You block the slug dart."

	case combat.Hit:
		message = fmt.Sprintf("The slug dart hits you for %d damage.", outcome.Damage)
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: message,
	})

	return nil
}
