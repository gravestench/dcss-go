package game

import (
	"reflect"
	"testing"
	"time"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func moveRatToOtherFloor(t *testing.T, g *Game) {
	t.Helper()
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[2].PlaceActor(rat, 8, 4); err != nil {
		t.Fatal(err)
	}
}

func TestHumanFighterRecoversThroughPlayerWaitsOnly(t *testing.T) {
	g := newStepGame(t)
	moveRatToOtherFloor(t, g)
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)

	health.Current = 7
	magic.Current = 0

	for range 17 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	progress, ok := g.stores.Regeneration.Get(g.player)

	if !ok ||
		health.Current != 8 ||
		magic.Current != 1 ||
		progress.HPProgress != 2 ||
		progress.MPProgress != 5 {
		t.Fatalf("17 waits: HP %+v MP %+v regen %+v found %v", health, magic, progress, ok)
	}

	if g.currentAut != 170 {
		t.Fatalf("clock %d", g.currentAut)
	}
}

func TestRegenerationSystemUsesVariableActionAut(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)
	progress, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 10
	magic.Current = 0
	progress.HPProgress = 94
	progress.MPProgress = 94

	expectedRNG := RestoreRNGStreams(g.seed, g.rng.States())
	hpRoll, err := expectedRNG.Intn("regeneration", 10)

	if err != nil {
		t.Fatal(err)
	}

	mpRoll, err := expectedRNG.Intn("regeneration", 10)

	if err != nil {
		t.Fatal(err)
	}

	wantHP := 10
	wantHPProgress := 99

	if hpRoll < 4 {
		wantHP = 11
		wantHPProgress = 0
	}

	wantMPProgress := 0

	if mpRoll < 3 {
		wantMPProgress = 1
	}

	g.turn.Actor = g.player

	updateLuaSystem(t, g, "status.regeneration", time.Duration(9))

	if health.Current != wantHP ||
		magic.Current != 1 ||
		progress.HPProgress != wantHPProgress ||
		progress.MPProgress != wantMPProgress ||
		!reflect.DeepEqual(g.rng.States(), expectedRNG.States()) {
		t.Fatalf("9-aut Lua regen got HP %+v MP %+v progress %+v", health, magic, progress)
	}
}

func TestMutationRegenerationRatesReachPlayerTurnSystem(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)
	progress, _ := g.stores.Regeneration.Get(g.player)

	health.Max = 30
	health.Current = 5
	magic.Max = 4
	magic.Current = 0
	progress.HPProgress = 0
	progress.MPProgress = 0

	for _, id := range []string{
		"MUT_REGENERATION",
		"MUT_MANA_REGENERATION",
	} {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		store := g.scripts.Components()["character.mutation"]

		if _, err := store.Set(entity, map[string]any{
			"owner":       g.player,
			"mutation_id": id,
			"acquired":    int64(1),
		}); err != nil {
			t.Fatal(err)
		}
	}

	g.turn.Actor = g.player

	updateLuaSystem(t, g, "status.regeneration", 10)

	if progress.HPProgress != 90 || progress.MPProgress != 18 {
		t.Fatalf("mutation regeneration counters = %+v", *progress)
	}
}

func TestNoRegenerationMutationStopsPlayerHealing(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	progress, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 5
	progress.HPProgress = 99

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_NO_REGENERATION",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	g.turn.Actor = g.player

	updateLuaSystem(t, g, "status.regeneration", 10)

	if health.Current != 5 || progress.HPProgress != 99 {
		t.Fatalf("No Regeneration still healed: HP=%d progress=%d",
			health.Current, progress.HPProgress)
	}
}

func TestInhibitedRegenerationStopsNearVisibleRat(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	progress, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 5
	progress.HPProgress = 99

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.mutation"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"mutation_id": "MUT_INHIBITED_REGENERATION",
		"acquired":    int64(1),
	}); err != nil {
		t.Fatal(err)
	}

	g.turn.Actor = g.player

	updateLuaSystem(t, g, "status.regeneration", 10)

	if health.Current != 5 || progress.HPProgress != 99 {
		t.Fatalf("visible rat did not inhibit healing: HP=%d progress=%d",
			health.Current, progress.HPProgress)
	}

	moveRatToOtherFloor(t, g)
	updateLuaSystem(t, g, "status.regeneration", 10)

	if health.Current != 6 {
		t.Fatalf("healing did not resume after rat left: HP=%d", health.Current)
	}
}

func TestRegenerationSaveContinuationAndLegacyDefault(t *testing.T) {
	g := newStepGame(t)
	moveRatToOtherFloor(t, g)
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)

	health.Current = 7
	magic.Current = 0

	for range 3 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

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
		t.Fatalf("regen continuation %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
	}

	legacy := newStepGame(t).Snapshot()

	for i := range legacy.Entities {
		legacy.Entities[i].Regeneration = nil
	}

	old, err := Restore(legacy)

	if err != nil {
		t.Fatal(err)
	}

	defer old.Close()
	progress, ok := old.stores.Regeneration.Get(old.player)

	if !ok || *progress != (ecs.Regeneration{}) {
		t.Fatalf("old save regen %+v found %v", progress, ok)
	}
}

func TestRegenerationRestoreRejectsInvalidCountersAndOwnership(t *testing.T) {
	g := newStepGame(t)

	for _, tc := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{
			name: "negative HP",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Player != nil {
						s.Entities[i].Regeneration.HPProgress = -1
					}
				}
			},
		},

		{
			name: "MP overflow",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Player != nil {
						s.Entities[i].Regeneration.MPProgress = 100
					}
				}
			},
		},

		{
			name: "monster component",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].AI != nil {
						s.Entities[i].Regeneration = &ecs.Regeneration{}
					}
				}
			},
		},

		{
			name: "item component",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil {
						s.Entities[i].Regeneration = &ecs.Regeneration{}
						break
					}
				}
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			bad := g.Snapshot()
			tc.mutate(&bad)

			if loaded, err := Restore(bad); err == nil {
				loaded.Close()
				t.Fatal("invalid regeneration save accepted")
			}
		})
	}
}
