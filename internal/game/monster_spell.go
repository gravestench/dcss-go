package game

import (
	"fmt"
	"time"

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
	intents   *akara.Store[ecs.Intent]

	catalog content.Catalog
	roller  monster.Roller
	turn    *TurnContext
}

func newMonsterSpellSystem(g *Game) *monsterSpellSystem {
	return &monsterSpellSystem{
		player: g.player,

		actors:    g.stores.Actors,
		positions: g.stores.Positions,
		health:    g.stores.Health,
		intents:   g.stores.Intents,

		catalog: g.catalog,
		roller:  g.rng,
		turn:    &g.turn,
	}
}

func (s *monsterSpellSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || intent.Kind != ecs.IntentSpell {
		return nil
	}

	actor, found := s.actors.Get(s.turn.Actor)

	if !found ||
		actor.KindID != "MONS_ENDOPLASM" ||
		intent.SpellID != "SPELL_FREEZE" {
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
		return fmt.Errorf("endoplasm has invalid Freeze book: %v", err)
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
		!adjacentActors(*casterPosition, *playerPosition) {
		return fmt.Errorf("endoplasm cannot Freeze distant or dead player")
	}

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
