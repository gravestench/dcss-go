package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
)

func TestLuaEnergyGrantUsesNamedRandomRounding(t *testing.T) {
	g := newStepGame(t)
	before := g.rng.States()

	exact, err := g.scripts.Policy("scheduler.grant", map[string]any{
		"active_level": 1,
		"elapsed":      10,
		"monsters": []any{
			map[string]any{
				"level_id": 1,
				"speed":    10,
				"points":   70,
			},

			map[string]any{
				"level_id": 2,
				"speed":    14,
				"points":   70,
			},
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(exact["points"], []any{int64(80), int64(70)}) {
		t.Fatalf("exact grant = %v", exact["points"])
	}

	if !reflect.DeepEqual(g.rng.States(), before) {
		t.Fatal("exact grant consumed monster RNG")
	}

	expected := RestoreRNGStreams(g.seed, before)
	roll, err := expected.Intn("monster_energy", 10)

	if err != nil {
		t.Fatal(err)
	}

	fractional, err := g.scripts.Policy("scheduler.grant", map[string]any{
		"active_level": 1,
		"elapsed":      9,
		"monsters": []any{
			map[string]any{
				"level_id": 1,
				"speed":    14,
				"points":   70,
			},
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	want := int64(82)

	if roll < 6 {
		want++
	}

	if !reflect.DeepEqual(fractional["points"], []any{want}) ||
		!reflect.DeepEqual(g.rng.States(), expected.States()) {
		t.Fatalf("fractional grant = %v, RNG %v", fractional["points"], g.rng.States())
	}
}

func TestLuaEnergyCostUsesResolvedIntent(t *testing.T) {
	g := newStepGame(t)

	for _, test := range []struct {
		intent ecs.IntentKind
		want   int64
	}{
		{
			intent: ecs.IntentMove,
			want:   90,
		},

		{
			intent: ecs.IntentMelee,
			want:   92,
		},

		{
			intent: ecs.IntentWait,
			want:   94,
		},
	} {
		result, err := g.scripts.Policy("scheduler.spend", map[string]any{
			"kind_id": "MONS_ALLIGATOR",
			"intent":  int(test.intent),
			"points":  100,
		})

		if err != nil ||
			result["points"] != test.want {
			t.Fatalf("intent %d => %v, %v; want %d", test.intent, result, err, test.want)
		}
	}

	for _, input := range []map[string]any{
		{
			"kind_id": "MONS_ALLIGATOR",
			"intent":  int(ecs.IntentWait),
			"points":  79,
		},

		{
			"kind_id": "MONS_ALLIGATOR",
			"intent":  int(ecs.IntentQuaff),
			"points":  100,
		},
	} {
		if _, err := g.scripts.Policy("scheduler.spend", input); err == nil {
			t.Fatalf("accepted invalid spend %v", input)
		}
	}
}
