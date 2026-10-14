package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
)

// monsterDecisionSystem turns an active monster's saved AI state into its
// transient action intent before movement and combat systems run.
type monsterDecisionSystem struct {
	player akara.Entity

	positions *akara.Store[ecs.Position]
	actors    *akara.Store[ecs.Actor]
	ai        *akara.Store[ecs.MonsterAI]
	followers *akara.Store[ecs.BandFollower]
	intents   *akara.Store[ecs.Intent]

	levels  map[int]*Level
	catalog content.Catalog
	rng     *RNGStreams
	clock   *Aut
	turn    *TurnContext
}

func newMonsterDecisionSystem(g *Game) *monsterDecisionSystem {
	return &monsterDecisionSystem{
		player: g.player,

		positions: g.stores.Positions,
		actors:    g.stores.Actors,
		ai:        g.stores.AI,
		followers: g.stores.Followers,
		intents:   g.stores.Intents,

		levels:  g.levels,
		catalog: g.catalog,
		rng:     g.rng,
		clock:   &g.currentAut,
		turn:    &g.turn,
	}
}

func (s *monsterDecisionSystem) Update(_ *akara.World, _ time.Duration) error {
	actor := s.turn.Actor

	if !s.ai.Has(actor) {
		return nil
	}

	if s.intents.Has(actor) {
		return fmt.Errorf("monster %d already has an intent", actor)
	}

	intent, err := s.chooseIntent(actor)

	if err != nil {
		return err
	}

	_, err = s.intents.Set(actor, intent)

	return err
}

func (s *monsterDecisionSystem) chooseIntent(actor akara.Entity) (ecs.Intent, error) {
	position, found := s.positions.Get(actor)

	if !found {
		return ecs.Intent{}, fmt.Errorf("monster %d has no position", actor)
	}

	player, found := s.positions.Get(s.player)

	if !found {
		return ecs.Intent{}, fmt.Errorf("player %d has no position", s.player)
	}

	if position.LevelID != player.LevelID {
		return ecs.Intent{}, fmt.Errorf("monster %d is not on the active floor", actor)
	}

	ai, found := s.ai.Get(actor)

	if !found {
		return ecs.Intent{}, fmt.Errorf("monster %d has no AI", actor)
	}

	level := s.levels[position.LevelID]

	if level == nil {
		return ecs.Intent{}, fmt.Errorf("monster level %d is missing", position.LevelID)
	}

	visible, err := visibility.Compute(level.terrain, position.X, position.Y, 7)

	if err != nil {
		return ecs.Intent{}, err
	}

	playerVisible := visible[player.Y*level.width+player.X]

	retreating := ai.BatRetreatActions > 0

	if retreating {
		ai.BatRetreatActions--
		// Batty monsters choose a new wander target on every retreat action.
		ai.Behavior = "wander"
		ai.TargetX = 0
		ai.TargetY = 0
	}

	if !retreating {
		if err := s.updateMonsterTarget(ai, *position, *player, playerVisible); err != nil {
			return ecs.Intent{}, err
		}
	}

	if playerVisible && !retreating {
		spell, cast, err := s.chooseMonsterSpell(actor, *position, *player)

		if err != nil {
			return ecs.Intent{}, err
		}

		if cast {
			return ecs.Intent{
				Kind:    ecs.IntentSpell,
				SpellID: spell,
			}, nil
		}
	}

	if ai.Behavior == "wander" {
		if err := s.updateWanderTarget(actor, ai, level, *position, visible); err != nil {
			return ecs.Intent{}, err
		}

		if ai.TargetX == 0 && ai.TargetY == 0 {
			return ecs.Intent{Kind: ecs.IntentWait}, nil
		}
	}

	intent := s.followMonsterTarget(actor, *ai, level, *position, *player, visible)

	if retreating && ai.BatRetreatActions == 0 {
		// Source mon-act.cc resumes seeking after the second later wander.
		ai.Behavior = "seek"
		ai.TargetX = player.X
		ai.TargetY = player.Y
	}

	if retreating && intent.Kind == ecs.IntentMelee {
		return ecs.Intent{Kind: ecs.IntentWait}, nil
	}

	return intent, nil
}

func (s *monsterDecisionSystem) updateMonsterTarget(
	ai *ecs.MonsterAI,
	position ecs.Position,
	player ecs.Position,
	playerVisible bool,
) error {
	if playerVisible {
		memoryRoll, err := s.rng.Intn("ai", 301)

		if err != nil {
			return err
		}

		ai.Behavior = "seek"
		ai.TargetX = player.X
		ai.TargetY = player.Y

		ai.MemoryUntilAut = int64(*s.clock) + int64(250+memoryRoll)
	} else if ai.Behavior == "seek" {
		if ai.MemoryUntilAut == 0 {
			// Earlier AI records carried a target but no deadline.
			ai.MemoryUntilAut = int64(*s.clock) + 250
		}

		if int64(*s.clock) >= ai.MemoryUntilAut {
			forgetMonsterTarget(ai)
		}
	} else if ai.Behavior != "seek" && ai.Behavior != "wander" {
		// Earlier AI records used "chase" without a remembered target.
		ai.Behavior = "wander"
		ai.TargetX = 0
		ai.TargetY = 0
	}

	if position.X == ai.TargetX && position.Y == ai.TargetY {
		forgetMonsterTarget(ai)
	}

	return nil
}

// forgetMonsterTarget clears the remembered destination and its expiry together.
func forgetMonsterTarget(ai *ecs.MonsterAI) {
	ai.Behavior = "wander"
	ai.TargetX = 0
	ai.TargetY = 0
	ai.MemoryUntilAut = 0
}
