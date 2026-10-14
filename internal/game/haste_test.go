package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func carriedHaste(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(entity, ecs.Item{
		KindID:   "POT_HASTE",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.CarriedBy.Set(entity, ecs.CarriedBy{
		Holder: g.player,
	}); err != nil {
		t.Fatal(err)
	}

	return entity
}

func nextSpeedStreamState(t *testing.T, g *Game, wantedRoll int) uint64 {
	t.Helper()

	for state := uint64(0); state < 100; state++ {
		probe := RestoreRNGStreams(g.rng.seed, map[string]uint64{
			"speed": state,
		})

		roll, err := probe.Intn("speed", 3)

		if err != nil {
			t.Fatal(err)
		}

		if roll == wantedRoll {
			g.rng.states["speed"] = state

			return probe.States()["speed"]
		}
	}

	t.Fatal("could not choose a speed roll")

	return 0
}

func TestHastedWieldUsesTruncatedSourceCosts(t *testing.T) {
	for _, test := range []struct {
		name      string
		speedRoll int
		wantCost  Aut
		useWeapon bool
	}{
		{
			name:      "unwield at six aut",
			speedRoll: 2,
			wantCost:  1,
		},

		{
			name:      "wield at seven aut",
			speedRoll: 0,
			wantCost:  3,
			useWeapon: true,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			g := newStepGame(t)
			durations, _ := g.stores.Durations.Get(g.player)
			durations.HasteAut = 100
			expectedSpeedState := nextSpeedStreamState(t, g, test.speedRoll)
			command := Command{
				Kind: CommandWield,
			}

			if test.useWeapon {
				weapon := addCarriedWeapon(t, g, "WPN_FLAIL")
				command.ItemID = uint64(weapon)
			}

			result, err := g.Step(command)

			if err != nil || result.Spent != test.wantCost {
				t.Fatalf("hasted wield spent %d aut, want %d: %v",
					result.Spent, test.wantCost, err)
			}

			if got := g.rng.States()["speed"]; got != expectedSpeedState {
				t.Fatalf("wield drew extra speed RNG: got %d, want %d",
					got, expectedSpeedState)
			}
		})
	}
}

func TestHasteQuaffUsesOldSpeedThenSpeedsLaterActions(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(ratID(t, g), 14, 7); err != nil {
		t.Fatal(err)
	}

	item := carriedHaste(t, g)
	quaff, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: uint64(item),
	})

	if err != nil || quaff.Spent != 10 ||
		quaff.View.HasteAut < 250 || quaff.View.HasteAut > 390 ||
		!containsEvent(quaff.Events, "You feel yourself speed up.") {
		t.Fatalf("haste quaff = %+v, %v", quaff, err)
	}

	if g.world.EntityExists(item) {
		t.Fatal("haste potion was not consumed")
	}

	before := quaff.View.HasteAut
	wait, err := g.Step(Command{Kind: CommandWait})

	if err != nil ||
		(wait.Spent != 6 && wait.Spent != 7) ||
		wait.View.HasteAut != before-int(wait.Spent) {
		t.Fatalf("hasted wait = %+v, %v", wait, err)
	}

	actor, _ := g.stores.Actors.Get(g.player)

	if actor.NextAut != int64(10+wait.Spent) {
		t.Fatalf("player deadline = %d, spent %d", actor.NextAut, wait.Spent)
	}

	streams := g.rng.States()
	inspect, err := g.Step(Command{Kind: CommandInspect})

	if err != nil ||
		inspect.Spent != 0 ||
		!reflect.DeepEqual(streams, g.rng.States()) {
		t.Fatalf("inspection drew speed or spent time: %+v, %v", inspect, err)
	}
}

func TestHasteSaveContinuationAndLegacyDefault(t *testing.T) {
	g := newStepGame(t)
	item := carriedHaste(t, g)

	if _, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: uint64(item),
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := loaded.Step(Command{Kind: CommandWait})

	if leftErr != nil ||
		rightErr != nil ||
		!reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("haste continuation = %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
	}

	legacy := snapshot
	legacy.Entities = append([]save.EntityRecord(nil), snapshot.Entities...)

	for index := range legacy.Entities {
		record := &legacy.Entities[index]

		if record.Player != nil {
			durations := *record.Durations
			durations.HasteAut = 0
			record.Durations = &durations
		}
	}

	old, err := Restore(legacy, testCatalog(t))

	if err != nil || old.View().HasteAut != 0 {
		t.Fatalf("legacy haste restore = %v, %d", err, old.View().HasteAut)
	}

	defer old.Close()
}

func TestHasteScalesMeleeAndDurationByTheSameAction(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	durations, _ := g.stores.Durations.Get(g.player)
	durations.HasteAut = 100
	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil ||
		result.Spent < 2 ||
		result.Spent > 9 ||
		result.View.HasteAut != 100-int(result.Spent) {
		t.Fatalf("hasted melee timing = %d aut, %d haste, %v",
			result.Spent, result.View.HasteAut, err)
	}
}

func TestHasteSchedulesPlayerBeforeLaterMonsterDeadline(t *testing.T) {
	g := newStepGame(t)
	rat, _ := g.stores.Actors.Get(ratID(t, g))
	rat.NextAut = 10
	durations, _ := g.stores.Durations.Get(g.player)
	durations.HasteAut = 100

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil ||
		(result.Spent != 6 && result.Spent != 7) ||
		rat.NextAut != 10 ||
		g.currentAut != result.Spent {
		t.Fatalf("haste deadline = %d, rat %d, clock %d, err %v",
			result.Spent, rat.NextAut, g.currentAut, err)
	}
}

func TestHasteExpiresAfterItsFinalFastAction(t *testing.T) {
	g := newStepGame(t)
	durations, _ := g.stores.Durations.Get(g.player)
	durations.HasteAut = 9

	lastFast, err := g.Step(Command{Kind: CommandWait})

	if err != nil ||
		(lastFast.Spent != 6 && lastFast.Spent != 7) ||
		lastFast.View.HasteAut != 0 ||
		!containsEvent(lastFast.Events, "You feel yourself slow down.") {
		t.Fatalf("last hasted action = %+v, %v", lastFast, err)
	}

	normal, err := g.Step(Command{Kind: CommandWait})

	if err != nil || normal.Spent != 10 {
		t.Fatalf("action after haste = %+v, %v", normal, err)
	}
}

func TestDungeonTwoHasSeparateHasteAndHealingPotions(t *testing.T) {
	g := newStepGame(t)
	positions := make(map[string]ecs.Position)

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, onFloor := g.stores.Positions.Get(entity)

		if onFloor {
			positions[item.KindID] = *position
		}
	}

	haste, found := positions["POT_HASTE"]

	if !found || haste.LevelID != 2 ||
		haste == positions["POT_HEAL_WOUNDS"] ||
		!g.levels[2].Walkable(haste.X, haste.Y) {
		t.Fatalf("D:2 haste placement = %+v; floor items %+v", haste, positions)
	}
}

func TestRestoreRejectsHasteOutsideItsSourceCap(t *testing.T) {
	g := newStepGame(t)
	base := g.Snapshot()

	for _, invalid := range []int{-1, 401} {
		bad := base
		bad.Entities = append([]save.EntityRecord(nil), base.Entities...)

		for index := range bad.Entities {
			record := &bad.Entities[index]

			if record.Player != nil {
				durations := *record.Durations
				durations.HasteAut = invalid
				record.Durations = &durations
			}
		}

		loaded, err := Restore(bad, testCatalog(t))

		if loaded != nil {
			loaded.Close()
		}

		if err == nil {
			t.Fatalf("restored impossible haste duration %d", invalid)
		}
	}
}
