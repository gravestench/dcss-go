package game

import (
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
)

// Duel crosses the real command, Lua generator, grid, and portal commit.
// A nonacting opponent leaves failure retries independent of monster AI.
func runOkawaruDuel(t *testing.T, killTarget, renounce,
	automaticDeparture bool) {
	g := newGeneratedTestGame(t, 99144)
	level := g.levels[1]

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_OKAWARU",
			"piety":  int64(200),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)
	startingProgress := *progress
	progress.Level = 10

	if _, err := g.stores.Progression.Set(g.player, *progress); err != nil {
		t.Fatal(err)
	}

	magic, _ := g.stores.Magic.Get(g.player)
	startingMagic := *magic
	magic.Max = 10
	magic.Current = 10

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	monster, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(monster, ecs.Actor{
		KindID: "MONS_OGRE",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(monster, ecs.Health{
		Current: 25,
		Max:     25,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(monster, ecs.Combatant{}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.AI.Set(monster, ecs.MonsterAI{
		Behavior: "sleep",
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.MonsterEnergy.Set(monster,
		ecs.MonsterEnergy{}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	origin := *position
	var aim point

	for _, candidate := range []point{
		{x: 1},
		{x: -1},
		{y: 1},
		{y: -1},
	} {
		x := position.X + candidate.x
		y := position.Y + candidate.y

		if level.Walkable(x, y) {
			if _, occupied := level.ActorAt(x, y); !occupied {
				aim = candidate
				break
			}
		}
	}

	if aim == (point{}) {
		t.Fatal("no adjacent cell for Duel test monster")
	}

	if err := level.PlaceActor(monster,
		position.X+aim.x, position.Y+aim.y); err != nil {
		t.Fatal(err)
	}

	// The synthetic Ogre occupies one extra valid Dungeon roster slot.
	level.initialActors++

	cancel, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_OKAWARU_DUEL",
		DX:        -1,
	})

	if err != nil || cancel.Spent != 0 {
		t.Fatalf("invalid Duel target spent %d: %v", cancel.Spent, err)
	}

	var result StepResult

	for attempt := 0; attempt < 15; attempt++ {
		result, err = g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_OKAWARU_DUEL",
			DX:        aim.x,
			DY:        aim.y,
		})

		if err != nil {
			t.Fatal(err)
		}

		current, _ := g.stores.Positions.Get(g.player)

		if current.LevelID == 3701 {
			break
		}
	}

	position, _ = g.stores.Positions.Get(g.player)
	challenger, _ := g.stores.Positions.Get(monster)

	if result.Spent != 10 || position.LevelID != 3701 ||
		challenger.LevelID != 3701 ||
		g.levels[3701] == nil ||
		g.levels[3701].BranchID != "BRANCH_ARENA" {
		t.Fatalf("Duel did not stage both actors: %+v %+v",
			position, challenger)
	}

	exits := 0
	for _, row := range g.levels[3701].Cells() {
		for _, feature := range row {
			if feature == terrain.ExitArena {
				exits++
			}
		}
	}

	if exits != 1 {
		t.Fatalf("Arena has %d exit arches", exits)
	}

	// The command fixture temporarily grants XL and MP to reach Duel. Use
	// its original legal player profile to isolate Arena save validation.
	activeProgress, _ := g.stores.Progression.Get(g.player)
	activeMagic, _ := g.stores.Magic.Get(g.player)
	duelProgress := *activeProgress
	duelMagic := *activeMagic

	if _, err := g.stores.Progression.Set(g.player,
		startingProgress); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Magic.Set(g.player,
		startingMagic); err != nil {
		t.Fatal(err)
	}

	restored, restoreErr := Restore(g.Snapshot())

	if restored != nil {
		restored.Close()
	}

	if _, err := g.stores.Progression.Set(g.player,
		duelProgress); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Magic.Set(g.player,
		duelMagic); err != nil {
		t.Fatal(err)
	}

	if restoreErr != nil {
		t.Fatalf("active Duel did not restore: %v", restoreErr)
	}

	if automaticDeparture {
		_, err := g.scripts.Components()["religion.worship"].Set(
			g.player,
			map[string]any{
				"god_id": "GOD_NO_GOD",
				"piety":  int64(0),
			},
		)

		if err != nil {
			t.Fatal(err)
		}

		departed, departErr := g.Step(Command{Kind: CommandWait})
		outside, _ := g.stores.Positions.Get(g.player)

		if departErr != nil || departed.Spent != 10 ||
			outside.LevelID != 1 || g.levels[3701] != nil {
			t.Fatalf("automatic departure did not retire Arena: %+v: %v",
				outside, departErr)
		}

		return
	}

	if renounce {
		left, leaveErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_RENOUNCE_RELIGION",
			TargetID:  "renounce_second:GOD_OKAWARU",
			Forced:    true,
		})

		if leaveErr != nil {
			t.Fatal(leaveErr)
		}

		outside, _ := g.stores.Positions.Get(g.player)
		worship, _ := g.scripts.Components()["religion.worship"].Get(g.player)
		god, _ := worship.Get("god_id")

		if left.Spent != 10 || outside.LevelID != 1 ||
			g.levels[3701] != nil || god != "GOD_NO_GOD" {
			t.Fatalf("Arena renunciation failed: %+v god=%v",
				outside, god)
		}

		return
	}

	if killTarget {
		visit, found := g.scripts.Components()["character.arena_visit"].Get(g.player)

		if !found {
			t.Fatal("Duel visit was not saved")
		}

		barrierX, _ := visit.Get("target_x")
		barrierY, _ := visit.Get("target_y")
		monsterHealth, _ := g.stores.Health.Get(monster)
		monsterHealth.Current = 0

		if _, err := g.stores.Health.Set(monster, *monsterHealth); err != nil {
			t.Fatal(err)
		}

		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}

		if g.levels[3701].Cells()[barrierY.(int64)][barrierX.(int64)] !=
			terrain.Floor {
			t.Fatal("final Duel death did not open the exit barrier")
		}
	}

	// The outside coordinate is retained exactly. A live target returns to
	// an adjacent free cell before the temporary floor is retired.
	var exit point
	for y, row := range g.levels[3701].Cells() {
		for x, feature := range row {
			if feature == terrain.ExitArena {
				exit = point{x: x, y: y}
			}
		}
	}

	if err := g.levels[3701].MoveActor(g.player,
		exit.x, exit.y); err != nil {
		t.Fatal(err)
	}

	returned, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)
	challenger, alive := g.stores.Positions.Get(monster)

	if returned.Spent != 10 || position.LevelID != 1 ||
		position.X != origin.X || position.Y != origin.Y ||
		g.levels[3701] != nil ||
		(!killTarget && (!alive || challenger.LevelID != 1)) ||
		(killTarget && alive) {
		t.Fatalf("Arena return lost origin or target: %+v %+v",
			position, challenger)
	}
}

func TestOkawaruDuelEntersAuthoredArena(t *testing.T) {
	runOkawaruDuel(t, false, false, false)
}

func TestOkawaruDuelVictoryOpensExit(t *testing.T) {
	runOkawaruDuel(t, true, false, false)
}

func TestOkawaruRenunciationReturnsFromArena(t *testing.T) {
	runOkawaruDuel(t, false, true, false)
}

func TestOkawaruAutomaticDepartureReturnsFromArena(t *testing.T) {
	runOkawaruDuel(t, false, false, true)
}
