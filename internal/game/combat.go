package game

import (
	"fmt"
	"slices"
	"time"

	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type combatSystem struct {
	player akara.Entity

	intents   *akara.Store[ecs.Intent]
	positions *akara.Store[ecs.Position]
	actors    *akara.Store[ecs.Actor]
	health    *akara.Store[ecs.Health]
	combat    *akara.Store[ecs.Combatant]
	poison    *akara.Store[ecs.Poison]
	ai        *akara.Store[ecs.MonsterAI]

	levels  map[int]*Level
	catalog content.Catalog
	fighter playerCombat
	roller  combat.Roller
	rng     *RNGStreams
	turn    *TurnContext
}

func newCombatSystem(g *Game) *combatSystem {
	s := g.stores

	return &combatSystem{
		player: g.player,

		intents:   s.Intents,
		positions: s.Positions,
		actors:    s.Actors,
		health:    s.Health,
		combat:    s.Combat,
		poison:    s.Poison,
		ai:        s.AI,

		levels:  g.levels,
		catalog: g.catalog,
		fighter: newPlayerCombat(g),
		roller:  g.rng,
		rng:     g.rng,
		turn:    &g.turn,
	}
}

func (s *combatSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || intent.Kind != ecs.IntentMelee {
		return nil
	}

	position, found := s.positions.Get(s.turn.Actor)

	if !found {
		return fmt.Errorf("attacker %d has no position", s.turn.Actor)
	}

	level := s.levels[position.LevelID]

	if level == nil {
		return fmt.Errorf("attacker %d has no level %d", s.turn.Actor, position.LevelID)
	}

	target, found := level.ActorAt(position.X+intent.DX, position.Y+intent.DY)

	if !found || target == s.turn.Actor {
		return fmt.Errorf("attacker %d has no target", s.turn.Actor)
	}

	victim, found := s.health.Get(target)

	if !found {
		return fmt.Errorf("target %d has no health", target)
	}

	if s.turn.Actor == s.player {
		return s.resolvePlayerMelee(target, victim)
	}

	if target != s.player {
		return fmt.Errorf("unsupported non-player melee defender %d", target)
	}

	return s.resolveMonsterMelee(victim)
}

func (s *combatSystem) resolvePlayerMelee(
	target akara.Entity,
	victim *ecs.Health,
) error {
	actor, found := s.actors.Get(target)

	if !found || !isOrdinaryMonster(actor.KindID) {
		return fmt.Errorf("unsupported player melee target %d", target)
	}

	defender, err := ordinaryMonster(s.catalog, actor.KindID)

	if err != nil {
		return err
	}

	input, err := s.fighter.attackInput(actor.KindID)

	if err != nil {
		return err
	}

	outcome, err := combat.PlayerMelee(s.roller, input)

	if err != nil {
		return err
	}

	beforeHP := victim.Current

	victim.Current = max(0, victim.Current-outcome.Damage)

	if beforeHP > 0 && victim.Current == 0 {
		s.turn.PlayerKill = target
	}

	message := fmt.Sprintf("You miss the %s.", defender.Name)

	if outcome.Kind == combat.Hit {
		if err := s.practicePlayerHit(input, actor.KindID); err != nil {
			return err
		}

		message = fmt.Sprintf("You hit the %s.", defender.Name)

		if outcome.Damage == 0 {
			message = fmt.Sprintf("You hit the %s but do no damage.", defender.Name)
		}
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: message,
	})

	if victim.Current == 0 {
		return nil
	}

	return s.resolveAuxiliaryHeadbutt(target, victim, defender.Name, actor.KindID)
}

func (s *combatSystem) resolveAuxiliaryHeadbutt(
	target akara.Entity,
	victim *ecs.Health,
	name, kindID string,
) error {
	in, err := s.fighter.headbuttInput(kindID)

	if err != nil {
		return err
	}

	outcome, err := combat.AuxiliaryHeadbutt(s.roller, in)

	if err != nil {
		return err
	}

	if !outcome.Attempted {
		return nil
	}

	message := fmt.Sprintf("Your headbutt misses the %s.", name)

	if outcome.Hit {
		victim.Current = max(0, victim.Current-outcome.Damage)
		message = fmt.Sprintf("You headbutt the %s.", name)

		if outcome.Damage == 0 {
			message = fmt.Sprintf("You headbutt the %s, but do no damage.", name)
		}

		if victim.Current == 0 {
			s.turn.PlayerKill = target
		}
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: message,
	})

	return nil
}

func (s *combatSystem) applyPoisonBite(animal content.MonsterDef) error {
	amount, err := combat.PoisonBiteAmount(s.roller, animal.HD)

	if err != nil ||
		amount == 0 {
		return err
	}

	poison, found := s.poison.Get(s.player)

	if !found {
		_, err = s.poison.Set(s.player, ecs.Poison{
			AmountScaled:    amount * 1000,
			SourceMonsterID: animal.ID,
		})

		if err != nil {
			return err
		}
	} else {
		poison.AmountScaled = min(2147483647, poison.AmountScaled+amount*1000)
		poison.SourceMonsterID = animal.ID
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "poison",
		Text: "You are poisoned.",
	})

	return nil
}

func (s *combatSystem) resolveMonsterMelee(victim *ecs.Health) error {
	actor, found := s.actors.Get(s.turn.Actor)

	if !found || !isOrdinaryMonster(actor.KindID) {
		return fmt.Errorf("unsupported melee attacker %d", s.turn.Actor)
	}

	animal, err := ordinaryMonster(s.catalog, actor.KindID)

	if err != nil {
		return err
	}

	defense, err := s.fighter.defense()

	if err != nil {
		return err
	}

	outcome, err := combat.ResolveNaturalAttack(s.roller, combat.NaturalAttack{
		HD:        animal.HD,
		Damage:    animal.Attacks[0].Damage,
		TypeID:    animal.Attacks[0].TypeID,
		FlavourID: animal.Attacks[0].FlavourID,
	}, defense)

	if err != nil {
		return err
	}

	state, found := s.combat.Get(s.player)

	if !found {
		return fmt.Errorf("player %d has no combat state", s.player)
	}

	state.ShieldBlocks = outcome.ShieldBlocks
	victim.Current = max(0, victim.Current-outcome.Damage)

	if err := s.practiceMonsterAttack(outcome, defense); err != nil {
		return err
	}

	message := ""

	switch outcome.Kind {
	case combat.Miss:
		message = fmt.Sprintf("The %s misses you.", animal.Name)

	case combat.Dodge:
		message = fmt.Sprintf("You dodge the %s's attack.", animal.Name)

	case combat.Block:
		message = fmt.Sprintf("You block the %s's attack.", animal.Name)

	case combat.Hit:
		verb := "bites"

		if animal.Attacks[0].TypeID == "AT_HIT" {
			verb = "hits"
		}

		if outcome.Damage == 0 {
			message = fmt.Sprintf("The %s %s you, but does no damage.", animal.Name, verb)
		} else {
			message = fmt.Sprintf("The %s %s you for %d damage.", animal.Name, verb, outcome.Damage)
		}

	default:
		return fmt.Errorf("unknown natural attack outcome %d", outcome.Kind)
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "combat",
		Text: message,
	})

	if outcome.Kind == combat.Miss || outcome.Kind == combat.Dodge {
		if err := s.resolveReflexiveHeadbutt(animal.Name, actor.KindID); err != nil {
			return err
		}
	}

	if slices.Contains(animal.Flags, "M_BATTY") {
		ai, found := s.ai.Get(s.turn.Actor)

		if !found {
			return fmt.Errorf("batty monster %d has no AI", s.turn.Actor)
		}

		ai.Behavior = "wander"
		ai.TargetX = 0
		ai.TargetY = 0
		ai.MemoryUntilAut = 0
		// DCSS counts the attack action itself toward BATTY_TURNS.
		ai.BatRetreatActions = max(2, animal.Speed/10) - 1
	}

	if outcome.Kind == combat.Hit && animal.Attacks[0].FlavourID == "AF_POISON" {
		return s.applyPoisonBite(animal)
	}

	return nil
}

func (s *combatSystem) resolveReflexiveHeadbutt(name, kindID string) error {
	in, err := s.fighter.headbuttInput(kindID)

	if err != nil {
		return err
	}

	outcome, err := combat.ReflexiveHeadbutt(s.roller, in)

	if err != nil {
		return err
	}

	if !outcome.Attempted {
		return nil
	}

	attacker, found := s.health.Get(s.turn.Actor)

	if !found || attacker.Current <= 0 {
		return fmt.Errorf("retaliation target %d is not alive", s.turn.Actor)
	}

	attacker.Current = max(0, attacker.Current-outcome.Damage)

	message := fmt.Sprintf("You headbutt the %s.", name)

	if outcome.Damage == 0 {
		message = fmt.Sprintf("You headbutt the %s, but do no damage.", name)
	}

	if attacker.Current == 0 {
		s.turn.PlayerKill = s.turn.Actor
	}

	s.turn.Events = append(s.turn.Events,
		Event{
			Kind: "combat",
			Text: "You furiously retaliate!",
		},

		Event{
			Kind: "combat",
			Text: message,
		},
	)

	return nil
}
