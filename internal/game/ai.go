package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
)

// monsterDecisionSystem turns an active monster's saved AI state into its
// transient action intent before movement and combat systems run.
type monsterDecisionSystem struct {
	player    akara.Entity
	positions *akara.Store[ecs.Position]
	ai        *akara.Store[ecs.MonsterAI]
	followers *akara.Store[ecs.BandFollower]
	intents   *akara.Store[ecs.Intent]
	levels    map[int]*Level
	rng       *RNGStreams
	clock     *Aut
	turn      *TurnContext
}

func newMonsterDecisionSystem(g *Game) *monsterDecisionSystem {
	return &monsterDecisionSystem{
		player:    g.player,
		positions: g.stores.Positions,
		ai:        g.stores.AI,
		followers: g.stores.Followers,
		intents:   g.stores.Intents,
		levels:    g.levels,
		rng:       g.rng,
		clock:     &g.currentAut,
		turn:      &g.turn,
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

	if err := s.updateMonsterTarget(ai, *position, *player, playerVisible); err != nil {
		return ecs.Intent{}, err
	}

	if ai.Behavior == "wander" {
		if err := s.updateWanderTarget(actor, ai, level, *position, visible); err != nil {
			return ecs.Intent{}, err
		}

		if ai.TargetX == 0 && ai.TargetY == 0 {
			return ecs.Intent{Kind: ecs.IntentWait}, nil
		}
	}

	return s.followMonsterTarget(actor, *ai, level, *position, *player, visible), nil
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
			ai.Behavior = "wander"
			ai.TargetX = 0
			ai.TargetY = 0
			ai.MemoryUntilAut = 0
		}
	} else if ai.Behavior != "seek" && ai.Behavior != "wander" {
		// Earlier AI records used "chase" without a remembered target.
		ai.Behavior = "wander"
		ai.TargetX = 0
		ai.TargetY = 0
	}

	if position.X == ai.TargetX && position.Y == ai.TargetY {
		ai.Behavior = "wander"
		ai.TargetX = 0
		ai.TargetY = 0
		ai.MemoryUntilAut = 0
	}

	return nil
}

func (s *monsterDecisionSystem) updateWanderTarget(
	actor akara.Entity,
	ai *ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	visible []bool,
) error {
	retarget := ai.TargetX == 0 && ai.TargetY == 0
	leaderPosition, inBand := s.bandLeaderPosition(actor, position.LevelID)

	if inBand &&
		chebyshevDistance(position.X, position.Y, leaderPosition.X, leaderPosition.Y) >= 6 {
		retarget = true
	}

	if inBand && ai.TargetX == leaderPosition.X && ai.TargetY == leaderPosition.Y &&
		chebyshevDistance(position.X, position.Y, leaderPosition.X, leaderPosition.Y) < 6 {
		retarget = true
	}

	if !retarget {
		roll, err := s.rng.Intn("ai", 20)

		if err != nil {
			return err
		}

		retarget = roll == 0
	}

	if retarget {
		return s.chooseWanderTarget(actor, ai, level, position.X, position.Y, visible)
	}

	return nil
}

func (s *monsterDecisionSystem) followMonsterTarget(
	actor akara.Entity,
	ai ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	player ecs.Position,
	visible []bool,
) ecs.Intent {
	dx, dy := sign(ai.TargetX-position.X), sign(ai.TargetY-position.Y)
	goalActor := akara.Entity(0)

	if ai.TargetX == player.X && ai.TargetY == player.Y {
		goalActor = s.player
	} else if follower, found := s.followers.Get(actor); found {
		leader, alive := s.positions.Get(follower.Leader)

		if alive && leader.LevelID == position.LevelID &&
			ai.TargetX == leader.X && ai.TargetY == leader.Y {
			goalActor = follower.Leader
		}
	}

	if !visible[ai.TargetY*level.width+ai.TargetX] {
		intent, found := s.routeMonsterIntent(ai, level, position, player, goalActor)

		if !found {
			return ecs.Intent{Kind: ecs.IntentWait}
		}

		return intent
	}

	// DCSS aims toward the target along both axes first. Cardinal steps remain
	// useful when a diagonal is blocked by terrain or another actor.
	for _, step := range [][2]int{
		{dx, dy},
		{dx, 0},
		{0, dy},
	} {
		if step == [2]int{} {
			continue
		}

		x, y := position.X+step[0], position.Y+step[1]

		if x == player.X && y == player.Y {
			return ecs.Intent{
				Kind: ecs.IntentMelee,
				DX:   step[0],
				DY:   step[1],
			}
		}

		if level.Walkable(x, y) {
			if _, occupied := level.ActorAt(x, y); !occupied {
				return ecs.Intent{
					Kind: ecs.IntentMove,
					DX:   step[0],
					DY:   step[1],
				}
			}
		}
	}

	if intent, found := s.routeMonsterIntent(ai, level, position, player, goalActor); found {
		return intent
	}

	return ecs.Intent{Kind: ecs.IntentWait}
}

func (s *monsterDecisionSystem) routeMonsterIntent(
	ai ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	player ecs.Position,
	goalActor akara.Entity,
) (ecs.Intent, bool) {
	dx, dy, found := level.RouteStep(
		position.X,
		position.Y,
		ai.TargetX,
		ai.TargetY,
		goalActor,
	)

	if !found {
		return ecs.Intent{}, false
	}

	nextX := position.X + dx
	nextY := position.Y + dy

	// RouteStep may enter a goal actor's tile for melee. A band leader is
	// a navigation goal, never a valid attack target for its followers.
	if goalActor != 0 && goalActor != s.player &&
		nextX == ai.TargetX && nextY == ai.TargetY {
		return ecs.Intent{Kind: ecs.IntentWait}, true
	}

	return monsterStepIntent(nextX, nextY, player.X, player.Y, dx, dy), true
}

func monsterStepIntent(nextX, nextY, playerX, playerY, dx, dy int) ecs.Intent {
	if nextX == playerX && nextY == playerY {
		return ecs.Intent{
			Kind: ecs.IntentMelee,
			DX:   dx,
			DY:   dy,
		}
	}

	return ecs.Intent{
		Kind: ecs.IntentMove,
		DX:   dx,
		DY:   dy,
	}
}

// chooseWanderTarget follows Crawl's 150 attempts with offsets in [-6, 6].
// A failed search leaves the animal waiting until its next decision.
func (s *monsterDecisionSystem) chooseWanderTarget(
	actor akara.Entity,
	ai *ecs.MonsterAI,
	level *Level,
	x, y int,
	visible []bool,
) error {
	ai.TargetX = 0
	ai.TargetY = 0

	if leader, found := s.bandLeaderPosition(actor, level.ID); found {
		return s.chooseBandWanderTarget(ai, level, x, y, leader, visible)
	}

	for attempt := 0; attempt < 150; attempt++ {
		dx, err := s.rng.Intn("ai", 13)

		if err != nil {
			return err
		}

		dy, err := s.rng.Intn("ai", 13)

		if err != nil {
			return err
		}

		targetX, targetY := x+dx-6, y+dy-6

		if (targetX != x || targetY != y) && level.Walkable(targetX, targetY) {
			ai.TargetX = targetX
			ai.TargetY = targetY

			return nil
		}
	}

	return nil
}

func (s *monsterDecisionSystem) bandLeaderPosition(
	actor akara.Entity,
	levelID int,
) (ecs.Position, bool) {
	follower, found := s.followers.Get(actor)

	if !found {
		return ecs.Position{}, false
	}

	leader, alive := s.positions.Get(follower.Leader)

	if !alive || leader.LevelID != levelID {
		return ecs.Position{}, false
	}

	return *leader, true
}

// Follower wandering favors cells within the source six-cell comfort range.
// A separated follower heads toward the leader until that range is reachable.
func (s *monsterDecisionSystem) chooseBandWanderTarget(
	ai *ecs.MonsterAI,
	level *Level,
	x, y int,
	leader ecs.Position,
	visible []bool,
) error {
	if chebyshevDistance(x, y, leader.X, leader.Y) > 13 {
		ai.TargetX = leader.X
		ai.TargetY = leader.Y

		return nil
	}

	candidates := make([]point, 0)

	for candidateY := 0; candidateY < len(level.terrain); candidateY++ {
		for candidateX := 0; candidateX < level.width; candidateX++ {
			if !visible[candidateY*level.width+candidateX] ||
				!level.Walkable(candidateX, candidateY) ||
				chebyshevDistance(candidateX, candidateY, leader.X, leader.Y) >= 6 ||
				(candidateX == x && candidateY == y) {
				continue
			}

			if _, occupied := level.ActorAt(candidateX, candidateY); occupied {
				continue
			}

			candidates = append(candidates, point{
				x: candidateX,
				y: candidateY,
			})
		}
	}

	if len(candidates) == 0 {
		ai.TargetX = leader.X
		ai.TargetY = leader.Y

		return nil
	}

	choice, err := s.rng.Intn("ai", len(candidates))

	if err != nil {
		return err
	}

	ai.TargetX = candidates[choice].x
	ai.TargetY = candidates[choice].y

	return nil
}

func chebyshevDistance(x1, y1, x2, y2 int) int {
	dx := x1 - x2

	if dx < 0 {
		dx = -dx
	}

	dy := y1 - y2

	if dy < 0 {
		dy = -dy
	}

	return max(dx, dy)
}

func sign(value int) int {
	if value < 0 {
		return -1
	}

	if value > 0 {
		return 1
	}

	return 0
}
