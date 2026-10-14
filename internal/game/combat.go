package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/rules"
	"github.com/gravestench/akara"
)

type combatSystem struct {
	game   *Game
	roller combat.Roller
	turn   *TurnContext
}

func (s *combatSystem) Update(_ *akara.World, _ time.Duration) error {
	g := s.game
	intent, found := g.stores.Intents.Get(s.turn.Actor)
	if !found || intent.Kind != ecs.IntentMelee {
		return nil
	}
	position, found := g.stores.Positions.Get(s.turn.Actor)
	if !found {
		return fmt.Errorf("attacker %d has no position", s.turn.Actor)
	}
	level := g.levels[position.LevelID]
	if level == nil {
		return fmt.Errorf("attacker %d has no level %d", s.turn.Actor, position.LevelID)
	}
	target, found := level.ActorAt(position.X+intent.DX, position.Y+intent.DY)
	if !found || target == s.turn.Actor {
		return fmt.Errorf("attacker %d has no target", s.turn.Actor)
	}
	victim, found := g.stores.Health.Get(target)
	if !found {
		return fmt.Errorf("target %d has no health", target)
	}
	if s.turn.Actor == g.player {
		base := g.catalog.Player().BaseDamage // until the player melee slice
		roll, err := s.roller.Intn("melee", base+1)
		if err != nil {
			return err
		}
		damage := rules.MeleeDamage(base, roll)
		victim.Current = max(0, victim.Current-damage)
		s.turn.Events = append(s.turn.Events, Event{Kind: "combat", Text: fmt.Sprintf("You hit the rat for %d damage.", damage)})
		return nil
	}
	if target != g.player {
		return fmt.Errorf("unsupported non-player melee defender %d", target)
	}
	actor, found := g.stores.Actors.Get(s.turn.Actor)
	if !found || actor.KindID != "MONS_RAT" {
		return fmt.Errorf("unsupported melee attacker %d", s.turn.Actor)
	}
	rat, err := g.catalog.Monster(actor.KindID)
	if err != nil {
		return err
	}
	defense, err := g.fighterDefense()
	if err != nil {
		return err
	}
	outcome, err := combat.RatBite(s.roller, combat.RatAttack{
		HD: rat.HD, Damage: rat.Attacks[0].Damage,
		TypeID: rat.Attacks[0].TypeID, FlavourID: rat.Attacks[0].FlavourID,
	}, defense)
	if err != nil {
		return err
	}
	state, found := g.stores.Combat.Get(g.player)
	if !found {
		return fmt.Errorf("player %d has no combat state", g.player)
	}
	state.ShieldBlocks = outcome.ShieldBlocks
	victim.Current = max(0, victim.Current-outcome.Damage)
	message := ""
	switch outcome.Kind {
	case combat.Miss:
		message = "The rat misses you."
	case combat.Dodge:
		message = "You dodge the rat's attack."
	case combat.Block:
		message = "You block the rat's attack."
	case combat.Hit:
		if outcome.Damage == 0 {
			message = "The rat bites you, but does no damage."
		} else {
			message = fmt.Sprintf("The rat bites you for %d damage.", outcome.Damage)
		}
	default:
		return fmt.Errorf("unknown rat bite outcome %d", outcome.Kind)
	}
	s.turn.Events = append(s.turn.Events, Event{Kind: "combat", Text: message})
	return nil
}

func (g *Game) fighterDefense() (combat.Defense, error) {
	attributes, found := g.stores.Attributes.Get(g.player)
	if !found {
		return combat.Defense{}, fmt.Errorf("player has no attributes")
	}
	skills, found := g.stores.Skills.Get(g.player)
	if !found {
		return combat.Defense{}, fmt.Errorf("player has no skills")
	}
	state, found := g.stores.Combat.Get(g.player)
	if !found {
		return combat.Defense{}, fmt.Errorf("player has no combat state")
	}
	input := combat.FighterDefense{Strength: attributes.Strength, Dexterity: attributes.Dexterity, ShieldBlocks: state.ShieldBlocks}
	for _, skill := range skills.Entries {
		switch skill.ID {
		case "SK_ARMOUR":
			input.ArmourSkill = skill.Level
		case "SK_SHIELDS":
			input.ShieldsSkill = skill.Level
		}
	}
	body, shield := false, false
	for _, entity := range g.stores.Equipped.Entities() {
		carrier, carried := g.stores.CarriedBy.Get(entity)
		if !carried || carrier.Holder != g.player {
			continue
		}
		equipped, _ := g.stores.Equipped.Get(entity)
		if equipped.Slot != "body" && equipped.Slot != "shield" {
			continue
		}
		item, found := g.stores.Items.Get(entity)
		if !found {
			return combat.Defense{}, fmt.Errorf("equipped entity %d has no item", entity)
		}
		kind, err := g.catalog.Item(item.KindID)
		if err != nil {
			return combat.Defense{}, err
		}
		if kind.Armour == nil {
			return combat.Defense{}, fmt.Errorf("equipped %s has no armour properties", kind.ID)
		}
		if equipped.Slot == "body" {
			input.BodyAC, input.BodyEV, input.BodyPlus = kind.Armour.AC, kind.Armour.EV, item.Plus
			body = true
		} else {
			input.ShieldAC, input.ShieldEV, input.ShieldPlus = kind.Armour.AC, kind.Armour.EV, item.Plus
			shield = true
		}
	}
	if !body || !shield {
		return combat.Defense{}, fmt.Errorf("Human Fighter lacks body armour or shield")
	}
	return combat.ProjectFighter(input)
}

type deathSystem struct {
	health *akara.Store[ecs.Health]
	player akara.Entity
	turn   *TurnContext
}

func (s *deathSystem) Update(_ *akara.World, _ time.Duration) error {
	for _, entity := range s.health.Entities() {
		health, _ := s.health.Get(entity)
		if health.Current > 0 {
			continue
		}
		if entity == s.player {
			s.turn.Events = append(s.turn.Events, Event{Kind: "death", Text: "You die."})
		} else {
			s.turn.Deaths = append(s.turn.Deaths, entity)
			s.turn.Events = append(s.turn.Events, Event{Kind: "death", Text: "The rat dies."})
		}
	}
	return nil
}
