package game

import (
	"strings"
	"testing"
	"time"

	"crawl/internal/ecs"
)

func TestLuaPoisonMatchesSourceRateRegions(t *testing.T) {
	for _, test := range []struct {
		name       string
		amount     int
		aut        int
		wantAmount int
		wantDamage int
	}{
		{
			name:       "minimum rate",
			amount:     4000,
			aut:        10,
			wantAmount: 3000,
			wantDamage: 1,
		},

		{
			name:       "ordinary exponential rate",
			amount:     100000,
			aut:        10,
			wantAmount: 80000,
			wantDamage: 20,
		},

		{
			name:       "maximum rate",
			amount:     500000,
			aut:        10,
			wantAmount: 450000,
			wantDamage: 50,
		},

		{
			name:       "partial action",
			amount:     2000,
			aut:        5,
			wantAmount: 1500,
			wantDamage: 1,
		},

		{
			name:       "status ends below one point",
			amount:     1000,
			aut:        10,
			wantAmount: 0,
			wantDamage: 1,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			g := newStepGame(t)

			g.turn.Actor = g.player

			health, _ := g.stores.Health.Get(g.player)

			health.Max = 200
			health.Current = 200

			if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
				AmountScaled: test.amount,
			}); err != nil {
				t.Fatal(err)
			}

			updateLuaSystem(t, g, "status.poison", time.Duration(test.aut))
			poison, present := g.stores.Poison.Get(g.player)
			amount := 0

			if present {
				amount = poison.AmountScaled
			}

			if amount != test.wantAmount ||
				health.Current != 200-test.wantDamage {
				t.Fatalf(
					"poison left amount %d and HP %d; want amount %d and damage %d",
					amount,
					health.Current,
					test.wantAmount,
					test.wantDamage,
				)
			}
		})
	}
}

func TestLuaStatusSystemsRejectInvalidState(t *testing.T) {
	for _, test := range []struct {
		name   string
		system string
		mutate func(*Game)
		want   string
	}{
		{
			name:   "missing player marker",
			system: "status.duration",
			mutate: func(g *Game) {
				g.stores.Players.Remove(g.player)
			},
			want: "player is missing core.player",
		},

		{
			name:   "missing duration state",
			system: "status.duration",
			mutate: func(g *Game) {
				g.stores.Durations.Remove(g.player)
			},
			want: "player is missing core.durations",
		},

		{
			name:   "negative might",
			system: "status.duration",
			mutate: func(g *Game) {
				durations, _ := g.stores.Durations.Get(g.player)

				durations.MightAut = -1
			},
			want: "invalid player durations",
		},

		{
			name:   "invalid recovery counter",
			system: "status.regeneration",
			mutate: func(g *Game) {
				progress, _ := g.stores.Regeneration.Get(g.player)

				progress.HPProgress = 100
			},
			want: "invalid player regeneration state",
		},

		{
			name:   "invalid poison amount",
			system: "status.poison",
			mutate: func(g *Game) {
				_, _ = g.stores.Poison.Set(g.player, ecs.Poison{
					AmountScaled: 999,
				})
			},
			want: "invalid player poison state",
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			g := newStepGame(t)

			g.turn.Actor = g.player

			test.mutate(g)

			for _, system := range g.scripts.Systems() {
				if system.Name != test.system {
					continue
				}

				err := system.Update(g.world, 10)

				if err == nil ||
					!strings.Contains(err.Error(), test.want) {
					t.Fatalf("wanted %q, got %v", test.want, err)
				}

				return
			}

			t.Fatalf("missing Lua system %s", test.system)
		})
	}
}

func TestLuaRegenerationLongActionUsesBothCounters(t *testing.T) {
	g := newStepGame(t)

	g.turn.Actor = g.player

	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)
	progress, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 10
	magic.Current = 0
	magic.Max = 3
	progress.HPProgress = 95
	progress.MPProgress = 95

	updateLuaSystem(t, g, "status.regeneration", 200)

	if health.Current != 12 ||
		progress.HPProgress != 15 ||
		magic.Current != 2 ||
		progress.MPProgress != 55 {
		t.Fatalf("long-action Lua regeneration: HP %+v MP %+v progress %+v", health, magic, progress)
	}
}

func TestLuaHasteWarningAndFinalFastAction(t *testing.T) {
	g := newStepGame(t)

	g.turn.Actor = g.player

	durations, _ := g.stores.Durations.Get(g.player)

	durations.HasteAut = 65

	for state := uint64(0); state < 100; state++ {
		probe := RestoreRNGStreams(g.seed, map[string]uint64{
			"speed": state,
		})

		roll, err := probe.Intn("speed", 2)

		if err != nil {
			t.Fatal(err)
		}

		if roll == 0 {
			g.rng.states["speed"] = state

			break
		}
	}

	updateLuaSystem(t, g, "status.duration", 7)

	if durations.HasteAut != 48 ||
		!containsEvent(g.turn.Events, "Your extra speed is starting to run out.") {
		t.Fatalf("Lua haste warning: duration %+v, events %+v", durations, g.turn.Events)
	}

	durations.HasteAut = 11
	updateLuaSystem(t, g, "status.duration", 14)

	if durations.HasteAut != 1 {
		t.Fatalf("final fast action left %d aut, want 1", durations.HasteAut)
	}

	updateLuaSystem(t, g, "status.duration", 6)

	if durations.HasteAut != 0 ||
		!containsEvent(g.turn.Events, "You feel yourself slow down.") {
		t.Fatalf("Lua haste expiry: duration %+v, events %+v", durations, g.turn.Events)
	}
}
