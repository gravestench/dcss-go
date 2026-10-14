package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func newBallPythonGame(t *testing.T) (*Game, akara.Entity) {
	return newBallPythonGameForSpecies(t, "SP_HUMAN")
}

func newBallPythonGameForSpecies(
	t *testing.T,
	speciesID string,
) (*Game, akara.Entity) {
	t.Helper()
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGame(
		1,
		catalog,
		speciesID,
		"JOB_FIGHTER",
		"WPN_FLAIL",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	for _, entity := range g.stores.AI.Entities() {
		actor, found := g.stores.Actors.Get(entity)

		if found && actor.KindID == "MONS_BALL_PYTHON" {
			return g, entity
		}
	}

	t.Fatal("seeded generated Dungeon has no ball python")

	return nil, 0
}

func TestGeneratedDungeonSupportsBallPythonOnlyInGeneratedRoster(t *testing.T) {
	generated, err := scenarioMonsterIDs(generatedDungeonScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	if !slices.Contains(generated, "MONS_BALL_PYTHON") {
		t.Fatal("generated Dungeon excludes source ball python")
	}

	fixed, err := scenarioMonsterIDs(populationScenarioID)

	if err != nil {
		t.Fatal(err)
	}

	if slices.Contains(fixed, "MONS_BALL_PYTHON") {
		t.Fatal("fixed population scenario unexpectedly changed")
	}
}

func TestGeneratedBallPythonSpawnsFromSourcePopulation(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	actor, _ := g.stores.Actors.Get(pythonID)
	health, _ := g.stores.Health.Get(pythonID)

	if actor.Speed != 12 ||
		health.Max < 2 ||
		health.Max > 5 {
		t.Fatalf("ball python actor %+v, health %+v", actor, health)
	}
}

func TestBallPythonDeathAwardsSourceXP(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	dx, dy := placePlayerBesideMonster(t, g, pythonID)
	health, _ := g.stores.Health.Get(pythonID)
	definition, _ := g.catalog.Monster("MONS_BALL_PYTHON")
	wantXP, err := character.OrdinaryNaturalExperience(definition, health.Max)

	if err != nil {
		t.Fatal(err)
	}

	if !definition.LeavesCorpse {
		t.Fatal("source ball python is not corpse eligible")
	}

	health.Current = 1

	for attempt := 0; attempt < 100 && g.world.EntityExists(pythonID); attempt++ {
		if _, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentMelee,
			DX:   dx,
			DY:   dy,
		}, 10, "player"); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(pythonID) {
		t.Fatal("ball python survived 100 melee attacks")
	}

	progress, _ := g.stores.Progression.Get(g.player)

	if progress.TotalXP != wantXP {
		t.Fatalf("ball python awarded %d XP, want %d", progress.TotalXP, wantXP)
	}

	for _, entity := range g.stores.Corpses.Entities() {
		corpse, _ := g.stores.Corpses.Get(entity)

		if corpse.MonsterID != "MONS_BALL_PYTHON" {
			t.Fatalf("ball python death left corpse %+v", corpse)
		}
	}
}

func TestBallPythonSecondAttackGrabsWithoutDirectDamage(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)
	g.turn.Actor = pythonID

	rolls := []combatRoll{
		{
			bound: 20,
			value: 19,
		},

		{
			bound: 10,
			value: 0,
		},

		{
			bound: 11,
			value: 0,
		},

		{
			bound: 100,
			value: 10,
		},

		{
			bound: 15,
			value: 14,
		},

		{
			bound: 18,
			value: 0,
		},

		{
			bound: 19,
			value: 0,
		},

		{
			bound: 3,
			value: 0,
		},

		{
			bound: 7,
			value: 0,
		},

		{
			bound: 20,
			value: 19,
		},

		{
			bound: 10,
			value: 0,
		},

		{
			bound: 11,
			value: 0,
		},

		{
			bound: 100,
			value: 10,
		},

		{
			bound: 15,
			value: 14,
		},

		{
			bound: 18,
			value: 0,
		},

		{
			bound: 19,
			value: 0,
		},
	}

	roller := &combatRoller{rolls: rolls}
	system := newCombatSystem(g)

	system.roller = roller

	playerHealth, _ := g.stores.Health.Get(g.player)
	before := playerHealth.Current

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	grip, found := g.stores.Constricted.Get(g.player)

	if !found ||
		grip.By != pythonID ||
		playerHealth.Current != before-1 ||
		len(roller.rolls) != 0 {
		t.Fatalf("grip %+v found %v, HP %d -> %d, rolls %+v",
			grip, found, before, playerHealth.Current, roller.rolls)
	}
}

func TestKilledPythonCannotGrabAfterMinotaurRetaliation(t *testing.T) {
	g, pythonID := newBallPythonGameForSpecies(t, "SP_MINOTAUR")
	placePlayerBesideMonster(t, g, pythonID)
	g.turn.Actor = pythonID

	pythonHealth, _ := g.stores.Health.Get(pythonID)
	playerHealth, _ := g.stores.Health.Get(g.player)

	pythonHealth.Current = 1

	defense, err := newPlayerCombat(g).defense()

	if err != nil {
		t.Fatal(err)
	}

	headbutt, err := newPlayerCombat(g).headbuttInput("MONS_BALL_PYTHON")

	if err != nil {
		t.Fatal(err)
	}

	rolls := []combatRoll{
		{
			bound: 20,
			value: 0,
		},

		{
			bound: 2 * defense.EV,
			value: 0,
		},

		{
			bound: 2*defense.EV + 1,
			value: 0,
		},

		{
			bound: 100,
			value: 0,
		},

		{
			bound: 2,
			value: 0,
		},

		{
			bound: 15,
			value: 14,
		},
	}

	if defense.ShieldClass > 0 {
		rolls = append(rolls,
			combatRoll{
				bound: 2 * defense.ShieldClass,
				value: 0,
			},

			combatRoll{
				bound: 2*defense.ShieldClass + 1,
				value: 0,
			},
		)
	}

	potential := (5 + headbutt.Horns*3) * max(2, 150+5*headbutt.Strength) / 2 / 100
	rolls = append(rolls,
		combatRoll{
			bound: 100,
			value: 0,
		},

		combatRoll{
			bound: potential,
			value: potential - 1,
		},

		combatRoll{
			bound: headbutt.FightingSkill100 + 1,
			value: 0,
		},
	)

	if headbutt.DefenderAC > 0 {
		rolls = append(rolls, combatRoll{
			bound: headbutt.DefenderAC + 1,
			value: 0,
		})
	}

	if headbutt.DefenderAC%2 != 0 {
		rolls = append(rolls, combatRoll{
			bound: 2,
			value: 0,
		})
	}

	roller := &combatRoller{rolls: rolls}
	system := newCombatSystem(g)

	system.roller = roller

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	if pythonHealth.Current != 0 ||
		g.turn.PlayerKill != pythonID ||
		g.stores.Constricted.Has(g.player) ||
		len(roller.rolls) != 0 {
		t.Fatalf("dead python attacked again: HP %d, grip %v, rolls %+v",
			pythonHealth.Current, g.stores.Constricted.Has(g.player), roller.rolls)
	}
}

func TestSecondGrabMissDoesNotTriggerMinotaurRetaliation(t *testing.T) {
	g, pythonID := newBallPythonGameForSpecies(t, "SP_MINOTAUR")
	placePlayerBesideMonster(t, g, pythonID)
	g.turn.Actor = pythonID

	playerHealth, _ := g.stores.Health.Get(g.player)
	system := newCombatSystem(g)

	system.roller = zeroMeleeRoller{}

	if err := system.resolveMonsterMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	retaliations := 0
	grabMisses := 0

	for _, event := range g.turn.Events {
		if strings.Contains(event.Text, "furiously retaliate") {
			retaliations++
		}

		if strings.Contains(event.Text, "misses you with its grab") {
			grabMisses++
		}
	}

	if retaliations != 1 || grabMisses != 1 {
		t.Fatalf("second grab caused %d retaliations and %d miss messages",
			retaliations, grabMisses)
	}
}

func TestBallPythonGripDamagesAfterItsActionAndEndsOnDeath(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	roller := &combatRoller{
		rolls: []combatRoll{
			{
				bound: 4,
				value: 0,
			},

			{
				bound: 12,
				value: 0,
			},
		},
	}

	system := newConstrictSystem(g)

	system.roller = roller
	g.turn.Actor = pythonID

	playerHealth, _ := g.stores.Health.Get(g.player)
	before := playerHealth.Current

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if playerHealth.Current != before-1 || len(roller.rolls) != 0 {
		t.Fatalf("grip damage %d -> %d, rolls %+v",
			before, playerHealth.Current, roller.rolls)
	}

	pythonHealth, _ := g.stores.Health.Get(pythonID)

	pythonHealth.Current = 0
	g.turn.Actor = g.player

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if g.stores.Constricted.Has(g.player) {
		t.Fatal("dead ball python retained its grip")
	}
}

func TestLethalConstrictionClearsSavedGrip(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	playerHealth.Current = 1
	g.turn.Actor = pythonID

	system := newConstrictSystem(g)

	system.roller = &combatRoller{
		rolls: []combatRoll{
			{
				bound: 4,
				value: 0,
			},

			{
				bound: 12,
				value: 0,
			},
		},
	}

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if playerHealth.Current != 0 || g.stores.Constricted.Has(g.player) {
		t.Fatalf("lethal grip left HP %d and status %v",
			playerHealth.Current, g.stores.Constricted.Has(g.player))
	}
}

func TestConstrictedPlayerLosesThreeEVAndShowsStatus(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)
	defender := newPlayerCombat(g)
	before, err := defender.defense()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	after, err := defender.defense()

	if err != nil {
		t.Fatal(err)
	}

	if after.EV != before.EV-3 || !g.View().Constricted {
		t.Fatalf("constricted EV %d -> %d, view %+v", before.EV, after.EV, g.View())
	}
}

func TestConstrictedPlayerSaveRoundTrip(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By:             pythonID,
		EscapeAttempts: 2,
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, g.catalog)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	grip, found := loaded.stores.Constricted.Get(loaded.player)

	if !found ||
		grip.By != pythonID ||
		grip.EscapeAttempts != 2 {
		t.Fatalf("restored grip %+v, found %v", grip, found)
	}

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("constricted player save changed on restore")
	}
}

func TestRestoreRejectsNegativePythonEnergy(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	snapshot := g.Snapshot()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.ID == uint64(pythonID) {
			record.MonsterEnergy.Points = -1

			break
		}
	}

	if loaded, err := Restore(snapshot, g.catalog); err == nil {
		loaded.Close()
		t.Fatal("restored impossible negative python energy")
	}
}

func TestRestoreRejectsInvalidBallPythonGripLinks(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	for _, name := range []string{
		"missing constrictor",
		"self constrictor",
		"negative attempts",
		"excessive attempts",
	} {
		t.Run(name, func(t *testing.T) {
			snapshot := g.Snapshot()

			for index := range snapshot.Entities {
				record := &snapshot.Entities[index]

				if record.ID != uint64(g.player) {
					continue
				}

				switch name {
				case "missing constrictor":
					record.Constricted.By = akara.Entity(999999)

				case "self constrictor":
					record.Constricted.By = g.player

				case "negative attempts":
					record.Constricted.EscapeAttempts = -1

				case "excessive attempts":
					record.Constricted.EscapeAttempts = 1001
				}
			}

			if loaded, err := Restore(snapshot, g.catalog); err == nil {
				loaded.Close()
				t.Fatal("restored invalid constriction link")
			}
		})
	}
}

func TestFailedConstrictedMoveSpendsActionAndCountsEscapeAttempt(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	beforeX, beforeY := playerPosition.X, playerPosition.Y
	dx, dy := freeAdjacentPlayerMove(t, g)

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	intent, err := g.stores.Intents.Set(g.player, ecs.Intent{
		Kind: ecs.IntentMove,
		DX:   dx,
		DY:   dy,
	})

	if err != nil {
		t.Fatal(err)
	}

	rolls := make([]combatRoll, 0, 11)

	for range 5 {
		rolls = append(rolls, combatRoll{
			bound: 13,
			value: 0,
		})
	}

	rolls = append(rolls, combatRoll{
		bound: 4,
		value: 0,
	})

	for range 5 {
		rolls = append(rolls, combatRoll{
			bound: 9,
			value: 8,
		})
	}

	roller := &combatRoller{rolls: rolls}
	system := newMovementSystem(g)

	system.roller = roller
	g.turn.Actor = g.player

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	grip, held := g.stores.Constricted.Get(g.player)

	if intent.Kind != ecs.IntentWait ||
		playerPosition.X != beforeX ||
		playerPosition.Y != beforeY ||
		!held ||
		grip.EscapeAttempts != 1 ||
		len(roller.rolls) != 0 {
		t.Fatalf("failed escape: intent %+v, grip %+v, rolls %+v",
			intent, grip, roller.rolls)
	}
}

func freeAdjacentPlayerMove(t *testing.T, g *Game) (int, int) {
	t.Helper()
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x, y := position.X+dx, position.Y+dy

			if !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); !occupied {
				return dx, dy
			}
		}
	}

	t.Fatal("constricted player has no free adjacent tile")

	return 0, 0
}

func TestSuccessfulConstrictedMoveReleasesAndSlowsPython(t *testing.T) {
	g, pythonID := newBallPythonGame(t)
	placePlayerBesideMonster(t, g, pythonID)
	dx, dy := freeAdjacentPlayerMove(t, g)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	beforeX, beforeY := playerPosition.X, playerPosition.Y
	energy, _ := g.stores.MonsterEnergy.Get(pythonID)

	// The python has already spent its attack cost before an escape.
	energy.Points = 70

	beforeEnergy := energy.Points

	if _, err := g.stores.Constricted.Set(g.player, ecs.Constricted{
		By: pythonID,
	}); err != nil {
		t.Fatal(err)
	}

	intent, err := g.stores.Intents.Set(g.player, ecs.Intent{
		Kind: ecs.IntentMove,
		DX:   dx,
		DY:   dy,
	})

	if err != nil {
		t.Fatal(err)
	}

	rolls := make([]combatRoll, 0, 11)

	for range 5 {
		rolls = append(rolls, combatRoll{
			bound: 13,
			value: 12,
		})
	}

	rolls = append(rolls, combatRoll{
		bound: 4,
		value: 0,
	})

	for range 5 {
		rolls = append(rolls, combatRoll{
			bound: 9,
			value: 0,
		})
	}

	roller := &combatRoller{rolls: rolls}
	system := newMovementSystem(g)

	system.roller = roller
	g.turn.Actor = g.player

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if intent.Kind != ecs.IntentMove ||
		playerPosition.X != beforeX+dx ||
		playerPosition.Y != beforeY+dy ||
		g.stores.Constricted.Has(g.player) ||
		energy.Points != beforeEnergy-5 ||
		len(roller.rolls) != 0 {
		t.Fatalf("successful escape: intent %+v, player %+v, energy %+v, rolls %+v",
			intent, playerPosition, energy, roller.rolls)
	}

	loaded, err := Restore(g.Snapshot(), g.catalog)

	if err != nil {
		t.Fatalf("restore after escaped constriction: %v", err)
	}

	loaded.Close()
}
