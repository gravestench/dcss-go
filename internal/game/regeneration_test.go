package game

import (
	"reflect"
	"testing"
	"time"

	"dcrawl-go/internal/character"
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
	health.Current, magic.Current = 7, 0
	for range 17 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	progress, ok := g.stores.Regeneration.Get(g.player)
	if !ok || health.Current != 8 || magic.Current != 1 || progress.HPProgress != 2 || progress.MPProgress != 5 {
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
	health.Current, magic.Current = 10, 0
	progress.HPProgress, progress.MPProgress = 94, 94
	expectedRNG := RestoreRNGStreams(g.seed, g.rng.States())
	want, err := character.Regenerate(expectedRNG, character.Vitality{
		HP:         10,
		MaxHP:      health.Max,
		MP:         0,
		MaxMP:      magic.Max,
		HPProgress: 94,
		MPProgress: 94,
	}, 9)
	if err != nil {
		t.Fatal(err)
	}

	g.turn.Actor = g.player
	if err := (&regenerationSystem{
		player:       g.player,
		health:       g.stores.Health,
		magic:        g.stores.Magic,
		regeneration: g.stores.Regeneration,
		rng:          g.rng,
		turn:         &g.turn,
	}).Update(nil, time.Duration(9)); err != nil {
		t.Fatal(err)
	}

	if health.Current != want.HP || magic.Current != want.MP ||
		progress.HPProgress != want.HPProgress || progress.MPProgress != want.MPProgress ||
		!reflect.DeepEqual(g.rng.States(), expectedRNG.States()) {
		t.Fatalf("9-aut system got HP %+v MP %+v regen %+v, want %+v", health, magic, progress, want)
	}
}

func TestRegenerationSaveContinuationAndLegacyDefault(t *testing.T) {
	g := newStepGame(t)
	moveRatToOtherFloor(t, g)
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)
	health.Current, magic.Current = 7, 0
	for range 3 {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := loaded.Step(Command{Kind: CommandWait})
	if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("regen continuation %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
	}

	legacy := newStepGame(t).Snapshot()
	for i := range legacy.Entities {
		legacy.Entities[i].Regeneration = nil
	}

	old, err := Restore(legacy, testCatalog(t))
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
			if loaded, err := Restore(bad, testCatalog(t)); err == nil {
				loaded.Close()
				t.Fatal("invalid regeneration save accepted")
			}
		})
	}
}
